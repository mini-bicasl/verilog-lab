// Module: csr_regs
// Description: Control/Status Register file for DDR4 controller.
//              Provides timing values, scheduler policy, refresh mode,
//              ECC controls, and read-back counters via a simple
//              valid/ready register bus.
//
// Interface:
//   clk        - controller clock
//   rst_n      - active-low synchronous reset
//   csr_valid  - request valid
//   csr_write  - 1 = write, 0 = read
//   csr_addr   - register address (byte-aligned, word-select on [7:2])
//   csr_wdata  - write data (32-bit)
//   csr_rdata  - read data (32-bit)
//   csr_ready  - response ready (one-cycle pulse)
//
// Output ports (to timing_cfg / other blocks):
//   All CSR register values are exported as individual outputs.

`timescale 1ns/1ps

module csr_regs (
    input  wire        clk,
    input  wire        rst_n,

    // CSR bus
    input  wire        csr_valid,
    input  wire        csr_write,
    input  wire [7:0]  csr_addr,
    input  wire [31:0] csr_wdata,
    output reg  [31:0] csr_rdata,
    output reg         csr_ready,

    // Timing registers (in controller clock cycles)
    output reg  [7:0]  t_rcd,       // RAS-to-CAS delay
    output reg  [7:0]  t_rp,        // Row precharge time
    output reg  [7:0]  t_ras,       // Row active time (min)
    output reg  [7:0]  t_rc,        // Row cycle time
    output reg  [7:0]  t_ccd_l,     // CAS-to-CAS delay (long, same bank group)
    output reg  [7:0]  t_ccd_s,     // CAS-to-CAS delay (short, diff bank group)
    output reg  [7:0]  t_rrd_l,     // RAS-to-RAS delay (long, same bank group)
    output reg  [7:0]  t_rrd_s,     // RAS-to-RAS delay (short, diff bank group)
    output reg  [7:0]  t_faw,       // Four-activate window
    output reg  [7:0]  t_wtr_l,     // Write-to-Read delay (long)
    output reg  [7:0]  t_wtr_s,     // Write-to-Read delay (short)
    output reg  [7:0]  t_wr,        // Write recovery time
    output reg  [7:0]  t_rtp,       // Read-to-Precharge time
    output reg  [15:0] t_rfc,       // Refresh cycle time
    output reg  [15:0] t_refi,      // Refresh interval
    output reg  [7:0]  t_mod,       // Mode register set command delay
    output reg  [7:0]  t_mrd,       // Mode register command delay

    // Scheduler / policy
    output reg  [1:0]  sched_policy,   // 0=FR-FCFS, 1=deterministic priority
    output reg         page_policy,    // 0=open page, 1=close page

    // Refresh mode
    output reg  [1:0]  ref_mode,       // 0=all-bank, 1=per-bank
    output reg  [3:0]  ref_defer_max,  // max defer count before forced refresh

    // ECC controls
    output reg         ecc_enable,     // 1 = ECC encode/decode enabled
    output reg         ecc_inject_sbe, // inject single-bit error (test)
    output reg         ecc_inject_dbe, // inject double-bit error (test)

    // Interrupt mask
    output reg         irq_mask_sbe,   // mask single-bit ECC interrupt
    output reg         irq_mask_dbe,   // mask double-bit ECC interrupt

    // Counters (write 1 to clear)
    input  wire [31:0] sbe_count_in,   // single-bit error counter from ECC
    input  wire [31:0] dbe_count_in,   // double-bit error counter from ECC
    output reg  [31:0] sbe_count_latch,
    output reg  [31:0] dbe_count_latch
);

    // -----------------------------------------------------------------------
    // Address map (byte addresses, word-select bits [7:2])
    // -----------------------------------------------------------------------
    // 0x00 : t_rcd[7:0]  | t_rp[7:0]  | t_ras[7:0] | t_rc[7:0]
    // 0x04 : t_ccd_l[7:0]| t_ccd_s[7:0]| t_rrd_l[7:0]| t_rrd_s[7:0]
    // 0x08 : t_faw[7:0]  | t_wtr_l[7:0]| t_wtr_s[7:0]| t_wr[7:0]
    // 0x0C : t_rtp[7:0]  | t_mod[7:0] | t_mrd[7:0] | (rsvd)
    // 0x10 : t_rfc[15:0] | t_refi[15:0]
    // 0x14 : sched_policy[1:0] | page_policy | ref_mode[1:0] | ref_defer_max[3:0] (rsvd)
    // 0x18 : ecc_enable | ecc_inject_sbe | ecc_inject_dbe | irq_mask_sbe | irq_mask_dbe (rsvd)
    // 0x1C : sbe_count (R/W1C)
    // 0x20 : dbe_count (R/W1C)
    // -----------------------------------------------------------------------

    localparam ADDR_TIMING0  = 8'h00;
    localparam ADDR_TIMING1  = 8'h04;
    localparam ADDR_TIMING2  = 8'h08;
    localparam ADDR_TIMING3  = 8'h0C;
    localparam ADDR_TIMING4  = 8'h10;
    localparam ADDR_POLICY   = 8'h14;
    localparam ADDR_ECC      = 8'h18;
    localparam ADDR_SBE_CNT  = 8'h1C;
    localparam ADDR_DBE_CNT  = 8'h20;

    // Latch external counters every cycle
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sbe_count_latch <= 32'h0;
            dbe_count_latch <= 32'h0;
        end else begin
            sbe_count_latch <= sbe_count_in;
            dbe_count_latch <= dbe_count_in;
        end
    end

    // -----------------------------------------------------------------------
    // Reset defaults (DDR4-2400 typical, 8ns controller clock assumed)
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_rcd        <= 8'd15;
            t_rp         <= 8'd15;
            t_ras        <= 8'd35;
            t_rc         <= 8'd50;
            t_ccd_l      <= 8'd6;
            t_ccd_s      <= 8'd4;
            t_rrd_l      <= 8'd6;
            t_rrd_s      <= 8'd4;
            t_faw        <= 8'd16;
            t_wtr_l      <= 8'd10;
            t_wtr_s      <= 8'd4;
            t_wr         <= 8'd16;
            t_rtp        <= 8'd8;
            t_rfc        <= 16'd260;
            t_refi       <= 16'd1170;
            t_mod        <= 8'd24;
            t_mrd        <= 8'd8;
            sched_policy <= 2'b00;
            page_policy  <= 1'b0;
            ref_mode     <= 2'b00;
            ref_defer_max<= 4'd8;
            ecc_enable   <= 1'b1;
            ecc_inject_sbe <= 1'b0;
            ecc_inject_dbe <= 1'b0;
            irq_mask_sbe <= 1'b0;
            irq_mask_dbe <= 1'b0;
            csr_rdata    <= 32'h0;
            csr_ready    <= 1'b0;
        end else begin
            // Default: no response
            csr_ready <= 1'b0;
            csr_rdata <= 32'h0;

            if (csr_valid) begin
                csr_ready <= 1'b1;

                if (csr_write) begin
                    // -------------------------------------------------------
                    // Write path
                    // -------------------------------------------------------
                    case (csr_addr)
                        ADDR_TIMING0: begin
                            t_rcd  <= csr_wdata[31:24];
                            t_rp   <= csr_wdata[23:16];
                            t_ras  <= csr_wdata[15:8];
                            t_rc   <= csr_wdata[7:0];
                        end
                        ADDR_TIMING1: begin
                            t_ccd_l <= csr_wdata[31:24];
                            t_ccd_s <= csr_wdata[23:16];
                            t_rrd_l <= csr_wdata[15:8];
                            t_rrd_s <= csr_wdata[7:0];
                        end
                        ADDR_TIMING2: begin
                            t_faw   <= csr_wdata[31:24];
                            t_wtr_l <= csr_wdata[23:16];
                            t_wtr_s <= csr_wdata[15:8];
                            t_wr    <= csr_wdata[7:0];
                        end
                        ADDR_TIMING3: begin
                            t_rtp  <= csr_wdata[31:24];
                            t_mod  <= csr_wdata[23:16];
                            t_mrd  <= csr_wdata[15:8];
                            // [7:0] reserved
                        end
                        ADDR_TIMING4: begin
                            t_rfc  <= csr_wdata[31:16];
                            t_refi <= csr_wdata[15:0];
                        end
                        ADDR_POLICY: begin
                            sched_policy  <= csr_wdata[31:30];
                            page_policy   <= csr_wdata[29];
                            ref_mode      <= csr_wdata[28:27];
                            ref_defer_max <= csr_wdata[26:23];
                        end
                        ADDR_ECC: begin
                            ecc_enable     <= csr_wdata[31];
                            ecc_inject_sbe <= csr_wdata[30];
                            ecc_inject_dbe <= csr_wdata[29];
                            irq_mask_sbe   <= csr_wdata[28];
                            irq_mask_dbe   <= csr_wdata[27];
                        end
                        ADDR_SBE_CNT: begin
                            // W1C: writing 1 to a bit clears the latch
                            // (actual counter managed externally)
                        end
                        ADDR_DBE_CNT: begin
                            // W1C
                        end
                        default: ; // ignore unknown addresses
                    endcase
                end else begin
                    // -------------------------------------------------------
                    // Read path
                    // -------------------------------------------------------
                    case (csr_addr)
                        ADDR_TIMING0: csr_rdata <= {t_rcd, t_rp, t_ras, t_rc};
                        ADDR_TIMING1: csr_rdata <= {t_ccd_l, t_ccd_s, t_rrd_l, t_rrd_s};
                        ADDR_TIMING2: csr_rdata <= {t_faw, t_wtr_l, t_wtr_s, t_wr};
                        ADDR_TIMING3: csr_rdata <= {t_rtp, t_mod, t_mrd, 8'h00};
                        ADDR_TIMING4: csr_rdata <= {t_rfc, t_refi};
                        ADDR_POLICY:  csr_rdata <= {sched_policy, page_policy, ref_mode,
                                                     ref_defer_max, 23'h0};
                        ADDR_ECC:     csr_rdata <= {ecc_enable, ecc_inject_sbe,
                                                     ecc_inject_dbe, irq_mask_sbe,
                                                     irq_mask_dbe, 27'h0};
                        ADDR_SBE_CNT: csr_rdata <= sbe_count_latch;
                        ADDR_DBE_CNT: csr_rdata <= dbe_count_latch;
                        default:      csr_rdata <= 32'hDEAD_BEEF;
                    endcase
                end
            end
        end
    end

endmodule

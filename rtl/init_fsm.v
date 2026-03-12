// Module: init_fsm
// Description: Implements the JEDEC DDR4 power-on initialization and mode
//              register programming sequence.  Blocks host traffic (via
//              traffic_en) until initialization is complete and the PHY
//              reports calibration done.
//
// State sequence:
//   RESET       - hold CKE low, wait tXPR (200 us / cfg_txpr cycles)
//   CKE_HIGH    - assert CKE, wait tXPR settling
//   MRS_MR3     - program MR3 (fine granularity refresh)
//   MRS_MR6     - program MR6 (Write training, skipped here as 0)
//   MRS_MR5     - program MR5 (LP4x/CRC control, using defaults)
//   MRS_MR4     - program MR4 (CS-to-CMD/ADDR Latency, etc.)
//   MRS_MR2     - program MR2 (CWL / write leveling)
//   MRS_MR1     - program MR1 (additive latency, DQ driver etc.)
//   MRS_MR0     - program MR0 (burst length, CAS latency)
//   ZQCL        - ZQ calibration long
//   WAIT_PHY    - wait for phy_cal_done
//   DONE        - assert traffic_en, sit idle
//
// Note: MRS timing (t_mod / t_mrd) uses the active timing profile from
//       timing_cfg; ZQCL wait is fixed at 512 controller cycles (tZQinit).

`timescale 1ns/1ps

module init_fsm (
    input  wire        clk,
    input  wire        rst_n,

    // Timing parameters (from timing_cfg)
    input  wire [7:0]  tc_mod,      // MRS update delay (cycles)
    input  wire [7:0]  tc_mrd,      // MRS command delay (cycles)

    // PHY status
    input  wire        phy_init_done, // DDR4 SDRAM is ready (CKE logic)
    input  wire        phy_cal_done,  // PHY training complete

    // PHY command interface (MRS / ZQCL micro-commands)
    output reg         phy_cmd_valid,
    input  wire        phy_cmd_ready,
    output reg  [2:0]  phy_cmd,      // 3'b000=NOP, 3'b001=MRS, 3'b010=ZQCL
    output reg  [17:0] phy_addr,     // A[17:0]
    output reg  [1:0]  phy_ba,       // BA[1:0]
    output reg  [1:0]  phy_bg,       // BG[1:0]

    // Status outputs
    output reg         init_done,    // initialization sequence complete
    output reg         traffic_en    // allow host traffic
);

    // -----------------------------------------------------------------------
    // FSM state encoding
    // -----------------------------------------------------------------------
    localparam [3:0]
        S_RESET    = 4'd0,
        S_CKE_HIGH = 4'd1,
        S_MRS_MR3  = 4'd2,
        S_MRS_MR6  = 4'd3,
        S_MRS_MR5  = 4'd4,
        S_MRS_MR4  = 4'd5,
        S_MRS_MR2  = 4'd6,
        S_MRS_MR1  = 4'd7,
        S_MRS_MR0  = 4'd8,
        S_ZQCL     = 4'd9,
        S_WAIT_PHY = 4'd10,
        S_DONE     = 4'd11;

    // PHY command encodings
    localparam [2:0] CMD_NOP  = 3'b000;
    localparam [2:0] CMD_MRS  = 3'b001;
    localparam [2:0] CMD_ZQCL = 3'b010;

    // tXPR ≈ 200 µs / 8 ns = 25 000 cycles  (adjust for speed bin as needed)
    localparam [15:0] TXPR_CYCLES   = 16'd25000;
    // tZQinit = 512 nCK
    localparam [9:0]  TZQINIT_CYCLES = 10'd512;

    // -----------------------------------------------------------------------
    // Registers
    // -----------------------------------------------------------------------
    reg [3:0]  state;
    reg [15:0] wait_cnt;   // generic wait counter (counts down)

    // Default MRS values (DDR4-2400, CL=16, CWL=12, BL8)
    // Use simplified fixed values for bring-up (production firmware should
    // reprogram these via csr_regs before asserting cfg_capture).
    localparam [17:0] MR0_INIT = 18'h00051;  // CL=11 default for bring-up
    localparam [17:0] MR1_INIT = 18'h00001;  // A0=DLL enable
    localparam [17:0] MR2_INIT = 18'h00000;  // CWL=9 (000)
    localparam [17:0] MR3_INIT = 18'h00000;  // fine granularity refresh off
    localparam [17:0] MR4_INIT = 18'h00000;  // defaults
    localparam [17:0] MR5_INIT = 18'h00000;  // defaults
    localparam [17:0] MR6_INIT = 18'h00000;  // defaults

    // -----------------------------------------------------------------------
    // FSM
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_RESET;
            wait_cnt      <= TXPR_CYCLES;
            phy_cmd_valid <= 1'b0;
            phy_cmd       <= CMD_NOP;
            phy_addr      <= 18'h0;
            phy_ba        <= 2'b00;
            phy_bg        <= 2'b00;
            init_done     <= 1'b0;
            traffic_en    <= 1'b0;
        end else begin
            // Default: de-assert command valid unless actively sending
            phy_cmd_valid <= 1'b0;

            case (state)
                // -----------------------------------------------------------
                // RESET: Hold CKE low, count down tXPR
                // -----------------------------------------------------------
                S_RESET: begin
                    if (wait_cnt == 16'd0) begin
                        state    <= S_CKE_HIGH;
                        wait_cnt <= {8'h0, tc_mod}; // wait tMOD after CKE
                    end else begin
                        wait_cnt <= wait_cnt - 16'd1;
                    end
                end

                // -----------------------------------------------------------
                // CKE_HIGH: CKE has been raised by PHY; wait tMOD before MRS
                // -----------------------------------------------------------
                S_CKE_HIGH: begin
                    if (wait_cnt == 16'd0) begin
                        state    <= S_MRS_MR3;
                        wait_cnt <= {8'h0, tc_mrd};
                        // Issue MRS to MR3
                        phy_cmd_valid <= 1'b1;
                        phy_cmd  <= CMD_MRS;
                        phy_addr <= MR3_INIT;
                        phy_ba   <= 2'b11;
                        phy_bg   <= 2'b00;
                    end else begin
                        wait_cnt <= wait_cnt - 16'd1;
                    end
                end

                // -----------------------------------------------------------
                // MRS states: send MRS, wait tMRD / tMOD
                // -----------------------------------------------------------
                S_MRS_MR3: begin
                    if (!phy_cmd_valid) begin // command was accepted
                        if (wait_cnt == 16'd0) begin
                            state    <= S_MRS_MR6;
                            wait_cnt <= {8'h0, tc_mrd};
                            phy_cmd_valid <= 1'b1;
                            phy_cmd  <= CMD_MRS;
                            phy_addr <= MR6_INIT;
                            phy_ba   <= 2'b10; // MR6 encoded as BG1=1
                            phy_bg   <= 2'b01;
                        end else begin
                            wait_cnt <= wait_cnt - 16'd1;
                        end
                    end
                end

                S_MRS_MR6: begin
                    if (!phy_cmd_valid) begin
                        if (wait_cnt == 16'd0) begin
                            state    <= S_MRS_MR5;
                            wait_cnt <= {8'h0, tc_mrd};
                            phy_cmd_valid <= 1'b1;
                            phy_cmd  <= CMD_MRS;
                            phy_addr <= MR5_INIT;
                            phy_ba   <= 2'b01;
                            phy_bg   <= 2'b01;
                        end else begin
                            wait_cnt <= wait_cnt - 16'd1;
                        end
                    end
                end

                S_MRS_MR5: begin
                    if (!phy_cmd_valid) begin
                        if (wait_cnt == 16'd0) begin
                            state    <= S_MRS_MR4;
                            wait_cnt <= {8'h0, tc_mrd};
                            phy_cmd_valid <= 1'b1;
                            phy_cmd  <= CMD_MRS;
                            phy_addr <= MR4_INIT;
                            phy_ba   <= 2'b00;
                            phy_bg   <= 2'b01;
                        end else begin
                            wait_cnt <= wait_cnt - 16'd1;
                        end
                    end
                end

                S_MRS_MR4: begin
                    if (!phy_cmd_valid) begin
                        if (wait_cnt == 16'd0) begin
                            state    <= S_MRS_MR2;
                            wait_cnt <= {8'h0, tc_mrd};
                            phy_cmd_valid <= 1'b1;
                            phy_cmd  <= CMD_MRS;
                            phy_addr <= MR2_INIT;
                            phy_ba   <= 2'b10;
                            phy_bg   <= 2'b00;
                        end else begin
                            wait_cnt <= wait_cnt - 16'd1;
                        end
                    end
                end

                S_MRS_MR2: begin
                    if (!phy_cmd_valid) begin
                        if (wait_cnt == 16'd0) begin
                            state    <= S_MRS_MR1;
                            wait_cnt <= {8'h0, tc_mrd};
                            phy_cmd_valid <= 1'b1;
                            phy_cmd  <= CMD_MRS;
                            phy_addr <= MR1_INIT;
                            phy_ba   <= 2'b01;
                            phy_bg   <= 2'b00;
                        end else begin
                            wait_cnt <= wait_cnt - 16'd1;
                        end
                    end
                end

                S_MRS_MR1: begin
                    if (!phy_cmd_valid) begin
                        if (wait_cnt == 16'd0) begin
                            state    <= S_MRS_MR0;
                            wait_cnt <= {8'h0, tc_mod}; // tMOD after last MRS
                            phy_cmd_valid <= 1'b1;
                            phy_cmd  <= CMD_MRS;
                            phy_addr <= MR0_INIT;
                            phy_ba   <= 2'b00;
                            phy_bg   <= 2'b00;
                        end else begin
                            wait_cnt <= wait_cnt - 16'd1;
                        end
                    end
                end

                S_MRS_MR0: begin
                    if (!phy_cmd_valid) begin
                        if (wait_cnt == 16'd0) begin
                            state    <= S_ZQCL;
                            wait_cnt <= {6'h0, TZQINIT_CYCLES};
                            // Issue ZQCL
                            phy_cmd_valid <= 1'b1;
                            phy_cmd  <= CMD_ZQCL;
                            phy_addr <= 18'h00400; // A10 = 1 (long)
                            phy_ba   <= 2'b00;
                            phy_bg   <= 2'b00;
                        end else begin
                            wait_cnt <= wait_cnt - 16'd1;
                        end
                    end
                end

                // -----------------------------------------------------------
                // ZQCL: wait tZQinit
                // -----------------------------------------------------------
                S_ZQCL: begin
                    if (!phy_cmd_valid) begin
                        if (wait_cnt == 16'd0) begin
                            state <= S_WAIT_PHY;
                        end else begin
                            wait_cnt <= wait_cnt - 16'd1;
                        end
                    end
                end

                // -----------------------------------------------------------
                // WAIT_PHY: stall until PHY training is done
                // -----------------------------------------------------------
                S_WAIT_PHY: begin
                    if (phy_cal_done) begin
                        state      <= S_DONE;
                        init_done  <= 1'b1;
                        traffic_en <= 1'b1;
                    end
                end

                // -----------------------------------------------------------
                // DONE: stay here, keep traffic enabled
                // -----------------------------------------------------------
                S_DONE: begin
                    init_done  <= 1'b1;
                    traffic_en <= 1'b1;
                end

                default: state <= S_RESET;
            endcase
        end
    end

endmodule

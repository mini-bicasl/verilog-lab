// Module: timing_cfg
// Description: Latches the active timing profile exported from csr_regs and
//              re-exports it to timing_checker, bank_machine, and refresh_fsm.
//              A capture-enable input allows atomic timing updates between
//              initialization and normal operation without tearing.
//
// Interface:
//   clk          - controller clock
//   rst_n        - active-low synchronous reset
//   cfg_capture  - pulse-high for one cycle to latch all timing inputs
//   t_*          - timing inputs from csr_regs (pass-through with optional latch)
//   tc_*         - timing outputs to downstream blocks

`timescale 1ns/1ps

module timing_cfg (
    input  wire        clk,
    input  wire        rst_n,

    // Latch-enable: when asserted the current csr_regs outputs are captured
    // into the active timing profile.  Deasserted = hold last value.
    input  wire        cfg_capture,

    // ------------------------------------------------------------------
    // Inputs from csr_regs
    // ------------------------------------------------------------------
    input  wire [7:0]  t_rcd,
    input  wire [7:0]  t_rp,
    input  wire [7:0]  t_ras,
    input  wire [7:0]  t_rc,
    input  wire [7:0]  t_ccd_l,
    input  wire [7:0]  t_ccd_s,
    input  wire [7:0]  t_rrd_l,
    input  wire [7:0]  t_rrd_s,
    input  wire [7:0]  t_faw,
    input  wire [7:0]  t_wtr_l,
    input  wire [7:0]  t_wtr_s,
    input  wire [7:0]  t_wr,
    input  wire [7:0]  t_rtp,
    input  wire [15:0] t_rfc,
    input  wire [15:0] t_refi,
    input  wire [7:0]  t_mod,
    input  wire [7:0]  t_mrd,

    // ------------------------------------------------------------------
    // Active timing profile outputs (to timing_checker / bank_machine /
    // refresh_fsm)
    // ------------------------------------------------------------------
    output reg  [7:0]  tc_rcd,
    output reg  [7:0]  tc_rp,
    output reg  [7:0]  tc_ras,
    output reg  [7:0]  tc_rc,
    output reg  [7:0]  tc_ccd_l,
    output reg  [7:0]  tc_ccd_s,
    output reg  [7:0]  tc_rrd_l,
    output reg  [7:0]  tc_rrd_s,
    output reg  [7:0]  tc_faw,
    output reg  [7:0]  tc_wtr_l,
    output reg  [7:0]  tc_wtr_s,
    output reg  [7:0]  tc_wr,
    output reg  [7:0]  tc_rtp,
    output reg  [15:0] tc_rfc,
    output reg  [15:0] tc_refi,
    output reg  [7:0]  tc_mod,
    output reg  [7:0]  tc_mrd,

    // Indicates the active profile has been captured at least once
    output reg         cfg_valid
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Safe reset-time defaults (DDR4-2400 / 8 ns clock)
            tc_rcd   <= 8'd15;
            tc_rp    <= 8'd15;
            tc_ras   <= 8'd35;
            tc_rc    <= 8'd50;
            tc_ccd_l <= 8'd6;
            tc_ccd_s <= 8'd4;
            tc_rrd_l <= 8'd6;
            tc_rrd_s <= 8'd4;
            tc_faw   <= 8'd16;
            tc_wtr_l <= 8'd10;
            tc_wtr_s <= 8'd4;
            tc_wr    <= 8'd16;
            tc_rtp   <= 8'd8;
            tc_rfc   <= 16'd260;
            tc_refi  <= 16'd1170;
            tc_mod   <= 8'd24;
            tc_mrd   <= 8'd8;
            cfg_valid <= 1'b0;
        end else if (cfg_capture) begin
            // Atomic capture of the CSR timing snapshot
            tc_rcd   <= t_rcd;
            tc_rp    <= t_rp;
            tc_ras   <= t_ras;
            tc_rc    <= t_rc;
            tc_ccd_l <= t_ccd_l;
            tc_ccd_s <= t_ccd_s;
            tc_rrd_l <= t_rrd_l;
            tc_rrd_s <= t_rrd_s;
            tc_faw   <= t_faw;
            tc_wtr_l <= t_wtr_l;
            tc_wtr_s <= t_wtr_s;
            tc_wr    <= t_wr;
            tc_rtp   <= t_rtp;
            tc_rfc   <= t_rfc;
            tc_refi  <= t_refi;
            tc_mod   <= t_mod;
            tc_mrd   <= t_mrd;
            cfg_valid <= 1'b1;
        end
        // else: hold the current active profile
    end

endmodule

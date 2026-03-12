// Testbench: timing_cfg_tb
// Description: Verifies that timing_cfg correctly latches CSR timing values
//              on cfg_capture, holds them when not capturing, and resets
//              to safe defaults.

`timescale 1ns/1ps

module timing_cfg_tb;

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
    reg        clk;
    reg        rst_n;
    reg        cfg_capture;

    reg [7:0]  t_rcd, t_rp, t_ras, t_rc;
    reg [7:0]  t_ccd_l, t_ccd_s, t_rrd_l, t_rrd_s;
    reg [7:0]  t_faw, t_wtr_l, t_wtr_s, t_wr, t_rtp;
    reg [15:0] t_rfc, t_refi;
    reg [7:0]  t_mod, t_mrd;

    wire [7:0]  tc_rcd, tc_rp, tc_ras, tc_rc;
    wire [7:0]  tc_ccd_l, tc_ccd_s, tc_rrd_l, tc_rrd_s;
    wire [7:0]  tc_faw, tc_wtr_l, tc_wtr_s, tc_wr, tc_rtp;
    wire [15:0] tc_rfc, tc_refi;
    wire [7:0]  tc_mod, tc_mrd;
    wire        cfg_valid;

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
    timing_cfg dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .cfg_capture(cfg_capture),
        .t_rcd    (t_rcd),    .t_rp    (t_rp),
        .t_ras    (t_ras),    .t_rc    (t_rc),
        .t_ccd_l  (t_ccd_l), .t_ccd_s (t_ccd_s),
        .t_rrd_l  (t_rrd_l), .t_rrd_s (t_rrd_s),
        .t_faw    (t_faw),   .t_wtr_l (t_wtr_l),
        .t_wtr_s  (t_wtr_s), .t_wr    (t_wr),
        .t_rtp    (t_rtp),
        .t_rfc    (t_rfc),   .t_refi  (t_refi),
        .t_mod    (t_mod),   .t_mrd   (t_mrd),
        .tc_rcd   (tc_rcd),  .tc_rp   (tc_rp),
        .tc_ras   (tc_ras),  .tc_rc   (tc_rc),
        .tc_ccd_l (tc_ccd_l),.tc_ccd_s(tc_ccd_s),
        .tc_rrd_l (tc_rrd_l),.tc_rrd_s(tc_rrd_s),
        .tc_faw   (tc_faw),  .tc_wtr_l(tc_wtr_l),
        .tc_wtr_s (tc_wtr_s),.tc_wr   (tc_wr),
        .tc_rtp   (tc_rtp),
        .tc_rfc   (tc_rfc),  .tc_refi (tc_refi),
        .tc_mod   (tc_mod),  .tc_mrd  (tc_mrd),
        .cfg_valid(cfg_valid)
    );

    // -----------------------------------------------------------------------
    // Clock: 8 ns period
    // -----------------------------------------------------------------------
    initial clk = 0;
    always #4 clk = ~clk;

    // -----------------------------------------------------------------------
    // Waveform dump
    // -----------------------------------------------------------------------
    initial begin
        $dumpfile("results/phase-1-configuration-and-bring-up-foundations/timing_cfg.vcd");
        $dumpvars(0, timing_cfg_tb);
    end

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    task check8;
        input [7:0]  got;
        input [7:0]  exp;
        input [127:0] name;
        begin
            if (got === exp) begin
                $display("  PASS: %0s = 0x%02h", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %0s: got 0x%02h expected 0x%02h", name, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check16;
        input [15:0] got;
        input [15:0] exp;
        input [127:0] name;
        begin
            if (got === exp) begin
                $display("  PASS: %0s = 0x%04h", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %0s: got 0x%04h expected 0x%04h", name, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check1;
        input got;
        input exp;
        input [127:0] name;
        begin
            if (got === exp) begin
                $display("  PASS: %0s = %0b", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %0s: got %0b expected %0b", name, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Test stimulus
    // -----------------------------------------------------------------------
    initial begin
        pass_count  = 0;
        fail_count  = 0;
        cfg_capture = 0;

        // Set all input timings to distinctive values
        t_rcd   = 8'd20; t_rp    = 8'd18; t_ras  = 8'd40; t_rc   = 8'd55;
        t_ccd_l = 8'd7;  t_ccd_s = 8'd5;  t_rrd_l= 8'd7;  t_rrd_s= 8'd5;
        t_faw   = 8'd20; t_wtr_l = 8'd12; t_wtr_s= 8'd6;  t_wr   = 8'd18;
        t_rtp   = 8'd9;  t_rfc   = 16'd300; t_refi= 16'd1200;
        t_mod   = 8'd28; t_mrd   = 8'd10;

        // Apply reset
        rst_n = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // ------------------------------------------------------------------
        // TEST 1: After reset, cfg_valid should be 0, outputs are defaults
        // ------------------------------------------------------------------
        $display("\n[TEST 1] Reset defaults");
        check1(cfg_valid, 1'b0, "cfg_valid after reset");
        check8(tc_rcd,  8'd15, "tc_rcd reset default");
        check8(tc_rp,   8'd15, "tc_rp reset default");
        check16(tc_rfc, 16'd260, "tc_rfc reset default");
        check16(tc_refi,16'd1170,"tc_refi reset default");

        // ------------------------------------------------------------------
        // TEST 2: Capture should latch new values
        // ------------------------------------------------------------------
        $display("\n[TEST 2] Capture new timing");
        @(posedge clk);
        cfg_capture = 1;
        @(posedge clk);
        cfg_capture = 0;
        @(posedge clk);

        check1(cfg_valid, 1'b1, "cfg_valid after capture");
        check8(tc_rcd,   8'd20,  "tc_rcd after capture");
        check8(tc_rp,    8'd18,  "tc_rp after capture");
        check8(tc_ras,   8'd40,  "tc_ras after capture");
        check8(tc_rc,    8'd55,  "tc_rc after capture");
        check8(tc_ccd_l, 8'd7,   "tc_ccd_l after capture");
        check8(tc_ccd_s, 8'd5,   "tc_ccd_s after capture");
        check8(tc_rrd_l, 8'd7,   "tc_rrd_l after capture");
        check8(tc_rrd_s, 8'd5,   "tc_rrd_s after capture");
        check8(tc_faw,   8'd20,  "tc_faw after capture");
        check8(tc_wtr_l, 8'd12,  "tc_wtr_l after capture");
        check8(tc_wtr_s, 8'd6,   "tc_wtr_s after capture");
        check8(tc_wr,    8'd18,  "tc_wr after capture");
        check8(tc_rtp,   8'd9,   "tc_rtp after capture");
        check16(tc_rfc,  16'd300,"tc_rfc after capture");
        check16(tc_refi, 16'd1200,"tc_refi after capture");
        check8(tc_mod,   8'd28,  "tc_mod after capture");
        check8(tc_mrd,   8'd10,  "tc_mrd after capture");

        // ------------------------------------------------------------------
        // TEST 3: Inputs change but no capture – outputs held
        // ------------------------------------------------------------------
        $display("\n[TEST 3] Hold without capture");
        t_rcd   = 8'd99;
        t_refi  = 16'd9999;
        repeat(3) @(posedge clk);
        check8(tc_rcd,   8'd20,    "tc_rcd held");
        check16(tc_refi, 16'd1200, "tc_refi held");

        // ------------------------------------------------------------------
        // TEST 4: Second capture picks up new values
        // ------------------------------------------------------------------
        $display("\n[TEST 4] Second capture");
        @(posedge clk);
        cfg_capture = 1;
        @(posedge clk);
        cfg_capture = 0;
        @(posedge clk);
        check8(tc_rcd,   8'd99,    "tc_rcd second capture");
        check16(tc_refi, 16'd9999, "tc_refi second capture");

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("\n============================");
        $display("PASS: %0d   FAIL: %0d", pass_count, fail_count);
        $display("============================");
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #50000;
        $display("TIMEOUT");
        $finish;
    end

endmodule

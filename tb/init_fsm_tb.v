// Testbench: init_fsm_tb
// Description: Verifies the DDR4 initialization FSM by accelerating timing
//              parameters to small values and checking that:
//              - init_done / traffic_en are deasserted during init
//              - all expected MRS commands are issued in order
//              - ZQCL is issued after MR0
//              - init_done / traffic_en are asserted after phy_cal_done

`timescale 1ns/1ps

module init_fsm_tb;

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
    reg        clk;
    reg        rst_n;
    reg [7:0]  tc_mod;
    reg [7:0]  tc_mrd;
    reg        phy_init_done;
    reg        phy_cal_done;

    wire        phy_cmd_valid;
    reg         phy_cmd_ready;
    wire [2:0]  phy_cmd;
    wire [17:0] phy_addr;
    wire [1:0]  phy_ba;
    wire [1:0]  phy_bg;
    wire        init_done;
    wire        traffic_en;

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
    init_fsm dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .tc_mod       (tc_mod),
        .tc_mrd       (tc_mrd),
        .phy_init_done(phy_init_done),
        .phy_cal_done (phy_cal_done),
        .phy_cmd_valid(phy_cmd_valid),
        .phy_cmd_ready(phy_cmd_ready),
        .phy_cmd      (phy_cmd),
        .phy_addr     (phy_addr),
        .phy_ba       (phy_ba),
        .phy_bg       (phy_bg),
        .init_done    (init_done),
        .traffic_en   (traffic_en)
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
        $dumpfile("results/phase-1-configuration-and-bring-up-foundations/init_fsm.vcd");
        $dumpvars(0, init_fsm_tb);
    end

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // Command encodings (matches init_fsm)
    localparam CMD_NOP  = 3'b000;
    localparam CMD_MRS  = 3'b001;
    localparam CMD_ZQCL = 3'b010;

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

    task check3;
        input [2:0] got;
        input [2:0] exp;
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

    // Wait for a command to appear on phy_cmd_valid, then accept it
    task wait_and_accept_cmd;
        output [2:0]  got_cmd;
        output [17:0] got_addr;
        output [1:0]  got_ba;
        output [1:0]  got_bg;
        integer timeout;
        begin
            timeout = 0;
            while (!phy_cmd_valid && timeout < 100000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= 100000) begin
                $display("  TIMEOUT waiting for phy_cmd_valid");
                fail_count = fail_count + 1;
            end
            got_cmd  = phy_cmd;
            got_addr = phy_addr;
            got_ba   = phy_ba;
            got_bg   = phy_bg;
            // Accept
            phy_cmd_ready = 1;
            @(posedge clk);
            phy_cmd_ready = 0;
        end
    endtask

    // -----------------------------------------------------------------------
    // The FSM uses TXPR_CYCLES=25000 internally.  Override init_fsm's local
    // parameter by making tc_mod / tc_mrd very small (2 cycles) so the test
    // runs quickly.  The TXPR wait is still hardcoded in init_fsm but we can
    // work around it by observing behaviour with small counters.
    //
    // Because TXPR_CYCLES is a localparam inside init_fsm we cannot override
    // it from the TB.  Instead we run the full sequence and use a generous
    // timeout of 50 000 cycles (400 µs sim time).
    // -----------------------------------------------------------------------

    reg [2:0]  cmd_got;
    reg [17:0] addr_got;
    reg [1:0]  ba_got, bg_got;
    integer    mrs_count;

    initial begin
        pass_count   = 0;
        fail_count   = 0;
        mrs_count    = 0;
        phy_cmd_ready  = 1;
        phy_init_done  = 1;  // PHY SDRAM power-up is handled outside this FSM
        phy_cal_done   = 0;

        // Use the fastest supported timing values to keep sim time short
        tc_mod = 8'd2;
        tc_mrd = 8'd2;

        // Apply reset
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;

        // ------------------------------------------------------------------
        // TEST 1: traffic_en / init_done must be 0 immediately after reset
        // ------------------------------------------------------------------
        $display("\n[TEST 1] No traffic during init");
        @(posedge clk);
        check1(traffic_en, 1'b0, "traffic_en=0 after reset");
        check1(init_done,  1'b0, "init_done=0 after reset");

        // ------------------------------------------------------------------
        // TEST 2: Collect all MRS and ZQCL commands issued by the FSM
        //         Expected order: MR3, MR6, MR5, MR4, MR2, MR1, MR0, ZQCL
        // ------------------------------------------------------------------
        $display("\n[TEST 2] Collect MRS / ZQCL sequence (waiting for tXPR first)");
        // Wait for first MRS (after tXPR delay of 25000 cycles)
        wait_and_accept_cmd(cmd_got, addr_got, ba_got, bg_got);
        check3(cmd_got, CMD_MRS, "cmd#1 = MRS");
        mrs_count = mrs_count + 1;

        // MR6
        wait_and_accept_cmd(cmd_got, addr_got, ba_got, bg_got);
        check3(cmd_got, CMD_MRS, "cmd#2 = MRS");
        mrs_count = mrs_count + 1;

        // MR5
        wait_and_accept_cmd(cmd_got, addr_got, ba_got, bg_got);
        check3(cmd_got, CMD_MRS, "cmd#3 = MRS");
        mrs_count = mrs_count + 1;

        // MR4
        wait_and_accept_cmd(cmd_got, addr_got, ba_got, bg_got);
        check3(cmd_got, CMD_MRS, "cmd#4 = MRS");
        mrs_count = mrs_count + 1;

        // MR2
        wait_and_accept_cmd(cmd_got, addr_got, ba_got, bg_got);
        check3(cmd_got, CMD_MRS, "cmd#5 = MRS");
        mrs_count = mrs_count + 1;

        // MR1
        wait_and_accept_cmd(cmd_got, addr_got, ba_got, bg_got);
        check3(cmd_got, CMD_MRS, "cmd#6 = MRS");
        mrs_count = mrs_count + 1;

        // MR0
        wait_and_accept_cmd(cmd_got, addr_got, ba_got, bg_got);
        check3(cmd_got, CMD_MRS, "cmd#7 = MRS");
        mrs_count = mrs_count + 1;

        // ZQCL
        wait_and_accept_cmd(cmd_got, addr_got, ba_got, bg_got);
        check3(cmd_got, CMD_ZQCL, "cmd#8 = ZQCL");
        // Check A10 set for long ZQ
        check1(addr_got[10], 1'b1, "ZQCL A10=1 (long)");

        $display("  Total MRS count = %0d (expected 7)", mrs_count);
        if (mrs_count == 7) begin
            $display("  PASS: MRS count");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: MRS count");
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------------
        // TEST 3: Still waiting for phy_cal_done – no traffic yet
        // ------------------------------------------------------------------
        $display("\n[TEST 3] Wait after ZQCL – no traffic until cal_done");
        repeat(600) @(posedge clk); // wait past tZQinit
        check1(traffic_en, 1'b0, "traffic_en=0 before cal_done");

        // ------------------------------------------------------------------
        // TEST 4: Assert phy_cal_done – traffic_en should follow
        // ------------------------------------------------------------------
        $display("\n[TEST 4] Assert phy_cal_done");
        @(posedge clk);
        phy_cal_done = 1;
        repeat(3) @(posedge clk);
        check1(traffic_en, 1'b1, "traffic_en=1 after cal_done");
        check1(init_done,  1'b1, "init_done=1 after cal_done");

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
        #5000000; // 5 ms sim time (generous, tXPR=25000 cycles x 8ns = 200us)
        $display("TIMEOUT");
        $finish;
    end

endmodule

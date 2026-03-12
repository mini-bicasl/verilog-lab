// Testbench: phy_adapter_tb
// Description: Verifies the phy_adapter module:
//   - Command forwarding with backpressure (phy_cmd_ready)
//   - Write data forwarding
//   - Read data forwarding
//   - adapter_rdy assertion/deassertion based on PHY status
//   - Waveform dump for debugging

`timescale 1ns/1ps

module phy_adapter_tb;

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
    reg        clk;
    reg        rst_n;

    // Upstream command
    reg        up_cmd_valid;
    wire       up_cmd_ready;
    reg [2:0]  up_cmd;
    reg [17:0] up_addr;
    reg [1:0]  up_ba;
    reg [1:0]  up_bg;

    // Upstream write data
    reg        up_wdata_valid;
    wire       up_wdata_ready;
    reg [71:0] up_wdata;
    reg [8:0]  up_wmask;

    // Upstream read data
    wire        up_rdata_valid;
    wire [71:0] up_rdata;

    // PHY cmd
    wire        phy_cmd_valid;
    reg         phy_cmd_ready;
    wire [2:0]  phy_cmd;
    wire [17:0] phy_addr;
    wire [1:0]  phy_ba;
    wire [1:0]  phy_bg;

    // PHY write
    wire        phy_wdata_valid;
    reg         phy_wdata_ready;
    wire [71:0] phy_wdata;
    wire [8:0]  phy_wmask;

    // PHY read
    reg         phy_rdata_valid;
    reg [71:0]  phy_rdata;

    // PHY status
    reg         phy_init_done;
    reg         phy_cal_done;
    reg         phy_error;

    wire        adapter_rdy;

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
    phy_adapter dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .up_cmd_valid   (up_cmd_valid),
        .up_cmd_ready   (up_cmd_ready),
        .up_cmd         (up_cmd),
        .up_addr        (up_addr),
        .up_ba          (up_ba),
        .up_bg          (up_bg),
        .up_wdata_valid (up_wdata_valid),
        .up_wdata_ready (up_wdata_ready),
        .up_wdata       (up_wdata),
        .up_wmask       (up_wmask),
        .up_rdata_valid (up_rdata_valid),
        .up_rdata       (up_rdata),
        .phy_cmd_valid  (phy_cmd_valid),
        .phy_cmd_ready  (phy_cmd_ready),
        .phy_cmd        (phy_cmd),
        .phy_addr       (phy_addr),
        .phy_ba         (phy_ba),
        .phy_bg         (phy_bg),
        .phy_wdata_valid(phy_wdata_valid),
        .phy_wdata_ready(phy_wdata_ready),
        .phy_wdata      (phy_wdata),
        .phy_wmask      (phy_wmask),
        .phy_rdata_valid(phy_rdata_valid),
        .phy_rdata      (phy_rdata),
        .phy_init_done  (phy_init_done),
        .phy_cal_done   (phy_cal_done),
        .phy_error      (phy_error),
        .adapter_rdy    (adapter_rdy)
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
        $dumpfile("results/phase-1-configuration-and-bring-up-foundations/phy_adapter.vcd");
        $dumpvars(0, phy_adapter_tb);
    end

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

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
                $display("  PASS: %0s = 0x%h", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %0s: got 0x%h expected 0x%h", name, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check72;
        input [71:0] got;
        input [71:0] exp;
        input [127:0] name;
        begin
            if (got === exp) begin
                $display("  PASS: %0s = 0x%018h", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %0s: got 0x%018h expected 0x%018h", name, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Test stimulus
    // -----------------------------------------------------------------------
    initial begin
        pass_count     = 0;
        fail_count     = 0;
        up_cmd_valid   = 0;
        up_cmd         = 0;
        up_addr        = 0;
        up_ba          = 0;
        up_bg          = 0;
        up_wdata_valid = 0;
        up_wdata       = 0;
        up_wmask       = 0;
        phy_cmd_ready  = 1;
        phy_wdata_ready= 1;
        phy_rdata_valid= 0;
        phy_rdata      = 0;
        phy_init_done  = 0;
        phy_cal_done   = 0;
        phy_error      = 0;

        // Apply reset
        rst_n = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // ------------------------------------------------------------------
        // TEST 1: adapter_rdy is 0 while PHY not ready
        // ------------------------------------------------------------------
        $display("\n[TEST 1] adapter_rdy=0 while PHY not ready");
        @(posedge clk);
        check1(adapter_rdy, 1'b0, "adapter_rdy=0 (PHY not up)");

        // ------------------------------------------------------------------
        // TEST 2: adapter_rdy asserts when both init and cal done
        // ------------------------------------------------------------------
        $display("\n[TEST 2] adapter_rdy=1 when PHY up");
        phy_init_done = 1;
        phy_cal_done  = 1;
        repeat(2) @(posedge clk);
        check1(adapter_rdy, 1'b1, "adapter_rdy=1");

        // ------------------------------------------------------------------
        // TEST 3: adapter_rdy deasserts on phy_error
        // ------------------------------------------------------------------
        $display("\n[TEST 3] adapter_rdy=0 on phy_error");
        phy_error = 1;
        repeat(2) @(posedge clk);
        check1(adapter_rdy, 1'b0, "adapter_rdy=0 on error");
        phy_error = 0;
        repeat(2) @(posedge clk);
        check1(adapter_rdy, 1'b1, "adapter_rdy=1 after error clear");

        // ------------------------------------------------------------------
        // TEST 4: Command forwarding - ACT command
        // Check phy_cmd_valid / phy_cmd DURING the cycle the command is
        // presented (before deasserting up_cmd_valid).
        // ------------------------------------------------------------------
        $display("\n[TEST 4] Command forwarding (ACT)");
        @(posedge clk);
        up_cmd_valid = 1;
        up_cmd       = 3'b001; // ACT
        up_addr      = 18'h1A5B;
        up_ba        = 2'b10;
        up_bg        = 2'b01;
        @(posedge clk); // phy_cmd_valid registered 1 at this edge
        // Check immediately after edge, before deasserting
        check3(phy_cmd, 3'b001, "phy_cmd=ACT");
        check1(phy_cmd_valid, 1'b1, "phy_cmd_valid=1");
        up_cmd_valid = 0;

        // ------------------------------------------------------------------
        // TEST 5: Command forwarding - RD command
        // ------------------------------------------------------------------
        $display("\n[TEST 5] Command forwarding (RD)");
        repeat(2) @(posedge clk);
        up_cmd_valid = 1;
        up_cmd       = 3'b010; // RD
        up_addr      = 18'h0123;
        up_ba        = 2'b00;
        up_bg        = 2'b00;
        @(posedge clk); // phy_cmd registered
        check3(phy_cmd, 3'b010, "phy_cmd=RD");
        up_cmd_valid = 0;

        // ------------------------------------------------------------------
        // TEST 6: Write data forwarding
        // ------------------------------------------------------------------
        $display("\n[TEST 6] Write data forwarding");
        repeat(2) @(posedge clk);
        up_wdata_valid = 1;
        up_wdata       = 72'hABCD_EF01_2345_6789_AA;
        up_wmask       = 9'h1FF; // all bytes valid
        @(posedge clk); // phy_wdata_valid registered 1
        check72(phy_wdata, 72'hABCD_EF01_2345_6789_AA, "phy_wdata");
        check1(phy_wdata_valid, 1'b1, "phy_wdata_valid=1");
        up_wdata_valid = 0;

        // ------------------------------------------------------------------
        // TEST 7: Read data forwarding (PHY -> upstream)
        // Check up_rdata_valid DURING the registered cycle.
        // ------------------------------------------------------------------
        $display("\n[TEST 7] Read data forwarding");
        repeat(2) @(posedge clk);
        phy_rdata_valid = 1;
        phy_rdata       = 72'hDEAD_BEEF_CAFE_BABE_12;
        @(posedge clk); // up_rdata_valid registered 1
        check1(up_rdata_valid, 1'b1, "up_rdata_valid=1");
        check72(up_rdata, 72'hDEAD_BEEF_CAFE_BABE_12, "up_rdata");
        phy_rdata_valid = 0;

        // ------------------------------------------------------------------
        // TEST 8: Backpressure – PHY not ready, upstream ready held low
        // ------------------------------------------------------------------
        $display("\n[TEST 8] Command backpressure");
        phy_cmd_ready = 0;
        repeat(2) @(posedge clk);
        up_cmd_valid = 1;
        up_cmd       = 3'b011; // WR
        up_addr      = 18'h0;
        up_ba        = 2'b00;
        up_bg        = 2'b00;
        @(posedge clk);
        // With phy_cmd_ready=0, up_cmd_ready should not be asserted
        check1(up_cmd_ready, 1'b0, "up_cmd_ready=0 during backpressure");
        up_cmd_valid  = 0;
        phy_cmd_ready = 1;
        repeat(2) @(posedge clk);

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
        #100000;
        $display("TIMEOUT");
        $finish;
    end

endmodule

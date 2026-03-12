// Testbench: csr_regs_tb
// Description: Verifies CSR register read/write, reset defaults, and
//              counter read-back for the csr_regs module.

`timescale 1ns/1ps

module csr_regs_tb;

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg         csr_valid;
    reg         csr_write;
    reg  [7:0]  csr_addr;
    reg  [31:0] csr_wdata;
    wire [31:0] csr_rdata;
    wire        csr_ready;

    // Timing outputs (monitored but not fully driven back)
    wire [7:0]  t_rcd, t_rp, t_ras, t_rc;
    wire [7:0]  t_ccd_l, t_ccd_s, t_rrd_l, t_rrd_s;
    wire [7:0]  t_faw, t_wtr_l, t_wtr_s, t_wr, t_rtp;
    wire [15:0] t_rfc, t_refi;
    wire [7:0]  t_mod, t_mrd;
    wire [1:0]  sched_policy;
    wire        page_policy;
    wire [1:0]  ref_mode;
    wire [3:0]  ref_defer_max;
    wire        ecc_enable, ecc_inject_sbe, ecc_inject_dbe;
    wire        irq_mask_sbe, irq_mask_dbe;
    wire [31:0] sbe_count_latch, dbe_count_latch;

    reg  [31:0] sbe_count_in, dbe_count_in;

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
    csr_regs dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .csr_valid      (csr_valid),
        .csr_write      (csr_write),
        .csr_addr       (csr_addr),
        .csr_wdata      (csr_wdata),
        .csr_rdata      (csr_rdata),
        .csr_ready      (csr_ready),
        .t_rcd          (t_rcd),
        .t_rp           (t_rp),
        .t_ras          (t_ras),
        .t_rc           (t_rc),
        .t_ccd_l        (t_ccd_l),
        .t_ccd_s        (t_ccd_s),
        .t_rrd_l        (t_rrd_l),
        .t_rrd_s        (t_rrd_s),
        .t_faw          (t_faw),
        .t_wtr_l        (t_wtr_l),
        .t_wtr_s        (t_wtr_s),
        .t_wr           (t_wr),
        .t_rtp          (t_rtp),
        .t_rfc          (t_rfc),
        .t_refi         (t_refi),
        .t_mod          (t_mod),
        .t_mrd          (t_mrd),
        .sched_policy   (sched_policy),
        .page_policy    (page_policy),
        .ref_mode       (ref_mode),
        .ref_defer_max  (ref_defer_max),
        .ecc_enable     (ecc_enable),
        .ecc_inject_sbe (ecc_inject_sbe),
        .ecc_inject_dbe (ecc_inject_dbe),
        .irq_mask_sbe   (irq_mask_sbe),
        .irq_mask_dbe   (irq_mask_dbe),
        .sbe_count_in   (sbe_count_in),
        .dbe_count_in   (dbe_count_in),
        .sbe_count_latch(sbe_count_latch),
        .dbe_count_latch(dbe_count_latch)
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
        $dumpfile("results/phase-1-configuration-and-bring-up-foundations/csr_regs.vcd");
        $dumpvars(0, csr_regs_tb);
    end

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    task csr_write_reg;
        input [7:0]  addr;
        input [31:0] data;
        begin
            @(posedge clk);
            csr_valid <= 1'b1;
            csr_write <= 1'b1;
            csr_addr  <= addr;
            csr_wdata <= data;
            @(posedge clk);
            csr_valid <= 1'b0;
            csr_write <= 1'b0;
        end
    endtask

    task csr_read_reg;
        input  [7:0]  addr;
        output [31:0] data;
        begin
            @(posedge clk);
            csr_valid <= 1'b1;
            csr_write <= 1'b0;
            csr_addr  <= addr;
            @(posedge clk);
            csr_valid <= 1'b0;
            data      <= csr_rdata;
        end
    endtask

    task check;
        input [31:0] got;
        input [31:0] exp;
        input [127:0] name;
        begin
            if (got === exp) begin
                $display("  PASS: %0s = 0x%08h", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %0s: got 0x%08h expected 0x%08h", name, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Test stimulus
    // -----------------------------------------------------------------------
    reg [31:0] rdata;

    initial begin
        pass_count  = 0;
        fail_count  = 0;
        csr_valid   = 0;
        csr_write   = 0;
        csr_addr    = 0;
        csr_wdata   = 0;
        sbe_count_in = 32'd5;
        dbe_count_in = 32'd2;

        // Apply reset
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // ------------------------------------------------------------------
        // TEST 1: Check reset defaults on TIMING0 (t_rcd=15,t_rp=15,t_ras=35,t_rc=50)
        // ------------------------------------------------------------------
        $display("\n[TEST 1] Reset default TIMING0");
        csr_read_reg(8'h00, rdata);
        @(posedge clk);
        check(csr_rdata, 32'h0F_0F_23_32, "TIMING0 reset");

        // ------------------------------------------------------------------
        // TEST 2: Write new timing values and read back
        // ------------------------------------------------------------------
        $display("\n[TEST 2] Write/read TIMING0");
        csr_write_reg(8'h00, 32'h10_11_28_3C);
        repeat(2) @(posedge clk);
        csr_read_reg(8'h00, rdata);
        @(posedge clk);
        check(csr_rdata, 32'h10_11_28_3C, "TIMING0 write-back");

        // ------------------------------------------------------------------
        // TEST 3: Verify individual output ports match after write
        // ------------------------------------------------------------------
        $display("\n[TEST 3] Output port values after TIMING0 write");
        @(posedge clk);
        check({24'h0, t_rcd}, 32'h10, "t_rcd");
        check({24'h0, t_rp},  32'h11, "t_rp");
        check({24'h0, t_ras}, 32'h28, "t_ras");
        check({24'h0, t_rc},  32'h3C, "t_rc");

        // ------------------------------------------------------------------
        // TEST 4: Write / read TIMING4 (t_rfc, t_refi)
        // ------------------------------------------------------------------
        $display("\n[TEST 4] Write/read TIMING4");
        csr_write_reg(8'h10, 32'h0104_0492); // t_rfc=260, t_refi=1170
        repeat(2) @(posedge clk);
        csr_read_reg(8'h10, rdata);
        @(posedge clk);
        check(csr_rdata, 32'h0104_0492, "TIMING4 write-back");

        // ------------------------------------------------------------------
        // TEST 5: ECC controls
        // ------------------------------------------------------------------
        $display("\n[TEST 5] ECC control register");
        // ecc_enable=1, ecc_inject_sbe=1, others=0
        csr_write_reg(8'h18, 32'hC000_0000); // [31]=1, [30]=1
        repeat(2) @(posedge clk);
        csr_read_reg(8'h18, rdata);
        @(posedge clk);
        check(csr_rdata[31], 1'b1, "ecc_enable");
        check(csr_rdata[30], 1'b1, "ecc_inject_sbe");
        check(csr_rdata[29], 1'b0, "ecc_inject_dbe=0");

        // ------------------------------------------------------------------
        // TEST 6: Counter read-back
        // ------------------------------------------------------------------
        $display("\n[TEST 6] Counter read-back");
        csr_read_reg(8'h1C, rdata);
        @(posedge clk);
        check(csr_rdata, 32'd5, "sbe_count");
        csr_read_reg(8'h20, rdata);
        @(posedge clk);
        check(csr_rdata, 32'd2, "dbe_count");

        // ------------------------------------------------------------------
        // TEST 7: Policy register
        // ------------------------------------------------------------------
        $display("\n[TEST 7] Policy register write/read");
        // sched_policy=1 (deterministic), page_policy=1 (close)
        csr_write_reg(8'h14, 32'hE000_0000); // [31:30]=11 sched, [29]=1 page
        repeat(2) @(posedge clk);
        csr_read_reg(8'h14, rdata);
        @(posedge clk);
        check(csr_rdata[31:30], 2'b11, "sched_policy=3");
        check({31'h0, csr_rdata[29]}, 32'h1, "page_policy=1");

        // ------------------------------------------------------------------
        // TEST 8: Unknown address returns DEADBEEF
        // ------------------------------------------------------------------
        $display("\n[TEST 8] Unknown address returns 0xDEADBEEF");
        csr_read_reg(8'hFF, rdata);
        @(posedge clk);
        check(csr_rdata, 32'hDEAD_BEEF, "unknown addr");

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

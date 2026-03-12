`timescale 1ns/1ps

module csr_regs_tb;

reg         clk;
reg         rst_n;
reg         csr_valid;
reg         csr_write;
reg  [7:0]  csr_addr;
reg  [31:0] csr_wdata;
wire [31:0] csr_rdata;
wire        csr_ready;
reg         ecc_single_error_inc;
reg         ecc_double_error_inc;
wire        timing_profile_load;
wire [15:0] t_rcd_cfg;
wire [15:0] t_rp_cfg;
wire [15:0] t_ras_cfg;
wire [15:0] t_rc_cfg;
wire [15:0] t_rrd_cfg;
wire [15:0] t_faw_cfg;
wire [15:0] t_wtr_cfg;
wire [15:0] t_rfc_cfg;
wire [15:0] t_refi_cfg;
wire [1:0]  scheduler_policy;
wire        refresh_per_bank_mode;
wire        refresh_defer_enable;
wire        ecc_enable;
wire        ecc_inject_single;
wire        ecc_inject_double;
wire [31:0] ecc_single_error_count;
wire [31:0] ecc_double_error_count;

csr_regs dut (
    .clk(clk),
    .rst_n(rst_n),
    .csr_valid(csr_valid),
    .csr_write(csr_write),
    .csr_addr(csr_addr),
    .csr_wdata(csr_wdata),
    .csr_rdata(csr_rdata),
    .csr_ready(csr_ready),
    .ecc_single_error_inc(ecc_single_error_inc),
    .ecc_double_error_inc(ecc_double_error_inc),
    .timing_profile_load(timing_profile_load),
    .t_rcd_cfg(t_rcd_cfg),
    .t_rp_cfg(t_rp_cfg),
    .t_ras_cfg(t_ras_cfg),
    .t_rc_cfg(t_rc_cfg),
    .t_rrd_cfg(t_rrd_cfg),
    .t_faw_cfg(t_faw_cfg),
    .t_wtr_cfg(t_wtr_cfg),
    .t_rfc_cfg(t_rfc_cfg),
    .t_refi_cfg(t_refi_cfg),
    .scheduler_policy(scheduler_policy),
    .refresh_per_bank_mode(refresh_per_bank_mode),
    .refresh_defer_enable(refresh_defer_enable),
    .ecc_enable(ecc_enable),
    .ecc_inject_single(ecc_inject_single),
    .ecc_inject_double(ecc_inject_double),
    .ecc_single_error_count(ecc_single_error_count),
    .ecc_double_error_count(ecc_double_error_count)
);

always #5 clk = ~clk;

task csr_write32(input [7:0] addr, input [31:0] data);
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

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    csr_valid = 1'b0;
    csr_write = 1'b0;
    csr_addr = 8'd0;
    csr_wdata = 32'd0;
    ecc_single_error_inc = 1'b0;
    ecc_double_error_inc = 1'b0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    if (t_rcd_cfg !== 16'd12) $fatal("reset default t_rcd_cfg mismatch");
    if (t_refi_cfg !== 16'd7800) $fatal("reset default t_refi_cfg mismatch");

    csr_write32(8'h00, 32'h00000022);
    if (t_rcd_cfg !== 16'h0022) $fatal("CSR write did not update t_rcd_cfg");

    csr_write32(8'h24, 32'h00000002);
    if (scheduler_policy !== 2'b10) $fatal("scheduler_policy mismatch");

    csr_write32(8'h28, 32'h00000003);
    if (!refresh_per_bank_mode || !refresh_defer_enable) $fatal("refresh control mismatch");

    csr_write32(8'h2C, 32'h00000007);
    if (!ecc_enable || !ecc_inject_single || !ecc_inject_double) $fatal("ecc control mismatch");

    csr_write32(8'h3C, 32'h00000001);
    if (!timing_profile_load) $fatal("timing_profile_load should pulse on apply write");
    @(posedge clk);
    if (timing_profile_load) $fatal("timing_profile_load pulse should clear");

    @(posedge clk);
    ecc_single_error_inc <= 1'b1;
    ecc_double_error_inc <= 1'b1;
    @(posedge clk);
    ecc_single_error_inc <= 1'b0;
    ecc_double_error_inc <= 1'b0;
    if (ecc_single_error_count !== 32'd1) $fatal("single ECC counter mismatch");
    if (ecc_double_error_count !== 32'd1) $fatal("double ECC counter mismatch");

    $display("csr_regs_tb PASS");
    $finish;
end

endmodule

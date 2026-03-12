`timescale 1ns/1ps

module timing_cfg_tb;

reg        clk;
reg        rst_n;
reg        cfg_load;
reg [15:0] t_rcd_cfg;
reg [15:0] t_rp_cfg;
reg [15:0] t_ras_cfg;
reg [15:0] t_rc_cfg;
reg [15:0] t_rrd_cfg;
reg [15:0] t_faw_cfg;
reg [15:0] t_wtr_cfg;
reg [15:0] t_rfc_cfg;
reg [15:0] t_refi_cfg;
wire [15:0] t_rcd;
wire [15:0] t_rp;
wire [15:0] t_ras;
wire [15:0] t_rc;
wire [15:0] t_rrd;
wire [15:0] t_faw;
wire [15:0] t_wtr;
wire [15:0] t_rfc;
wire [15:0] t_refi;

timing_cfg dut (
    .clk(clk),
    .rst_n(rst_n),
    .cfg_load(cfg_load),
    .t_rcd_cfg(t_rcd_cfg),
    .t_rp_cfg(t_rp_cfg),
    .t_ras_cfg(t_ras_cfg),
    .t_rc_cfg(t_rc_cfg),
    .t_rrd_cfg(t_rrd_cfg),
    .t_faw_cfg(t_faw_cfg),
    .t_wtr_cfg(t_wtr_cfg),
    .t_rfc_cfg(t_rfc_cfg),
    .t_refi_cfg(t_refi_cfg),
    .t_rcd(t_rcd),
    .t_rp(t_rp),
    .t_ras(t_ras),
    .t_rc(t_rc),
    .t_rrd(t_rrd),
    .t_faw(t_faw),
    .t_wtr(t_wtr),
    .t_rfc(t_rfc),
    .t_refi(t_refi)
);

always #5 clk = ~clk;

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cfg_load = 1'b0;
    t_rcd_cfg = 16'd0;
    t_rp_cfg = 16'd0;
    t_ras_cfg = 16'd0;
    t_rc_cfg = 16'd0;
    t_rrd_cfg = 16'd0;
    t_faw_cfg = 16'd0;
    t_wtr_cfg = 16'd0;
    t_rfc_cfg = 16'd0;
    t_refi_cfg = 16'd0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    if (t_rcd !== 16'd12) $fatal("reset value mismatch");
    if (t_refi !== 16'd7800) $fatal("reset t_refi mismatch");

    t_rcd_cfg  = 16'd20;
    t_rp_cfg   = 16'd21;
    t_ras_cfg  = 16'd22;
    t_rc_cfg   = 16'd23;
    t_rrd_cfg  = 16'd24;
    t_faw_cfg  = 16'd25;
    t_wtr_cfg  = 16'd26;
    t_rfc_cfg  = 16'd27;
    t_refi_cfg = 16'd28;
    cfg_load   = 1'b1;
    @(posedge clk);
    cfg_load   = 1'b0;
    @(posedge clk);

    if (t_rcd !== 16'd20 || t_refi !== 16'd28) $fatal("load operation failed");

    $display("timing_cfg_tb PASS");
    $finish;
end

endmodule

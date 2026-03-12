`timescale 1ns/1ps

module phy_adapter_tb;

reg clk;
reg rst_n;
reg ctrl_cmd_valid;
wire ctrl_cmd_ready;
reg [2:0] ctrl_cmd;
reg [16:0] ctrl_addr;
reg [1:0] ctrl_ba;
reg [1:0] ctrl_bg;
reg ctrl_wdata_valid;
wire ctrl_wdata_ready;
reg [71:0] ctrl_wdata;
reg [8:0] ctrl_wmask;
reg phy_cmd_ready;
wire phy_cmd_valid;
wire [2:0] phy_cmd;
wire [16:0] phy_addr;
wire [1:0] phy_ba;
wire [1:0] phy_bg;
reg phy_wdata_ready;
wire phy_wdata_valid;
wire [71:0] phy_wdata;
wire [8:0] phy_wmask;
reg phy_init_done;
reg phy_cal_done;
reg phy_error;
wire adapter_ready;
wire adapter_error;

phy_adapter dut (
    .clk(clk),
    .rst_n(rst_n),
    .ctrl_cmd_valid(ctrl_cmd_valid),
    .ctrl_cmd_ready(ctrl_cmd_ready),
    .ctrl_cmd(ctrl_cmd),
    .ctrl_addr(ctrl_addr),
    .ctrl_ba(ctrl_ba),
    .ctrl_bg(ctrl_bg),
    .ctrl_wdata_valid(ctrl_wdata_valid),
    .ctrl_wdata_ready(ctrl_wdata_ready),
    .ctrl_wdata(ctrl_wdata),
    .ctrl_wmask(ctrl_wmask),
    .phy_cmd_ready(phy_cmd_ready),
    .phy_cmd_valid(phy_cmd_valid),
    .phy_cmd(phy_cmd),
    .phy_addr(phy_addr),
    .phy_ba(phy_ba),
    .phy_bg(phy_bg),
    .phy_wdata_ready(phy_wdata_ready),
    .phy_wdata_valid(phy_wdata_valid),
    .phy_wdata(phy_wdata),
    .phy_wmask(phy_wmask),
    .phy_init_done(phy_init_done),
    .phy_cal_done(phy_cal_done),
    .phy_error(phy_error),
    .adapter_ready(adapter_ready),
    .adapter_error(adapter_error)
);

always #5 clk = ~clk;

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    ctrl_cmd_valid = 1'b0;
    ctrl_cmd = 3'd0;
    ctrl_addr = 17'd0;
    ctrl_ba = 2'd0;
    ctrl_bg = 2'd0;
    ctrl_wdata_valid = 1'b0;
    ctrl_wdata = 72'd0;
    ctrl_wmask = 9'd0;
    phy_cmd_ready = 1'b1;
    phy_wdata_ready = 1'b1;
    phy_init_done = 1'b0;
    phy_cal_done = 1'b0;
    phy_error = 1'b0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    if (adapter_ready) $fatal("adapter should not be ready before PHY done");
    ctrl_cmd_valid = 1'b1;
    if (phy_cmd_valid) $fatal("command should not pass through before ready");

    phy_init_done = 1'b1;
    phy_cal_done = 1'b1;
    ctrl_cmd = 3'd2;
    ctrl_addr = 17'h1234;
    ctrl_ba = 2'b01;
    ctrl_bg = 2'b10;
    ctrl_wdata_valid = 1'b1;
    ctrl_wdata = 72'h1234_ABCD_EF12_3456_78;
    ctrl_wmask = 9'h1F;
    @(posedge clk);

    if (!adapter_ready) $fatal("adapter should be ready once PHY status is done");
    if (!phy_cmd_valid || phy_cmd != 3'd2) $fatal("command did not pass through");
    if (!phy_wdata_valid || phy_wdata != ctrl_wdata) $fatal("write data did not pass through");

    phy_error = 1'b1;
    @(posedge clk);
    phy_error = 1'b0;
    @(posedge clk);
    if (!adapter_error) $fatal("adapter_error should latch on phy_error");
    if (adapter_ready) $fatal("adapter_ready should drop after latched error");

    $display("phy_adapter_tb PASS");
    $finish;
end

endmodule

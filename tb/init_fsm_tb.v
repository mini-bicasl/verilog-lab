`timescale 1ns/1ps

module init_fsm_tb;

reg clk;
reg rst_n;
reg start;
reg phy_init_done;
reg phy_cal_done;
reg phy_cmd_ready;
wire phy_cmd_valid;
wire [2:0] phy_cmd;
wire init_done;
wire traffic_enable;
wire busy;
wire timeout_error;

init_fsm #(
    .WAIT_TIMEOUT_CYCLES(16'd32)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .phy_init_done(phy_init_done),
    .phy_cal_done(phy_cal_done),
    .phy_cmd_ready(phy_cmd_ready),
    .phy_cmd_valid(phy_cmd_valid),
    .phy_cmd(phy_cmd),
    .init_done(init_done),
    .traffic_enable(traffic_enable),
    .busy(busy),
    .timeout_error(timeout_error)
);

always #5 clk = ~clk;

integer cmd_seen;

always @(posedge clk) begin
    if (phy_cmd_valid && phy_cmd_ready) begin
        cmd_seen <= cmd_seen + 1;
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    start = 1'b0;
    phy_init_done = 1'b0;
    phy_cal_done = 1'b0;
    phy_cmd_ready = 1'b1;
    cmd_seen = 0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    repeat (3) @(posedge clk);
    phy_init_done = 1'b1;
    phy_cal_done = 1'b1;

    wait(init_done);
    @(posedge clk);
    if (!traffic_enable) $fatal("traffic_enable should be set after init");
    if (cmd_seen != 5) $fatal("expected 5 init commands (4xMRS + 1xZQCL)");
    if (timeout_error) $fatal("timeout_error should not assert in success flow");

    $display("init_fsm_tb PASS");
    $finish;
end

endmodule

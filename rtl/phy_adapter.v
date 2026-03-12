module phy_adapter #(
    parameter CMD_W  = 3,
    parameter ADDR_W = 17,
    parameter BA_W   = 2,
    parameter BG_W   = 2,
    parameter DQ_W   = 72
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  ctrl_cmd_valid,
    output wire                  ctrl_cmd_ready,
    input  wire [CMD_W-1:0]      ctrl_cmd,
    input  wire [ADDR_W-1:0]     ctrl_addr,
    input  wire [BA_W-1:0]       ctrl_ba,
    input  wire [BG_W-1:0]       ctrl_bg,
    input  wire                  ctrl_wdata_valid,
    output wire                  ctrl_wdata_ready,
    input  wire [DQ_W-1:0]       ctrl_wdata,
    input  wire [DQ_W/8-1:0]     ctrl_wmask,
    input  wire                  phy_cmd_ready,
    output wire                  phy_cmd_valid,
    output wire [CMD_W-1:0]      phy_cmd,
    output wire [ADDR_W-1:0]     phy_addr,
    output wire [BA_W-1:0]       phy_ba,
    output wire [BG_W-1:0]       phy_bg,
    input  wire                  phy_wdata_ready,
    output wire                  phy_wdata_valid,
    output wire [DQ_W-1:0]       phy_wdata,
    output wire [DQ_W/8-1:0]     phy_wmask,
    input  wire                  phy_init_done,
    input  wire                  phy_cal_done,
    input  wire                  phy_error,
    output wire                  adapter_ready,
    output reg                   adapter_error
);

assign adapter_ready = phy_init_done && phy_cal_done && !adapter_error;

assign ctrl_cmd_ready   = adapter_ready && phy_cmd_ready;
assign phy_cmd_valid    = adapter_ready && ctrl_cmd_valid;
assign phy_cmd          = ctrl_cmd;
assign phy_addr         = ctrl_addr;
assign phy_ba           = ctrl_ba;
assign phy_bg           = ctrl_bg;

assign ctrl_wdata_ready = adapter_ready && phy_wdata_ready;
assign phy_wdata_valid  = adapter_ready && ctrl_wdata_valid;
assign phy_wdata        = ctrl_wdata;
assign phy_wmask        = ctrl_wmask;

always @(posedge clk) begin
    if (!rst_n) begin
        adapter_error <= 1'b0;
    end else if (phy_error) begin
        adapter_error <= 1'b1;
    end
end

endmodule

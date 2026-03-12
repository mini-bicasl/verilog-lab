module init_fsm #(
    parameter WAIT_TIMEOUT_CYCLES = 16'd1024
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        phy_init_done,
    input  wire        phy_cal_done,
    input  wire        phy_cmd_ready,
    output reg         phy_cmd_valid,
    output reg  [2:0]  phy_cmd,
    output reg         init_done,
    output reg         traffic_enable,
    output reg         busy,
    output reg         timeout_error
);

localparam [2:0] CMD_MRS  = 3'd6;
localparam [2:0] CMD_ZQCL = 3'd7;

localparam [3:0] ST_IDLE     = 4'd0;
localparam [3:0] ST_WAIT_PHY = 4'd1;
localparam [3:0] ST_MRS0     = 4'd2;
localparam [3:0] ST_MRS1     = 4'd3;
localparam [3:0] ST_MRS2     = 4'd4;
localparam [3:0] ST_MRS3     = 4'd5;
localparam [3:0] ST_ZQCL     = 4'd6;
localparam [3:0] ST_DONE     = 4'd7;
localparam [3:0] ST_ERROR    = 4'd8;

reg [3:0] state;
reg [15:0] wait_count;

always @(posedge clk) begin
    if (!rst_n) begin
        state          <= ST_IDLE;
        wait_count     <= 16'd0;
        phy_cmd_valid  <= 1'b0;
        phy_cmd        <= 3'd0;
        init_done      <= 1'b0;
        traffic_enable <= 1'b0;
        busy           <= 1'b0;
        timeout_error  <= 1'b0;
    end else begin
        phy_cmd_valid <= 1'b0;

        case (state)
            ST_IDLE: begin
                init_done      <= 1'b0;
                traffic_enable <= 1'b0;
                busy           <= 1'b0;
                timeout_error  <= 1'b0;
                wait_count     <= 16'd0;
                if (start) begin
                    state <= ST_WAIT_PHY;
                    busy  <= 1'b1;
                end
            end

            ST_WAIT_PHY: begin
                if (phy_init_done && phy_cal_done) begin
                    state <= ST_MRS0;
                end else if (wait_count >= WAIT_TIMEOUT_CYCLES) begin
                    state         <= ST_ERROR;
                    timeout_error <= 1'b1;
                    busy          <= 1'b0;
                end else begin
                    wait_count <= wait_count + 1'b1;
                end
            end

            ST_MRS0: begin
                phy_cmd_valid <= 1'b1;
                phy_cmd       <= CMD_MRS;
                if (phy_cmd_ready) begin
                    state <= ST_MRS1;
                end
            end

            ST_MRS1: begin
                phy_cmd_valid <= 1'b1;
                phy_cmd       <= CMD_MRS;
                if (phy_cmd_ready) begin
                    state <= ST_MRS2;
                end
            end

            ST_MRS2: begin
                phy_cmd_valid <= 1'b1;
                phy_cmd       <= CMD_MRS;
                if (phy_cmd_ready) begin
                    state <= ST_MRS3;
                end
            end

            ST_MRS3: begin
                phy_cmd_valid <= 1'b1;
                phy_cmd       <= CMD_MRS;
                if (phy_cmd_ready) begin
                    state <= ST_ZQCL;
                end
            end

            ST_ZQCL: begin
                phy_cmd_valid <= 1'b1;
                phy_cmd       <= CMD_ZQCL;
                if (phy_cmd_ready) begin
                    state          <= ST_DONE;
                    init_done      <= 1'b1;
                    traffic_enable <= 1'b1;
                    busy           <= 1'b0;
                end
            end

            ST_DONE: begin
                init_done      <= 1'b1;
                traffic_enable <= 1'b1;
                busy           <= 1'b0;
            end

            default: begin
                state <= ST_ERROR;
            end
        endcase
    end
end

endmodule

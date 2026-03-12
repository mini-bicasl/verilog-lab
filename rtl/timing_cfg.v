module timing_cfg (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         cfg_load,
    input  wire [15:0]  t_rcd_cfg,
    input  wire [15:0]  t_rp_cfg,
    input  wire [15:0]  t_ras_cfg,
    input  wire [15:0]  t_rc_cfg,
    input  wire [15:0]  t_rrd_cfg,
    input  wire [15:0]  t_faw_cfg,
    input  wire [15:0]  t_wtr_cfg,
    input  wire [15:0]  t_rfc_cfg,
    input  wire [15:0]  t_refi_cfg,
    output reg  [15:0]  t_rcd,
    output reg  [15:0]  t_rp,
    output reg  [15:0]  t_ras,
    output reg  [15:0]  t_rc,
    output reg  [15:0]  t_rrd,
    output reg  [15:0]  t_faw,
    output reg  [15:0]  t_wtr,
    output reg  [15:0]  t_rfc,
    output reg  [15:0]  t_refi
);

always @(posedge clk) begin
    if (!rst_n) begin
        t_rcd  <= 16'd12;
        t_rp   <= 16'd12;
        t_ras  <= 16'd32;
        t_rc   <= 16'd44;
        t_rrd  <= 16'd6;
        t_faw  <= 16'd24;
        t_wtr  <= 16'd8;
        t_rfc  <= 16'd350;
        t_refi <= 16'd7800;
    end else if (cfg_load) begin
        t_rcd  <= t_rcd_cfg;
        t_rp   <= t_rp_cfg;
        t_ras  <= t_ras_cfg;
        t_rc   <= t_rc_cfg;
        t_rrd  <= t_rrd_cfg;
        t_faw  <= t_faw_cfg;
        t_wtr  <= t_wtr_cfg;
        t_rfc  <= t_rfc_cfg;
        t_refi <= t_refi_cfg;
    end
end

endmodule

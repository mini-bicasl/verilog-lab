module csr_regs #(
    parameter ADDR_W = 8,
    parameter DATA_W = 32
) (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 csr_valid,
    input  wire                 csr_write,
    input  wire [ADDR_W-1:0]    csr_addr,
    input  wire [DATA_W-1:0]    csr_wdata,
    output reg  [DATA_W-1:0]    csr_rdata,
    output wire                 csr_ready,
    input  wire                 ecc_single_error_inc,
    input  wire                 ecc_double_error_inc,
    output reg                  timing_profile_load,
    output reg  [15:0]          t_rcd_cfg,
    output reg  [15:0]          t_rp_cfg,
    output reg  [15:0]          t_ras_cfg,
    output reg  [15:0]          t_rc_cfg,
    output reg  [15:0]          t_rrd_cfg,
    output reg  [15:0]          t_faw_cfg,
    output reg  [15:0]          t_wtr_cfg,
    output reg  [15:0]          t_rfc_cfg,
    output reg  [15:0]          t_refi_cfg,
    output reg  [1:0]           scheduler_policy,
    output reg                  refresh_per_bank_mode,
    output reg                  refresh_defer_enable,
    output reg                  ecc_enable,
    output reg                  ecc_inject_single,
    output reg                  ecc_inject_double,
    output reg  [31:0]          ecc_single_error_count,
    output reg  [31:0]          ecc_double_error_count
);

localparam [ADDR_W-1:0] ADDR_T_RCD      = 8'h00;
localparam [ADDR_W-1:0] ADDR_T_RP       = 8'h04;
localparam [ADDR_W-1:0] ADDR_T_RAS      = 8'h08;
localparam [ADDR_W-1:0] ADDR_T_RC       = 8'h0C;
localparam [ADDR_W-1:0] ADDR_T_RRD      = 8'h10;
localparam [ADDR_W-1:0] ADDR_T_FAW      = 8'h14;
localparam [ADDR_W-1:0] ADDR_T_WTR      = 8'h18;
localparam [ADDR_W-1:0] ADDR_T_RFC      = 8'h1C;
localparam [ADDR_W-1:0] ADDR_T_REFI     = 8'h20;
localparam [ADDR_W-1:0] ADDR_SCHED_CTRL = 8'h24;
localparam [ADDR_W-1:0] ADDR_REFRESH    = 8'h28;
localparam [ADDR_W-1:0] ADDR_ECC_CTRL   = 8'h2C;
localparam [ADDR_W-1:0] ADDR_ECC_S_CNT  = 8'h30;
localparam [ADDR_W-1:0] ADDR_ECC_D_CNT  = 8'h34;
localparam [ADDR_W-1:0] ADDR_APPLY      = 8'h3C;

assign csr_ready = 1'b1;

always @(posedge clk) begin
    if (!rst_n) begin
        t_rcd_cfg             <= 16'd12;
        t_rp_cfg              <= 16'd12;
        t_ras_cfg             <= 16'd32;
        t_rc_cfg              <= 16'd44;
        t_rrd_cfg             <= 16'd6;
        t_faw_cfg             <= 16'd24;
        t_wtr_cfg             <= 16'd8;
        t_rfc_cfg             <= 16'd350;
        t_refi_cfg            <= 16'd7800;
        scheduler_policy      <= 2'b00;
        refresh_per_bank_mode <= 1'b0;
        refresh_defer_enable  <= 1'b1;
        ecc_enable            <= 1'b1;
        ecc_inject_single     <= 1'b0;
        ecc_inject_double     <= 1'b0;
        ecc_single_error_count <= 32'd0;
        ecc_double_error_count <= 32'd0;
        timing_profile_load    <= 1'b0;
    end else begin
        timing_profile_load <= 1'b0;

        if (ecc_single_error_inc) begin
            ecc_single_error_count <= ecc_single_error_count + 32'd1;
        end
        if (ecc_double_error_inc) begin
            ecc_double_error_count <= ecc_double_error_count + 32'd1;
        end

        if (csr_valid && csr_write) begin
            case (csr_addr)
                ADDR_T_RCD:      t_rcd_cfg              <= csr_wdata[15:0];
                ADDR_T_RP:       t_rp_cfg               <= csr_wdata[15:0];
                ADDR_T_RAS:      t_ras_cfg              <= csr_wdata[15:0];
                ADDR_T_RC:       t_rc_cfg               <= csr_wdata[15:0];
                ADDR_T_RRD:      t_rrd_cfg              <= csr_wdata[15:0];
                ADDR_T_FAW:      t_faw_cfg              <= csr_wdata[15:0];
                ADDR_T_WTR:      t_wtr_cfg              <= csr_wdata[15:0];
                ADDR_T_RFC:      t_rfc_cfg              <= csr_wdata[15:0];
                ADDR_T_REFI:     t_refi_cfg             <= csr_wdata[15:0];
                ADDR_SCHED_CTRL: scheduler_policy       <= csr_wdata[1:0];
                ADDR_REFRESH: begin
                    refresh_per_bank_mode <= csr_wdata[0];
                    refresh_defer_enable  <= csr_wdata[1];
                end
                ADDR_ECC_CTRL: begin
                    ecc_enable        <= csr_wdata[0];
                    ecc_inject_single <= csr_wdata[1];
                    ecc_inject_double <= csr_wdata[2];
                end
                ADDR_ECC_S_CNT: ecc_single_error_count <= csr_wdata;
                ADDR_ECC_D_CNT: ecc_double_error_count <= csr_wdata;
                ADDR_APPLY:     timing_profile_load    <= csr_wdata[0];
                default: ;
            endcase
        end
    end
end

always @(*) begin
    case (csr_addr)
        ADDR_T_RCD:      csr_rdata = {16'd0, t_rcd_cfg};
        ADDR_T_RP:       csr_rdata = {16'd0, t_rp_cfg};
        ADDR_T_RAS:      csr_rdata = {16'd0, t_ras_cfg};
        ADDR_T_RC:       csr_rdata = {16'd0, t_rc_cfg};
        ADDR_T_RRD:      csr_rdata = {16'd0, t_rrd_cfg};
        ADDR_T_FAW:      csr_rdata = {16'd0, t_faw_cfg};
        ADDR_T_WTR:      csr_rdata = {16'd0, t_wtr_cfg};
        ADDR_T_RFC:      csr_rdata = {16'd0, t_rfc_cfg};
        ADDR_T_REFI:     csr_rdata = {16'd0, t_refi_cfg};
        ADDR_SCHED_CTRL: csr_rdata = {30'd0, scheduler_policy};
        ADDR_REFRESH:    csr_rdata = {30'd0, refresh_defer_enable, refresh_per_bank_mode};
        ADDR_ECC_CTRL:   csr_rdata = {29'd0, ecc_inject_double, ecc_inject_single, ecc_enable};
        ADDR_ECC_S_CNT:  csr_rdata = ecc_single_error_count;
        ADDR_ECC_D_CNT:  csr_rdata = ecc_double_error_count;
        default:         csr_rdata = {DATA_W{1'b0}};
    endcase
end

endmodule

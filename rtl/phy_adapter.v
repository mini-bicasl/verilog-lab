// Module: phy_adapter
// Description: PHY command/data handshake shell.  Translates internal
//              micro-commands (ACT/RD/WR/PRE/REF/MRS/ZQCL/NOP) and data
//              payloads into the DDR4 PHY-facing strobe interface.
//
//              This is an abstraction layer; real PHY command encoding is
//              vendor-specific.  The adapter:
//                - Accepts commands from the scheduler / init_fsm
//                - Forwards them to the PHY command port with backpressure
//                - Passes write data (72-bit ECC payload) to the PHY
//                - Receives read data from the PHY and passes it upstream
//                - Monitors phy_init_done / phy_cal_done / phy_error
//
// Interface:
//   clk / rst_n   - clock and active-low synchronous reset
//
//   -- Upstream command interface (from scheduler / init_fsm) --
//   up_cmd_valid  - upstream command valid
//   up_cmd_ready  - adapter accepts upstream command
//   up_cmd[2:0]   - command (NOP=0,ACT=1,RD=2,WR=3,PRE=4,REF=5,MRS=6,ZQCL=7)
//   up_addr[17:0] - row/col/mode address
//   up_ba[1:0]    - bank address
//   up_bg[1:0]    - bank-group address
//
//   -- Upstream write data interface --
//   up_wdata_valid
//   up_wdata_ready
//   up_wdata[71:0]  - 72-bit ECC-encoded write data
//   up_wmask[8:0]   - byte enable mask
//
//   -- Upstream read data interface --
//   up_rdata_valid
//   up_rdata[71:0]
//
//   -- PHY command port (downstream) --
//   phy_cmd_valid / phy_cmd_ready
//   phy_cmd[2:0] / phy_addr[17:0] / phy_ba[1:0] / phy_bg[1:0]
//
//   -- PHY write data port --
//   phy_wdata_valid / phy_wdata_ready
//   phy_wdata[71:0] / phy_wmask[8:0]
//
//   -- PHY read data port --
//   phy_rdata_valid
//   phy_rdata[71:0]
//
//   -- PHY status --
//   phy_init_done / phy_cal_done / phy_error
//
//   -- Status output --
//   adapter_rdy   - 1 once PHY is up and no error

`timescale 1ns/1ps

module phy_adapter (
    input  wire        clk,
    input  wire        rst_n,

    // -------------------------------------------------------------------
    // Upstream command interface
    // -------------------------------------------------------------------
    input  wire        up_cmd_valid,
    output reg         up_cmd_ready,
    input  wire [2:0]  up_cmd,
    input  wire [17:0] up_addr,
    input  wire [1:0]  up_ba,
    input  wire [1:0]  up_bg,

    // -------------------------------------------------------------------
    // Upstream write data
    // -------------------------------------------------------------------
    input  wire        up_wdata_valid,
    output reg         up_wdata_ready,
    input  wire [71:0] up_wdata,
    input  wire [8:0]  up_wmask,

    // -------------------------------------------------------------------
    // Upstream read data (to ECC decode / data_path)
    // -------------------------------------------------------------------
    output reg         up_rdata_valid,
    output reg  [71:0] up_rdata,

    // -------------------------------------------------------------------
    // PHY command port (downstream)
    // -------------------------------------------------------------------
    output reg         phy_cmd_valid,
    input  wire        phy_cmd_ready,
    output reg  [2:0]  phy_cmd,
    output reg  [17:0] phy_addr,
    output reg  [1:0]  phy_ba,
    output reg  [1:0]  phy_bg,

    // -------------------------------------------------------------------
    // PHY write data port
    // -------------------------------------------------------------------
    output reg         phy_wdata_valid,
    input  wire        phy_wdata_ready,
    output reg  [71:0] phy_wdata,
    output reg  [8:0]  phy_wmask,

    // -------------------------------------------------------------------
    // PHY read data port
    // -------------------------------------------------------------------
    input  wire        phy_rdata_valid,
    input  wire [71:0] phy_rdata,

    // -------------------------------------------------------------------
    // PHY status
    // -------------------------------------------------------------------
    input  wire        phy_init_done,
    input  wire        phy_cal_done,
    input  wire        phy_error,

    // -------------------------------------------------------------------
    // Adapter status
    // -------------------------------------------------------------------
    output reg         adapter_rdy  // PHY up, no error
);

    // -----------------------------------------------------------------------
    // Adapter ready: combinational from PHY status
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            adapter_rdy <= 1'b0;
        else
            adapter_rdy <= phy_init_done & phy_cal_done & ~phy_error;
    end

    // -----------------------------------------------------------------------
    // Command forwarding
    // The adapter presents an identity mapping between the upstream command
    // interface and the PHY command port.  Backpressure from phy_cmd_ready
    // is propagated back to up_cmd_ready.
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phy_cmd_valid <= 1'b0;
            phy_cmd       <= 3'b000;
            phy_addr      <= 18'h0;
            phy_ba        <= 2'b00;
            phy_bg        <= 2'b00;
            up_cmd_ready  <= 1'b0;
        end else begin
            // Simple combinational forwarding registered one stage
            if (up_cmd_valid && phy_cmd_ready) begin
                phy_cmd_valid <= 1'b1;
                phy_cmd       <= up_cmd;
                phy_addr      <= up_addr;
                phy_ba        <= up_ba;
                phy_bg        <= up_bg;
                up_cmd_ready  <= 1'b1;
            end else if (!up_cmd_valid) begin
                phy_cmd_valid <= 1'b0;
                up_cmd_ready  <= 1'b0;
            end else begin
                // PHY busy: hold command, deassert ready to upstream
                phy_cmd_valid <= phy_cmd_valid;
                up_cmd_ready  <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Write data forwarding
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phy_wdata_valid <= 1'b0;
            phy_wdata       <= 72'h0;
            phy_wmask       <= 9'h0;
            up_wdata_ready  <= 1'b0;
        end else begin
            if (up_wdata_valid && phy_wdata_ready) begin
                phy_wdata_valid <= 1'b1;
                phy_wdata       <= up_wdata;
                phy_wmask       <= up_wmask;
                up_wdata_ready  <= 1'b1;
            end else if (!up_wdata_valid) begin
                phy_wdata_valid <= 1'b0;
                up_wdata_ready  <= 1'b0;
            end else begin
                phy_wdata_valid <= phy_wdata_valid;
                up_wdata_ready  <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Read data forwarding (PHY -> upstream, no buffering needed at this
    // abstraction level – just register one stage for timing closure)
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            up_rdata_valid <= 1'b0;
            up_rdata       <= 72'h0;
        end else begin
            up_rdata_valid <= phy_rdata_valid;
            up_rdata       <= phy_rdata;
        end
    end

endmodule

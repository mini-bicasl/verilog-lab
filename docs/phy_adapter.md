# `phy_adapter` – PHY Command/Data Handshake Shell

## Overview

`phy_adapter` is the abstraction boundary between the DDR4 controller's internal micro-command pipeline and the vendor-specific PHY command/data strobes.  It forwards commands and data in both directions with single-cycle registered latency, propagates PHY backpressure to upstream blocks, and derives the `adapter_rdy` status signal from the PHY health pins.

## Role in Architecture

```
scheduler / init_fsm
        |  up_cmd_valid/ready/cmd/addr/ba/bg
        v
  [ phy_adapter ]
        |  phy_cmd_valid/ready/cmd/addr/ba/bg
        v
     DDR4 PHY ←── vendor-specific implementation
        |
        | phy_rdata_valid / phy_rdata[71:0]
        v
  [ phy_adapter ]
        |  up_rdata_valid / up_rdata[71:0]
        v
  ecc_decode / data_path
```

## Module Interface

### Ports – Upstream (Controller Side)

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | Controller clock |
| `rst_n` | in | 1 | Active-low synchronous reset |
| `up_cmd_valid` | in | 1 | Upstream command valid |
| `up_cmd_ready` | out | 1 | Adapter ready to accept command |
| `up_cmd` | in | 3 | Command type (see encoding below) |
| `up_addr` | in | 18 | Row/column/mode address |
| `up_ba` | in | 2 | Bank address |
| `up_bg` | in | 2 | Bank-group address |
| `up_wdata_valid` | in | 1 | Write data valid |
| `up_wdata_ready` | out | 1 | Adapter ready to accept write data |
| `up_wdata` | in | 72 | ECC-encoded write data (64-bit + 8 check bits) |
| `up_wmask` | in | 9 | Byte-enable mask (1 bit per byte) |
| `up_rdata_valid` | out | 1 | Read data valid to upstream |
| `up_rdata` | out | 72 | Read data from PHY (72-bit raw) |

### Ports – Downstream (PHY Side)

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `phy_cmd_valid` | out | 1 | Command valid to PHY |
| `phy_cmd_ready` | in | 1 | PHY ready to accept command |
| `phy_cmd` | out | 3 | Command type (pass-through) |
| `phy_addr` | out | 18 | Address (pass-through) |
| `phy_ba` | out | 2 | Bank address |
| `phy_bg` | out | 2 | Bank-group address |
| `phy_wdata_valid` | out | 1 | Write data valid to PHY |
| `phy_wdata_ready` | in | 1 | PHY ready to accept write data |
| `phy_wdata` | out | 72 | Write data to PHY |
| `phy_wmask` | out | 9 | Byte-enable mask |
| `phy_rdata_valid` | in | 1 | PHY provides read data |
| `phy_rdata` | in | 72 | Read data from PHY |
| `phy_init_done` | in | 1 | PHY SDRAM power-up complete |
| `phy_cal_done` | in | 1 | PHY training calibration complete |
| `phy_error` | in | 1 | PHY error (training failure, etc.) |

### Status Port

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `adapter_rdy` | out | 1 | 1 when PHY is operational and error-free |

## Command Encoding

| `up_cmd` / `phy_cmd` | Mnemonic | Description |
|----------------------|----------|-------------|
| `3'b000` | NOP | No operation |
| `3'b001` | ACT | Row activate |
| `3'b010` | RD | Read |
| `3'b011` | WR | Write |
| `3'b100` | PRE | Precharge |
| `3'b101` | REF | Refresh |
| `3'b110` | MRS | Mode register set |
| `3'b111` | ZQCL | ZQ calibration long |

## Data Path

- **Command path**: `up_cmd_*` → register stage → `phy_cmd_*`.  Backpressure (`phy_cmd_ready=0`) stalls `up_cmd_ready`.
- **Write path**: `up_wdata_*` → register stage → `phy_wdata_*`.  Backpressure from `phy_wdata_ready` stalls `up_wdata_ready`.
- **Read path**: `phy_rdata_*` → one register stage → `up_rdata_*` (no upstream backpressure at this layer).

## `adapter_rdy` Semantics

```
adapter_rdy = phy_init_done & phy_cal_done & ~phy_error
```

- Asserted once the PHY is fully operational.
- Deasserted immediately on `phy_error=1`; re-asserted when the error clears (PHY-managed recovery).
- Upstream logic (scheduler, `ddr4_ctrl_top`) should gate command issuance on `adapter_rdy`.

## Design Notes

- Latency: one register stage in each direction (1 cycle command, 1 cycle read data).
- The adapter does not perform command encoding; it passes the abstract 3-bit command value directly.  The vendor PHY is responsible for translating this to DDR4 CS#/RAS#/CAS#/WE# signals.
- `up_cmd_ready` is deasserted when `phy_cmd_ready=0`, implementing correct valid-ready backpressure.

## Files

- RTL: [`rtl/phy_adapter.v`](../rtl/phy_adapter.v)
- Testbench: [`tb/phy_adapter_tb.v`](../tb/phy_adapter_tb.v)

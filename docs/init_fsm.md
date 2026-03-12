# `init_fsm` – DDR4 Initialization & Mode-Register Programming FSM

## Overview

`init_fsm` implements the mandatory JEDEC DDR4 power-on initialization sequence.  It drives MRS (Mode Register Set) commands and a long ZQ calibration (ZQCL) command toward the PHY command port, then waits for PHY training to complete before asserting `traffic_en` to allow normal host traffic.

## Role in Architecture

```
          phy_cal_done (from PHY)
                  |
  rst_n ──> [ init_fsm ] ──> phy_cmd_valid/cmd/addr/ba/bg ──> phy_adapter ──> DDR4 PHY
                  |
                  +──> init_done  (status)
                  └──> traffic_en ──> ddr4_ctrl_top (gate normal traffic)
```

## Initialization State Sequence

```
RESET ──(tXPR elapsed)──> CKE_HIGH ──(tMOD)──> MRS_MR3 ──(tMRD)──> MRS_MR6
  ──(tMRD)──> MRS_MR5 ──(tMRD)──> MRS_MR4 ──(tMRD)──> MRS_MR2
  ──(tMRD)──> MRS_MR1 ──(tMRD/tMOD)──> MRS_MR0 ──> ZQCL ──(tZQinit=512 nCK)──>
  WAIT_PHY ──(phy_cal_done=1)──> DONE
```

### State descriptions

| State | Description |
|-------|-------------|
| `RESET` | CKE held low, countdown of tXPR (25 000 cycles ≈ 200 µs @ 8 ns) |
| `CKE_HIGH` | CKE raised by PHY; FSM waits `tc_mod` before first MRS |
| `MRS_MR3` | Programs Fine Granularity Refresh (default: off) |
| `MRS_MR6` | Programs Write Training / VREFDQ training |
| `MRS_MR5` | Programs CRC and CA parity / LP4x controls |
| `MRS_MR4` | Programs CS-to-CMD/ADDR latency / MPR page |
| `MRS_MR2` | Programs CWL and write-leveling |
| `MRS_MR1` | Programs additive latency, DQ driver strength |
| `MRS_MR0` | Programs CAS latency, burst length, DLL reset |
| `ZQCL` | Issues ZQCL (A10=1) with `tZQinit = 512` cycle wait |
| `WAIT_PHY` | Waits for `phy_cal_done` from the PHY |
| `DONE` | Holds `init_done = 1`, `traffic_en = 1`; stays indefinitely |

## Module Interface

### Ports

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | Controller clock |
| `rst_n` | in | 1 | Active-low synchronous reset |
| `tc_mod` | in | 8 | tMOD (from `timing_cfg`) |
| `tc_mrd` | in | 8 | tMRD (from `timing_cfg`) |
| `phy_init_done` | in | 1 | SDRAM power-up / CKE logic complete (from PHY) |
| `phy_cal_done` | in | 1 | PHY training complete |
| `phy_cmd_valid` | out | 1 | Command valid to PHY |
| `phy_cmd_ready` | in | 1 | PHY accepts command |
| `phy_cmd` | out | 3 | Command type (0=NOP, 1=MRS, 2=ZQCL) |
| `phy_addr` | out | 18 | Address/mode-register word |
| `phy_ba` | out | 2 | Bank address |
| `phy_bg` | out | 2 | Bank-group address |
| `init_done` | out | 1 | Initialization complete |
| `traffic_en` | out | 1 | Allow host traffic (same as `init_done`) |

### Timing Notes

- **tXPR** (25 000 cycles) is a hardcoded localparam sized for 200 µs at 8 ns.  Adjust for other clock frequencies.
- **tMRD / tMOD** are supplied by `timing_cfg` so they track the programmed speed bin.
- **tZQinit** (512 nCK) is hardcoded per JEDEC spec.

## Mode Register Defaults

| Register | Reset value | Key setting |
|----------|-------------|-------------|
| MR0 | `0x00051` | CL=11 (bring-up safe), BL=8 |
| MR1 | `0x00001` | DLL enable |
| MR2 | `0x00000` | CWL=9 |
| MR3–MR6 | `0x00000` | All defaults |

> These are bring-up defaults. Production firmware should overwrite them via `csr_regs` before asserting `cfg_capture`, then trigger a new init.

## Completion Criteria

- `init_done` / `traffic_en` are asserted **only** after:
  1. All 7 MRS commands have been accepted by the PHY
  2. ZQCL + tZQinit wait has elapsed
  3. `phy_cal_done` has been received

## Files

- RTL: [`rtl/init_fsm.v`](../rtl/init_fsm.v)
- Testbench: [`tb/init_fsm_tb.v`](../tb/init_fsm_tb.v)

# `timing_cfg` – Active Timing Profile Latch

## Overview

`timing_cfg` sits between `csr_regs` and the timing-sensitive datpath blocks (`timing_checker`, `bank_machine`, `refresh_fsm`).  It holds a single stable snapshot of all JEDEC timing parameters and exposes them as registered outputs that never change mid-operation.  A `cfg_capture` pulse atomically replaces the held profile with the current CSR values.

## Role in Architecture

```
csr_regs (timing outputs)
        |
        | (continuous wires)
        v
  [ timing_cfg ]
        |  cfg_capture (one-cycle pulse from init_fsm or software)
        |
        +──> tc_* outputs ──> timing_checker (legality checks)
        +──> tc_* outputs ──> bank_machine   (row-open timer)
        └──> tc_* outputs ──> refresh_fsm    (tREFI / tRFC)
```

## Module Interface

### Ports

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | Controller clock |
| `rst_n` | in | 1 | Active-low synchronous reset |
| `cfg_capture` | in | 1 | Pulse-high for one cycle to latch timing inputs |
| `t_rcd` … `t_mrd` | in | 8/16 | Timing inputs from `csr_regs` |
| `tc_rcd` … `tc_mrd` | out | 8/16 | Active timing profile (held until next capture) |
| `cfg_valid` | out | 1 | 1 once a capture has occurred since reset |

### Capture Semantics

- On `cfg_capture=1` (one-cycle pulse), all `t_*` inputs are sampled at the rising clock edge and stored in the output registers.
- While `cfg_capture=0`, outputs hold their last captured value.
- `cfg_valid` is 0 after reset and becomes 1 after the first successful capture.
- Multiple captures are allowed; each overwrites the previous profile.

## Timing Parameters

All values are in **controller clock cycles**.

| Output | Width | Description |
|--------|-------|-------------|
| `tc_rcd` | 8 | RAS-to-CAS delay |
| `tc_rp` | 8 | Row precharge time |
| `tc_ras` | 8 | Row active time (minimum) |
| `tc_rc` | 8 | Row cycle time (tRAS + tRP) |
| `tc_ccd_l` | 8 | CAS-to-CAS (same bank group) |
| `tc_ccd_s` | 8 | CAS-to-CAS (different bank group) |
| `tc_rrd_l` | 8 | RAS-to-RAS (same bank group) |
| `tc_rrd_s` | 8 | RAS-to-RAS (different bank group) |
| `tc_faw` | 8 | Four-activate window |
| `tc_wtr_l` | 8 | Write-to-read (same bank group) |
| `tc_wtr_s` | 8 | Write-to-read (different bank group) |
| `tc_wr` | 8 | Write recovery time |
| `tc_rtp` | 8 | Read-to-precharge time |
| `tc_rfc` | 16 | Refresh cycle time |
| `tc_refi` | 16 | Refresh interval |
| `tc_mod` | 8 | Mode register set delay |
| `tc_mrd` | 8 | Mode register command delay |

## Reset Defaults

The module powers up with the same defaults as `csr_regs` so downstream blocks remain functional even if `cfg_capture` is never asserted during a simulation or bringup.  See [`csr_regs.md`](csr_regs.md) for the numeric defaults.

## Update Rules

1. Write new timing values to `csr_regs` via the CSR bus.
2. Assert `cfg_capture=1` for exactly one clock cycle.
3. On the next rising edge, `tc_*` outputs carry the new values.
4. No `cfg_capture` pulse should be issued while a DRAM command is in-flight; best practice is to issue it only during the initialization window (before `traffic_en` is asserted by `init_fsm`).

## Files

- RTL: [`rtl/timing_cfg.v`](../rtl/timing_cfg.v)
- Testbench: [`tb/timing_cfg_tb.v`](../tb/timing_cfg_tb.v)

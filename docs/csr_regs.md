# `csr_regs` – Control/Status Register File

## Overview

`csr_regs` is the central configuration hub for the DDR4 controller.  It exposes a flat register map accessible through a simple valid/ready bus.  All timing parameters, scheduler policy, refresh mode, ECC controls, interrupt masks, and error counters are stored here and broadcast as combinational/registered outputs to downstream blocks.

## Role in Architecture

```
host_if / software driver
        |
        v
   [ csr_regs ]  ──> timing outputs ──> timing_cfg ──> timing_checker / bank_machine
        |           ──> policy   ──> scheduler
        |           ──> ref_mode ──> refresh_fsm
        └──────────── ecc config ──> ecc_encode / ecc_decode
```

## Module Interface

### Ports

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | Controller clock |
| `rst_n` | in | 1 | Active-low synchronous reset |
| `csr_valid` | in | 1 | Bus transaction valid |
| `csr_write` | in | 1 | 1 = write, 0 = read |
| `csr_addr` | in | 8 | Byte address (word-aligned, selects on `[7:2]`) |
| `csr_wdata` | in | 32 | Write data |
| `csr_rdata` | out | 32 | Read data (registered, valid one cycle after `csr_valid`) |
| `csr_ready` | out | 1 | Response handshake (one-cycle pulse) |
| `t_rcd` … `t_mrd` | out | 8/16 | Active timing values (see register map) |
| `sched_policy` | out | 2 | Scheduler arbitration policy |
| `page_policy` | out | 1 | 0 = open-page, 1 = close-page |
| `ref_mode` | out | 2 | 0 = all-bank refresh, 1 = per-bank refresh |
| `ref_defer_max` | out | 4 | Max refresh defer count before force |
| `ecc_enable` | out | 1 | 1 = ECC encode/decode enabled |
| `ecc_inject_sbe` | out | 1 | Single-bit error injection (test) |
| `ecc_inject_dbe` | out | 1 | Double-bit error injection (test) |
| `irq_mask_sbe` | out | 1 | Mask single-bit ECC interrupt |
| `irq_mask_dbe` | out | 1 | Mask double-bit ECC interrupt |
| `sbe_count_in` | in | 32 | Live single-bit error count (from ECC path) |
| `dbe_count_in` | in | 32 | Live double-bit error count (from ECC path) |
| `sbe_count_latch` | out | 32 | Latched SBE counter (read-back) |
| `dbe_count_latch` | out | 32 | Latched DBE counter (read-back) |

### Bus Protocol

- One-cycle transaction: assert `csr_valid` for one cycle; `csr_ready` is asserted the following cycle.
- Reads: `csr_rdata` is valid when `csr_ready` is high.
- Writes: take effect on the cycle `csr_ready` is asserted.
- Back-to-back transactions are supported; `csr_ready` is a single-cycle pulse.

## Register Map

| Address | Field | Reset | Description |
|---------|-------|-------|-------------|
| `0x00` | `{t_rcd, t_rp, t_ras, t_rc}` | `0x0F0F2332` | Core row timing (bytes, cycles) |
| `0x04` | `{t_ccd_l, t_ccd_s, t_rrd_l, t_rrd_s}` | `0x06060404` | CAS/RAS spacing |
| `0x08` | `{t_faw, t_wtr_l, t_wtr_s, t_wr}` | `0x100A0410` | FAW / write-to-read / write recovery |
| `0x0C` | `{t_rtp, t_mod, t_mrd, rsvd}` | `0x08180800` | RTP / MRS timing |
| `0x10` | `{t_rfc[15:0], t_refi[15:0]}` | `0x01040492` | Refresh timing (16-bit each) |
| `0x14` | `{sched_policy[1:0], page_policy, ref_mode[1:0], ref_defer_max[3:0], rsvd}` | `0x00000000` | Scheduler & refresh policy |
| `0x18` | `{ecc_enable, ecc_inject_sbe, ecc_inject_dbe, irq_mask_sbe, irq_mask_dbe, rsvd}` | `0x80000000` | ECC controls |
| `0x1C` | `sbe_count` | R/O | Single-bit error counter (W1C write clears external) |
| `0x20` | `dbe_count` | R/O | Double-bit error counter |

> Reset defaults target DDR4-2400 with an 8 ns controller clock.  Update these values at initialization time via the CSR bus before asserting `cfg_capture` in `timing_cfg`.

## Reset Defaults

| Parameter | Reset value | DDR4-2400 (8 ns clock) |
|-----------|-------------|------------------------|
| `t_rcd` | 15 | tRCD = 120 ns / 8 ns = 15 cycles |
| `t_rp` | 15 | tRP = 120 ns / 8 ns = 15 cycles |
| `t_ras` | 35 | tRAS = 280 ns / 8 ns = 35 cycles |
| `t_rc` | 50 | tRC = 400 ns / 8 ns = 50 cycles |
| `t_rfc` | 260 | tRFC = 260 cycles (8 Gb DRAM) |
| `t_refi` | 1170 | tREFI = 7.8 µs / 8 ns ≈ 975, padded to 1170 |
| `ecc_enable` | 1 | ECC on by default |

## Programming Model

1. Assert reset (`rst_n=0`) to load all defaults.
2. Optionally reprogram timing for your speed bin via writes to `0x00`–`0x10`.
3. Write policy/ECC registers at `0x14`–`0x18`.
4. Trigger `timing_cfg.cfg_capture=1` to atomically publish the new values.

## Files

- RTL: [`rtl/csr_regs.v`](../rtl/csr_regs.v)
- Testbench: [`tb/csr_regs_tb.v`](../tb/csr_regs_tb.v)

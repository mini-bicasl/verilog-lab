# csr_regs

`csr_regs` implements the configuration/status register map for DDR4 controller bring-up settings.

## Responsibilities

- Expose programmable timing values used by downstream timing logic
- Select scheduler policy and refresh behavior mode bits
- Control ECC enable and injection knobs
- Count ECC single- and double-bit events
- Emit a `timing_profile_load` pulse to request a timing profile latch

## Interface Summary

- CSR bus: `csr_valid`, `csr_write`, `csr_addr`, `csr_wdata`, `csr_rdata`, `csr_ready`
- Event inputs: `ecc_single_error_inc`, `ecc_double_error_inc`
- Configuration outputs: `t_*_cfg`, scheduler/refresh/ECC controls

## Register Map

- `0x00..0x20`: timing values (`tRCD`, `tRP`, `tRAS`, `tRC`, `tRRD`, `tFAW`, `tWTR`, `tRFC`, `tREFI`)
- `0x24`: scheduler policy (`[1:0]`)
- `0x28`: refresh controls (`per_bank_mode`, `defer_enable`)
- `0x2C`: ECC controls (`enable`, `inject_single`, `inject_double`)
- `0x30`: ECC single-bit counter
- `0x34`: ECC double-bit counter
- `0x3C`: apply register (`bit0` pulses `timing_profile_load`)

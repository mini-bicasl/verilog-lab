# DDR4 Controller Implementation Plan

This plan turns `docs/ARCHITECTURE.md` into an incremental implementation roadmap for a server-grade JEDEC DDR4 controller.

## RTL Modules

### Phase 1: Configuration and bring-up foundations

- [ ] `csr_regs`: CSR map for timing values, scheduler policy, refresh mode, ECC controls, and counters
- [ ] `timing_cfg`: latched timing profile export to datapath/control blocks
- [ ] `init_fsm`: JEDEC DDR4 initialization and mode-register programming gate
- [ ] `phy_adapter`: PHY command/data handshake shell (`phy_cmd_*`, `phy_wdata_*`, `phy_rdata_*`, PHY status)

### Phase 2: Command buffering, legality, and per-bank state

- [ ] `host_if`: host request/response channels with ID propagation and backpressure handling
- [ ] `cmd_queue`: decode and queue ACT/RD/WR/PRE/REF intents from host requests
- [ ] `bank_machine`: per-bank row-open/idle tracking and command readiness status
- [ ] `timing_checker`: JEDEC timing legality engine (tRCD/tRP/tRAS/tRC/tCCD/tFAW/tWTR/tRRD/tRFC/tREFI)

### Phase 3: Arbitration, refresh, and data integrity

- [ ] `scheduler`: legal command selection with policy mode (fairness/performance)
- [ ] `refresh_fsm`: tREFI-based refresh deadline tracking with defer/pull-in control
- [ ] `ecc_encode`: SECDED encode from host 64-bit write payload to 72-bit DRAM payload
- [ ] `ecc_decode`: SECDED decode/correct, single/double-bit reporting, syndrome/status outputs
- [ ] `data_path`: write buffering, read reordering, and width alignment between host and DRAM payload

### Phase 4: Top-level integration

- [ ] `ddr4_ctrl_top`: integrate all control/data modules and enforce traffic gating until init/calibration complete

## Module Dependencies

- `csr_regs` -> `timing_cfg`, `refresh_fsm`, `scheduler`, `ecc_encode`, `ecc_decode`
- `timing_cfg` -> `timing_checker`, `bank_machine`, `refresh_fsm`
- `init_fsm` + `phy_adapter` -> `ddr4_ctrl_top` traffic enable sequencing
- `host_if` -> `cmd_queue` -> `scheduler`
- `bank_machine` + `timing_checker` -> `scheduler` legal-command decision
- `refresh_fsm` -> `scheduler` refresh priority/blackout coordination
- `ecc_encode`/`ecc_decode` + `data_path` -> host/PHY data movement
- all modules -> `ddr4_ctrl_top`

## Testbenches

### Unit-level testbenches

- [x] `csr_regs_tb`: read/write map checks, reset defaults, mode bit effects
- [ ] `timing_checker_tb`: directed legality checks for core timing constraints and violation prevention
- [ ] `bank_machine_tb`: row-open/close transitions and command readiness blocking
- [ ] `refresh_fsm_tb`: deadline/defer/pull-in behavior and blackout window assertions
- [ ] `ecc_encode_tb` + `ecc_decode_tb`: clean path, single-bit correction, double-bit detect
- [ ] `scheduler_tb`: arbitration policy behavior under bank conflicts and refresh pressure
- [ ] `data_path_tb`: burst alignment, write buffering, and read response ordering

### Integration/system testbenches

- [ ] `ddr4_ctrl_top_tb`: initialization gate, host traffic flow, refresh interaction, and ECC status propagation
- [ ] Constrained-random scenario set: mixed read/write bursts, bank conflicts, timing pressure, and refresh deadlines

## Documentation

- [x] `docs/csr_regs.md`: register map, reset values, programming model
- [x] `docs/timing_cfg.md`: timing parameter semantics and update rules
- [x] `docs/init_fsm.md`: initialization state sequence and completion criteria
- [ ] `docs/host_if.md`: host-side protocol timing and response semantics
- [ ] `docs/cmd_queue.md`: queue formats, ordering guarantees, and backpressure behavior
- [ ] `docs/bank_machine.md`: tracked state per bank and readiness rules
- [ ] `docs/timing_checker.md`: enforced constraints and legality matrix
- [ ] `docs/scheduler.md`: arbitration policies and command-selection strategy
- [ ] `docs/refresh_fsm.md`: refresh policy, deadlines, and scheduler coupling
- [ ] `docs/ecc_encode.md` + `docs/ecc_decode.md`: SECDED algorithm details and error reporting
- [ ] `docs/data_path.md`: data formatting, buffering, and ID ordering behavior
- [x] `docs/phy_adapter.md`: PHY abstraction and handshake expectations
- [ ] `docs/ddr4_ctrl_top.md`: integration-level interfaces, reset/bring-up behavior

## Verification / Coverage

- [ ] Timing legality coverage: each supported timing parameter both pass/fail scenarios
- [ ] Refresh coverage: normal cadence, max-defer boundary, and blackout command blocking
- [ ] ECC coverage: no-error, single-bit corrected, and double-bit detected flows
- [ ] Scheduler coverage: fairness mode and performance mode under contention
- [ ] Initialization coverage: no host traffic before `init_fsm` done and PHY calibration done
- [ ] End-to-end data integrity coverage: write/read round-trip with ID-tagged and in-order response modes

## Incremental Implementation Order

1. `csr_regs` + `timing_cfg`
2. `init_fsm` + `phy_adapter`
3. `host_if` + `cmd_queue`
4. `bank_machine` + `timing_checker`
5. `scheduler`
6. `refresh_fsm`
7. `ecc_encode` + `ecc_decode` + `data_path`
8. `ddr4_ctrl_top`
9. System-level constrained-random verification and coverage closure

## JSON Traceability Expectations

Each implementation/verification task should continue emitting machine-readable status under `results/` and include:

- `rtl_done`, `tb_done`, `doc_done`
- `simulation_passed`
- `coverage_completed` and `coverage_percentage`
- `plan_item_completed` for the corresponding checklist item(s)

# DDR4 Controller Architecture (Server-Grade, JEDEC DDR4)

## Project Overview

This document specifies a commercial server-grade DDR4 SDRAM controller targeting JEDEC DDR4 operation with:

- Multi-bank command scheduling and page policy control
- SECDED ECC support for 64-bit data words (72-bit DRAM burst payload)
- Mandatory refresh management (all-bank or per-bank mode)
- Configurable timing parameters to support multiple DDR4 speed bins and DIMM topologies

The controller is designed as a synthesizable RTL subsystem that bridges a host-side command/data interface to a DDR4 PHY-facing command and data pipeline.

## Functional Blocks / Modules

1. **`ddr4_ctrl_top`**
   - Top-level integration module
   - Instantiates scheduler, timing checker, refresh FSM, ECC path, and PHY interface adapter

2. **`host_if`**
   - Accepts host read/write requests with address, burst length, ID, and write data
   - Returns read data, status, and ECC error metadata

3. **`cmd_queue`**
   - Buffers decoded requests and tracks ordering constraints
   - Separates ACT/RD/WR/PRE/REF command intents for scheduler arbitration

4. **`bank_machine`**
   - One instance per DRAM bank (or bank-group-aware partition)
   - Tracks row state (open row, idle, timing blockers) and readiness for next command

5. **`scheduler`**
   - Chooses next legal command across banks
   - Enforces policy (FR-FCFS or deterministic priority mode)
   - Coordinates with timing guard logic and refresh requests

6. **`timing_cfg`**
   - Register block for JEDEC timing values (in controller clock cycles)
   - Provides active timing profile to timing checker and bank machines

7. **`timing_checker`**
   - Central legality engine for command-to-command timing
   - Enforces configurable constraints such as tRCD, tRP, tRAS, tRC, tFAW, tCCD, tWTR, tRRD, tRFC, tREFI

8. **`refresh_fsm`**
   - Generates refresh requests at tREFI intervals
   - Supports all-bank refresh and optional per-bank refresh mode
   - Handles postponement/pull-in policy within JEDEC-legal windows

9. **`ecc_encode`**
   - Generates ECC check bits for host write data
   - Outputs 72-bit payload toward write data path

10. **`ecc_decode`**
    - Checks/corrects read payload
    - Corrects single-bit errors, detects double-bit errors, and reports syndrome/status

11. **`data_path`**
    - Aligns burst data between host width and DDR burst format
    - Includes write-data buffering and read-data reordering

12. **`phy_adapter`**
    - Converts scheduled micro-commands into PHY command/data strobes
    - Handles training-complete handshaking and PHY backpressure

13. **`init_fsm`**
    - Implements DDR4 initialization sequence and mode register programming
    - Releases normal traffic only after initialization and PHY-ready completion

14. **`csr_regs`**
    - Control/status registers for timing, refresh mode, ECC enable/inject, interrupts, and counters

## Interfaces

### System Signals

- `clk`: Controller clock
- `rst_n`: Active-low synchronous reset

### Host Interface (logical)

- Request channel:
  - `host_req_valid`, `host_req_ready`
  - `host_req_addr[ADDR_W-1:0]`
  - `host_req_write`
  - `host_req_len[LEN_W-1:0]`
  - `host_req_wdata[DATA_W-1:0]`
  - `host_req_wstrb[DATA_W/8-1:0]`
  - `host_req_id[ID_W-1:0]`
- Response channel:
  - `host_rsp_valid`, `host_rsp_ready`
  - `host_rsp_rdata[DATA_W-1:0]`
  - `host_rsp_id[ID_W-1:0]`
  - `host_rsp_err`
  - `host_rsp_ecc_single`, `host_rsp_ecc_double`

Typical server configuration:

- `DATA_W = 64` (host data)
- Internal DRAM data path `DQ_W = 72` (64 data + 8 SECDED check bits)

### CSR / Configuration Interface

- `csr_valid`, `csr_write`, `csr_addr`, `csr_wdata`, `csr_rdata`, `csr_ready`
- Programs timing registers, refresh policy, scheduler policy, ECC controls, and interrupt masks

### DDR4 PHY Interface (abstracted)

- Command/address:
  - `phy_cmd_valid`, `phy_cmd_ready`
  - `phy_cmd[CMD_W-1:0]` (ACT/RD/WR/PRE/REF/MRS/ZQCL)
  - `phy_addr`, `phy_ba`, `phy_bg`
- Write data:
  - `phy_wdata_valid`, `phy_wdata_ready`
  - `phy_wdata[DQ_W-1:0]`, `phy_wmask[DQ_W/8-1:0]`
- Read data:
  - `phy_rdata_valid`, `phy_rdata[DQ_W-1:0]`
- Status:
  - `phy_init_done`, `phy_cal_done`, `phy_error`

## Timing / Protocols / Constraints

1. **JEDEC DDR4 compliance target**
   - Command sequencing and spacing are constrained by configurable timing values loaded from CSR at boot/runtime-safe points.

2. **Configurable timing set (minimum)**
   - `tRCD`, `tRP`, `tRAS`, `tRC`, `tCCD_L/S`, `tRRD_L/S`, `tFAW`, `tWTR_L/S`, `tWR`, `tRTP`, `tRFC`, `tREFI`, `tMOD`, `tMRD`

3. **Refresh behavior**
   - Refresh deadline tracking at tREFI cadence
   - Scheduler must prioritize refresh before violating maximum defer window
   - During refresh blackout, non-legal commands are blocked

4. **ECC behavior**
   - Write path always encodes ECC when enabled
   - Read path performs SECDED decode/correct before host response
   - Double-bit errors are flagged and optionally interrupting; corrected-single-bit counters are accumulated

5. **Initialization / bring-up**
   - No host traffic accepted until `init_fsm` completes JEDEC initialization and PHY calibration reports completion

6. **Ordering and QoS**
   - Supports strict in-order completion mode and ID-tagged completion mode
   - Arbitration policy is selectable between fairness mode and performance mode

## Block Diagram

```text
                +---------------------- ddr4_ctrl_top ----------------------+
host_if <------>| host_if  <-> cmd_queue <-> scheduler <-> phy_adapter      |----> DDR4 PHY
                |                    ^            ^             |             |
                |                    |            |             v             |
                |               bank_machine[*] timing_checker  data_path     |
                |                    ^            ^             ^   |          |
                |                    |            |             |   v          |
                |               refresh_fsm <-> timing_cfg <-> csr_regs       |
                |                                               ^              |
                |                              ecc_encode/ecc_decode           |
                |                                               |              |
                |                                            init_fsm ---------+
                +--------------------------------------------------------------+
```

## Notes

- This specification defines architecture and module responsibilities; exact RTL partitioning may be refined during implementation while preserving interface intent and JEDEC constraints.
- PHY training algorithms are treated as external to this controller and exposed via `phy_*_done/error` status.
- Multi-rank support is optional in first implementation but should be anticipated in address mapping and timing/resource abstractions.
- Verification expectations:
  - Directed + constrained-random traffic with bank conflicts
  - Timing-violation prevention checks
  - Refresh deadline stress scenarios
  - ECC single/double-bit fault injection and status validation

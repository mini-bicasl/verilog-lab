# timing_cfg

`timing_cfg` latches a coherent timing profile from CSR-provided values and exports it to control/datapath logic.

## Responsibilities

- Hold active JEDEC timing parameters as stable outputs
- Update all timing outputs atomically when `cfg_load` is asserted
- Provide safe reset defaults for bring-up

## Interface Summary

- Inputs: `cfg_load`, `t_*_cfg` configuration values
- Outputs: active timing profile (`t_rcd`, `t_rp`, `t_ras`, `t_rc`, `t_rrd`, `t_faw`, `t_wtr`, `t_rfc`, `t_refi`)

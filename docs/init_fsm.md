# init_fsm

`init_fsm` controls DDR4 initialization sequencing and gates normal traffic until initialization finishes.

## Responsibilities

- Wait for PHY-level readiness (`phy_init_done` and `phy_cal_done`)
- Emit initialization command sequence (`MRS` programming then `ZQCL`)
- Raise `init_done` / `traffic_enable` only after command sequence completion
- Assert `timeout_error` if PHY readiness is not observed in time

## Interface Summary

- Inputs: `start`, PHY ready status, and `phy_cmd_ready`
- Outputs: `phy_cmd_valid`, `phy_cmd`, `init_done`, `traffic_enable`, `busy`, `timeout_error`

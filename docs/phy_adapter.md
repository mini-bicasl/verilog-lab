# phy_adapter

`phy_adapter` is the PHY handshake shell between scheduler/datapath command streams and abstracted PHY signals.

## Responsibilities

- Gate command/data traffic until PHY initialization and calibration are complete
- Pass scheduled command/address/bank signals to PHY handshakes
- Pass write data/mask stream to PHY handshakes
- Latch a sticky adapter error when `phy_error` is reported

## Interface Summary

- Controller-side command/data handshake:
  - `ctrl_cmd_valid/ready`, `ctrl_cmd`, `ctrl_addr`, `ctrl_ba`, `ctrl_bg`
  - `ctrl_wdata_valid/ready`, `ctrl_wdata`, `ctrl_wmask`
- PHY-side handshake:
  - `phy_cmd_valid/ready`, `phy_cmd`, `phy_addr`, `phy_ba`, `phy_bg`
  - `phy_wdata_valid/ready`, `phy_wdata`, `phy_wmask`
- Status:
  - Inputs: `phy_init_done`, `phy_cal_done`, `phy_error`
  - Outputs: `adapter_ready`, `adapter_error`

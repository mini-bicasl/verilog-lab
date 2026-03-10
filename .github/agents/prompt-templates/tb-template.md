# AI Testbench Generation Prompt

## Context
Use the existing:
- `docs/ARCHITECTURE.md` — module and interface descriptions
- `docs/PLAN.md` — checklist and status of testbench tasks

## Instructions for AI Agent
Generate testbench code for the next unimplemented item in the PLAN.md checklist.

1. Read `docs/ARCHITECTURE.md` for module ports, behaviors, and expected signals.
2. Identify next unchecked testbench item in `docs/PLAN.md`.
3. Create corresponding testbench(s) under `tb/`.
4. Include directed tests and at least a few randomized tests for robustness.
5. Simulate and ensure the bench compiles and runs successfully.

## Mandatory JSON Output
```json
{
  "tb_files": ["tb/<module>_tb.v", "..."],
  "simulation_passed": <true/false>,
  "coverage_percentage": <number>,
  "plan_item_completed": true,
  "version": "<issue_number>_<YYYYMMDD>"
}

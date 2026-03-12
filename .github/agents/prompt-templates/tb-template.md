# Testbench Generation Template

Use this template when generating testbenches for the AI-assisted Verilog lab workflow (see `docs/INSTRUCTION.md`).

## CONTEXT

The workflow provides a context file built from:

- **Required:** `docs/ARCHITECTURE.md` or `docs/ARCHITECTURE.md`
- **Optional:** `docs/PLAN.md`, `docs/INTERFACE_SPEC.md`, `docs/TESTPLAN.md` if present

Use the context file given in the prompt.

## TASK

Generate a Verilog testbench for module: **`{{module_name}}`**.

Use the resolved phase name from `docs/PLAN.md` and write all artifacts to **`results/phase-{{phase_name}}/`**.

### TESTBENCH REQUIREMENTS

- Cover inputs and corner cases; use `TESTPLAN.md` test vectors if in context
- Include clock(s), reset, and stimulus generation
- Add assertions or checks for interface and timing constraints where appropriate
- Comment each major test step
- Dump waveforms (e.g. `$dumpfile` / `$dumpvars` for `.vcd`) for debugging

### DELIVERABLES

1. Testbench file: **`tb/{{module_name}}_tb.v`**
2. Simulation log: **`<results_dir>/{{module_name}}_sim.log`**
3. Waveform dump (VCD): **`<results_dir>/{{module_name}}.vcd`** (or a clearly named equivalent under the same folder)
4. Optional: CSV dump(s): **`<results_dir>/{{module_name}}*.csv`**
5. Update (or create) status file: **`<results_dir>/{{module_name}}_result.json`**

### VALIDATION

- Testbench must compile with Icarus Verilog
- You MUST run it with `vvp` and it must complete without errors
- VCD (or equivalent) should be produced for debugging

### MANDATORY JSON OUTPUT

At the **end** of your response, output exactly one JSON block and ensure the same data is reflected in `<results_dir>/{{module_name}}_result.json`.

```json
{
  "module": "{{module_name}}",
  "rtl_done": false,
  "tb_done": true,
  "doc_done": false,
  "simulation_passed": false,
  "coverage_completed": false,
  "coverage_percentage": 0,
  "plan_item_completed": false,
  "error_summary": ""
}
```

- `simulation_passed`: set to `true` ONLY if you actually executed `vvp` successfully in this run; otherwise it MUST be `false`.
- `plan_item_completed`: MUST be `true` only when **RTL + TB + docs exist** and **simulation_passed is true**.
- `error_summary`: empty if all checks pass; otherwise a concise 1–3 sentence description of what is failing and why.

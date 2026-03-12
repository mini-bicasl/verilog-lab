# RTL Generation Template

Use this template when generating RTL for the AI-assisted Verilog lab workflow (see `docs/INSTRUCTION.md`).

## CONTEXT

The workflow provides a context file built from (in order):

- **Required:** `docs/ARCHITECTURE.md` or `ARCHITECTURE.md` (architecture and interfaces)
- **Optional:** `docs/PLAN.md` (Implementation Plan)
- **Optional (if present):** `docs/INTERFACE_SPEC.md`, `docs/NAMING_CONVENTIONS.md`, `docs/TESTPLAN.md` 

Use the context file given in the prompt as the single source of truth.

## TASK

Generate synthesizable Verilog RTL for the requested module: **`{{module_name}}`**.

Use the resolved phase name from `docs/PLAN.md` and write all artifacts to **`results/phase-{{phase_name}}/`**.

### MODULE REQUIREMENTS

- Follow interfaces and block descriptions from the architecture document
- Include synchronous reset and proper clock domains
- Comment each FSM state and key combinational logic
- Use naming consistent with the architecture; if `NAMING_CONVENTIONS.md` is in context, follow it
- Keep module hierarchy consistent with the architecture

### DELIVERABLES

1. RTL file: **`rtl/{{module_name}}.v`**
2. Update (or create) status file: **`<results_dir>/{{module_name}}_result.json`**

### VALIDATION

- Code must compile with Icarus Verilog (`iverilog -g2012`)
- If a testbench exists for this module (`tb/{{module_name}}_tb.v`), you MUST run it with `vvp` and only then set `simulation_passed: true`.
- Prefer Verilator-clean style where practical

### MANDATORY JSON OUTPUT

At the **end** of your response, output exactly one JSON block and ensure the same data is reflected in `<results_dir>/{{module_name}}_result.json`.

```json
{
  "module": "{{module_name}}",
  "rtl_done": true,
  "tb_done": false,
  "doc_done": false,
  "simulation_passed": false,
  "coverage_completed": false,
  "coverage_percentage": 0,
  "plan_item_completed": false,
  "error_summary": ""
}
```

- `simulation_passed`: set to `true` ONLY if you actually executed `vvp` successfully for this module’s TB in this run; otherwise it MUST be `false`.
- `plan_item_completed`: MUST be `true` only when **RTL + TB + docs exist** and **simulation_passed is true**.
- `error_summary`: empty if all checks pass; otherwise a concise 1–3 sentence description of what is failing and why.

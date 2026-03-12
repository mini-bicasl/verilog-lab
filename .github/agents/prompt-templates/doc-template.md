# Documentation Template

Use this template when generating module documentation for the AI-assisted Verilog lab workflow (see `docs/INSTRUCTION.md`).

## CONTEXT

The workflow provides a context file built from:

- **Required:** `docs/ARCHITECTURE.md` or `docs/ARCHITECTURE.md`
- **Optional:** `docs/PLAN.md`, `docs/INTERFACE_SPEC.md`, `docs/NAMING_CONVENTIONS.md` if present

Use the context file and any referenced RTL/testbench paths.

## TASK

Write Markdown documentation for module: **`{{module_name}}`**.

Use the resolved phase name from `docs/PLAN.md` and write all artifacts to **`results/phase-{{phase_name}}/`**.

### DOCUMENTATION REQUIREMENTS

- Short overview and role of the module in the architecture
- Module interface: ports, widths, directions, and purpose
- State machine or control flow (ASCII or Mermaid diagram if useful)
- Timing or protocol notes if applicable
- References to RTL (`rtl/{{module_name}}.v`) and testbench (`tb/{{module_name}}_tb.v`)
- Brief rationale for main design choices and constraints
- Code-comment summaries only where they add clarity

### DELIVERABLES

1. Documentation file: **`docs/{{module_name}}.md`**
2. Use headings, tables, and diagrams so it renders well on GitHub
3. Update (or create) status file: **`<results_dir>/{{module_name}}_result.json`** (`doc_done` flag + completion gating)

### MANDATORY JSON OUTPUT

At the **end** of your response, output exactly one JSON block and ensure the same data is reflected in `<results_dir>/{{module_name}}_result.json`.

```json
{
  "module": "{{module_name}}",
  "rtl_done": false,
  "tb_done": false,
  "doc_done": true,
  "simulation_passed": false,
  "coverage_completed": false,
  "coverage_percentage": 0,
  "plan_item_completed": false,
  "error_summary": ""
}
```

- `plan_item_completed`: MUST be `true` only when **RTL + TB + docs exist** and **simulation_passed is true**.
- `error_summary`: empty if all checks pass; otherwise a concise description of what is still missing (e.g., "simulation not passing yet").

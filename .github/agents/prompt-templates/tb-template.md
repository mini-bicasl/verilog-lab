# Testbench Generation Template

## CONTEXT
Include relevant files:
- Architecture: `ARCHITECTURE.md`
- Interface spec: `INTERFACE_SPEC.md`
- Testplan: `TESTPLAN.md`

## TASK
Generate a Verilog testbench for module `{{module_name}}`.

### TESTBENCH REQUIREMENTS
- Cover all input vectors and corner cases from TESTPLAN.md
- Include clocks, resets, and stimulus generation
- Assertions for interface constraints
- Comment each test step
- Generate waveform files (`*.vcd`)

### DELIVERABLES
- Testbench file (`*_tb.v`) in `/tb/`
- Optional Markdown description of test strategy

### VALIDATION
- Testbench must run and pass without errors
- Compile with Icarus Verilog
- Generate VCD waveform for debugging

### MANDATORY JSON OUTPUT
Return a JSON summary after testbench generation:
```json
{
  "rtl_files": ["rtl/{{module_name}}.v"],
  "simulation_passed": true,
  "coverage_percentage": 100,
  "plan_item_completed": true,
  "version": "{{issue_number}}_{{YYYYMMDD}}"
}

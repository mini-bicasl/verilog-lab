# AI Testbench Generation Prompt

## Issue Description
{{ISSUE_BODY}}

## Instructions for AI Agent

You are generating testbenches for RTL modules.

1. **File Placement**  
   - Save all testbench files in `tb/`.  
   - Use `<module>_tb.v` naming.  
2. **Test Cases**  
   - Include at least 5 directed test cases for functional verification.  
   - Include at least 2 randomized tests if possible.  
3. **Simulation**  
   - Ensure testbench compiles and runs without errors.  
   - Include minimal simulation logs.  
4. **Comments**  
   - Document each test case and expected behavior.  
   - Reference the corresponding RTL module and design document.  

## Mandatory JSON Output
```json
{
  "tb_files": ["tb/<module>_tb.v", "..."],
  "simulation_passed": true,
  "coverage_percentage": 90,
  "notes": "List of test cases included",
  "version": "<issue_number>_<YYYYMMDD>"
}

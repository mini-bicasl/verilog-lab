# AI Testbench Generation Prompt

## Issue Description
{{ISSUE_BODY}}

## Instructions for AI Agent

1. **Purpose:** Generate a synthesizable and simulation-ready testbench for the RTL module described in the issue.  
2. **Files:** Save all testbench files under `tb/` folder, using consistent naming based on module name.  
3. **Test Cases:**  
   - Include at least 5 directed tests covering normal and edge cases.  
   - Add at least 2 randomized test cases if possible.  
4. **Simulation:** Ensure the testbench compiles and simulates without errors (e.g., using `iverilog` or equivalent).  
5. **Comments:** Include inline comments explaining the test scenario, expected results, and signal relationships.  
6. **Documentation:** Each testbench should include a brief module header comment with:  
   - Module purpose  
   - Inputs and outputs tested  
   - References to specification sections  
7. **Output JSON:** Provide a JSON summary with the following keys:  
   ```json
   {
     "tb_files": ["tb/<filename>.v", "..."],
     "simulation_passed": true/false
   }

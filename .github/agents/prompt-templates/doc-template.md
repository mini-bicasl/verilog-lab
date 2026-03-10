# AI Documentation Generation Prompt

## Issue Description
{{ISSUE_BODY}}

## Instructions for AI Agent

1. **Purpose:** Generate Markdown documentation for the RTL module(s) and/or testbench described in the issue.  
2. **Files:** Save all documentation files under `docs/` folder, named to match the corresponding module.  
3. **Content Requirements:** Each documentation file should include:  
   - Module name and purpose  
   - Input and output signal descriptions  
   - High-level description of the functionality (FSM, pipelines, encoding/decoding, etc.)  
   - References to related testbench(s) and simulation logs  
   - Notes on coding conventions used  
4. **Style:**  
   - Markdown format, headers for sections (## Inputs, ## Outputs, ## Functionality, ## Testbench Reference)  
   - Bullet points or tables where appropriate for clarity  
   - Concise, educational style suitable for beginners  
5. **Output JSON:** Provide a JSON summary with the following keys:  
   ```json
   {
     "doc_files": ["docs/<filename>.md", "..."]
   }
6. **Constraints**: Ensure documentation matches the code exactly, follows style guide, and is beginner-friendly.

**Deliverable**: Fully documented Markdown files describing the RTL/testbench, ready to be included in the repository and linked from PRs.



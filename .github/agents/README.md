# AI Agents for Verilog Lab

This folder defines **agent configs** and **prompt templates** used by the AI-driven RTL workflow. The actual automation runs in **`.github/workflows/`**, primarily **`ai-pipeline.yml`**.

At a high level, the user thinks in terms of **Specification → Planning → Implementation → Verification**.  
Internally, the **Implementation** phase fans out to three specialized agents:

- RTL generation
- Testbench generation
- Documentation generation

## How the end-to-end workflow uses these agents

1. **User opens an AI issue** by choosing one of the four issue templates:
   - [AI Specification](../ISSUE_TEMPLATE/1_specification.yml) – high-level idea / ARCHITECTURE.md
   - [AI Planning](../ISSUE_TEMPLATE/2_planning.yml) – implementation plan / PLAN.md
   - [AI Implementation](../ISSUE_TEMPLATE/3_implementation.yml) – one module (requires module name) → RTL + TB + docs
   - [AI Verification](../ISSUE_TEMPLATE/4_verification.yml) – tests, constraints, or refinements (optional module + focus checkboxes)
2. **Workflow:** [ai-pipeline.yml](../workflows/ai-pipeline.yml) runs:
   - Parses the issue body to determine the phase and module name.
   - Builds a **context file** from:
     - `docs/ARCHITECTURE.md` (or root `ARCHITECTURE.md`)
     - `docs/PLAN.md` (if present)
     - Optional spec files: `INTERFACE_SPEC.md`, `NAMING_CONVENTIONS.md`, `TESTPLAN.md` (root or `docs/`).
3. **Phase routing:**
   - `Specification` and `Planning`:
     - Used for high-level architecture and plan work.
     - No automatic RTL/TB/Documentation generation is triggered by the pipeline.
   - `Implementation`:
     - Triggers **all three agents**: RTL, Testbench, and Documentation, for the given module.
   - `Verification`:
     - Reserved for coverage / test improvements. It does not auto-run these agents by default.
4. **Agents run:**
   - Each agent uses a prompt template from `prompt-templates/` plus the context file.
   - They generate files under `rtl/`, `tb/`, `docs/`, and run-scoped artifacts under:
     - `results/phase-<phase_name>/`
     (logs, dumps, and `*_result.json`).
5. **Outputs and PRs:**
   - The workflow commits generated files on `ai/...` branches and opens PRs.
   - When the user adds the label **`ready-to-merge`** to a PR, the same workflow auto-merges it.

See **`docs/INSTRUCTION.md`** for the full user-facing flow.

## Contents

| File | Purpose |
|------|--------|
| **rtl-generator.yml** | Agent spec for RTL generation (context, deliverables, JSON schema). |
| **tb-generator.yml** | Agent spec for testbench generation. |
| **doc-generator.yml** | Agent spec for documentation generation. |
| **prompt-templates/rtl-template.md** | Prompt template for the RTL agent (updates `results/phase-<phase_name>/<module>_result.json`; `simulation_passed` must reflect an actual `vvp` run). |
| **prompt-templates/tb-template.md** | Prompt template for the testbench agent (writes `results/phase-<phase_name>/<module>_sim.log` and updates `results/phase-<phase_name>/<module>_result.json`). |
| **prompt-templates/doc-template.md** | Prompt template for the documentation agent (updates `results/phase-<phase_name>/<module>_result.json`; completion is gated on passing sim). |
| **prompt-templates/PLAN.md** | Reference for Implementation Plan structure (actual plan lives in `docs/PLAN.md`). |
| **prompt-templates/ARCHITECTURE.md** | Reference for architecture structure (actual doc lives in `docs/ARCHITECTURE.md`). |

## Context files

- **Required:** `docs/ARCHITECTURE.md` (or root `ARCHITECTURE.md`) — single source of truth for modules, interfaces, and high-level behavior.
- **Optional:** `docs/PLAN.md` and, if present:
  - `INTERFACE_SPEC.md`
  - `NAMING_CONVENTIONS.md`
  - `TESTPLAN.md`
  (either in the repo root or under `docs/`).

The workflow builds a single context file per run and passes it to the agents.  
Each prompt template describes the expected JSON output shape for traceability in **`results/phase-<phase_name>/`**.

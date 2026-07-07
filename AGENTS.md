# AGENTS.md

> Entry point for AI coding agents (Codex, Claude Code, Kiro CLI, etc.) working in this workspace.
> Human-readable overview is in [README.md](README.md).

## Project overview

This is a **multi-agent workspace** for managing several projects under a single kiro-cli setup.

- Each project has its own agent (`.kiro/agents/<name>.json`) and task directory (`tasks/<name>/`).
- A shared context layer (`.kiro/shared/`, `.kiro/learned/`, `.kiro/skills/`) carries information across agents.
- The [AI-DLC](https://github.com/awslabs/aidlc-workflows) v0.1.8 methodology is pre-installed under `.kiro/steering/` and `.kiro/aws-aidlc-rule-details/`.

## Repository structure

```text
.kiro/
├── steering/                          # Auto-loaded rules (AI-DLC + local overrides)
│   ├── aws-aidlc-rules/core-workflow.md    # Upstream three-phase workflow
│   ├── locale-override.md             # Chinese interaction + JST + per-task aidlc-docs
│   ├── change-management.md           # CR-log + phase-approval gate (M1.2.5)
│   ├── interface-contracts.md         # Mandatory contract freeze at end of INCEPTION (M1.3)
│   ├── cross-unit-smoke.md            # Per-unit smoke + Build&Test must actually run (M1.3)
│   └── code-quality.md                # 3-layer quality gate: codegen rules + reviewer + tooling (M1.9)
├── aws-aidlc-rule-details/            # AI-DLC detail rules (loaded on demand)
├── agents/                            # Per-project agent definitions
├── prompts/                           # Per-agent system prompts (referenced via file://)
├── shared/SHARED-CONTEXT.md{,.tpl}    # Workspace env (.tpl shipped, .md created by init-workspace.sh)
├── learned/LEARNED.md{,.tpl}          # Cross-task knowledge pool (.tpl shipped, .md created by init-workspace.sh)
├── skills/                            # Cross-project reusable instruction modules
│   ├── auto-learn.md                  # Capture rules + layer decision tree
│   ├── memory-layering.md             # Where each kind of knowledge belongs
│   ├── raise-cr.md                    # Capture scope suggestions without breaking flow
│   ├── aidlc-auto-trigger.md          # Proactively propose AI-DLC based on request shape
│   └── adr.md                         # Scaffold an Architecture Decision Record (next number + template)
├── adr/                               # Architecture Decision Records (framework layer)
│   ├── README.md                      # Mechanism + framework ADR index (auto-loaded via resources)
│   ├── 0000-template.md               # Nygard-lite skeleton
│   └── NNNN-*.md                      # One decision each (numbers never reused)
├── templates/
│   ├── task/                          # Scaffolding for new tasks (used by new-task.sh)
│   │   ├── task.yaml.tpl              # Structured metadata (project_path, repo_url, branch_prefix)
│   │   ├── learned.md.tpl             # Per-task knowledge pool
│   │   ├── change-requests.md.tpl     # Per-task CR log (copied to aidlc-docs/, gitignored)
│   │   ├── RESUME.md.tpl              # Includes Current AI-DLC Stage section
│   │   └── prompt.md.tpl              # Persona / decision principles / communication style
│   └── inputs/                        # AI-DLC Vision + Tech-Env templates and guides
│       ├── vision.md.tpl              # Blank vision skeleton (copied by new-task.sh)
│       └── tech-env.md.tpl            # Blank tech-env skeleton (copied by new-task.sh)
└── settings/

scripts/
├── init-workspace.sh                  # Bootstrap user-instance files from .tpl (one-time after clone)
├── new-task.sh                        # Scaffold a new task in one command
├── codex-review.sh                    # Independent (codex) pre-commit review — run before every commit (Linux/macOS)
├── codex-review.ps1                   # Windows launcher for codex-review.sh (kiro's execute_bash is PowerShell; bare bash = broken WSL)
└── update-aidlc.sh                    # Update AI-DLC rules from GitHub release

tasks/<name>/
├── task.yaml                          # Structured metadata — single source of truth for paths/repo
├── RESUME.md                          # Cross-session human-readable summary (+ Current AI-DLC Stage)
├── WORKFLOW.md                        # Process definition
├── learned.md                         # Per-task knowledge pool (project schema, domain quirks)
├── vision.md                          # AI-DLC Vision document (skip with new-task.sh --no-aidlc)
├── tech-env.md                        # AI-DLC Tech-Env document (skip with new-task.sh --no-aidlc)
└── aidlc-docs/                        # AI-DLC artifacts (gitignored)
    ├── change-requests.md             # CR log (phase-approval gate blocks on OPEN rows)
    ├── aidlc-state.md                 # Source of truth while AI-DLC is running
    └── …                              # requirements / design / etc.
```

## Which docs to read by task type

- **Adding a new project** → run `scripts/new-task.sh <name> <project-path>`, then edit the generated files
- **AI-DLC workflow questions** → `.kiro/skills/aidlc-usage-tips.md`
- **Starting an AI-DLC workflow for a new project** → `.kiro/templates/inputs/README.md`
- **Cross-agent collaboration** → `.kiro/skills/agent-delegation.md`
- **Recording a project-specific lesson** (schema, domain, business quirk) → append to `tasks/<name>/learned.md`
- **Recording a cross-task lesson** (tool / framework / internal-system recipe) → append to `.kiro/learned/LEARNED.md` with a "Why cross-task" line
- **Deciding where a lesson belongs** → read `.kiro/skills/memory-layering.md`
- **Capturing a scope suggestion ("顺手加 X" / "为啥不也 Y") mid-flow** → append a CR row to `tasks/<name>/aidlc-docs/change-requests.md` using `.kiro/skills/raise-cr.md`; CR types and phase-approval gate live in `.kiro/steering/change-management.md`
- **Recording *why* something is built a certain way** (mechanism/architecture decision + rejected alternatives) → scaffold an ADR via `.kiro/skills/adr.md`; framework decisions go to `.kiro/adr/`, task-project decisions to `tasks/<name>/adr/`. This is distinct from a CR (scope) and a learned entry (reusable snippet) — see `.kiro/adr/README.md`
- **Reviewing a code change before commit** → run `bash scripts/codex-review.sh <repo>` for an independent (codex) second opinion; playbook in `.kiro/skills/codex-review.md`, rationale in `.kiro/adr/0002-review-outsourced-to-codex.md`. Tests you run yourself — codex is review, not a test substitute
- **Code style / output formats** → `.kiro/skills/output-templates.md`
- **Delegating small tasks to local LLMs** → `.kiro/skills/delegate-to-local-llm.md`

## Setup commands

```bash
# Lint markdown files (matches awslabs/aidlc-workflows style)
npx markdownlint-cli2 "**/*.md"

# Auto-fix where possible
npx markdownlint-cli2 --fix "**/*.md"

# Install pre-commit hooks (optional)
pre-commit install

# Bootstrap user-instance files (one-time, idempotent)
./scripts/init-workspace.sh

# Scaffold a new task (creates task.yaml + RESUME/WORKFLOW/learned + vision/tech-env)
./scripts/new-task.sh <task-name> <project-path>

# Same, but skip AI-DLC inputs (vision.md / tech-env.md) for ad-hoc tasks
./scripts/new-task.sh --no-aidlc <task-name> <project-path>
```

## Rules for agents

1. **Language**: Chat in Chinese (中文). Commit messages in English. See `.kiro/steering/locale-override.md`.
2. **State management**: After significant work, update `tasks/<name>/RESUME.md` (the `## Current AI-DLC Stage` section for in-progress AI-DLC workflows). Don't fabricate state — read the file first.
2a. **Paths and repo coordinates**: read from `tasks/<name>/task.yaml`. Don't hard-code `project_path` in prompts or RESUME — it lives in one place.
2b. **Scope discipline**: when a suggestion arrives (from user or self-detected), raise a CR via `.kiro/skills/raise-cr.md`. Never silently expand scope. Phase approval blocks on OPEN CRs — see `.kiro/steering/change-management.md`.
2c. **Interface freeze**: INCEPTION cannot close until every unit has a machine-readable contract under `aidlc-docs/inception/application-design/contracts/<unit>.{yaml,py,ts}` and the cross-unit review is clean. See `.kiro/steering/interface-contracts.md`.
2d. **Smoke + Build&Test discipline**: per-unit code-gen step 7 requires passing smoke against any upstream unit already generated; Build & Test is incomplete until test commands have actually been executed and the results captured. See `.kiro/steering/cross-unit-smoke.md`.
2e. **AI-DLC proposal**: at the start of a fresh session, detect the request shape (new system / feature / refactor / bug-fix / spike / ops) per `.kiro/skills/aidlc-auto-trigger.md` and PROPOSE the appropriate depth in one short message. User keeps full veto power; never start AI-DLC silently.
2f. **Code-quality gate**: codegen follows the constraints in `.kiro/steering/code-quality.md` (Layer A — reuse over creation, validate once, no speculative abstractions). After per-unit code-gen step 7 smoke passes, run the `code-quality-reviewer` agent (Layer C — semantic duplication / cross-file validation / over-abstraction / defensive over-coding); a `Request changes` verdict blocks closing step 7. Build & Test enforces the tooling thresholds (Layer B) declared in `tech-env.md`. Optimize for adoptability (≤5 evidenced findings), not finding count.
3. **AI-DLC artifacts**: Generate under `tasks/<name>/aidlc-docs/`, NOT repository root.
4. **Learning**: Run the layer decision tree in `.kiro/skills/memory-layering.md` before writing. Project-specific → `tasks/<name>/learned.md`. Cross-task reusable → `.kiro/learned/LEARNED.md` (with "Why cross-task" line). Follow `.kiro/skills/auto-learn.md` archival rules.
5. **Context loading**: task/workspace context (task.yaml, RESUME, WORKFLOW, learned, CR-log, SHARED-CONTEXT, LEARNED) is injected via each agent.json's **`resources` (file://)** list — **NOT** `agentSpawn` hooks. The new Kiro CLI does **not** feed agentSpawn hook stdout into the model context (verified: a hook-only `task.yaml` never loaded, the same file in `resources` did). To change what loads at spawn, edit the agent's `resources`. Don't duplicate that content in chat. Methodology/gates come from `.kiro/steering/*` (auto-loaded by the rules engine).
6. **Cross-agent work**: Use `subagent` tool with rules in `.kiro/skills/agent-delegation.md`.
7. **Vibe coding is forbidden** — when AI-DLC is in use, update design docs first, then regenerate code. See `aidlc-usage-tips.md`.
8. **Architecture decisions**: when a change shapes a mechanism/structure, has a non-obvious alternative, and a future reader will ask "why this way", record an ADR via `.kiro/skills/adr.md`. Framework-mechanism decisions → `.kiro/adr/` (add a line to its README index); this task's underlying-project decisions → `tasks/<name>/adr/` (index in that RESUME.md). Changed your mind = new ADR + mark the old one `superseded by NNNN`. Don't confuse with CR (scope) or learned (reusable snippet).
9. **Review before commit (hard gate)**: any code change — including changes to this workspace's own scripts/steering/skills/agents — runs the independent codex review before `git commit`. Invocation differs by platform: **Windows** `pwsh -ExecutionPolicy Bypass -File scripts/codex-review.ps1 <repo>` (kiro's execute_bash is PowerShell; bare `bash` is a broken WSL); **Linux/macOS** `bash scripts/codex-review.sh <repo>`. Order: you run tests → codex review → triage every finding (fix real bugs and re-run tests / reject false positives with a one-line reason / escalate disagreements) → commit only once clean. Tests are yours to run; codex is review, not a test substitute. This is orthogonal to the Layer C `code-quality-reviewer` (same-model, per-unit) — both run. See `.kiro/skills/codex-review.md`.

## Code style

- Markdown only in this template (no production code lives here).
- Markdown lint config: `.markdownlint-cli2.yaml` (MD013/MD024/MD033/MD036 disabled to match AI-DLC document style).
- Commit messages: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`).

## License

MIT

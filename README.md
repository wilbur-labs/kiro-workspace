# kiro-workspace-template

A multi-agent workspace architecture for [kiro-cli](https://github.com/kirocli/kiro), pre-integrated with [AI-DLC](https://github.com/awslabs/aidlc-workflows) workflow rules.

Organize multiple AI agents, shared context, learned memories, skills, and task tracking in a single workspace — with a structured three-phase development methodology built in.

---

## Big Picture (3 layers)

| Layer | Where it lives | What it answers |
|-------|----------------|-----------------|
| **Methodology** | `.kiro/steering/` + `.kiro/aws-aidlc-rule-details/` | *How* to develop — AI-DLC three-phase workflow |
| **Context** | `.kiro/shared/`, `.kiro/learned/`, `.kiro/skills/` | *What to remember* across sessions and agents |
| **Tasks** | `.kiro/agents/*.json`, `tasks/<name>/` | *What you're working on* — one entry per project |

---

## Directory Structure

```
.kiro/
├── steering/                        # ★ AI-DLC rules + locale override (auto-loaded)
│   ├── aws-aidlc-rules/
│   │   └── core-workflow.md         # Three-phase adaptive workflow
│   └── locale-override.md           # Chinese interaction + JST timestamps + AI-DLC output path
│
├── aws-aidlc-rule-details/          # AI-DLC detail rules (referenced on demand)
│   ├── common/                      # Welcome msg, QA format, validation
│   ├── inception/                   # Requirements, user stories, design
│   ├── construction/                # Code gen, tests, IaC
│   ├── operations/                  # Deploy, monitor
│   └── extensions/                  # Optional: security baseline, property testing
│
├── agents/                          # One JSON per project
│   └── example.json
│
├── prompts/                         # Agent system prompts (referenced via file://)
│   └── example.md
│
├── shared/                          # Workspace-level env (gitignored — user-instance)
│   ├── SHARED-CONTEXT.md.tpl        # Skeleton shipped with template
│   └── SHARED-CONTEXT.md            # Created by scripts/init-workspace.sh
├── learned/                         # Cross-task knowledge pool (with archive policy)
│   ├── LEARNED.md.tpl               # Skeleton shipped with template
│   ├── LEARNED.md                   # Created by scripts/init-workspace.sh (gitignored)
│   └── archive/                     # Monthly archives (see auto-learn.md)
│
├── skills/                          # Cross-project reusable instructions
│   ├── README.md                    # Convention for what goes here
│   ├── auto-learn.md                # When/how to capture learnings (with layer decision tree)
│   ├── memory-layering.md           # Where each kind of knowledge belongs
│   ├── output-templates.md
│   ├── agent-delegation.md
│   ├── aidlc-usage-tips.md          # Distilled best practices for AI-DLC interaction
│   └── delegate-to-local-llm.md
│
├── templates/
│   ├── task/                        # Scaffolding for new tasks (used by new-task.sh)
│   │   ├── RESUME.md.tpl
│   │   ├── WORKFLOW.md.tpl
│   │   ├── learned.md.tpl           # Per-task knowledge pool (project-specific)
│   │   ├── agent.json.tpl
│   │   └── prompt.md.tpl
│   └── inputs/                      # AI-DLC Vision + Tech-Env document templates
│       ├── README.md
│       ├── inputs-quickstart.md
│       ├── vision-document-guide.md
│       ├── technical-environment-guide.md
│       └── example-*.md
│
├── settings/
│   └── cli.json
└── VERSION                          # AI-DLC version tracking

scripts/
├── init-workspace.sh                # Bootstrap user-instance files from .tpl (run once after clone)
├── new-task.sh                      # Scaffold a new task in one command
└── update-aidlc.sh                  # Update AI-DLC rules from GitHub release

tasks/
└── <task-name>/
    ├── RESUME.md                    # Cross-session summary (human-readable)
    ├── WORKFLOW.md                  # Process definition
    ├── learned.md                   # Per-task knowledge pool (project schema, domain quirks)
    ├── aidlc-docs/                  # AI-DLC artifacts (gitignored)
    │   ├── aidlc-state.md
    │   └── audit.md
    └── skills/                      # (Optional) project-specific skills
```

---

## "I want to X — which file do I edit?"

| Goal | File |
|------|------|
| Add a new project/task | Run `scripts/new-task.sh <name> <project-path>` |
| Change global env info (URLs, team, tools) | `.kiro/shared/SHARED-CONTEXT.md` |
| Tune an agent's role/rules | `.kiro/prompts/<name>.md` |
| Add/remove an agent's tools or resources | `.kiro/agents/<name>.json` |
| Record a project-specific learning (schema, domain quirk) | Append to `tasks/<name>/learned.md` |
| Record a cross-project learning (tool / framework / internal-system recipe) | Append to `.kiro/learned/LEARNED.md` (must include "Why cross-task" line) |
| Decide where a learning belongs | Read `.kiro/skills/memory-layering.md` |
| Add a reusable cross-project skill | New file in `.kiro/skills/` |
| Add a project-specific skill | New file in `tasks/<name>/skills/` |
| Customize AI-DLC behavior (language, output path) | `.kiro/steering/locale-override.md` |
| Add an org-wide steering rule | New file in `.kiro/steering/` |
| Update task state at end of session | `tasks/<name>/RESUME.md` |

---

## Quick Start

```bash
# 1. Clone this template
git clone <this-repo> my-workspace
cd my-workspace

# 2. Bootstrap user-instance files from bundled .tpl skeletons (one-time, idempotent)
./scripts/init-workspace.sh

# 3. Edit shared context
$EDITOR .kiro/shared/SHARED-CONTEXT.md

# 4. Scaffold a new task
./scripts/new-task.sh myproject /home/me/myproject

# 4. Refine the agent
$EDITOR .kiro/prompts/myproject.md
$EDITOR tasks/myproject/RESUME.md

# 5. Refine the agent
$EDITOR .kiro/prompts/myproject.md
$EDITOR tasks/myproject/RESUME.md

# 6. (Optional but highly recommended) Prepare AI-DLC inputs
cp .kiro/templates/inputs/example-minimal-vision-scientific-calculator-api.md \
   tasks/myproject/vision.md
cp .kiro/templates/inputs/example-minimal-tech-env-scientific-calculator-api.md \
   tasks/myproject/tech-env.md
$EDITOR tasks/myproject/vision.md tasks/myproject/tech-env.md

# 7. Start working
kiro-cli chat --agent myproject

# Inside the chat, kick off AI-DLC:
#   AI-DLC を使って、tasks/myproject/vision.md と tasks/myproject/tech-env.md を読んで開始してください。
```

## Optional Tooling

```bash
# Lint markdown files (matches awslabs/aidlc-workflows style)
npx markdownlint-cli2 "**/*.md"

# Install pre-commit hooks
pip install pre-commit && pre-commit install
```

---

## AI-DLC Integration

This template ships with [AI-DLC v0.1.8](https://github.com/awslabs/aidlc-workflows) rules. AI-DLC adds a structured three-phase workflow:

- **Inception** — Requirements analysis, user stories, architecture design
- **Construction** — Detailed design, code generation, testing
- **Operations** — Deployment and monitoring

To trigger AI-DLC, prefix your request with the activator:

```
AI-DLC を使って、<your goal>
```

Rules are in English but `locale-override.md` ensures all responses, questions, and generated documents are in Chinese (中文), with JST timestamps.

### Generated artifacts go per-task

AI-DLC artifacts are written to `tasks/<task-name>/aidlc-docs/` (gitignored), not the repository root. This isolates concurrent tasks.

- `aidlc-state.md` — workflow state machine (source of truth while running)
- `audit.md` — timestamped action log
- Requirements / user stories / design docs

`RESUME.md` remains the **human-readable cross-session summary** (separate role from `aidlc-state.md`).

### Verify setup

Run `kiro-cli`, then `/context show` — you should see:
- `.kiro/steering/aws-aidlc-rules`
- `.kiro/steering/locale-override.md`

---

## Session Recovery

Agents read `RESUME.md` on spawn via `agentSpawn` hooks (paths are relative, no hardcoded `~/`). This ensures continuity across sessions without relying on conversation history.

## Cross-agent Coordination

Use `subagent` tool with the rules in `.kiro/skills/agent-delegation.md` to dispatch work between agents (e.g., backend agent → frontend agent).

## Memory Layering

Knowledge is split across layers to keep agent context lean and prevent cross-task pollution. Full decision tree in [`.kiro/skills/memory-layering.md`](.kiro/skills/memory-layering.md).

| Layer | File | When to write here |
|---|---|---|
| Per-task state | `tasks/<name>/RESUME.md` | Current state, next steps, blockers |
| Per-task learned | `tasks/<name>/learned.md` | Project-specific schema, domain rules, business quirks |
| Cross-task learned | `.kiro/learned/LEARNED.md` | Reusable tool / framework / internal-system recipes |
| Shared context | `.kiro/shared/SHARED-CONTEXT.md` | Stable workspace env (org, team, network) |
| Steering rules | `.kiro/steering/*.md` | Enforced code-gen / AI-DLC behavior |

Capture rules and promotion flow live in [`.kiro/skills/auto-learn.md`](.kiro/skills/auto-learn.md). `LEARNED.md` follows an archival policy:
- Active file keeps ~50 most recent entries
- Older entries archived to `learned/archive/YYYY-MM.md`
- Per-agent splits when one agent's entries exceed ~30

## License

MIT

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
├── shared/SHARED-CONTEXT.md         # Cross-agent environment/preferences
├── learned/                         # Auto-appended experience (with archive policy)
│   ├── LEARNED.md
│   └── archive/                     # Monthly archives (see auto-learn.md)
│
├── skills/                          # Cross-project reusable instructions
│   ├── README.md                    # Convention for what goes here
│   ├── auto-learn.md
│   ├── output-templates.md
│   ├── agent-delegation.md
│   ├── aidlc-usage-tips.md          # Distilled best practices for AI-DLC interaction
│   └── delegate-to-local-llm.md
│
├── templates/
│   ├── task/                        # Scaffolding for new tasks (used by new-task.sh)
│   │   ├── RESUME.md.tpl
│   │   ├── WORKFLOW.md.tpl
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
├── new-task.sh                      # Scaffold a new task in one command
└── update-aidlc.sh                  # Update AI-DLC rules from GitHub release

tasks/
└── <task-name>/
    ├── RESUME.md                    # Cross-session summary (human-readable)
    ├── WORKFLOW.md                  # Process definition
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
| Record a learned lesson | Append to `.kiro/learned/LEARNED.md` |
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

# 2. Edit shared context
$EDITOR .kiro/shared/SHARED-CONTEXT.md

# 3. Scaffold a new task
./scripts/new-task.sh myproject /home/me/myproject

# 4. Refine the agent
$EDITOR .kiro/prompts/myproject.md
$EDITOR tasks/myproject/RESUME.md

# 5. (Optional but highly recommended) Prepare AI-DLC inputs
cp .kiro/templates/inputs/example-minimal-vision-scientific-calculator-api.md \
   tasks/myproject/vision.md
cp .kiro/templates/inputs/example-minimal-tech-env-scientific-calculator-api.md \
   tasks/myproject/tech-env.md
$EDITOR tasks/myproject/vision.md tasks/myproject/tech-env.md

# 6. Start working
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

## Memory Hygiene

`.kiro/learned/LEARNED.md` follows the archival policy in `.kiro/skills/auto-learn.md`:
- Active file keeps ~50 most recent entries
- Older entries archived to `learned/archive/YYYY-MM.md`
- Per-agent splits when one agent's entries exceed ~30

## License

MIT

# Skills Directory Convention

This directory holds **cross-project, reusable** instruction documents that any agent can reference.

## What belongs here

- Generic patterns: `auto-learn.md`, `output-templates.md`, `agent-delegation.md`
- Tool usage rules: `delegate-to-local-llm.md`, `gitlab-api.md`
- Universal checklists: `ci-review-checklist.md`

## What does NOT belong here

- Project-specific workflows (e.g. how to train a model in project X). These belong in:
  ```
  tasks/<project-name>/skills/
  ```
  or
  ```
  tasks/<project-name>/docs/
  ```
  and are referenced via the agent's `resources` field.

## Reference Format in agent JSON

```json
"resources": [
  "skill://.kiro/skills/auto-learn.md",
  "file://tasks/myproject/skills/training-workflow.md"
]
```

`skill://` for cross-project skills, `file://` for project-specific.

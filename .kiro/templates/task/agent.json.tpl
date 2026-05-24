{
  "name": "{{TASK_NAME}}",
  "description": "Agent for {{TASK_NAME}} — replace with real description.",
  "prompt": "file://../prompts/{{TASK_NAME}}.md",
  "tools": [
    "fs_read",
    "fs_write",
    "execute_bash",
    "grep",
    "glob",
    "code",
    "web_fetch"
  ],

  "allowedTools": [
    "fs_read",
    "grep",
    "glob",
    "code"
  ],
  "resources": [
    "file://tasks/{{TASK_NAME}}/WORKFLOW.md",
    "file://tasks/{{TASK_NAME}}/RESUME.md",
    "skill://.kiro/skills/auto-learn.md",
    "skill://.kiro/skills/memory-layering.md",
    "skill://.kiro/skills/raise-cr.md",
    "skill://.kiro/skills/aidlc-auto-trigger.md",
    "skill://.kiro/skills/output-templates.md",
    "skill://.kiro/skills/agent-delegation.md",
    "skill://.kiro/skills/aidlc-usage-tips.md"
  ],
  "hooks": {
    "agentSpawn": [
      {
        "command": "echo '=== TASK METADATA ===' && cat ./tasks/{{TASK_NAME}}/task.yaml 2>/dev/null || echo '⚠ tasks/{{TASK_NAME}}/task.yaml missing — re-run scripts/new-task.sh or copy from .kiro/templates/task/task.yaml.tpl'",
        "description": "Load task metadata (project_path, repo_url, branch_prefix) — single source of truth"
      },
      {
        "command": "cat ./tasks/{{TASK_NAME}}/RESUME.md 2>/dev/null | head -40",
        "description": "Load task state"
      },
      {
        "command": "cat ./tasks/{{TASK_NAME}}/aidlc-docs/aidlc-state.md 2>/dev/null | head -20",
        "description": "Load AI-DLC state (machine-maintained source of truth while AI-DLC is running)"
      },
      {
        "command": "echo '=== Open CRs (must clear before phase approval — see .kiro/steering/change-management.md) ===' && grep -E '^\\| CR-[0-9]+\\b.* OPEN ' ./tasks/{{TASK_NAME}}/aidlc-docs/change-requests.md 2>/dev/null | head -10",
        "description": "Surface open change requests that block the next phase-approval gate"
      },
      {
        "command": "cat ./.kiro/shared/SHARED-CONTEXT.md 2>/dev/null || echo '⚠ .kiro/shared/SHARED-CONTEXT.md missing — run scripts/init-workspace.sh to create it from the bundled .tpl'",
        "description": "Load workspace-level shared context"
      },
      {
        "command": "cat ./tasks/{{TASK_NAME}}/learned.md 2>/dev/null",
        "description": "Load task-specific learnings (project schema, domain quirks)"
      },
      {
        "command": "cat ./.kiro/learned/LEARNED.md 2>/dev/null || echo '⚠ .kiro/learned/LEARNED.md missing — run scripts/init-workspace.sh to create it from the bundled .tpl'",
        "description": "Load cross-task learnings (reusable across projects)"
      }
    ]
  },
  "welcomeMessage": "{{TASK_NAME}} agent ready. What would you like to do?"
}

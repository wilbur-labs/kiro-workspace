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
    "file://tasks/{{TASK_NAME}}/task.yaml",
    "file://tasks/{{TASK_NAME}}/RESUME.md",
    "file://tasks/{{TASK_NAME}}/WORKFLOW.md",
    "file://tasks/{{TASK_NAME}}/learned.md",
    "file://tasks/{{TASK_NAME}}/aidlc-docs/aidlc-state.md",
    "file://tasks/{{TASK_NAME}}/aidlc-docs/change-requests.md",
    "file://tasks/{{TASK_NAME}}/vision.md",
    "file://tasks/{{TASK_NAME}}/tech-env.md",
    "file://.kiro/shared/SHARED-CONTEXT.md",
    "file://.kiro/learned/LEARNED.md",
    "file://.kiro/adr/README.md",
    "skill://.kiro/skills/auto-learn.md",
    "skill://.kiro/skills/adr.md",
    "skill://.kiro/skills/codex-review.md",
    "skill://.kiro/skills/memory-layering.md",
    "skill://.kiro/skills/raise-cr.md",
    "skill://.kiro/skills/aidlc-auto-trigger.md",
    "skill://.kiro/skills/output-templates.md",
    "skill://.kiro/skills/agent-delegation.md",
    "skill://.kiro/skills/aidlc-usage-tips.md"
  ],
  "welcomeMessage": "{{TASK_NAME}} agent ready. What would you like to do?"
}

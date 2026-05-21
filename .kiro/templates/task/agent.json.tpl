{
  "name": "{{TASK_NAME}}",
  "description": "Agent for {{TASK_NAME}} — replace with real description.",
  "prompt": "file://.kiro/prompts/{{TASK_NAME}}.md",
  "_comment_tools": "All tools the agent CAN use",
  "tools": [
    "fs_read",
    "fs_write",
    "execute_bash",
    "grep",
    "glob",
    "code",
    "web_fetch"
  ],

  "_comment_allowedTools": "Tools that can execute without user confirmation",
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
    "skill://.kiro/skills/output-templates.md",
    "skill://.kiro/skills/agent-delegation.md",
    "skill://.kiro/skills/aidlc-usage-tips.md"
  ],
  "hooks": {
    "agentSpawn": [
      {
        "command": "cat ./tasks/{{TASK_NAME}}/RESUME.md 2>/dev/null | head -40",
        "description": "Load task state"
      },
      {
        "command": "cat ./.kiro/shared/SHARED-CONTEXT.md 2>/dev/null",
        "description": "Load shared context"
      },
      {
        "command": "cat ./.kiro/learned/LEARNED.md 2>/dev/null",
        "description": "Load learned memories"
      }
    ]
  },
  "welcomeMessage": "{{TASK_NAME}} agent ready. What would you like to do?"
}

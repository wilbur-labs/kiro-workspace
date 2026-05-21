# Agent Delegation

Use this skill to coordinate work across multiple agents in this workspace.

## When to delegate

- Task spans multiple project domains (e.g. backend agent needs frontend agent's input)
- Specialized knowledge required that another agent already has loaded
- Parallel tracks to speed up research/implementation

## How to delegate

Use the `subagent` tool with `mode: "blocking"` for results-needed-now tasks:

```yaml
stages:
  - name: research
    role: <other-agent-name>
    prompt_template: "Research X and report findings"
  - name: implement
    role: <self>
    depends_on: [research]
    prompt_template: "Implement based on {research output}"
```

## Context handoff rules

1. Do NOT dump your full context to the sub-agent. Summarize the relevant slice.
2. Pass file paths instead of file contents when possible — the sub-agent can read them.
3. Always include the task name so the sub-agent knows which `tasks/<name>/RESUME.md` to consult.
4. After sub-agent completes, update `LEARNED.md` if any cross-cutting lesson emerged.

## When NOT to delegate

- Trivial work that takes less time than spawning a sub-agent
- When the receiving agent doesn't have the right tools/permissions
- When the task requires interactive user input (sub-agents can't ask the user)

## Examples

| Scenario | Delegate to | Why |
|----------|-------------|-----|
| Need to query MindRAG API behavior | `mindrag` agent | Has the codebase loaded |
| Need a translation training experiment | `lora-studio` agent | Has the training pipeline context |
| Generic web research | self with `web_fetch` | No specialized agent needed |

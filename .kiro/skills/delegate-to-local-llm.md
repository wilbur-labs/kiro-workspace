# Delegating to Local LLMs

Delegate small/medium tasks (code gen, QA, summary, translation, code review) to local LLM CLIs (e.g., gemini-cli, codex) to save kiro-cli token budget.

## Tool Selection

| Tool | Best for | Command |
|------|----------|---------|
| gemini-cli | General QA, summary, translation, design discussion, code review | `gemini -p "..."` |
| codex | Code generation, file editing, bug fixes, refactoring | `npx codex exec "..."` |

## Invocation (via execute_bash)

```bash
# Simple QA
gemini -p "Explain the difference between errors.Join and fmt.Errorf in Go"

# Read file then ask
cat path/to/file.go | gemini -p "Find bugs in this code"

# Code generation/edit
npx codex exec "Add a WithTimeout option to pkg/buildops/option.go"
```

## When to delegate

Delegate to local LLM:
- Single-shot QA
- Small-scale code generation (within one file)
- Code summary / explanation
- Translation
- Simple refactoring
- Composing git/shell commands

Keep with kiro-cli:
- Multi-file large-scale changes
- Project state management (e.g. RESUME.md updates)
- Heavy-context reasoning across the workspace
- Tasks requiring user approval flow

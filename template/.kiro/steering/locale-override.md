# Locale & Output Conventions

## Language

All AI-DLC workflow interactions, documents, questions, and generated artifacts MUST be in Chinese (中文).

- All chat responses: Chinese
- All generated documents (requirements, user stories, design docs): Chinese
- All questions presented to the user: Chinese
- Code comments: Chinese or English (developer's choice)
- Commit messages: English

## Time

- `audit.md` timestamps: Use JST (Japan Standard Time, UTC+9) with current time.

## AI-DLC Artifact Output Path

When the AI-DLC workflow generates artifacts (`aidlc-state.md`, `audit.md`, requirements, user stories, design docs, etc.), output them under:

```
tasks/<task-name>/aidlc-docs/
```

NOT in the repository root `aidlc-docs/`. This keeps each task's AI-DLC artifacts isolated and prevents cross-task contamination when multiple tasks use AI-DLC concurrently.

If the user has not specified `<task-name>`, ask before proceeding. Default fallback: `tasks/default/aidlc-docs/`.

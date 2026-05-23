# Auto-Learn Skill

When discovering valuable patterns during work, capture them — but choose the right layer first.

## Layer Decision (do this BEFORE writing)

Before appending anywhere, ask: **is this learning task-specific or cross-task?**

```
Is the lesson tied to THIS project's data shape, schema, domain rules,
or business quirks — and would NOT apply to a fresh project in this workspace?
│
├─ YES → tasks/<current-task>/learned.md          (per-task pool)
│
└─ NO ─ Is it a reusable snippet, tool gotcha, language idiom, or
        internal-system integration recipe that another task could hit?
        │
        ├─ YES → .kiro/learned/LEARNED.md          (cross-task pool)
        │
        └─ NO ── Is it stable workspace-level config
                 (org, team, network, paths)?
                 │
                 ├─ YES → .kiro/shared/SHARED-CONTEXT.md
                 │       (but usually configured manually, not learned)
                 │
                 └─ NO ─ Is it a code-generation rule or AI-DLC override?
                         │
                         ├─ YES → .kiro/steering/<rule>.md
                         │       (enforced behavior, not memory — needs design)
                         │
                         └─ NO → Don't record it. Likely too generic
                                 or too ephemeral.
```

Quick examples:

| Lesson | Layer | Why |
|---|---|---|
| "User table PK is uuid, not int" | per-task | project-specific schema |
| "FastAPI Depends() doesn't run for ws endpoints — use middleware" | cross-task | framework gotcha, reusable |
| "ReportLab needs `STSong-Light` + `UniGB-UCS2-H` for CJK" | cross-task | tool recipe, reusable |
| "Internal SSO at sso.internal/ expects `X-Auth-Token` not `Authorization`" | cross-task | internal system, reusable |
| "Acme Corp uses HTTPS proxy 10.0.0.1:3128" | shared-context | workspace env, configured |
| "Never use `eval()` on AI-generated code" | steering | rule, not memory |

## Trigger Conditions

- Found a solution after hitting a bug (error message + fix)
- Discovered user preferences or habits
- Repeated operation patterns (can be abstracted as templates)
- User corrected agent's mistake (record correct approach)

## Format

```markdown
### [YYYY-MM-DD] AgentName — Short title

Description (1-3 lines, key info only).
```

For entries in `.kiro/learned/LEARNED.md` (cross-task pool), add a one-line **Why cross-task** justification — this gates against pollution from accidental per-task entries:

```markdown
### [YYYY-MM-DD] AgentName — Short title

Description (1-3 lines, key info only).
Why cross-task: <one sentence — what makes this reusable across projects>.
```

## Promotion (per-task → cross-task)

When you notice a `tasks/<X>/learned.md` entry that also applies to task Y you're working on:

1. **Don't copy.** Copying creates two drifting sources.
2. Propose to user: "Found in `tasks/X/learned.md`: <entry>. This also applies to <current>. Promote to `LEARNED.md`?"
3. On approval: move entry to `.kiro/learned/LEARNED.md`, add **Why cross-task** line, leave one-line pointer in `tasks/X/learned.md`:
   ```markdown
   ### [original date] — Short title → promoted to LEARNED.md
   ```

## Do NOT Record

- One-time temporary info
- Content already in RESUME.md or WORKFLOW.md
- Obvious common knowledge
- Per-task entries copy-pasted into LEARNED.md (use promotion flow instead)

## Archival (avoid context bloat)

Applies to `.kiro/learned/LEARNED.md`. Per-task `learned.md` is bounded by task lifetime, no archival needed.

1. **Per-agent file**: When entries from a single agent exceed ~30, split into `.kiro/learned/<agent-name>.md` and reference from the main file.
2. **Monthly archive**: At the end of each month, move entries older than 90 days into `.kiro/learned/archive/YYYY-MM.md`. Keep only a one-line index in `LEARNED.md`:
   ```markdown
   ## Archive
   - [2026-03] 12 entries — [archive/2026-03.md](archive/2026-03.md)
   ```
3. **Keep recent N**: The active `LEARNED.md` should contain at most ~50 most-recent entries.
4. **Loadable subset**: agentSpawn hooks load `tasks/<name>/learned.md` + `.kiro/learned/LEARNED.md` (not archives) to keep context lean.

# Memory Layering — Decision Tree

This workspace splits knowledge across **five layers** to keep agent context lean and avoid cross-task pollution. Use this file to decide where a piece of information belongs.

## Layers

| Layer | File | Scope | Lifetime | Loaded by agentSpawn? |
|---|---|---|---|---|
| **Task state** | `tasks/<name>/RESUME.md` | this task | until task completes | yes (head -40) |
| **Per-task learned** | `tasks/<name>/learned.md` | this task | until task completes | yes |
| **Cross-task learned** | `.kiro/learned/LEARNED.md` | all tasks in workspace | persistent (90-day archive) | yes |
| **Shared context** | `.kiro/shared/SHARED-CONTEXT.md` | workspace env | persistent, manually maintained | yes |
| **Steering / rules** | `.kiro/steering/*.md` | enforced behavior | persistent | via kiro-cli rules engine |

## When to Write Where

```
Q: Is this PROJECT-SPECIFIC (schema, domain, business logic, this codebase's quirks)?
   └─ YES → tasks/<name>/learned.md

Q: Is this a REUSABLE snippet, tool gotcha, framework idiom, or internal-system recipe?
   └─ YES → .kiro/learned/LEARNED.md (add "Why cross-task: ..." line)

Q: Is this STABLE workspace-level config (org, team, network, proxy, internal URLs)?
   └─ YES → .kiro/shared/SHARED-CONTEXT.md (manually maintained, not learned)

Q: Is this an ENFORCED RULE (code-gen constraint, AI-DLC override)?
   └─ YES → .kiro/steering/<rule>.md (design carefully — this changes agent behavior)

Q: Is this the CURRENT STATE of work (in progress, next steps, blockers)?
   └─ YES → tasks/<name>/RESUME.md

Q: None of the above?
   └─ Don't record it. Likely too generic, too ephemeral, or noise.
```

## Concrete Examples

| Lesson | Layer | Why |
|---|---|---|
| "Todo table PK is uuid, not auto-int" | per-task | schema choice for this project only |
| "Auth uses bcrypt cost=12, not default" | per-task | this project's security config |
| "FastAPI `Depends()` doesn't fire for WebSocket — use middleware" | cross-task | framework gotcha hits any FastAPI project |
| "ReportLab CJK needs `STSong-Light` + `UniGB-UCS2-H` codec" | cross-task | tool recipe, reusable |
| "Internal SSO expects `X-Auth-Token` header, not `Authorization`" | cross-task | internal system, any project that integrates hits this |
| "Corporate HTTPS proxy: 10.0.0.1:3128" | shared-context | workspace-level network fact |
| "Team Slack: #ai-platform; on-call: PagerDuty rotation 'aip'" | shared-context | org-level constant |
| "Never write `eval()` in generated code" | steering | enforced code-gen rule |
| "Currently mid-way through unit B code-gen, blocked on contract review" | RESUME.md | current state, transient |

## Promotion (per-task → cross-task)

When an entry in `tasks/<X>/learned.md` turns out to apply to a second task:

1. **Don't copy** — copying creates drift between two sources.
2. Move the entry to `.kiro/learned/LEARNED.md`.
3. Add a **Why cross-task** line justifying the move.
4. Leave a one-line pointer in `tasks/<X>/learned.md`:
   ```markdown
   ### [original date] — Short title → promoted to LEARNED.md
   ```

The reverse (cross-task → per-task) should rarely happen. If a `LEARNED.md` entry turns out to be project-specific, fix the original mis-classification: remove it from `LEARNED.md` entirely (not move down).

## Anti-Patterns

- **Dumping everything into LEARNED.md** — pollutes every future agent with one project's quirks. The applicability filter exists to prevent this.
- **Splitting one fact across layers** — a single lesson belongs in exactly one place. If it feels like it spans two, ask whether you're conflating two distinct lessons.
- **Treating SHARED-CONTEXT as a learning pool** — it's manually curated stable config, not a free-form notebook. Auto-learn skill should never write there.
- **Using LEARNED.md as a changelog** — for project history, use git log; for task progress, use RESUME.md.

## Related

- `.kiro/skills/auto-learn.md` — when and how to capture learnings (the trigger / format)
- `.kiro/templates/task/learned.md.tpl` — per-task learned skeleton
- `.kiro/learned/LEARNED.md` — cross-task pool (this is the destination, not the trigger)

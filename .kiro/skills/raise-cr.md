# Raise CR — Capture Scope Changes Without Breaking Flow

Companion skill to `.kiro/steering/change-management.md`. The steering file defines WHAT a CR is and WHEN the gate enforces it. This file is the agent's playbook for HOW to capture one in the middle of a working conversation, with zero friction.

## When to Raise

Watch for these triggers and raise a CR **the moment one fires** — don't wait until the end of the conversation, don't bundle multiple into one.

### User-side triggers (verbatim cues to listen for)

- "顺手加 X" / "顺便修一下" / "捎带做了 Y"
- "为啥不也 Y" / "我们应该考虑 Z"
- "啊不对，其实我想要的是…"
- "这个 X 也加上吧" / "再加个 Y 字段"
- "actually let's also …" / "while we're at it …" / "can we also …"
- "wait, this doesn't match what we said in vision"

### Agent-side triggers (your own self-check)

Before you write design.md or generate code, ask yourself:

- "Does this match the approved vision.md and requirements.md?"
- "Am I about to add a field / endpoint / screen / behavior that's NOT in the approved scope?"
- "Would the original vision.md let me write a one-line acceptance test for this?"

If any answer is "no" → raise a CR on yourself.

### Reviewer-side triggers

A code-reviewer or design-reviewer agent surfacing "this contradicts requirement R-7" or "this introduces a feature not in the approved scope" → that finding becomes a CR.

## Capture Phrases (paste-ready)

The point is to acknowledge the suggestion WITHOUT committing to it, log it, and continue current work.

For a user suggestion that smells like creep:

> 听起来你想加 X，要不要先记成 CR-N 待会儿一起决定？这样我先把现在 unit-A 的事做完，approve construction 之前我会回到 CR-N 让你决定 accept / backlog / reject。

For a user suggestion that smells like refine (within scope):

> X 看起来是 unit-A 范围内的细节调整，我把它记成 CR-N type=refine，等会儿更新 design.md 时一起处理。如果你觉得超出范围，告诉我，我改成 creep。

For a self-detected creep (agent caught itself drifting):

> 等下 — 我刚才打算加 X，但 vision.md 里没有这一条。先停一下，raise CR-N type=creep 让你决定 (a) accept + 改 vision (b) backlog (c) reject。继续之前要 approve。

For a bug:

> 发现一处实现和 design 不一致：<具体>。raise CR-N type=bug，apply 后继续。

## Zero-Friction Logging

When you raise a CR:

1. **Append one row** to `tasks/<task-name>/aidlc-docs/change-requests.md`. Don't reorganize, don't refactor the table, don't summarize old entries.
2. **Status starts as `OPEN`**. Type starts as `UNCLASSIFIED` if you're capturing a raw user suggestion, or your best guess (`bug` / `clarify` / `refine` / `creep` / `cut`) if it's obvious.
3. **Continue the work you were doing.** Do NOT pause to triage unless the suggestion blocks current work (e.g. user is asking you to remove a function you're mid-way through writing).

Row template:

```markdown
| CR-N | YYYY-MM-DD | construction / unit-X stage-Y | user | "<verbatim or paraphrase>" | UNCLASSIFIED | OPEN | | |
```

## When to Triage (NOT in the middle of work)

Triage at one of:

- **End of stage** (e.g. just before approving "Code Generation step 7" for the current unit).
- **End of phase** (forced by the phase approval gate — see `change-management.md`).
- **User explicitly asks** ("let's go through open CRs now").

Triage = move `Status: OPEN` → `DECIDED` with `Type` + `Decision` filled. For `creep` accepted, also: update `vision.md` + `requirements.md` first, fill `Propagated To`, then set `DONE`.

## Anti-Patterns

- **"I'll just remember it"** — No. Always write the row immediately.
- **Bundling 5 unrelated suggestions into one CR** — Each suggestion gets its own row. Forensic clarity beats list compression.
- **Triaging in the middle of unit code-gen** — Breaks flow, fragments the audit trail. Wait for a natural stop.
- **Asking the user to triage every CR the moment it's raised** — Defeats the purpose of zero-friction capture. Triage in batches at gate boundaries.
- **Auto-classifying a user's suggestion as `creep` without confirming** — Capture as `UNCLASSIFIED`, let the user (or a deliberate triage moment) classify.

## Related

- `.kiro/steering/change-management.md` — CR types, phase gate, propagation rules.
- `.kiro/templates/task/change-requests.md.tpl` — CR-log skeleton.
- `.kiro/skills/auto-learn.md` — orthogonal: capture-rules for cross-task learnings, not scope changes.

# AI-DLC Usage Tips

Distilled best practices from awslabs/aidlc-workflows `docs/WORKING-WITH-AIDLC.md`.
Apply these patterns when interacting with the AI-DLC workflow.

## 1. "Do Not Update" Pattern

**Not every question should trigger a document update.** Prefix exploratory questions with a no-change instruction:

```text
Do not update any documents. Help me understand why [decision] was made.
Do not change anything. Assess the impact of [proposed change].
```

Drop the constraint only when ready to act.

## 2. Question → Doc → Approval Flow

AI-DLC writes questions into a markdown file (NOT in chat) and waits.

When answering `[Answer]: <letter>` tags:

- **Add a label**: `C — financial summary` (clearer than `C` alone)
- **Include brief justification**: `A — design-first; OpenAPI before code`
- **Combine options**: `B and C — both API gateway and app-level rate limiting`
- **Use X freely** for custom answers when none of A-E fit
- **State deliberate "no"**: `D — no caching required at this time`

After answering, return to chat with:

```text
We have answered your clarification questions. Please re-read the file and proceed.
```

The "re-read" hint forces a disk reload (avoids stale in-memory state).

## 3. Context Management — The Core Rule

**Clear context at every natural decision point.**

AI-DLC has gates (question files, document approvals). These are the right moments to start a fresh context:

- After answering a question file → fresh context → "re-read file and continue"
- After approving/requesting changes on a document → fresh context → next stage
- **Never accept "compact context"** — compaction loses more than a clean reset

Resume with state-file method:

```text
Go to aidlc-docs/aidlc-state.md, find the first unchecked item,
then go to the corresponding plan file and resume from that point.
```

Tip: `git commit && git push` before every context reset for clean recovery points.

## 4. Never Vibe Code

**Update the design first, then regenerate the code.** Don't directly edit AI-generated code files.

When you find an issue:

```text
Step 1: Do not update any documents yet. I have discovered issue [X].
        Review the design and help me understand where to address this.

Step 2: Please update [specific design doc] to reflect [the fix].
        Then check whether requirements/user stories also need updates.

Step 3: The design for [unit] has been updated. Please re-run code generation
        for the affected files only.
```

If you must direct-edit to unblock the team, log it honestly afterwards so the audit trail stays accurate.

## 5. Standing Rules

Set these once at phase start instead of repeating per request:

```text
Every time you update a document, check whether the change impacts requirements
and user stories, and prompt me if it does.
```

```text
When you make a design decision during code generation, always ensure the
documentation reflects this change before proceeding.
```

```text
At the component design phase, no single component should have more than [X]
aggregate story points. If exceeded, break it down.
```

## 6. Loading External Reference Files

Anytime, any phase:

```text
Please read [file path]. Use it as the basis for [what you want].
```

```text
We have an existing audit table structure. Please add it to the inception
documents and reference it for this service.
```

## 7. Independent Critiques

For unbiased review, ask in a **fresh context** (no memory of why decisions were made):

```text
Produce a critique document of [the requirements / the component design].
Do this in a new context separate from everything else.
```

## 8. Depth Levels

```text
Keep this at minimal depth — we just need basic structure documented.
This is a production-critical component. Run at comprehensive depth.
```

## 9. Batching Prompts

- **Coupled changes to the same subject** → one prompt
- **Unrelated changes** → separate prompts
- When in doubt, separate.

## 10. Brownfield: Watch for Duplicate Files

For brownfield projects, AI-DLC modifies files in place. If you see `Foo_modified.java` next to `Foo.java`, flag it:

```text
I see [Foo_modified.java] alongside [Foo.java]. Please merge into the original
and delete the duplicate.
```

## 11. Just-In-Time Tool Injection

Don't add test framework / test management instructions at project start — they may be lost in context compression. Inject them at the phase where they're needed:

```text
At the functional test generation step, inject the following instruction:
generate tests using [test management system] format described in [spec file].
```

## 12. Reports Go in `reports/`, Not `aidlc-docs/`

Human-facing reports (architecture diagrams, presentations) should NOT be saved in `aidlc-docs/` — those will inflate AI context in subsequent stages.

```text
Pause. Start a new context. Read [report spec] and produce the report based on
current AIDLC artifacts. Save to reports/, not aidlc-docs/.
```

## 13. Back-Propagating Code Changes to Design

After code polish, sweep changes back upstream:

```text
When you have finished polishing the code, review each unit's final design files
and propagate any changes back up to requirements and user stories.
Make a plan for how to do this step by step before executing.
```

---

## Quick Reference Card

| Want | Say |
|------|-----|
| Just ask a question, don't change anything | `Do not update any documents.` |
| Resume after context reset | `Go to aidlc-docs/aidlc-state.md, find first unchecked item, resume.` |
| Re-read after answering | `We have answered your questions. Please re-read the file and proceed.` |
| Get unbiased critique | `Produce a critique in a new context separate from everything else.` |
| Run lighter | `Keep this at minimal depth.` |
| Run heavier | `Run at comprehensive depth.` |
| Backlog (don't delete) feature | `Backlog [feature], remove from design, flag stories as backlogged.` |
| Bug found in code | Step 1-3 above. Update design, then regenerate.

Source: <https://github.com/awslabs/aidlc-workflows/blob/main/docs/WORKING-WITH-AIDLC.md>

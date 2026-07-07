# Codex Review — Independent Second Opinion Before Commit

Outsource code review to **codex** (a different model, no knowledge of this session) before every commit. This is the independent-model gate that Layer C (`code-quality-reviewer`) structurally can't be — Layer C is a kiro subagent, same model family, same runtime, so it shares this session's blind spots. See `.kiro/adr/0002-review-outsourced-to-codex.md`.

**Tests are not this.** You run tests yourself (pytest / `tsc --noEmit` / build) — the fast gate. This skill is review only, and never replaces tests.

## How it relates to the three-layer gate

`.kiro/steering/code-quality.md` defines Layer A (prevent) / C (detect, internal reviewer) / B (measure, tooling). Codex is a **fourth, independent** checkpoint at a different point in time:

| | Layer C reviewer | Codex review |
|---|---|---|
| Model | same as primary (kiro subagent) | **independent** (OpenAI Codex) |
| Sees session context | yes | **no** (fresh eyes) |
| When | per-unit, mid-construction (code-gen step 7) | **before every commit** |
| Scope | this unit's diff, 4 semantic classes | the whole uncommitted change |

They are complementary — run Layer C at step 7 as usual; run codex before you commit. Don't drop one for the other.

## When to run

**Hard rule: any code change, before `git commit`, run codex review.** This includes changes to the workspace framework itself (steering, skills, agent JSON, scripts) — the framework is not exempt from its own gate.

Order: ① you run the relevant tests and they pass → ② codex review → ③ triage every finding → ④ commit only once clean.

## How to run

1. **Confirm tests passed** for this change. Not run yet → run them first; codex does not replace tests.
2. **Find the repo.** The project repo is in this task's `tasks/<task>/task.yaml` (`project_path` / repo coordinates). For a change to the workspace itself, the repo is the workspace root.
3. **Run the script** (use the shell / `execute_bash` tool). **Pick by platform** —
   the invocation differs because bare `bash` is not usable inside a kiro agent on
   Windows (see the platform box below):

   - **Windows** (kiro's `execute_bash` runs on PowerShell; bare `bash` = broken WSL):

     ```powershell
     pwsh -ExecutionPolicy Bypass -File scripts/codex-review.ps1 <repo_dir>
     ```

   - **Linux / macOS**:

     ```bash
     bash scripts/codex-review.sh <repo_dir>
     ```

   - Default scope = `--uncommitted` (reviews staged/unstaged/untracked before commit).
   - Other scopes pass through (append after `<repo_dir>`): `--commit HEAD` (a commit) / `--base main` (against a branch) / a plain focus prompt (e.g. `"focus on the write-path safety"`).
   - Codex is slow (1–3 min). If the tool backgrounds it, wait for completion or read the output.
   - **Model is not pinned** — the script uses codex's default (latest) model.

   > **Why two invocations (Windows).** kiro-cli's `execute_bash` runs commands
   > through PowerShell on Windows, and bare `bash` there resolves to a broken WSL
   > bash, so `bash scripts/codex-review.sh` fails. `codex-review.ps1` locates the
   > real Git Bash and runs the same `.sh` through it. Core logic stays in one
   > cross-platform `.sh`; only the launcher differs by platform.

4. **Triage each finding.** Codex is independent and **cannot see this session's context**, so expect some false positives or misunderstandings of settled decisions:
   - Real bug / real improvement → fix it, then **re-run the relevant tests**.
   - False positive / conflicts with a settled decision (an intentional design, a hard rule, a trade-off the user already approved) → don't change it, but be able to say in one line why you're rejecting it.
   - Unsure → surface it to the user (a codex-vs-you disagreement is often exactly the boundary case worth a human call).
5. **Report briefly.** Tell the user how many findings, which you fixed, which you rejected (with reason), any disagreement needing their call. Say you re-ran tests on the fixes.
6. **Then commit.** Only after review is clean (fixed + tests pass, or explicitly rejected). This is the pre-commit hard gate.

## Anti-Patterns

- **Skipping codex because Layer C already ran** — Layer C is the same model; it can't be the independent opinion. Different checkpoint, different reviewer.
- **Pasting codex's raw output to the user** — distill to "accepted / rejected + reason".
- **Committing framework changes without codex** — the workspace's own scripts/steering/skills go through the same gate.
- **Pinning a codex model version** — let the script use the default; pinned versions rot.

## Related

- `.kiro/adr/0002-review-outsourced-to-codex.md` — the decision + rejected alternatives.
- `.kiro/steering/code-quality.md` — the three-layer gate codex sits alongside.
- `scripts/codex-review.sh` — the wrapper this skill drives.

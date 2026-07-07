# 0002. Outsource pre-commit review to codex (independent model); keep the internal reviewer for per-unit detection

- **Status**: accepted
- **Date**: 2026-07-07
- **Layer**: framework

## Context

The workspace already has a Layer C code reviewer (`code-quality-reviewer`, see `.kiro/steering/code-quality.md`). But it is a **kiro subagent** — same model family, same runtime, and it runs inside the same overall session. Same-model review has a self-consistency blind spot: the reviewer tends to accept the shapes the primary model finds natural, so a whole class of "looked fine to me, looks fine to me" errors slips through. A gate that shares the author's blind spots is not a real independent gate.

This is the P4 gap in the workflow-polish task: kiro's only review was internal, violating the "independent model avoids self-review" principle that claude-workspace already adopted (its ADR-0002).

## Decision

- **Tests stay with the primary agent** (pytest / `tsc --noEmit` / build) — the fast gate, not outsourced.
- **Add an independent external review gate: codex** (OpenAI Codex CLI, a different model with no knowledge of this session). Run it **before every commit** via `scripts/codex-review.sh` (default scope `--uncommitted`). Playbook: `.kiro/skills/codex-review.md`.
- **Codex complements Layer C, does not replace it.** Layer C runs per-unit mid-construction (code-gen step 7) on the four semantic classes; codex runs at commit time over the whole change with fresh, independent eyes. Both run.
- **The framework itself is not exempt**: changes to steering / skills / agent JSON / scripts also go through codex before commit (P5).
- Do not pin the codex model version — use its configured default (latest).

## Consequences

- One extra 1–3 min gate before each commit. Codex can't see the session context → some false positives / misunderstood settled decisions → each finding is triaged (fix real bugs, reject false positives with a one-line reason, escalate genuine disagreements to the user).
- Two reviewers now exist with a clear division (internal/per-unit vs external/pre-commit) — the skill and steering must keep them from double-enforcing or being confused for each other.
- Proven immediately: this same task's ADR-mechanism commit (kiro 7cb67a8) was codex-reviewed pre-commit and codex caught an over-broad "every agent" auto-load claim the primary model had written — exactly the independent-eyes value.
- `scripts/codex-review.sh` is duplicated from claude-workspace rather than shared, so kiro-workspace stays a self-contained template (a fork without claude-workspace still works). Accepted drift cost; the two are independent by design (workflow-polish anchor).
- **Windows shell wrinkle** (found in live verification): kiro-cli's `execute_bash` runs on PowerShell, and bare `bash` there resolves to a broken WSL bash — so `bash codex-review.sh` fails in-agent. Fix follows the core-in-bash / thin-platform-launcher shape: core logic stays in `codex-review.sh`; `scripts/codex-review.ps1` is a Windows launcher that finds the real Git Bash and runs the `.sh` through it. Linux/macOS call the `.sh` directly. Verified in-agent (`& "…\Git\bin\bash.exe" …` returns MINGW output).

## Alternatives considered

- **Keep only the internal Layer C reviewer** — rejected: same-model self-consistency bias; not an independent opinion. This is the exact P4 gap.
- **Replace Layer C with codex** — rejected: Layer C runs mid-construction per unit (before code even reaches commit) and is tuned for adoptability on four semantic classes; codex is a coarser, later, whole-change gate. Dropping C loses the early per-unit catch.
- **Share one `codex-review.sh` across both workspaces** — rejected: makes kiro-workspace depend on claude-workspace being cloned alongside it, breaking the self-contained-template property. The workflow-polish anchor keeps the two independent.
- **Human-only review** — rejected: slow, inconsistent, requires a person present; doesn't scale to every commit.
- **CI linter / type-checker only** — kept, but as the test layer (Layer B); tools can't do semantic review (logic / boundary / design). Not a substitute for an independent model reading the change.

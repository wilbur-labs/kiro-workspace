# AI-DLC Auto-Trigger — Propose, Don't Decide

When a user opens a fresh session and describes a piece of work, the agent should recognize the **shape** of the request and proactively propose using AI-DLC at an appropriate depth — without making the decision for the user.

**Why this exists:** the upstream `locale-override.md` says AI-DLC is "ALWAYS" used, but in practice the user has to remember to prefix with `AI-DLC を使って`. That puts the cognitive load on the wrong side. This skill flips it: the agent reads the shape, makes a recommendation, and the user just confirms or redirects.

The user keeps full veto power. The agent's job is to surface the option clearly, not to start AI-DLC silently.

## Trigger Shapes

Listen for these shapes in the user's opening message. Match by intent, not by exact wording.

| Shape | User cues | Recommended AI-DLC depth | Why |
|---|---|---|---|
| **New system / greenfield** | "做个 X 系统" / "build a new Y service" / "搭个 Z 平台" / "start a new project for …" | **standard** (full inception → construction → operations) | The whole pipeline pays off — vision.md frames scope, contracts freeze the units, smoke catches integration early. |
| **New feature on existing project** | "加个 Y 功能" / "add Z to project X" / "扩展现有 X 支持 Y" / "feature: …" | **standard**, scoped to the new unit(s) | Skip the full reverse-engineer, but do run a mini-inception for the new surface + the contract diff with existing units. |
| **Refactor / restructure** | "重构 Z 模块" / "restructure the X layer" / "把 X 拆成 Y+Z" / "migrate from A to B" | **comprehensive** | Refactors are the highest-risk shape — invisible scope, easy to silently expand. Full AI-DLC + change-management gate are most valuable here. |
| **Bug fix** | "修个 bug" / "fix the X issue" / "用户反馈 Y 不工作" / "production is broken" | **skip** (direct work) | The investigate-fix-verify loop is too short for AI-DLC to add value. But: if root-cause analysis reveals a missing requirement → that's a `clarify` or `creep` CR and AI-DLC may still need to be re-entered. |
| **Investigation / spike** | "看看 X 怎么做的" / "research how to do Y" / "spike Z" / "我想了解 …" | **skip** (direct work) | Investigation precedes scope definition; running AI-DLC over an undefined target is wasted ceremony. The output of the spike may then trigger one of the rows above. |
| **Operational / one-shot** | "跑下 X 命令" / "deploy Y" / "rotate the Z secret" / "check the logs of …" | **skip** | Ops work has no design phase. |
| **Ambiguous** | One-line message with no verb, or "help me with X" without context | **ask first**, don't propose AI-DLC yet | Get one clarifying question in, then re-match against the shapes above. |

## Depth Definitions

| Depth | What runs | What is skipped |
|---|---|---|
| **minimal** | requirements-analysis + application-design + code-generation per unit, with contracts (M1.3 #1) | user-stories, NFR phases, reverse-engineering |
| **standard** (default for features / new systems) | full inception (requirements + stories + app-design + units-generation + contracts) + per-unit construction + Build & Test (M1.3 #2) | operations may be deferred if not deploying |
| **comprehensive** (refactors / migrations) | minimal **+** reverse-engineering of the existing code **+** the full M1.3 gates **+** explicit NFR phase | nothing — this is the full pipeline |

## The Proposal Phrase

When you detect a trigger shape, respond before doing any work with a single short message in this form:

```
这看起来像 [shape]，建议走 AI-DLC [depth]（[一句话理由]）。继续？(Y / n / depth=minimal|comprehensive)
```

Concrete examples (Chinese):

- User: "我想做一个商品搜索 API"
  → "这看起来像**新系统**，建议走 AI-DLC **standard**（contracts + smoke 在多 unit 项目里最值钱）。继续？(Y / n / depth=…)"
- User: "把现在的 auth 模块拆成 auth-core 和 auth-jwt 两个 unit"
  → "这看起来像**重构**，建议走 AI-DLC **comprehensive**（拆 unit 是接口边界变更，contracts freeze + change-management 最关键）。继续？(Y / n / depth=…)"
- User: "登录后 token 没刷新，line 142"
  → "这看起来像 **bug fix**，建议**跳过 AI-DLC** 直接 investigate-fix-verify。如果排查发现是需求漏洞（不是实现 bug），我会建议补 inception。继续？(Y / n)"

In English contexts, mirror the structure; keep the question concise.

## What "Continue" Means

- **Y** — kick off AI-DLC at the proposed depth. If this is a new task, scaffold `tasks/<name>/` via `scripts/new-task.sh` first (which now creates vision.md / tech-env.md / task.yaml / change-requests.md).
- **n** — the user wants to handle it directly. Do not re-propose AI-DLC unless the conversation reveals a shape change (e.g. a "quick fix" turns out to need a contract update).
- **depth=<X>** — adopt the user's override and start.
- **Anything else** — treat as a clarification, ask one targeted question, re-match.

## Anti-Patterns

- **Silent start** — opening with `AI-DLC を使って…` and beginning to generate vision.md without user confirmation. Defeats the veto.
- **Over-proposing** — re-prompting the user about AI-DLC after they already said `n`. They redirected; respect it.
- **Under-proposing** — burying the recommendation in three paragraphs of preamble. The proposal is one short message.
- **Wrong depth** — defaulting to `comprehensive` for everything because "more is safer". Comprehensive on a small feature wastes the user's time and erodes trust in the proposal.
- **Treating bug-fix shape as feature** — fixing a bug doesn't need a vision.md. If you find yourself writing one, the shape was misclassified.
- **Skipping the proposal on what looks ambiguous** — if you can't tell what the user wants, ASK; don't guess and silently start AI-DLC.

## When the Shape Changes Mid-Conversation

The first message sets the initial shape, but the user may pivot. Examples:

- "Fix this bug" → during investigation, reveal it requires schema change → propose elevating to standard AI-DLC for the affected unit.
- "Build a new service" → user changes their mind about scope mid-inception → that's a `cut` CR through `.kiro/steering/change-management.md`, not a new shape detection.

Use the same proposal phrase template when re-proposing after a shape shift. Don't proceed unilaterally.

## Related

- `.kiro/steering/locale-override.md` — upstream "always use AI-DLC" rule that this skill operationalizes without putting the burden on the user.
- `.kiro/steering/change-management.md` — once AI-DLC is running, scope changes route through the CR gate, not back through this skill.
- `scripts/new-task.sh` — invoked on `Y` for new tasks; sets up the full scaffold (task.yaml + vision/tech-env + change-requests + learned).
- `.kiro/skills/aidlc-usage-tips.md` — distilled best practices for working WITHIN an AI-DLC session (once this skill has triggered one).

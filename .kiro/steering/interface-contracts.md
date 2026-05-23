# Interface Contracts — Cross-Unit Freeze Gate

Inserts a mandatory **Interface Contracts** stage at the end of INCEPTION, after Units Generation and before transitioning to CONSTRUCTION. Without this gate, AI-DLC's Application Design (`.kiro/aws-aidlc-rule-details/inception/application-design.md`) only produces high-level component interfaces — `component-methods.md` lists method signatures but no machine-readable schema. Two units then enter Code Generation in parallel with incompatible assumptions, and the mismatch only surfaces at Build & Test.

This file is a steering **override**: it adds a stage on top of the upstream AWS rules. The upstream files under `.kiro/aws-aidlc-rule-details/` are NOT modified (they get overwritten by `scripts/update-aidlc.sh`).

## Where this stage lives in the workflow

```
INCEPTION
├── Workspace Detection
├── Requirements Analysis
├── User Stories
├── Application Design
├── Units Generation
└── Interface Contracts  ← THIS STAGE (added by this override)
    ↓
   gate: cross-unit review + user approval
    ↓
CONSTRUCTION
```

The transition into CONSTRUCTION is BLOCKED until this stage's gate passes.

## Required Artifacts

For every unit defined in `aidlc-docs/inception/application-design/unit-of-work.md`, generate exactly one machine-readable contract under:

```
aidlc-docs/inception/application-design/contracts/<unit-name>.{yaml,py,ts}
```

Pick the schema language by what the unit exposes. **Exactly one per unit.**

| Format          | When to use                                                                 | Example file              |
|-----------------|-----------------------------------------------------------------------------|---------------------------|
| OpenAPI YAML    | Unit exposes an HTTP API (REST / GraphQL gateway)                           | `contracts/auth.yaml`     |
| Pydantic models | Unit is a Python library / internal service consumed via function calls     | `contracts/auth.py`       |
| TypeScript types | Unit is a JS/TS library or front-end consumed via imports                   | `contracts/auth.ts`       |

The contract MUST cover:

1. **Public surface only.** Internal helpers, private methods, db schemas → out of scope.
2. **Every method/endpoint/event** the unit publishes to others.
3. **Input shape** (request body, function args, event payload) with field types.
4. **Output shape** (response body, return type, emitted event) with field types.
5. **Error modes** the consumer must handle (HTTP error codes / exception types / failure events).
6. **Versioning hint** (`v1` / SemVer / "internal — break freely") so consumers know the stability contract.

If a unit has NO outward-facing surface (purely internal helper), document this explicitly with a one-line `# No external surface — internal-only` placeholder so the gate is not bypassed by omission.

## Step-by-Step Execution

1. **List units** — read `aidlc-docs/inception/application-design/unit-of-work.md` and enumerate every unit. Pause if the list is empty or unclear; that is a Units Generation defect, not a contract defect.
2. **Pick schema language per unit** — apply the table above. Prefer OpenAPI when the unit's primary boundary is HTTP, even if internal Python code wraps it.
3. **Draft each contract** — populate the required surface (methods, inputs, outputs, errors, versioning). One contract file per unit. Do NOT inline contracts of multiple units into one file — they must be independently reviewable.
4. **Run the cross-unit review** — for every (consumer, producer) pair in `unit-of-work-dependency.md`:
   - The consumer-perspective question: "If I'm the consumer of unit X, does X's contract give me every method / field / error I need to do my job?"
   - Surface gaps as a CR (see `.kiro/skills/raise-cr.md`), classified as `clarify` if the missing detail was an oversight, `creep` if it's a new requirement.
5. **Present the contract set to the user** for approval. The prompt MUST list every contract file + a one-line summary of dependencies covered. Example:

   ```
   Interface Contracts ready for approval:
     - contracts/auth.yaml         (consumed by: todo-crud, notification)
     - contracts/todo-crud.py      (consumed by: notification)
     - contracts/notification.ts   (consumed by: web-frontend)
   Cross-unit review found 0 gaps after CR-3 resolved.
   Approve to proceed to CONSTRUCTION? (y/n)
   ```

## Phase Gate Rules

CONSTRUCTION cannot start while any of these conditions hold:

1. A unit listed in `unit-of-work.md` has no contract file under `contracts/`.
2. A contract file exists but is missing a required surface section (inputs / outputs / errors / versioning).
3. The cross-unit review surfaced gaps that became CRs (see `.kiro/steering/change-management.md`) and any of those CRs are not `DONE`.
4. The user has not explicitly approved the contract set.

The contract files become the **freeze**. After approval, modifying a contract is itself a `clarify` or `creep` CR — not a silent design change.

## Why machine-readable, not just prose

`component-methods.md` (upstream Application Design output) gives method signatures in markdown. That is enough for human readers but not enough for:

- Automated cross-unit smoke testing (M1.3 #2 — generates stub clients/servers from the contract).
- Type-checking the consumer code against the producer's actual schema during Code Generation.
- Detecting breakage when a producer evolves the contract (a `diff` on a YAML file is unambiguous; a diff on prose is interpretation-dependent).

OpenAPI / Pydantic / TS-types are all parseable, all have toolchains, and all support diffs that humans and CI can review.

## Anti-Patterns

- **Single-file all-units contract** — review impossible, diff noise high. One file per unit.
- **Contracts that re-document internal helpers** — that's design.md territory, not contract.md.
- **Bypassing the gate with "we'll firm it up in construction"** — that's the exact failure mode this stage exists to prevent.
- **Generating contracts AFTER code-gen as documentation** — by then it's a description, not a contract; consumers have already been written against assumptions.
- **Skipping the cross-unit review because "the dependency is obvious"** — the review is what surfaces the gaps. Run it even when you think it's redundant.

## Related

- `.kiro/aws-aidlc-rule-details/inception/units-generation.md` — upstream stage that lists the units this gate operates on (do not modify).
- `.kiro/aws-aidlc-rule-details/inception/application-design.md` — upstream stage that produces `component-methods.md` (do not modify).
- `.kiro/steering/cross-unit-smoke.md` — companion CONSTRUCTION-phase rule that USES these contracts to generate per-unit smoke tests.
- `.kiro/steering/change-management.md` — CRs raised during the cross-unit review flow through this gate.

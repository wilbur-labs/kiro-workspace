# Cross-Unit Smoke + Build & Test Enforcement

Two CONSTRUCTION-phase enforcement layers that share one principle: **integration must be exercised early and the result must be a real test run, not a markdown document about testing.**

This file is a steering **override** on top of:

- `.kiro/aws-aidlc-rule-details/construction/code-generation.md` (per-unit code generation)
- `.kiro/aws-aidlc-rule-details/construction/build-and-test.md` (currently a meta-stage that generates testing *instructions*)

Upstream files under `.kiro/aws-aidlc-rule-details/` are NOT modified.

## Why this exists

Without these overrides, two failure modes are common:

1. **Late-binding integration breakage.** Unit A and Unit B both pass their own unit tests. They first run together at Build & Test, weeks after each was code-generated. The contract mismatch surfaces with no clear owner, far from the code that introduced it.
2. **Tests-as-document substitute for tests-as-running-code.** AI-DLC's Build & Test stage in its current shape generates `build-instructions.md` and `test-strategy.md`. Both are useful artifacts, but absence of a passing test run is not evidence of a working system.

Companion to `.kiro/steering/interface-contracts.md`, which provides the machine-readable contracts these smoke tests target.

---

## Part 1 — Per-Unit Cross-Unit Smoke (extends code-generation.md)

When generating code for unit X, after step 7 (final unit-test pass) of upstream `code-generation.md` is complete:

1. **Compute upstream dependencies.** From `aidlc-docs/inception/application-design/unit-of-work-dependency.md`, list every unit Y that X consumes AND that has already completed Code Generation.
2. **If the set is empty**, skip the smoke step (X has no upstream that's ready) and proceed.
3. **Otherwise, for each Y in the set:**
   - Locate Y's contract at `aidlc-docs/inception/application-design/contracts/<Y>.{yaml,py,ts}`.
   - Generate a smoke test that exercises X's calling code against Y's actual generated implementation (not a mock).
     - OpenAPI contract → spin up Y's service locally (docker-compose / spawned subprocess / in-process for Python), have X hit a representative endpoint, assert the response shape matches Y's contract.
     - Pydantic contract → import Y's models, instantiate the call X makes, assert no validation errors.
     - TS types → tsc / type-check X's import-and-use of Y's types as a build-time check.
   - **Smoke covers happy path + one error path.** Not exhaustive — Build & Test handles the full integration matrix. Smoke catches "did we actually plug A into B."
4. **Smoke MUST pass before X's code-generation step 7 is considered complete.** Failure blocks closing the step; resolution is either (a) fix X (the consumer was wrong), (b) raise a `bug` CR if Y's implementation deviates from its frozen contract, or (c) raise a `clarify` CR if the contract itself is ambiguous.

The smoke artifacts live alongside X's normal tests, under whatever the project convention is (`tests/smoke/test_x_against_y.py`, `src/x/__tests__/smoke.x-y.ts`, etc.). They are not throwaway scripts — they run in CI.

## Part 2 — Build & Test Must Actually Run (overrides build-and-test.md)

The upstream `build-and-test.md` stage produces `build-instructions.md`, `test-strategy.md`, etc. — useful, but documents, not test runs. This override adds an enforcement clause:

**Build & Test stage is INCOMPLETE until:**

1. Every test command listed in the generated `test-strategy.md` has been **executed**, not just written down.
2. The full test matrix passes:
   - Per-unit unit tests
   - Cross-unit smoke tests from Part 1 (now running together as the integration tier)
   - Integration tests (whatever the project's `test-strategy.md` defines as such)
3. The actual test-run output is captured in `aidlc-docs/construction/build-and-test/test-run-<timestamp>.log`.
4. The agent reports the pass/fail counts to the user explicitly:

   ```
   Build & Test results:
     Unit tests:        148 passed, 0 failed
     Cross-unit smoke:    9 passed, 0 failed
     Integration:        23 passed, 0 failed
   Approve to proceed to OPERATIONS? (y/n)
   ```

**Failure blocks the transition to OPERATIONS.** Failing tests are either:

- A `bug` CR (implementation diverged from a frozen contract or requirement).
- A `clarify` CR (the test's expectation is wrong because the requirement was ambiguous).
- A `creep` CR (the test reveals an unstated requirement — needs vision.md update before fixing the test).

Treat a yellow build the same as a red build. "Flaky" is a temporary classification with a CR attached to fix it.

## Failure-Mode Glossary

| Symptom                                              | Likely classification | Where to look                                |
|------------------------------------------------------|-----------------------|----------------------------------------------|
| Smoke fails because X calls a method Y doesn't have  | bug in X (or stale design.md) | X's code-gen, X's design.md            |
| Smoke fails because Y's response shape differs from its contract | bug in Y       | Y's code-gen, Y's contract.yaml/.py/.ts  |
| Smoke fails because the contract itself is wrong     | clarify CR            | contract.yaml/.py/.ts + Interface Contracts gate |
| Build & Test reveals a missing requirement           | creep CR              | vision.md + requirements.md                  |
| Integration test passes locally, fails in CI         | environment mismatch  | tech-env.md + IaC                            |

## Anti-Patterns

- **Mocking upstream units in smoke** — defeats the purpose. Use the actual generated code. If Y is too heavy to spin up, that is itself a finding (Y has poor testability — raise a CR).
- **Overriding the unit-under-test's OWN calling code** — subtler than mocking upstream, and worse because it looks like a real integration test. Using `dependency_overrides` (FastAPI), monkeypatch, or a DI swap to replace the *consumer's* real call path (e.g. todo-crud's `get_current_user`) with a parallel re-implementation defined inside the test fixture means smoke exercises the fixture's copy, not the generated code. **Litmus test: break the real consumer code once — if smoke still passes, the smoke is not testing it.** The fixture copy is also semantic duplication of the code it shadows. Correct approach: drive the unit's *real* dependency against the real upstream — point the consumer's service URL at an in-process ASGI transport, or inject the transport into the real dependency — never replace the dependency wholesale. Every smoke must be shown to fail when the contract it guards is broken.
- **Skipping smoke because "the contract is simple"** — simple contracts are exactly where assumed shape mismatches hide. Run it.
- **Treating Build & Test as a documentation stage** — the upstream rule's emphasis on producing markdown is incomplete. This override is what closes that gap.
- **Marking a phase approved with red tests "we'll fix them later"** — phase gate blocks, see `.kiro/steering/change-management.md`. "Later" becomes "never" when the next unit starts.
- **Letting smoke and integration overlap to the point that running smoke is redundant** — keep smoke fast (target: < 30s per unit pair). Push exhaustive matrix coverage into the integration tier.

## Related

- `.kiro/steering/interface-contracts.md` — the freeze gate that produces the contracts smoke targets.
- `.kiro/steering/change-management.md` — failures become CRs that flow through the phase-approval gate.
- `.kiro/aws-aidlc-rule-details/construction/code-generation.md` — upstream per-unit code-gen flow that Part 1 hooks into after step 7.
- `.kiro/aws-aidlc-rule-details/construction/build-and-test.md` — upstream Build & Test stage that Part 2 overrides.

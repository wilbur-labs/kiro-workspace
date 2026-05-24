# Technical Environment: {{TASK_NAME}}

> Fill in only the sections that apply to your stack. Delete sections that
> don't (e.g. no cloud → drop "Cloud and Deployment"). The point is to
> constrain choices that AI-DLC would otherwise have to guess. See
> `.kiro/templates/inputs/technical-environment-guide.md` for the long-form
> guide and `example-*-tech-env-*.md` for worked examples.

## Language and Package Manager

- **<language + version>**
- **<package manager>** (no <alternatives>)
- <config file convention>
- <lockfile policy>

## Frameworks and Libraries

> Pin the major frameworks. Don't enumerate every dep — just the ones whose
> choice constrains design (e.g. "FastAPI + Pydantic v2", not "we use httpx").

- <framework 1>
- <framework 2>

## Cloud and Deployment

> Drop this whole section if not cloud-deployed.

- **<cloud provider>**, region(s): <region>
- **<compute model>** (serverless / containers / VMs)
- **<data stores>**
- **<IaC tool>** — no manual console changes

## Testing

- **<test framework>** with coverage minimum <N>%
- **<type checker>** in <strict | normal> mode
- **<linter / formatter>**
- <mock / fixture strategy>

## Code Quality Tooling

> Declares the tools and thresholds the Build & Test quality gate runs (Layer B
> of `.kiro/steering/code-quality.md`). Keep the row for your language, delete
> the rest. Thresholds are the recommended starting point — gate **new code**
> strictly, hold legacy to "don't make it worse". Tighten after real data, not
> up front.

| Language | Tools | Gate (per function/method unless noted) |
| --- | --- | --- |
| TypeScript / JS | `eslint` + `typescript-eslint` + `eslint-plugin-sonarjs`; `jscpd` | complexity ≤ 10; cognitive ≤ 15; max-depth ≤ 4; max-params ≤ 5; new-code duplication ≤ 3% (`minLines 8`, `minTokens 80`) |
| Python | `ruff` (or `flake8`); `radon` + `xenon`; `jscpd` | `max-complexity 10`; `xenon --max-absolute B --max-modules A --max-average A`; duplication ≤ 3% |
| Java | `PMD` + `CPD`; `SpotBugs` or `SonarQube` | CPD `minimumTokens 100`, 0 new CPD violations; method cognitive ≤ 15 / CC ≤ 10; 0 new high/critical |

CI gate commands (keep the block for your stack):

```bash
# TS/JS
npx eslint .
npx jscpd --config .jscpd.json

# Python
ruff check .
xenon src --max-absolute B --max-modules A --max-average A
npx jscpd --pattern "**/*.py" --threshold 3 src

# Java
mvn verify   # PMD / CPD / SpotBugs if configured
```

> Cognitive complexity is preferred over cyclomatic where the tool offers both —
> it tracks how hard the code is to read, not just path count.

## Do NOT Use

> The strongest constraint you can give AI-DLC. Each row prevents a class of
> bad code-gen. Phrase as "X is banned, use Y instead, because Z".

| Prohibited | Reason | Use Instead |
| --- | --- | --- |
| <library/pattern> | <reason> | <alternative> |
| <library/pattern> | <reason> | <alternative> |

## Security Basics

- <auth mechanism>
- <secret storage>
- <transport security>
- <input validation rule>
- <logging / PII rule>

## Example Code Pattern

> Optional but very effective. One short worked example for each major file
> type (endpoint, business-logic module, test). AI-DLC will mimic the
> structure exactly. Leave empty if you want AI-DLC to pick the style.

```<language>
// <example endpoint / module / test structure>
```

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

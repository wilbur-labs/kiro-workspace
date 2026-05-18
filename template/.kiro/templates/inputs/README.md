# AI-DLC Input Document Templates

Before kicking off AI-DLC for a new project, prepare these two documents.
They dramatically reduce clarifying questions and improve every downstream artifact.

## What you need

1. **Vision Document** — what to build and why
2. **Technical Environment Document** — what tools and constraints apply

## Quick start

```bash
# Greenfield (new project)
cp .kiro/templates/inputs/example-minimal-vision-scientific-calculator-api.md \
   tasks/<task-name>/vision.md
cp .kiro/templates/inputs/example-minimal-tech-env-scientific-calculator-api.md \
   tasks/<task-name>/tech-env.md

# Brownfield (existing codebase)
cp .kiro/templates/inputs/example-minimal-vision-brownfield.md \
   tasks/<task-name>/vision.md
cp .kiro/templates/inputs/example-minimal-tech-env-brownfield.md \
   tasks/<task-name>/tech-env.md
```

Then edit both files with your project's specifics, and kick off AI-DLC:

```text
作成するドキュメントやチャットのやり取りはすべて日本語/中文でお願いします。
AI-DLC を使って、tasks/<task-name>/vision.md と tasks/<task-name>/tech-env.md を読んで開始してください。
```

## Files in this directory

| File | Purpose |
|------|---------|
| `inputs-quickstart.md` | One-page summary for greenfield + brownfield |
| `vision-document-guide.md` | Full Vision document guide with template |
| `technical-environment-guide.md` | Full Tech-Env guide with template |
| `example-minimal-vision-*` | Minimal examples to copy from |
| `example-minimal-tech-env-*` | Minimal examples to copy from |
| `example-vision-scientific-calculator-api.md` | Full greenfield example |
| `example-tech-env-scientific-calculator-api.md` | Full greenfield example |

## Key inputs (minimum viable)

### Vision

- One paragraph: what + for whom
- MVP feature list (in scope)
- Out-of-scope list (explicit)
- Open questions (known unknowns) — these feed straight into Requirements Analysis as pre-declared ambiguities

### Technical Environment

- Language + version, package manager, framework
- Cloud provider + deployment model
- Test framework
- **Prohibited libraries table** (with reason + recommended alternative)
- Security basics
- **At least one example each** for: typical endpoint, function, test

The example code patterns are the single highest-leverage addition. They give AI-DLC a concrete pattern to follow during code generation.

## For brownfield

- Vision needs current state description + explicit "must not change" list
- Tech-Env should describe the existing stack, with example code from real existing files

Source: <https://github.com/awslabs/aidlc-workflows/tree/main/docs/writing-inputs>

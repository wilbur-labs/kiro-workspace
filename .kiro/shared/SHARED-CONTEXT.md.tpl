# Shared Context

Workspace-level environment information loaded by every task agent at spawn (via each `agent.json`'s `resources` list — `file://.kiro/shared/SHARED-CONTEXT.md`).

Use this file for facts that are **stable across tasks and apply to every agent** in this workspace: organization conventions, team contacts, common tooling, network/auth quirks, paths to shared resources.

**Not for:**

- Task-specific state → `tasks/<name>/RESUME.md`
- Task-specific learnings → `tasks/<name>/learned.md`
- Cross-project reusable lessons → `.kiro/learned/LEARNED.md`
- Code-generation rules / AI-DLC overrides → `.kiro/steering/`

See `.kiro/skills/memory-layering.md` for the full decision tree.

---

## Organization

<!-- Org name, team, primary stakeholders. Example:
- Org: Sharp AI Engineering Center
- Team: eAssistant Platform
- Primary contacts: name <email>
-->

## Tooling

<!-- Workspace-wide tools every agent should know about. Example:
- LLM gateway: https://llm.internal/v1 (OpenAI-compatible, requires SSO token)
- Code review: gh CLI, repos under github.com/<org>/
- Internal package registry: pypi.internal/simple/
-->

## Network / Auth Quirks

<!-- Anything weird about the local environment that every agent will hit. Example:
- Corporate proxy on 10.x.x.x — set HTTPS_PROXY when fetching from public registries
- GitLab runner token expires monthly; renew via `gitlab-cli token refresh`
-->

## Shared Resources

<!-- Paths to artifacts shared across tasks. Example:
- Steering rules: .kiro/steering/
- AI-DLC upstream rules (do not edit): .kiro/aws-aidlc-rule-details/
- AI-DLC version: .kiro/VERSION
-->

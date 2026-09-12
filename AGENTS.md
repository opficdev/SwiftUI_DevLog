# DevLog Agent Instructions

## Scope

- These instructions apply only to the repository root.
- Read every route that matches the current task. Routes are cumulative.

## Required routing

| Task | Required document |
| --- | --- |
| Every task | `.agents/rules/general.md` |
| Module boundaries, file ownership, layer dependencies, DI, repository/service contracts, external SDK placement, Widget flow, `StorePattern`, or architecture documentation | `.agents/rules/architecture.md` |
| PR, review thread, commit, Xcode project, CI, verification, localization, release, or build tooling | `.agents/rules/project-workflows.md` |

## Routing rules

- `AGENTS.md` is the repository entrypoint and routing source.
- `.agents/rules/general.md` applies to every task.
- Read all matching task-specific documents before planning, editing, reviewing, or verifying.
- For architecture work, also read `README.md` before editing.
- The main agent owns investigation, editing, verification, and the final report.
- Do not require a `Design Brief`, Spec, `Task Packet`, or role-specific result before starting work.
- If repository-local instructions conflict with global memory, follow the repository-local instructions.
- Write DevLog PR and review text in Korean.

## Lightweight delegation

- Prefer the configured `gpt-5.3-codex-spark` agent for a bounded task that matches its description: `architecture_watcher`, `verification_runner`, `github_ci_analyst`, or `documentation_writer`.
- If Spark is unavailable, use only the matching `*_luna` agent with `gpt-5.6-luna` and `xhigh` reasoning.
- Dispatch the lightweight task directly from the user request or current diff. Do not create a role chain, `Design Brief`, Spec, or `Task Packet` for delegation.
- Keep planning, Swift implementation, final decisions, integration, git writes, and GitHub writes with the main agent.
- The main agent must check the delegated result before using it, but should not repeat the same investigation without a concrete reason.
- If both configured lightweight models are unavailable, continue with the main agent. Do not dispatch another fallback agent.

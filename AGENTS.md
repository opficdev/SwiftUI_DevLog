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
| Prior technical decisions whose reasoning could change the current decision | `../DevLog_Harness/AGENTS.md`, `../DevLog_Harness/profiles/devlog-ios/profile.md`, `../DevLog_Harness/profiles/decision-memory.md`, `../DevLog_Harness/skills/decision-search/SKILL.md` |
| A durable technical decision that the user asks to record in Notion | `../DevLog_Harness/AGENTS.md`, `../DevLog_Harness/profiles/devlog-ios/profile.md`, `../DevLog_Harness/profiles/decision-memory.md`, `../DevLog_Harness/skills/decision-write/SKILL.md` |

## Routing rules

- `AGENTS.md` is the repository entrypoint and routing source.
- `.agents/rules/general.md` applies to every task.
- Read all matching task-specific documents before planning, editing, reviewing, or verifying.
- For architecture work, also read `README.md` before editing.
- The main agent owns investigation, editing, verification, and the final report.
- Build-only verification is allowed. Do not run, launch, install, boot, or open the app or Simulator unless the user explicitly requests it in the current turn.
- Do not require a `Design Brief`, Spec, `Task Packet`, or role-specific result before starting work.
- If repository-local instructions conflict with global memory, follow the repository-local instructions.
- Write DevLog PR and review text in Korean.

## External Harness

- Treat a sibling `../DevLog_Harness` repository as the automatic Harness for this repository when every routed Harness file exists.
- Load Harness files only for a matching route. Do not read Decision Memory or its skills for unrelated work.
- Resolve the sibling path at runtime. Do not persist a user-specific absolute path in this repository.
- Read Notion scope and data-source settings from the Harness repository's local Git configuration. Do not copy those values or credentials into this repository.
- Keep this repository's rules authoritative for source changes, architecture, verification, git, and GitHub work.
- If the Harness or a routed file is unavailable, continue with this repository's rules unless the requested capability depends on it. Report the missing dependency instead of guessing or broadening the search.

## Lightweight delegation

- Prefer the configured `gpt-5.3-codex-spark` agent for a bounded task that matches its description: `architecture_watcher`, `verification_runner`, `github_ci_analyst`, or `documentation_writer`.
- If Spark is unavailable, use only the matching `*_luna` agent with `gpt-5.6-luna` and `xhigh` reasoning.
- Dispatch the lightweight task directly from the user request or current diff. Do not create a role chain, `Design Brief`, Spec, or `Task Packet` for delegation.
- Keep planning, Swift implementation, final decisions, integration, git writes, and GitHub writes with the main agent.
- The main agent must check the delegated result before using it, but should not repeat the same investigation without a concrete reason.
- If both configured lightweight models are unavailable, continue with the main agent. Do not dispatch another fallback agent.

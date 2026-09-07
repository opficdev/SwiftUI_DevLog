# DevLog Agent Roles

## Purpose

This file defines the runnable AI role workflow for DevLog work.

It is not background documentation. Use it to split work across AI models, create and approve Specs, pass task packets between roles, and decide which review or verification gates must run before completion.

Use `.agents/workflows.md` for task-specific runbooks that combine these roles into executable workflows.

`AGENTS.md` remains the canonical repository rule file. If this file conflicts with `AGENTS.md`, follow `AGENTS.md`.

## Operating rules

- Use one active writer for a file at a time.
- Do not dispatch multiple editing roles over overlapping files.
- Read-only roles must not edit files, stage changes, commit, push, resolve review threads, or change GitHub state unless their role explicitly allows that action and the user requested it.
- The main agent owns integration, final diff inspection, and the final user report.
- Build-only verification is allowed. Do not run, launch, install, boot, or open the app or Simulator unless the user explicitly requests it in the current turn.
- Keep generated Xcode workspace/project and `Package.resolved` churn out of source control unless an approved dependency-lock policy requires it.
- Keep AI workflow and rule documents under `.agents/`. Do not put them under `docs/`.
- For non-trivial design or implementation work, do not dispatch `Implementer`, `Code Reviewer`, or `Verification Runner` before the user approves a `Designer Result` and the Planner persists its Spec under `.agents/specs/`.
- If implementation changes a requirement or scope, update the Spec and obtain user approval again before continuing.

## Model assignment

Use these model tiers when assigning work to another LLM.

| Tier | Use | Default model |
| --- | --- | --- |
| `Primary` | Planning, implementation, architecture decisions, final integration, failed-check triage | Strongest available Codex/GPT coding model |
| `SDD Gate` | Design analysis and final diff review | `gpt-6-astra` with `medium` reasoning |
| `Lightweight` | Read-only review, checklist validation, log summarization, documentation draft, first-pass architecture preflight | `gpt-5.3-codex-spark`, unavailable 시 `gpt-5.6-luna`와 `high` 추론 |
| `Fast` | Low-risk text cleanup, simple file presence checks, short summaries | Pinned fast model from the configured custom agent TOML when a Fast role is defined |

Default role-to-model and execution assignment:

| Role | Execution owner or custom agent | Default tier | Escalate to `Primary` when |
| --- | --- | --- | --- |
| Planner | active main agent | `Primary` | Always for live issues, PR scope, architecture scope, or implementation planning |
| Designer | `designer` | `SDD Gate` | Any unresolved constraint, alternative, scope boundary, acceptance criterion, verification method, commit unit, or user approval |
| Implementer | active main agent | `Primary` | Always for Swift production code, tests, target dependencies, DI, SDK placement, or GitHub writes |
| Architecture Watcher | `architecture_watcher` | `Lightweight` for preflight, `Primary` for final boundary verdict | Any finding is `Block` or `Needs Owner Decision`, or the change touches module dependency, SDK placement, Widget flow, StorePattern, or DI |
| Code Reviewer | `code_reviewer` | `SDD Gate` | Any finding that blocks Spec acceptance criteria or requires user decision |
| Verification Runner | `verification_runner` | `Lightweight` | Verification fails, failure cause is unclear, or a fix is needed |
| GitHub/CI Analyst | `github_ci_analyst` | `Lightweight` | CI root cause requires code or workflow changes, or review comments conflict |
| Documentation Writer | `documentation_writer` | `Lightweight` | Text must explain complex architecture, release risk, CI root cause, or PR scope tradeoffs |

Project-scoped custom agents live in `.codex/agents/`. Their TOML files pin the concrete model and sandbox for spawned sessions; this table is the canonical role-to-agent routing map. `Designer` and `Code Reviewer` are Astra-only SDD gates; the other custom roles retain the existing Spark-first routing.

Do not assign `Lightweight` as the only model for production Swift implementation, target dependency changes, DI assembly, repository/service contract changes, Firebase or SDK placement, Widget data-flow changes, StorePattern responsibility changes, commits, pushes, PR creation, or final integration.

### Model dispatch requirements

- A model tier assignment is an execution requirement, not a label for work the main agent already performed.
- `Primary` roles belong to the active main agent and must not be delegated to a sub-agent that uses or inherits the active `Primary` model.
- Every sub-agent created through this role workflow must use the configured `SDD Gate`, `Lightweight`, or `Fast` model that is different from the active `Primary` model. The exact `designer` and `code_reviewer` custom agent dispatches are the only exception when the active `Primary` also uses their required Astra model.
- When a role is assigned to `SDD Gate`, `Lightweight`, or `Fast`, the main agent must dispatch the configured custom agent from the routing table before using its result.
- A sub-agent that inherits the active `Primary` model does not satisfy an `SDD Gate`, `Lightweight`, or `Fast` assignment. The Astra exception applies only to the exact `designer` and `code_reviewer` custom agent dispatches; it does not permit an inherited or generic sub-agent.
- Do not satisfy an `SDD Gate`, `Lightweight`, or `Fast` role by completing the role directly in `Primary` and describing it as delegated work.
- A generic sub-agent spawn that does not load the configured custom agent TOML does not satisfy an `SDD Gate`, `Lightweight`, or `Fast` role execution.
- If the custom agent cannot be loaded or the dispatch surface cannot select that custom agent, stop before dispatch and report which role cannot run.
- `Designer` and `Code Reviewer` must use only `gpt-6-astra` with `medium` reasoning. If the connected side-task surface cannot select Astra after an exact `task_name` retry, stop the SDD gate; do not use a fallback.
- A configured `gpt-5.3-codex-spark` model is unavailable only when the connected side-task surface cannot select it after an exact `task_name` retry. In that case, dispatch the matching `*_luna` custom role with `gpt-5.6-luna` and `high` reasoning effort. Do not select another fallback model.
- If the assigned model is available but current tool policy requires explicit user permission before dispatch, missing permission is not fallback. Stop and ask for permission before continuing the required role.
- `Primary` must integrate and verify delegated output, but must not skip the delegated role when the workflow requires it and the assigned model is available.

### Connected side-task dispatch

- Run every `SDD Gate`, `Lightweight`, or `Fast` role as a side task connected to the current main task.
- Use `spawn_agent` from tools or `Option-Command-S` from the UI sidebar. Treat both as the same connected dispatch surface.
- Set `spawn_agent.task_name` to the exact `.codex/agents/<name>.toml` filename without the extension and the exact TOML `name` value.
- Do not add arbitrary prefixes or suffixes to `task_name`. Names such as `issue_documentation_writer` and `documentation_writer_issue` do not select the configured custom agent.
- Return each role result to the current main task so `Primary` can review and integrate it.
- Send later work for the same role to the existing agent with `followup_task` instead of creating another agent name.
- Do not use external `codex exec` or a separate user-owned `create_thread` as a repository role dispatch surface.
- Do not count a generic sub-agent that does not select the configured custom agent as an `SDD Gate`, `Lightweight`, or `Fast` role execution.
- Do not treat a failure from external `codex exec`, `create_thread`, or an arbitrary `task_name` as proof that the configured custom agent or pinned model is unavailable.

Use these exact role identifiers:

| Role | Exact `task_name` | Configuration |
| --- | --- | --- |
| Designer | `designer` | `.codex/agents/designer.toml` |
| Architecture Watcher | `architecture_watcher` | `.codex/agents/architecture_watcher.toml` |
| Code Reviewer | `code_reviewer` | `.codex/agents/code_reviewer.toml` |
| Verification Runner | `verification_runner` | `.codex/agents/verification_runner.toml` |
| GitHub/CI Analyst | `github_ci_analyst` | `.codex/agents/github_ci_analyst.toml` |
| Documentation Writer | `documentation_writer` | `.codex/agents/documentation_writer.toml` |

Spark fallback custom agents use the same role suffix with `_luna`: `architecture_watcher_luna`, `verification_runner_luna`, `github_ci_analyst_luna`, and `documentation_writer_luna`. `Designer` and `Code Reviewer` have no Luna fallback.

### Fallback policy

- The configured custom agent TOML is the source of truth for the non-Primary role model and sandbox.
- The configured custom agent TOML keeps `gpt-5.3-codex-spark` as the default model for existing Lightweight roles. If Spark is unavailable, use only the matching `*_luna` custom agent with `gpt-5.6-luna` and `high` reasoning effort, preserving the same sandbox and developer instructions.
- If `gpt-5.6-luna` with `high` reasoning effort is also unavailable, do not fall back to another model; stop and report the unavailable role.
- If `Primary` is unavailable, do not perform implementation, architecture verdict, final integration, git write actions, or GitHub write actions.
- Do not downgrade `Primary` roles to `Lightweight` or `Fast` only because a cheaper model is available.
- For user-facing summaries, a lower tier may draft text, but `Primary` must check it when the text depends on architecture decisions, release risk, CI root cause, or exact diff behavior.

### Escalation rule

Escalate to `Primary` before editing or reporting completion when a non-Primary role returns any of these:

- `Block`
- `Needs Owner Decision`
- `Fail`
- unclear root cause
- architecture boundary uncertainty
- runtime behavior uncertainty
- conflicting review comments
- missing verification that affects confidence

Escalation does not mean the `Primary` model should automatically edit. It must first re-check the task packet, the blocking output, and `AGENTS.md`.

## Workflow

Use this sequence for non-trivial AI-assisted work.

1. Planner creates a `Design Brief`.
2. Designer returns a `Designer Result`; the user approves it.
3. Planner persists the approved Spec and creates a `Task Packet` from it.
4. Implementer edits only the assigned scope.
5. Architecture Watcher reviews architecture-sensitive diffs when required.
6. Code Reviewer reviews the final diff against the approved Spec for bugs, regressions, and missing acceptance criteria.
7. Verification Runner records acceptance-criterion evidence and runs allowed checks.
8. Documentation Writer prepares issue, PR, release, or user-facing text when needed.
9. GitHub/CI Analyst inspects live GitHub state when PR comments, issue state, or CI logs matter.

Read-only roles can run in parallel when they do not depend on the same unfinished output. Editing roles should run sequentially unless their assigned files and ownership boundaries are disjoint.

For full issue, implementation, review, CI, and docs-only runbooks, use `.agents/workflows.md`.

## Task packet

Planner must produce this packet before handing work to another role.

```md
## Task Packet

- Source:
- Approved Spec:
- Goal:
- Scope:
- Out of scope:
- Acceptance criteria:
- Expected changed files:
- Current owner:
- Architecture risk: none / possible / confirmed
- Required roles:
- Model assignment:
- Execution authority: app or Simulator / external writes / CI or PR actions
- Verification:
- Stop conditions:
```

Use `Architecture risk: possible` when the task touches module boundaries, imports, target dependencies, DI, repository or service contracts, Widget flow, `ThirdParty` package linkage, StorePattern boundaries, or architecture documentation. The `Approved Spec` field must be a `.agents/specs/` path for non-trivial work, and `Acceptance criteria` must reproduce only the approved Spec criteria needed for execution and verification.

## Role activation

Use this template when assigning an `SDD Gate`, `Lightweight`, or `Fast` role through its configured custom agent. `Primary` roles do not use this activation template because the active main agent owns them.

Create the connected side task with `spawn_agent.task_name` set to the exact identifier in the routing table. When using the UI sidebar, create the same connected side task with `Option-Command-S`. After the first dispatch, use `followup_task` for later work assigned to the same role.

```md
You are the `<Role Name>` for the DevLog iOS repository.

Read `AGENTS.md` first. Then read `.agents/roles.md` and follow the `<Role Name>` section.

Assigned model tier: `<SDD Gate | Lightweight | Fast>`
Custom agent: `<configured custom agent name>`

Task packet:
<paste Task Packet here>

Rules:
- Stay inside the role permissions.
- Do not edit files if this is a read-only role.
- Do not run, launch, install, boot, or open the app or Simulator.
- Perform this role in the assigned model context. Do not return work copied from a different model context as this role's own result.
- Stop and report if the task packet conflicts with `AGENTS.md`.
- Return only the output format defined for `<Role Name>`.
```

The receiving model must start by identifying its active role and must end with that role's output format. If it cannot complete the role because required context or permission is missing, it must return the same output format with the blocker in the findings or failure field.

## Routing table

| Task type | Required roles | Notes |
| --- | --- | --- |
| Issue planning | Planner, Designer | Add GitHub/CI Analyst when live issue or PR state is the source of truth. |
| Swift implementation | Planner, Designer, Implementer, Code Reviewer, Verification Runner | Add Architecture Watcher when boundary or dependency risk exists. |
| Module, DI, SDK, Widget, StorePattern, or architecture docs | Planner, Designer, Architecture Watcher, Implementer, Code Reviewer, Verification Runner | Architecture Watcher must read `AGENTS.md`, `README.md`, and `.agents/rules/architecture.md`. |
| Review feedback | GitHub/CI Analyst, Planner, Designer, Implementer, Code Reviewer, Verification Runner | Use thread-aware review inspection when unresolved review threads matter. |
| CI failure | GitHub/CI Analyst, Planner, Designer, Verification Runner | Add Implementer only after a user-approved Spec identifies a concrete root cause. |
| PR or release text | Documentation Writer | Add Code Reviewer when text must match actual diff. |
| Docs-only AI workflow change | Planner, Designer, Implementer, Code Reviewer, Verification Runner | No iOS build required unless Swift/iOS project code changes. |

## Planner

Planner converts the user request, issue, or PR state into a `Design Brief`. After user approval of the `Designer Result` and Spec persistence, Planner converts only that Spec into a scoped `Task Packet`.

May:

- Inspect repository files, current diffs, issue bodies, PR bodies, and recent commits.
- Identify likely owning layer, target, and files.
- Decide which roles are required.
- Ask the user when scope, ownership, or architecture decisions are ambiguous.
- Persist an approved Spec under `.agents/specs/` before fixing the `Task Packet` for non-trivial work.

Must not:

- Edit implementation files.
- Confirm a `Task Packet` before an approved Spec exists for non-trivial work.
- Relax architecture rules to make a task easier.
- Treat stale memory or previous issue text as newer than live repository or GitHub state.

Output:

```md
## Planner Result

- Goal:
- Scope:
- Out of scope:
- Required roles:
- Design Brief:
- Approved Spec:
- Handoff packet:
- User decision needed:
```

## Designer

Designer is the `gpt-6-astra` and `medium` SDD gate for non-trivial work.

May:

- Analyze a `Design Brief`, the current repository state, and live issue or PR context provided by the Planner.
- Identify constraints, alternatives, changed boundaries, acceptance criteria, verification methods, and independently reviewable minimum commit units.
- Return a `Designer Result` that the user can approve as the basis for a Spec.

Must not:

- Edit files, stage changes, commit, push, or change GitHub state.
- Approve its own result on behalf of the user.
- Select a fallback model when Astra is unavailable.

Output:

```md
## Designer Result

- Design Brief:
- Constraints:
- Alternatives:
- Changed boundaries:
- Acceptance criteria:
- Verification:
- Minimum commit units:
- Spec path:
- User approval needed:
```

## Implementer

Implementer applies the scoped code or document change.

May:

- Edit files in the task packet.
- Use the approved Spec and its acceptance criteria as the implementation boundary.
- Add narrowly scoped helper types or tests when required by the task.
- Run local read-only inspection commands and targeted formatting commands.

Must not:

- Expand scope beyond the task packet.
- Continue after a requirement or scope change without updating the Spec and obtaining user approval.
- Change app logic unless the new approach preserves results and strictly improves time or space complexity, or the user explicitly requested the logic change.
- Add or loosen module dependencies without an Architecture Watcher pass.
- Run, launch, install, boot, or open the app or Simulator.
- Commit, push, or create PRs unless the user explicitly requested that git action.

Output:

```md
## Implementer Result

- Changed files:
- Scope notes:
- Architecture-sensitive changes:
- Verification suggested:
```

## Architecture Watcher

Architecture Watcher is a read-only gate for DevLog boundaries.

Use it when a task touches module boundaries, file ownership, layer dependencies, DI assembly, repository or service contracts, widget data flow, `ThirdParty` package linkage, StorePattern responsibilities, or architecture documentation.

Must read before reviewing:

- `AGENTS.md`
- `README.md`
- `.agents/rules/architecture.md`
- `.agents/rules/project-workflows.md` when PR, commit, Xcode project, CI, widget, Store, localization, release, or build tooling is involved

Must inspect:

- Source imports in changed Swift files.
- Relevant `Project.swift`, `Workspace.swift`, or target dependency changes.
- Layer ownership before and after the change.
- `ThirdParty` package product linkage and whether it remains free of DevLog application behavior.
- Same-layer dependency injection.
- Widget, WidgetCore, and WidgetExtension boundaries when widget flow is touched.
- Presentation `StorePattern` responsibility boundaries when Presentation feature logic is touched.

Must not:

- Edit files.
- Approve ambiguous ownership by assumption.
- Treat a manifest-only target dependency as permission for a source-level DevLog architecture dependency. A direct `ThirdParty` dependency permits only imports of its external package products.
- Hide architecture decisions inside build-fix wording.

Output:

```md
## Architecture Watch Result

- Verdict: Pass / Block / Needs Owner Decision
- Changed layer:
- Owning target:
- Dependency direction:
- Target dependency impact:
- ThirdParty linkage:
- Same-layer DI:
- Widget boundary:
- StorePattern:
- Findings:
- Required user decision:
```

## Code Reviewer

Code Reviewer is the `gpt-6-astra` and `medium` read-only final-diff SDD gate.

May:

- Inspect `git diff`, changed files, and related tests.
- Prioritize bugs, regressions, architecture drift, readability problems, and missing tests.
- Verify whether the change matches the approved Spec, its acceptance criteria, and the task packet.

Must not:

- Edit files.
- Rewrite style-only preferences as required fixes.
- Request unrelated cleanup outside the current scope.

Output findings first:

```md
## Code Review Result

- Verdict: Pass / Block / Needs Follow-up
- Findings:
- Spec path and acceptance criteria:
- Missing tests or verification:
- Scope drift:
```

Use file and line references for findings when possible.

## Verification Runner

Verification Runner runs allowed checks and records evidence.

May:

- Run `swiftlint` on changed Swift files with the applicable config.
- Run unit tests when they do not launch the app.
- Run `xcodebuild build` or equivalent build-only checks.
- Run docs-only checks such as file existence, `git diff --check`, and Markdown structure inspection.
- Record evidence for every Spec acceptance criterion.

Must not:

- Run, launch, install, boot, or open the app or Simulator.
- Use build-and-run commands as verification.
- Treat skipped checks as passed.
- Modify source files except through explicitly assigned formatting commands.

Output:

```md
## Verification Result

- Status: Pass / Fail / Not Run
- Commands:
- Spec path and acceptance criteria evidence:
- Evidence:
- Not run:
- Failure notes:
```

## GitHub/CI Analyst

GitHub/CI Analyst inspects live GitHub state.

May:

- Read issues, PRs, review comments, labels, and workflow runs.
- Inspect CI logs with `gh` when GitHub Actions details matter.
- Summarize actionable comments and separate required fixes from optional suggestions.
- Create or update issues and comments only when the user explicitly requested that GitHub write action.

Must not:

- Edit local files.
- Resolve review threads, push commits, or create PRs unless the user explicitly requested that action.
- Infer current issue scope from stale local notes when live issue text is available.

Output:

```md
## GitHub CI Result

- Source:
- Current state:
- Actionable items:
- Non-actionable items:
- Links:
- Next role:
```

## Documentation Writer

Documentation Writer prepares user-facing or project-facing text.

May:

- Draft issue bodies, PR bodies, release notes, README changes, and review replies.
- Edit documentation files when assigned by the task packet.
- Align wording with actual diff and repository templates.

Must not:

- Edit app code.
- Put AI workflow documents under `docs/`.
- Overstate implementation details that are not present in the diff.
- Create PRs, comments, or releases unless the user explicitly requested that GitHub write action.

Output:

```md
## Documentation Result

- Target:
- Draft or changed file:
- Source diff used:
- Remaining decision:
```

## Completion gates

Before reporting completion:

- Confirm the diff only touches the assigned scope.
- Confirm the approved Spec path and every acceptance criterion are referenced by the task packet, code review, and verification result.
- Confirm all required roles have produced results or state why a role was skipped.
- Confirm Swift changes received the required lint, test, or build-only verification.
- Confirm docs-only changes were checked without claiming app build verification.
- Report unresolved user decisions instead of silently choosing architecture policy.

## Example workflows

### Docs-only AI workflow change

1. Planner creates a `Design Brief` from the issue.
2. Designer returns a `Designer Result`; the user approves it.
3. Planner persists the approved Spec and creates a task packet from it.
4. Implementer edits the assigned workflow files.
5. Code Reviewer checks the Spec, task packet, and final diff.
6. Verification Runner records evidence for every acceptance criterion.
7. Main agent reports changed files, architecture boundary decision, and verification result.

### Swift bug fix

1. Planner creates a `Design Brief` from the issue.
2. Designer returns a `Designer Result`; the user approves it.
3. Planner persists the approved Spec and creates a `Task Packet` from it.
4. Architecture Watcher runs if imports, dependencies, DI, Widget, SDK placement, or StorePattern ownership might change.
5. Implementer applies the focused fix.
6. Code Reviewer reviews the Spec, task packet, and final diff.
7. Verification Runner records acceptance-criterion evidence and runs changed-file SwiftLint and build-only or test checks.

### Review-thread follow-up

1. GitHub/CI Analyst reads unresolved review threads.
2. Planner creates a `Design Brief` that separates required changes from optional suggestions.
3. Designer returns a `Designer Result`; the user approves it.
4. Planner persists the approved Spec and creates a `Task Packet` from it.
5. Implementer applies only accepted fixes.
6. Architecture Watcher runs when the fix touches architecture-sensitive areas.
7. Code Reviewer checks the Spec, task packet, and final diff.
8. Verification Runner records acceptance-criterion evidence and runs allowed checks.
9. GitHub/CI Analyst replies or resolves threads only if the user requested that GitHub action.

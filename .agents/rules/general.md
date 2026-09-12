# DevLog General Agent Rules

## Logic preservation and optimization

- Reuse the existing program logic as-is whenever possible.
- Change logic only when the new approach produces exactly the same result and strictly improves time or space complexity.
- If there is no clear complexity improvement, keep the original logic.

## Code modification response style

- When asked to modify code, return only the precise changed locations and the modified code for those locations.
- Do not include full files, unrelated code, or explanatory text unless explicitly requested.
- You do not need to paste code in the prompt after updating it in the repository.

## Naming and Swift style

- In Swift, do not write explicit type annotations unless required.
- Use `opfic` in new Swift file headers.
- Prefer `<` and `<=` over `>` and `>=` when writing comparisons, if the condition can be expressed clearly that way.

## Documentation placement

- Keep AI working rules under `.agents/rules/`.
- Treat existing files under `.agents/specs/` as historical records, not required inputs for new work.
- Keep `docs/` for README images and draw.io sources.
- Do not add AI working rules under `docs/`.

## Repository-local rules

- DevLog-specific working rules belong in this repository, not in global agent memory.
- Treat `AGENTS.md` and the routed `.agents/` documents as the canonical DevLog AI working rules.
- If global memory conflicts with this repository, follow the repository.

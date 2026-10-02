# AGENTS.md

Working conventions for an AI coding agent. This file encodes the preferences
shown by the maintainer during development. Follow these first; ask only when a
task is ambiguous.

## General principles

- **Read the files, don't assume.** Report the literal contents of what you
  inspect instead of describing a project speculatively. Before concluding
  anything, confirm it against the source.
- **Start small.** Prefer a minimal, incremental change over a big refactor. One
  clear concern per change.
- **Respect scope.** Do not commit, push, or run destructive commands unless the
  task explicitly asks. If a change is made, keep it isolated and reversible (the
  repo is under git — a hard reset undoes uncommitted edits).
- **Give a rationale.** When proposing a fix, say why before implementing, and
  note the tradeoffs / edge cases.
- **Show the commit message before committing.** Present the message for
  approval, then commit.
- **Be concise in summaries.** State the change and its effect; don't pad.

## Tooling / quality gates

- Run the project's syntax / lint checks before finishing and confirm they pass.
- Quality linters/formatters run on commit via pre-commit hooks (if any); let
  them normalize files rather than hand-formatting.
- Prefer a throwaway scratch directory for tests so the real files / state are
  never touched.

## Commit style

Conventional-commits. Keep the subject a single line and put a short bulleted
rationale in the body. Example:

```
feat: add behavior X
- rationale point 1
- rationale point 2
```

---
name: update-docs
description: Update project documentation to reflect recent code changes
argument-hint: "[N commits or base-branch]"
---

## Task

1. Read the project's `CLAUDE.md` to understand the project layout, conventions, and where documentation lives
2. Get the recent changes by running: `~/.claude/skills/update-docs/get-branch-diff.sh $ARGUMENTS`
   - No argument on a feature branch: diffs against the default branch (all branch commits)
   - No argument on main/master: shows the last commit
   - A number (e.g. `5`): shows the last N commits
   - A branch name (e.g. `develop`): diffs against that branch
3. Analyze the diff output
4. Identify which documentation files (READMEs, guides, API docs, changelogs, etc.) are affected by these changes
5. For each affected doc:
   - Check if it already reflects the changes (skip if up to date)
   - Update it to accurately reflect the new behavior, APIs, or configuration
6. Do NOT create new documentation files unless the changes introduce something entirely new that has no existing doc home
7. Do NOT touch docs unrelated to the changes
8. Summarize what you updated and why

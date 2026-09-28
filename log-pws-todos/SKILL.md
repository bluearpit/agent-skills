---
name: log-pws-todos
description: Logs follow-up todos discussed during coding into Obsidian for Personal Workspace projects. Use when the user asks to capture pending work, action items, or "do later" tasks while working in a project under ~/Documents/personal/workspace/.
---

# Log PWS Todos

## Purpose

Capture todos that come up during implementation and append them to an Obsidian note for the current project.

## Required path guard

Only run this workflow when the active project/workspace path starts with:

`~/Documents/personal/workspace/`

If the active project is outside this root:

1. Stop immediately.
2. Tell the user this skill only supports projects under that workspace root.
3. Ask whether they want to proceed manually.

Also verify the resolved active workspace/project directory actually exists on disk before continuing. If it does not exist, stop and report the missing path.

## Destination mapping

Map project-relative paths from the workspace root into:

`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/pws/`

Rule:

- Source project path: `~/Documents/personal/workspace/<relative-path>`
- Obsidian project path: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/pws/<relative-path>`

Create the destination directory if it does not exist.

## Todo file and format

Write todos to:

`<obsidian-project-path>/TODO.md`

If the file does not exist, create it with this header:

```markdown
# TODO
```

Append each new todo as a markdown checkbox with timestamp and context:

```markdown
- [ ] YYYY-MM-DD HH:MM - <todo text> (source: <project-relative-path or "chat">)
```

Use local machine time from the current session.

## Capture workflow

1. Resolve the active workspace path.
2. Validate it is inside `~/Documents/personal/workspace/`.
3. Check that this source workspace/project directory exists.
4. If the source directory does not exist, stop and report the missing path to the user.
5. Compute `<relative-path>` and destination under Obsidian `pws`.
6. Ensure destination directory exists.
7. Ensure `TODO.md` exists with `# TODO` header.
8. Append the todo item(s) in checkbox format.
9. Confirm back to the user with:
   - destination file path
   - number of todos added
   - exact appended lines

## Input handling

- If the user gives multiple tasks, append one checkbox line per task.
- Keep user wording intact unless they ask for rewriting.
- Do not deduplicate unless the user explicitly asks.

## Example

Input todo:

`add retry handling for rerank API failures`

Appended line:

`- [ ] 2026-05-16 22:53 - add retry handling for rerank API failures (source: embedder)`

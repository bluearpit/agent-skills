# Claude Code Skills

Custom [skills](https://docs.anthropic.com/en/docs/claude-code/skills) (slash commands) for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Skills

### `/update-docs`

Automatically updates project documentation to reflect recent code changes. Reads the project's `CLAUDE.md` to understand the project structure, then analyzes the git diff and updates any relevant docs.

**Usage:**

| Command | Behavior |
|---------|----------|
| `/update-docs` (on a feature branch) | Diffs all commits against the default branch |
| `/update-docs` (on main) | Shows the last commit |
| `/update-docs 5` | Shows the last 5 commits |
| `/update-docs develop` | Diffs against the `develop` branch |

## Installation

1. Clone this repo:

   ```bash
   git clone https://github.com/bluearpit/claude-code-skills.git
   ```

2. Symlink the skills you want into your Claude Code skills directory:

   ```bash
   # Create the skills directory if it doesn't exist
   mkdir -p ~/.claude/skills

   # Symlink a specific skill
   ln -s /path/to/claude-code-skills/update-docs ~/.claude/skills/update-docs
   ```

3. Make sure helper scripts are executable:

   ```bash
   chmod +x ~/.claude/skills/update-docs/get-branch-diff.sh
   ```

4. The skill is now available as `/update-docs` in any Claude Code session.

## Contributing

Feel free to open a PR to add your own skills. Each skill should be a directory with a `SKILL.md` file and any supporting scripts or templates.

## License

MIT

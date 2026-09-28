# Agent Skills

[Skills](https://docs.anthropic.com/en/docs/claude-code/skills) for AI coding agents: Claude Code, Cursor, Codex, OpenCode and pi. Each skill is a directory with a `SKILL.md` and any supporting files.

## Skills

| Skill | What it does |
|---|---|
| `pr-review` | Reviews a pull request for correctness, design, operational risk and test coverage. Runs the two skills below as part of the review. |
| `architecture-review` | Reviews structure: module boundaries, coupling, data ownership, failure handling, APIs, operability. |
| `software-design-principles` | DRY, single source of truth and separation of concerns for shared constants, config and product packaging. |
| `performance-tuning` | Measurement-first performance work on a single program or library. |
| `headless-agent-delegation` | Runs Claude Code or Cursor headless to use an integration (for example an MCP server) the current agent lacks, with a least-privilege tool allowlist. |
| `update-docs` | Updates project docs to match recent code changes (`/update-docs`, `/update-docs 5`, `/update-docs develop`). |
| `web-scraper` | Scrapes structured data from websites with Playwright, including JavaScript-rendered pages. |
| `log-pws-todos` | Logs follow-up todos from a coding session into Obsidian, for projects under `~/Documents/personal/workspace/`. |

Third-party skills I also use, installed from upstream rather than copied here:

- `dev-browser`: [sawyerhood/dev-browser](https://github.com/sawyerhood/dev-browser)
- `dagster-expert`, `dignified-python`: [dagster-io/skills](https://github.com/dagster-io/skills)
- `find-skills`: [vercel-labs/skills](https://github.com/vercel-labs/skills)
- `search-project-history`: ships with [agentrecall](https://github.com/bluearpit/agentrecall)

## Installation

```bash
git clone https://github.com/bluearpit/agent-skills.git
cd agent-skills
./install.sh              # symlinks every skill into ~/.agents/skills
agentrecall skills --apply  # links ~/.agents/skills into Claude Code
```

`~/.agents/skills` is the one place skills live. Cursor, Codex, OpenCode and pi read it directly. Claude Code needs the links that `agentrecall skills --apply` creates (or symlink each skill into `~/.claude/skills` yourself).

Because the installed skills are symlinks into this repo, `git pull` updates every agent at once. To add a skill, create its directory here and run `./install.sh` again.

## License

MIT

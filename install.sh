#!/bin/bash
# Symlinks every skill (a directory with SKILL.md) into ~/.agents/skills/.
# Cursor, Codex, OpenCode and pi read that folder directly; for Claude Code,
# run `agentrecall skills --apply` afterwards to link it into ~/.claude/skills.

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.agents/skills"

mkdir -p "$SKILLS_DIR"

for dir in "$REPO_DIR"/*/; do
    dir="${dir%/}"
    skill_name="$(basename "$dir")"
    [ -f "$dir/SKILL.md" ] || continue
    target="$SKILLS_DIR/$skill_name"
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$dir" ]; then
        echo "  skip  $skill_name (already linked)"
    elif [ -L "$target" ]; then
        ln -sfn "$dir" "$target"
        echo "  relink $skill_name -> $dir"
    elif [ -e "$target" ]; then
        echo "  WARN  $skill_name exists and is not a symlink, skipping"
    else
        ln -s "$dir" "$target"
        echo "  link  $skill_name -> $dir"
    fi
done

echo "Done."

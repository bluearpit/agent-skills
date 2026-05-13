#!/bin/bash
# Symlinks all skills (directories with SKILL.md) into ~/.claude/skills/
# Run after adding a new skill to the repo.

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$SKILLS_DIR"

for dir in "$REPO_DIR"/*/; do
    skill_name="$(basename "$dir")"
    if [ -f "$dir/SKILL.md" ]; then
        target="$SKILLS_DIR/$skill_name"
        if [ -L "$target" ]; then
            echo "  skip  $skill_name (already linked)"
        elif [ -e "$target" ]; then
            echo "  WARN  $skill_name exists but is not a symlink, skipping"
        else
            ln -s "$dir" "$target"
            echo "  link  $skill_name -> $dir"
        fi
    fi
done

echo "Done."

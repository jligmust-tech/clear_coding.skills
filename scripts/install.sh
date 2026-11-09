#!/usr/bin/env sh
# Link the three skills into the directories used by common coding agents.
#
#   ./scripts/install.sh                  # all agents, global
#   ./scripts/install.sh claude global    # one agent, global
#   ./scripts/install.sh codex project    # one agent, current project
#
# Run from the project where you want project-scoped links to appear.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

AGENT=${1:-all}
SCOPE=${2:-global}

case "$SCOPE" in
  global|project) ;;
  *) echo "usage: $0 [all|claude|codex|cursor|gemini|opencode|copilot] [global|project]" >&2; exit 2 ;;
esac

target_dir() {
  agent=$1
  case "$agent:$SCOPE" in
    claude:global)   echo "$HOME/.claude/skills" ;;
    claude:project)  echo ".claude/skills" ;;
    codex:global)    echo "$HOME/.agents/skills" ;;
    codex:project)   echo ".agents/skills" ;;
    cursor:global)   echo "$HOME/.cursor/skills" ;;
    cursor:project)  echo ".cursor/skills" ;;
    gemini:global)   echo "$HOME/.gemini/skills" ;;
    gemini:project)  echo ".gemini/skills" ;;
    opencode:global) echo "$HOME/.config/opencode/skills" ;;
    opencode:project) echo ".opencode/skills" ;;
    copilot:global)  echo "$HOME/.copilot/skills" ;;
    copilot:project) echo "" ;;
    *) echo "" ;;
  esac
}

if [ "$AGENT" = "all" ]; then
  AGENTS="claude codex cursor gemini opencode copilot"
else
  AGENTS=$AGENT
fi

for agent in $AGENTS; do
  dir=$(target_dir "$agent")
  if [ -z "$dir" ]; then
    echo "skip $agent ($SCOPE): no documented project path"
    continue
  fi
  mkdir -p "$dir"
  for skill in explore-r debug-r write-r; do
    ln -sfn "$ROOT/skills/$skill" "$dir/$skill"
    echo "linked $agent: $dir/$skill"
  done
done

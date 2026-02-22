#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/feat.sh <feature-spec-file>

This script enriches a feature spec by running the PM agent first,
then the Architect agent, then the Designer agent, updating the same file in place.
It ensures a "Tasks" section exists and is filled with implementable tasks for future agents.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

CODEX_BIN="${CODEX_BIN:-codex}"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SPEC_INPUT="$1"

if [[ "$SPEC_INPUT" = /* ]]; then
  SPEC_PATH="$SPEC_INPUT"
else
  SPEC_PATH="$ROOT_DIR/$SPEC_INPUT"
fi

if [ ! -f "$SPEC_PATH" ]; then
  echo "Feature spec file not found: $SPEC_PATH" >&2
  exit 1
fi

case "$SPEC_PATH" in
  "$ROOT_DIR"/*) ;;
  *)
    echo "Feature spec file must be inside the repo: $SPEC_PATH" >&2
    exit 1
    ;;
esac

AGENT_PM="$ROOT_DIR/agents/pm.md"
AGENT_ARCH="$ROOT_DIR/agents/architect.md"
AGENT_DESIGNER="$ROOT_DIR/agents/designer.md"

if [ ! -f "$AGENT_PM" ]; then
  echo "PM agent file not found: $AGENT_PM" >&2
  exit 1
fi

if [ ! -f "$AGENT_ARCH" ]; then
  echo "Architect agent file not found: $AGENT_ARCH" >&2
  exit 1
fi

if [ ! -f "$AGENT_DESIGNER" ]; then
  echo "Designer agent file not found: $AGENT_DESIGNER" >&2
  exit 1
fi


SPEC_REL="${SPEC_PATH#$ROOT_DIR/}"

run_codex() {
  local agent_name="$1"
  local agent_file="$2"

  "$CODEX_BIN" exec --full-auto --cd "$ROOT_DIR" - <<EOF
You are the ${agent_name} for this task. Follow these agent instructions exactly:

$(cat "$agent_file")

Task:
- Open and update the feature spec at: $SPEC_REL
- The file currently has only a bare minimum description.
- Expand and improve the content based on your agent responsibilities.
- Ensure a "## Tasks" section exists and contains a checklist of implementable tasks.
- Keep the spec in markdown, and edit only this file.
- Do not create or modify any other files. Do not run tests.

If needed, preserve existing headings and extend them instead of replacing them.
EOF
}

run_codex "PM Agent" "$AGENT_PM"
run_codex "Architect Agent" "$AGENT_ARCH"
run_codex "Designer Agent" "$AGENT_DESIGNER"

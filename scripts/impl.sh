#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/impl.sh <feature-spec-file> [section-name]

Implements tasks listed under "Tasks" in the feature spec using the Coder agent,
then runs the Inspector agent to review and improve unit/BDD tests if needed.
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
SECTION_NAME="${2:-Tasks}"

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

AGENT_CODER="$ROOT_DIR/agents/coder.md"
AGENT_INSPECTOR="$ROOT_DIR/agents/inspector.md"

if [ ! -f "$AGENT_CODER" ]; then
  echo "Coder agent file not found: $AGENT_CODER" >&2
  exit 1
fi

if [ ! -f "$AGENT_INSPECTOR" ]; then
  echo "Inspector agent file not found: $AGENT_INSPECTOR" >&2
  exit 1
fi

SECTION_RE="$(printf '%s' "$SECTION_NAME" | sed -e 's/[][\\.^$*+?(){}|]/\\&/g')"
if ! rg -n "^[#]{2,3}[[:space:]]+${SECTION_RE}[[:space:]]*$" "$SPEC_PATH" >/dev/null; then
  echo "Section not found in spec: $SECTION_NAME" >&2
  echo "Add a '## ${SECTION_NAME}' heading with 1-3 tasks before running this script." >&2
  exit 1
fi

SPEC_REL="${SPEC_PATH#$ROOT_DIR/}"

"$CODEX_BIN" exec --full-auto --cd "$ROOT_DIR" - <<EOF
You are the Coder Agent for this task. Follow these agent instructions exactly:

$(cat "$AGENT_CODER")

Task:
- Use the feature spec at: $SPEC_REL
- Implement the tasks listed under the "Tasks" heading.
- If new work is discovered, add it to "Tasks" with clear, actionable phrasing.
- Update the feature spec to mark completed tasks as done and note any deviations.
- Add or update tests required by those tasks (including BDD tests under tests/).
- Keep changes minimal and aligned with the architecture in the spec.

If the "${SECTION_NAME}" section is missing or empty, stop and do not change any files.
EOF

"$CODEX_BIN" exec --full-auto --cd "$ROOT_DIR" - <<EOF
You are the Inspector Agent for this task. Follow these agent instructions exactly:

$(cat "$AGENT_INSPECTOR")

Task:
- Review unit and BDD tests for the feature spec at: $SPEC_REL
- Ensure tests follow industry best practices and provide reliable coverage.
- Improve or add tests if quality or coverage is insufficient.
- Keep changes minimal and aligned with the spec.
- Do not change production code unless needed for deterministic tests.
EOF

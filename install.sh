#!/bin/bash
# Install gemini-antigravity-for-claude-code as a shared launchd service on macOS and register it
# with Claude Code.   Usage: ./install.sh [--dry-run] [--port 8772] [--label com.gemini-antigravity.mcp]
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"; PORT=8772; LABEL=com.gemini-antigravity.mcp; DRY=0
while [ $# -gt 0 ]; do case "$1" in
  --dry-run) DRY=1 ;; --port) PORT="$2"; shift ;; --label) LABEL="$2"; shift ;;
  *) echo "unknown option $1"; exit 1 ;; esac; shift; done
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
run() { if [ $DRY = 1 ]; then echo "+ $*"; else "$@"; fi; }

command -v agy >/dev/null || [ -x "$HOME/.local/bin/agy" ] || {
  echo "Antigravity CLI (agy) not found. Install: curl -fsSL https://antigravity.google/cli/install.sh | bash"
  echo "then run 'agy' once and sign in with your Google AI Pro/Ultra account."; exit 1; }
if [ ! -x "$DIR/.venv/bin/python" ]; then
  if command -v uv >/dev/null; then run uv venv "$DIR/.venv" --python 3.12
    run uv pip install --python "$DIR/.venv/bin/python" -r "$DIR/requirements.txt"
  else run python3 -m venv "$DIR/.venv"; run "$DIR/.venv/bin/pip" install -r "$DIR/requirements.txt"; fi
fi
RENDERED=$(sed -e "s|__DIR__|$DIR|g" -e "s|__HOME__|$HOME|g" -e "s|__LABEL__|$LABEL|g" -e "s|__PORT__|$PORT|g" \
  "$DIR/launchd/gemini-mcp.plist.template")
if [ $DRY = 1 ]; then echo "--- would write $PLIST:"; echo "$RENDERED"; else
  mkdir -p "$HOME/Library/LaunchAgents"; printf '%s\n' "$RENDERED" > "$PLIST"; plutil -lint "$PLIST" >/dev/null
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST"; fi
run claude mcp add --transport http -s user gemini "http://127.0.0.1:$PORT/mcp"
echo "Done. Service $LABEL on 127.0.0.1:$PORT; log ~/Library/Logs/gemini-mcp.log. New Claude Code sessions will see the 'gemini' tools."

#!/usr/bin/env bash
# install.sh — installs the bug-bounty-recon command and subagents into Claude Code.
# Uses the FLAT user-scope layout (~/.claude/commands/ and ~/.claude/agents/)
# which auto-loads without any plugin/marketplace registration.

set -u

readonly C_GREEN=$'\033[0;32m'
readonly C_RED=$'\033[0;31m'
readonly C_YELLOW=$'\033[0;33m'
readonly C_BLUE=$'\033[0;34m'
readonly C_RESET=$'\033[0m'

log()  { printf "%s[*]%s %s\n" "$C_BLUE"   "$C_RESET" "$1"; }
ok()   { printf "%s[+]%s %s\n" "$C_GREEN"  "$C_RESET" "$1"; }
warn() { printf "%s[!]%s %s\n" "$C_YELLOW" "$C_RESET" "$1"; }
err()  { printf "%s[-]%s %s\n" "$C_RED"    "$C_RESET" "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/bug-bounty-recon"
SRC_COMMANDS="$SRC_DIR/commands"
SRC_AGENTS="$SRC_DIR/agents"

DST_COMMANDS="$HOME/.claude/commands"
DST_AGENTS="$HOME/.claude/agents"
LEGACY_PLUGIN_DIR="$HOME/.claude/plugins/bug-bounty-recon"

# --- preflight ---------------------------------------------------------------

if [ ! -d "$SRC_DIR" ]; then
  err "Source folder not found at $SRC_DIR"
  err "Run this script from the repo root that contains bug-bounty-recon/"
  exit 1
fi

if [ ! -d "$SRC_COMMANDS" ] || [ ! -d "$SRC_AGENTS" ]; then
  err "Expected bug-bounty-recon/commands/ and bug-bounty-recon/agents/ in source"
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  warn "claude CLI not found on PATH. Install Claude Code first:"
  warn "  https://docs.anthropic.com/en/docs/claude-code/setup"
  warn "Files will still be installed for when you do install it."
fi

# --- clean up legacy plugin-format install (from older install.sh) ----------

if [ -d "$LEGACY_PLUGIN_DIR" ]; then
  warn "Removing legacy plugin-format install at $LEGACY_PLUGIN_DIR"
  rm -rf "$LEGACY_PLUGIN_DIR"
fi

# --- install -----------------------------------------------------------------

log "Installing into Claude Code (flat user-scope layout)..."
mkdir -p "$DST_COMMANDS" "$DST_AGENTS"

# Slash command
cp "$SRC_COMMANDS/fingerprint.md" "$DST_COMMANDS/fingerprint.md"
ok "Command installed: $DST_COMMANDS/fingerprint.md"

# All 13 agents (1 orchestrator + 12 workers)
INSTALLED_AGENTS=0
for f in "$SRC_AGENTS"/*.md; do
  [ -f "$f" ] || continue
  cp "$f" "$DST_AGENTS/$(basename "$f")"
  INSTALLED_AGENTS=$((INSTALLED_AGENTS + 1))
done
ok "Agents installed: $INSTALLED_AGENTS files in $DST_AGENTS/"

# --- API key check -----------------------------------------------------------

echo
if [ -n "${PDCP_API_KEY:-}" ]; then
  ok "PDCP_API_KEY is set (length: ${#PDCP_API_KEY})"
else
  warn "PDCP_API_KEY is not set. The /fingerprint command will abort without it."
  warn "Get a key at https://cloud.projectdiscovery.io and add to your shell rc:"
  echo "    export PDCP_API_KEY=\"your-key-here\""
fi

# --- next steps --------------------------------------------------------------

echo
ok "Installation complete."
log "Next steps:"
echo "  1. If Claude Code is already running, exit and restart it (the /clear command does NOT reload files)."
echo "  2. From any working directory, run:"
echo "       claude"
echo "       > /fingerprint target.com"
echo
log "To uninstall, run: ./uninstall.sh"

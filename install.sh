#!/usr/bin/env bash
# install.sh — installs the bug-bounty-recon plugin into Claude Code.
# Copies bug-bounty-recon/ into ~/.claude/plugins/ and prints next steps.

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
PLUGIN_SRC="$SCRIPT_DIR/bug-bounty-recon"
PLUGIN_DST="$HOME/.claude/plugins/bug-bounty-recon"

# --- preflight ---------------------------------------------------------------

if [ ! -d "$PLUGIN_SRC" ]; then
  err "Plugin folder not found at $PLUGIN_SRC"
  err "Run this script from the repo root that contains bug-bounty-recon/"
  exit 1
fi

if [ ! -f "$PLUGIN_SRC/.claude-plugin/plugin.json" ]; then
  err "Plugin manifest missing: $PLUGIN_SRC/.claude-plugin/plugin.json"
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  warn "claude CLI not found on PATH. Install Claude Code first:"
  warn "  https://docs.anthropic.com/en/docs/claude-code/setup"
  warn "Plugin files will still be installed in ~/.claude/plugins/ for when you do install it."
fi

# --- install -----------------------------------------------------------------

log "Installing bug-bounty-recon plugin..."
mkdir -p "$HOME/.claude/plugins"

if [ -d "$PLUGIN_DST" ]; then
  warn "Existing install found at $PLUGIN_DST — replacing."
  rm -rf "$PLUGIN_DST"
fi

cp -r "$PLUGIN_SRC" "$PLUGIN_DST"
ok "Plugin installed to $PLUGIN_DST"

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
echo "  1. Restart Claude Code, OR run '/plugin reload' in an active session."
echo "  2. Verify with '/plugin list' (you should see bug-bounty-recon v1.0.0)."
echo "  3. From any working directory, run:"
echo "       claude"
echo "       > /fingerprint target.com"
echo
log "Plugin folder: $PLUGIN_DST"
log "To uninstall, run: ./uninstall.sh"

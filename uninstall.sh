#!/usr/bin/env bash
# uninstall.sh — removes the bug-bounty-recon plugin from Claude Code.

set -u

readonly C_GREEN=$'\033[0;32m'
readonly C_YELLOW=$'\033[0;33m'
readonly C_BLUE=$'\033[0;34m'
readonly C_RESET=$'\033[0m'

log()  { printf "%s[*]%s %s\n" "$C_BLUE"   "$C_RESET" "$1"; }
ok()   { printf "%s[+]%s %s\n" "$C_GREEN"  "$C_RESET" "$1"; }
warn() { printf "%s[!]%s %s\n" "$C_YELLOW" "$C_RESET" "$1"; }

PLUGIN_DST="$HOME/.claude/plugins/bug-bounty-recon"

if [ ! -d "$PLUGIN_DST" ]; then
  warn "Plugin is not installed at $PLUGIN_DST — nothing to remove."
  exit 0
fi

log "Removing $PLUGIN_DST..."
rm -rf "$PLUGIN_DST"
ok "bug-bounty-recon plugin uninstalled."

echo
log "Note: this does NOT remove the recon tools (subfinder, etc.)."
log "If you also want to remove the tools, use 'apt-get remove' / 'rm \$HOME/go/bin/<tool>' manually."

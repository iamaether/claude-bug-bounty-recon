#!/usr/bin/env bash
# uninstall.sh — removes the bug-bounty-recon command and subagents from Claude Code.

set -u

readonly C_GREEN=$'\033[0;32m'
readonly C_YELLOW=$'\033[0;33m'
readonly C_BLUE=$'\033[0;34m'
readonly C_RESET=$'\033[0m'

log()  { printf "%s[*]%s %s\n" "$C_BLUE"   "$C_RESET" "$1"; }
ok()   { printf "%s[+]%s %s\n" "$C_GREEN"  "$C_RESET" "$1"; }
warn() { printf "%s[!]%s %s\n" "$C_YELLOW" "$C_RESET" "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_AGENTS="$SCRIPT_DIR/bug-bounty-recon/agents"

DST_COMMANDS="$HOME/.claude/commands"
DST_AGENTS="$HOME/.claude/agents"
LEGACY_PLUGIN_DIR="$HOME/.claude/plugins/bug-bounty-recon"

REMOVED=0

# Slash command
if [ -f "$DST_COMMANDS/fingerprint.md" ]; then
  rm -f "$DST_COMMANDS/fingerprint.md"
  ok "Removed $DST_COMMANDS/fingerprint.md"
  REMOVED=$((REMOVED + 1))
fi

# Agents — only remove files that match what we installed (use source folder as the manifest)
if [ -d "$SRC_AGENTS" ]; then
  for f in "$SRC_AGENTS"/*.md; do
    [ -f "$f" ] || continue
    target="$DST_AGENTS/$(basename "$f")"
    if [ -f "$target" ]; then
      rm -f "$target"
      ok "Removed $target"
      REMOVED=$((REMOVED + 1))
    fi
  done
else
  warn "Source folder $SRC_AGENTS not found — cannot match agent files for removal."
  warn "If you installed before and lost the source, remove agents manually from $DST_AGENTS/"
fi

# Legacy plugin-format install (if present from earlier installer)
if [ -d "$LEGACY_PLUGIN_DIR" ]; then
  rm -rf "$LEGACY_PLUGIN_DIR"
  ok "Removed legacy plugin directory $LEGACY_PLUGIN_DIR"
  REMOVED=$((REMOVED + 1))
fi

echo
if [ "$REMOVED" -eq 0 ]; then
  warn "Nothing to remove — bug-bounty-recon was not installed."
else
  ok "Uninstall complete ($REMOVED items removed)."
fi
log "Note: this does NOT remove the recon tools (subfinder, etc.). Use apt-get / rm \$HOME/go/bin/<tool> manually."

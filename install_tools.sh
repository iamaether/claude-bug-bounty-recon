#!/usr/bin/env bash
# install_tools.sh — installs every recon tool the bug-bounty-recon plugin needs.
# Designed for Kali Linux / Debian-based distros. Idempotent — safe to re-run.

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

# --- preflight ---------------------------------------------------------------

if ! command -v apt-get >/dev/null 2>&1; then
  err "apt-get not found. This installer targets Kali / Debian. Install tools manually on other distros."
  exit 1
fi

if ! command -v go >/dev/null 2>&1; then
  log "Go not found. Installing golang..."
  sudo apt-get update -qq
  sudo apt-get install -y golang-go || { err "Failed to install Go."; exit 1; }
fi

# Ensure GOPATH/bin is on PATH for this script and future shells
GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$PATH"
if ! grep -q 'go/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/go/bin:$PATH"' >> "$HOME/.bashrc"
  log "Added \$HOME/go/bin to PATH in ~/.bashrc"
fi

# --- helpers -----------------------------------------------------------------

have() { command -v "$1" >/dev/null 2>&1; }

go_install() {
  local name="$1" path="$2"
  if have "$name"; then ok "$name already installed"; return 0; fi
  log "Installing $name via go install..."
  if go install "$path" 2>/dev/null; then
    ok "$name installed"
  else
    err "Failed to install $name from $path"
    return 1
  fi
}

apt_install() {
  local name="$1" pkg="${2:-$1}"
  if have "$name"; then ok "$name already installed"; return 0; fi
  log "Installing $name via apt..."
  if sudo apt-get install -y -qq "$pkg" >/dev/null 2>&1; then
    ok "$name installed"
  else
    err "Failed to install $name (package: $pkg)"
    return 1
  fi
}

# --- install pass ------------------------------------------------------------

log "Refreshing apt index..."
sudo apt-get update -qq

# --- apt-provided tools ---
apt_install nmap
apt_install jq
apt_install amass
apt_install findomain  # may not be in all repos; fallback below if it fails

if ! have findomain; then
  log "findomain not in apt. Falling back to GitHub binary..."
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)  FDOMAIN_ASSET="findomain-linux.zip" ;;
    aarch64) FDOMAIN_ASSET="findomain-aarch64.zip" ;;
    i686|i386) FDOMAIN_ASSET="findomain-linux-i386.zip" ;;
    *) FDOMAIN_ASSET="" ;;
  esac
  TMPD=$(mktemp -d)
  if [ -n "$FDOMAIN_ASSET" ] && curl -fsSL -o "$TMPD/findomain.zip" \
      "https://github.com/Findomain/Findomain/releases/latest/download/$FDOMAIN_ASSET"; then
    (cd "$TMPD" && unzip -q findomain.zip && sudo mv findomain /usr/local/bin/findomain && sudo chmod +x /usr/local/bin/findomain) \
      && ok "findomain installed" || err "findomain install failed"
  else
    err "findomain download failed (arch: $ARCH)"
  fi
  rm -rf "$TMPD"
fi

# --- ProjectDiscovery suite (go install) ---
go_install subfinder github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go_install httpx     github.com/projectdiscovery/httpx/cmd/httpx@latest
go_install dnsx      github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go_install katana    github.com/projectdiscovery/katana/cmd/katana@latest
go_install chaos     github.com/projectdiscovery/chaos-client/cmd/chaos@latest

# --- tomnomnom suite ---
go_install assetfinder github.com/tomnomnom/assetfinder@latest
go_install waybackurls github.com/tomnomnom/waybackurls@latest

# --- crawlers / aux ---
go_install gospider github.com/jaeles-project/gospider@latest
go_install hakrawler github.com/hakluke/hakrawler@latest
go_install gau      github.com/lc/gau/v2/cmd/gau@latest
go_install subjs    github.com/lc/subjs@latest

# --- linkfinder (python) ---
if ! have linkfinder; then
  log "Installing linkfinder via pipx (or pip --user)..."
  if have pipx; then
    pipx install linkfinder 2>/dev/null || pipx install git+https://github.com/GerbenJavado/LinkFinder.git
  else
    pip3 install --user --quiet linkfinder 2>/dev/null || \
      pip3 install --user --quiet git+https://github.com/GerbenJavado/LinkFinder.git
  fi
  have linkfinder && ok "linkfinder installed" || warn "linkfinder install failed — install manually if needed"
fi

# --- rustscan ---
if ! have rustscan; then
  log "Installing rustscan from GitHub release..."
  ARCH=$(dpkg --print-architecture)
  TMPD=$(mktemp -d)
  RUSTSCAN_DEB_URL=$(curl -fsSL https://api.github.com/repos/RustScan/RustScan/releases/latest \
    | jq -r --arg arch "$ARCH" '.assets[] | select(.name | endswith($arch + ".deb")) | .browser_download_url' \
    | head -n 1)
  if [ -n "$RUSTSCAN_DEB_URL" ] && curl -fsSL -o "$TMPD/rustscan.deb" "$RUSTSCAN_DEB_URL"; then
    sudo dpkg -i "$TMPD/rustscan.deb" >/dev/null 2>&1 && ok "rustscan installed" || err "rustscan dpkg failed"
  else
    err "rustscan download failed — try manual install from https://github.com/RustScan/RustScan/releases"
  fi
  rm -rf "$TMPD"
fi

# --- final audit -------------------------------------------------------------

echo
log "Verifying all required tools..."
REQUIRED=(subfinder amass assetfinder findomain chaos dnsx httpx katana gospider hakrawler waybackurls gau subjs linkfinder nmap rustscan jq)
MISSING=()
for t in "${REQUIRED[@]}"; do
  if have "$t"; then ok "$t"; else err "$t"; MISSING+=("$t"); fi
done

echo
if [ ${#MISSING[@]} -eq 0 ]; then
  ok "All required tools installed."
  log "Next steps:"
  echo "  1. export PDCP_API_KEY=\"your-projectdiscovery-key\"  (get one at https://cloud.projectdiscovery.io)"
  echo "  2. ./install.sh  (install the Claude Code plugin)"
else
  warn "${#MISSING[@]} tool(s) missing: ${MISSING[*]}"
  warn "Install them manually before running ./install.sh"
  exit 1
fi

# bug-bounty-recon

A Claude Code plugin that automates a 12-agent bug bounty recon pipeline against a single target domain. Designed to run inside a Kali Linux VM where the recon tools are installed.

## What it does

Run `/fingerprint <target>` and a head orchestrator agent drives 12 specialized worker subagents through this chain:

```
1. subdomain-enumerator       (subfinder, amass, assetfinder, findomain, chaos, crt.sh)
2. subdomain-deduplicator
   ↓ (orchestrator runs inline dnsx validation)
3. status-sorter              (httpx)
4. important-filter
5. highvalue-selector
6. url-crawler                ┐ parallel
9. network-scanner            ┘
7. url-classifier
10. port-organizer
8. output-organizer
   ↓ (join: wait for 8 + 10)
11. ai-analyzer
12. ai-prioritizer            → attack_plan.txt
```

Each worker has a fixed contract (objective, input/output paths, scope, dedup, signal) but **invents its own methodology** at runtime — flags, tool combinations, even adding tools the SOP didn't anticipate.

## Requirements

- Claude Code, signed in with your Claude subscription
- Kali Linux (or any Linux distro) with these tools on `$PATH`:
  - `subfinder amass assetfinder findomain chaos dnsx httpx katana gospider hakrawler waybackurls gau subjs linkfinder nmap rustscan jq`
- A ProjectDiscovery API key exported as `PDCP_API_KEY` (needed for `chaos`). Get one at https://cloud.projectdiscovery.io

## Install

Inside your Kali VM, clone the repo and run the two installers:

```bash
git clone https://github.com/iamaether/claude-bug-bounty-recon.git
cd claude-bug-bounty-recon
chmod +x install_tools.sh install.sh uninstall.sh
./install_tools.sh    # installs subfinder, amass, httpx, etc.
./install.sh          # installs /fingerprint + 13 agents into ~/.claude/
```

Then export your ProjectDiscovery key (required for `chaos`):

```bash
export PDCP_API_KEY="your-key-here"
# Persist by appending to ~/.bashrc or ~/.zshrc
```

**Restart Claude Code** (fully exit and reopen — `/clear` does NOT reload files). Then verify:

```
/help
```

You should see `/fingerprint` listed under commands.

To remove: `./uninstall.sh` (leaves the recon tools alone).

## Install layout

The installer uses Claude Code's flat user-scope layout (NOT the plugin/marketplace system):

- `~/.claude/commands/fingerprint.md` — the slash command
- `~/.claude/agents/recon-orchestrator.md` — the head agent
- `~/.claude/agents/subdomain-enumerator.md` ... `ai-prioritizer.md` — 12 worker agents

These auto-load on Claude Code startup without any marketplace registration.

## Use

```bash
export PDCP_API_KEY="your-pdcp-key"
mkdir -p ~/recon-workspace && cd ~/recon-workspace
claude
```

In the Claude Code session:

```
/fingerprint example.com
```

The plugin will:
1. Preflight-check tools and `PDCP_API_KEY`.
2. Auto-create `./scope.txt` with `*.example.com` if missing.
3. Create `./recon/example.com/` and required subfolders.
4. Dispatch the orchestrator, which runs the full 12-agent chain.

Final output: `./recon/example.com/attack_plan.txt`.

## Scope

To restrict scope before running, create `./scope.txt` manually with wildcard patterns (one per line):

```
*.example.com
api.example.org
```

## Output layout

```
recon/example.com/
├── all_subdomains_raw.txt
├── all_subdomains.txt
├── all_subdomains_resolved.txt
├── important_subdomains.txt
├── highvalue.txt
├── crawled_all.txt
├── ai_analysis.txt
├── attack_plan.txt          ← start here
├── portscan_summary.txt
├── orchestrator.log
├── subdomains_by_status/
├── urls_by_subdomain/
├── portscan/
└── subdomains/
    └── <sub>/
        ├── get_params.txt
        ├── post_params.txt
        ├── api_endpoints.txt
        ├── js_files.txt
        ├── redirect_urls.txt
        ├── js_secrets.txt
        └── open_ports.txt
```

## Legal

Run this only against targets you are explicitly authorized to test (your own assets, bug bounty programs in scope, CTFs). Active scanning of unauthorized hosts is illegal in most jurisdictions.

# claude-bug-bounty-recon

A Claude Code slash command + 13 subagents that automate a 12-agent bug bounty recon pipeline. One head orchestrator drives 12 specialized worker subagents through subdomain enumeration, status sorting, crawling, port scanning, secret detection, and AI-driven attack-plan generation — invoked with `/fingerprint <target>`.

## Quick install (Kali Linux)

```bash
git clone https://github.com/iamaether/claude-bug-bounty-recon.git
cd claude-bug-bounty-recon
chmod +x install_tools.sh install.sh uninstall.sh
./install_tools.sh        # installs subfinder, amass, httpx, etc.
./install.sh              # installs /fingerprint + 13 agents into ~/.claude/
export PDCP_API_KEY="your-projectdiscovery-key"
```

**Fully restart Claude Code** (exit + reopen — `/clear` does NOT reload files), then:

```bash
claude
> /fingerprint target.com
```

Output: `./recon/<target>/attack_plan.txt`.

## What's in here

- [`bug-bounty-recon/`](bug-bounty-recon/) — source tree (1 slash command + 13 subagent files)
- [`install_tools.sh`](install_tools.sh) — installs all 17 recon tools via apt + go install
- [`install.sh`](install.sh) — copies the command and agents into Claude Code's user-scope dirs (`~/.claude/commands/`, `~/.claude/agents/`)
- [`uninstall.sh`](uninstall.sh) — removes the command and agents (leaves the tools)
- [`bug-bounty-recon/README.md`](bug-bounty-recon/README.md) — full docs (architecture, usage, output layout)

> Note: this uses Claude Code's **flat user-scope layout**, not the `/plugins` marketplace system. The marketplace system requires registering a plugin via a marketplace.json, which adds friction. The flat layout auto-loads on Claude Code startup with zero config.

## Requirements

- Kali Linux (or any Debian-based distro) — installer is apt-based
- Claude Code, signed in with your Claude subscription
- A ProjectDiscovery API key for `chaos`: https://cloud.projectdiscovery.io

## Architecture

```
/fingerprint target.com
    ↓
recon-orchestrator (head agent — never runs tools itself)
    ↓ dispatches each worker, verifies output, retries on failure
1. subdomain-enumerator     (subfinder, amass, assetfinder, findomain, chaos, crt.sh)
2. subdomain-deduplicator
   ↓ (orchestrator runs inline dnsx validation)
3. status-sorter            (httpx)
4. important-filter
5. highvalue-selector
6. url-crawler              ┐ parallel
9. network-scanner          ┘
7. url-classifier
10. port-organizer
8. output-organizer
   ↓ (join: wait for 8 + 10)
11. ai-analyzer
12. ai-prioritizer          → attack_plan.txt
```

Each worker has a fixed contract (objective, input/output paths, scope, dedup, signal) but **invents its own methodology** at runtime — flags, tool combinations, and even additional tools the SOP didn't anticipate.

## Legal

Run this only against targets you are explicitly authorized to test (your own assets, bug bounty programs in scope, CTFs). Active scanning of unauthorized hosts is illegal in most jurisdictions.

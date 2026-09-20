# Grok Bot ↔ Hermes Remote — SSH Linkup

[![Status](https://img.shields.io/badge/status-active-brightgreen)](#)
[![Activation](https://img.shields.io/badge/sole_activation-Hermes_4425834-blue)](#sole-activation--hermes-bot-4425834)
[![Sanitized](https://img.shields.io/badge/secrets-placeholders_only-lightgrey)](#security--sanitization)
[![License](https://img.shields.io/badge/license-private-important)](#)

Sanitized handoff for wiring **Grok Bot** to **Hermes Desktop / Hermes Remote** over Tailscale SSH, with a single multiplexed gateway exposing all profile API ports.

> **Never commit secrets.** Hostnames, IPs, API keys, tokens, and private keys stay in local env / your secret store. This repo uses placeholders only.

---

## Table of contents

- [Quick start](#quick-start)
- [Architecture overview](#architecture-overview)
- [How Grok Bot connects to Hermes Desktop](#how-grok-bot-connects-to-hermes-desktop)
- [Sole activation — Hermes bot 4425834](#sole-activation--hermes-bot-4425834)
- [Multiplexed gateway](#multiplexed-gateway)
- [Environment configuration](#environment-configuration)
- [Setup instructions](#setup-instructions)
- [Scripts](#scripts)
- [Obsidian vault note](#obsidian-vault-note)
- [Security & sanitization](#security--sanitization)
- [Troubleshooting](#troubleshooting)

---

## Quick start

```bash
# 1. Clone (private repo)
git clone <REPO_URL>
cd hermes-grok-ssh-handoff

# 2. Configure remote (MagicDNS or host alias — never commit real values)
cp .env.example .env
# Edit .env:
#   HERMES_REMOTE=admin@<TAILSCALE_MAGICDNS_OR_HOST>

# 3. Load env and activate (idempotent)
set -a && source .env && set +a
./scripts/activate.sh activate
./scripts/activate.sh status
./scripts/activate.sh probe    # expect HTTP 401 = up + auth-gated
```

**Activation rule:** production activate/pause/status goes through **Hermes Grok Bot `4425834` only**. Other bots route requests to that bot; they do not SSH-activate the remote themselves.

---

## Architecture overview

```
┌─────────────────────┐
│  User / Chief of    │
│  Staff (Grok Bot)   │
└──────────┬──────────┘
           │ ask to activate / use Hermes
           ▼
┌─────────────────────┐
│ Hermes Grok Bot     │  ← SOLE activation port (serverId 4425834)
│ (this linkup owner) │
└──────────┬──────────┘
           │ Tailscale SSH  ($HERMES_REMOTE)
           ▼
┌─────────────────────┐
│ Hermes Remote       │  macOS host · Hermes Desktop / CLI
│ ~/.hermes           │
└──────────┬──────────┘
           │ hermes gateway (launchd-supervised)
           ▼
┌─────────────────────────────────────────────┐
│ Multiplexed gateway                         │
│   http://localhost:8642                     │
│   /p/<profile>/v1   × 25 profile APIs       │
└─────────────────────────────────────────────┘
```

| Layer | Responsibility |
|--------|----------------|
| **Grok Bot CoS** | Orchestrates; never bypasses Hermes 4425834 for remote activation |
| **Hermes bot 4425834** | Only bot allowed to activate / probe / pause remote ports |
| **Tailscale SSH** | Encrypted path to Hermes Desktop host |
| **Hermes CLI** | `hermes gateway status\|start\|list\|pause` on the remote |
| **Multiplexed gateway** | One process; all profile HTTP APIs on loopback `:8642` |

---

## How Grok Bot connects to Hermes Desktop

1. **Network:** Grok Bot’s machine joins the same Tailscale tailnet as the Hermes Desktop Mac.
2. **Auth:** SSH as the remote admin user via Tailscale (BatchMode keys or Tailscale SSH). Host comes from `HERMES_REMOTE` — **not** hard-coded in git.
3. **CLI:** Remote `hermes` on `PATH` (typically `~/.local/bin/hermes`), home `~/.hermes`.
4. **Control plane:** Hermes bot 4425834 runs `./scripts/activate.sh …` (or equivalent SSH commands) against that host.
5. **Data / vault:** Obsidian + Obliviarch stay on the remote filesystem; vault work prefers profile **`vaultkeeper`**, still only via Hermes 4425834 → SSH.

There is **no** account-wide Hermes MCP for this linkup. Access is **bot-scoped** to 4425834.

---

## Sole activation — Hermes bot 4425834

```
User / CoS  →  Hermes 4425834  →  Tailscale SSH  →  hermes gateway *
            ↳ nothing else activates remote ports
```

### Rules

1. **No bypass** — other Grok bots must not SSH-activate the remote for production.
2. **No global Hermes MCP** — do not `AddMcpServer` Hermes account-wide for this path.
3. **No silent gateway restart** while post-`hermes update` restart-pending — ask the user first.
4. **Vault** — prefer `vaultkeeper`; still only through 4425834.

Full contract: [`docs/ACTIVATION_CONTRACT.md`](docs/ACTIVATION_CONTRACT.md)

---

## Multiplexed gateway

- **Listener:** `http://localhost:8642` (loopback on the Hermes host)
- **URL pattern:** `http://localhost:8642/p/<profile>/v1`
- **Health probe without API key:** HTTP **401** ⇒ process up and auth-gated (healthy)

### Profile API ports (25)

| Group | Profiles |
|--------|----------|
| Ops / OODA | `radar` · `analyst` · `warroom` · `strike` · `helm` · `dealcrusher` |
| Content | `playmaker` · `scribe` · `shotcaller` · `amp` · `deckhand` |
| Design / FE | `taste` · `atelier` · `moodboard` · `curate` · `polish` · `kinetic` · `wireframe` · `forge` |
| Knowledge / work | `vaultkeeper` · `archivist` · `ledger` · `hirekit` · `mule` · `dsh` |

Plus the **`default`** multiplexer profile (gateway supervisor target).

Deep dive: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

---

## Environment configuration

Copy [`.env.example`](.env.example) → `.env` (gitignored):

| Variable | Required | Example placeholder | Purpose |
|----------|----------|---------------------|---------|
| `HERMES_REMOTE` | **Yes** | `admin@<TAILSCALE_MAGICDNS>` | SSH target for activate/status/probe |
| `HERMES_BIN` | No | `/Users/<USER>/.local/bin/hermes` | Override remote hermes path if needed |

```bash
# .env.example (safe to commit)
HERMES_REMOTE=admin@<TAILSCALE_MAGICDNS_OR_HOST>
# HERMES_BIN=/Users/<USER>/.local/bin/hermes
```

**Do not** put real MagicDNS names, IPs, keys, or tokens in tracked files.

---

## Setup instructions

### Prerequisites

- Tailscale connectivity between Grok Bot box and Hermes Desktop host
- SSH BatchMode access as the remote admin user
- Hermes CLI installed on the remote (`hermes gateway …` works in a login shell)
- This repo cloned on the Grok Bot box (or scripts mirrored under the Hermes bot’s workspace)

### Install

```bash
git clone <REPO_URL>
cd hermes-grok-ssh-handoff
cp .env.example .env
# fill HERMES_REMOTE only
chmod +x scripts/activate.sh
```

### Verify ignores (optional)

```bash
git check-ignore -v .env id_rsa secrets/token.pem
# each path should print a matching .gitignore rule
```

### Day-2 ops

| Intent | Command |
|--------|---------|
| Activate all profile ports | `./scripts/activate.sh activate` |
| Status + list | `./scripts/activate.sh status` |
| Probe all 25 | `./scripts/activate.sh probe` |
| Safe pause | `./scripts/activate.sh deactivate` |

---

## Scripts

| Path | Role |
|------|------|
| [`scripts/activate.sh`](scripts/activate.sh) | Sole box-side entrypoint: `activate` · `status` · `list` · `probe` · `deactivate` |

Requires `HERMES_REMOTE` in the environment.

---

## Obsidian vault note

Vault-ready knowledge note (schema frontmatter + tags + wikilinks):

- [`obsidian/Grok-Bot-Hermes-SSH-Linkup.md`](obsidian/Grok-Bot-Hermes-SSH-Linkup.md)

**Filing:** Hermes bot **4425834** places this into the remote Obsidian vault (prefer under `Knowledge/20-Reports/` and/or `handoffs/`). Vault ops after that prefer **`vaultkeeper`**, still only via Hermes → SSH.

---

## Security & sanitization

- ✅ No host IPs, tokens, private keys, or live `.env` values in git history of this handoff package
- ✅ Placeholders only (`<TAILSCALE_MAGICDNS>`, `<USER>`, `<REPO_URL>`)
- ✅ Root [`.gitignore`](.gitignore) excludes `.env*`, `*.pem` / `*.key`, SSH keys, `credentials/`, `secrets/`, IDE folders, Python/Node build artifacts, local override scripts
- ✅ See [`SECURITY.md`](SECURITY.md)

If a secret is ever committed: **rotate immediately** and purge from history.

---

## Troubleshooting

| Symptom | Likely cause | Action |
|---------|--------------|--------|
| `HERMES_REMOTE` unset | Env not loaded | `source .env` |
| SSH timeout | Tailscale / ACL | Check tailnet; confirm MagicDNS |
| Gateway not supervised | Gateway down | `./scripts/activate.sh activate` via Hermes 4425834 |
| Probe `FAIL` / connection refused | Listener down | `hermes gateway status` on remote via Hermes |
| Probe `401` | **Healthy** | Auth required — expected without API key |
| Restart-pending after update | Mixed modules warning | Ask user before `hermes gateway restart` |

---

## Related docs

- [Activation contract](docs/ACTIVATION_CONTRACT.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Security](SECURITY.md)
- [Obsidian note](obsidian/Grok-Bot-Hermes-SSH-Linkup.md)

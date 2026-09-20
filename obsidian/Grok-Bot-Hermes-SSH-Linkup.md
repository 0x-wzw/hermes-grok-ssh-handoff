---
title: "Grok Bot ↔ Hermes Remote — SSH Linkup"
type: handoff
category: infrastructure
created: 2026-09-20
updated: 2026-09-20
slug: grok-bot-hermes-ssh-linkup
timestamp: 20260920-0929
domain: system
status: active
source: grok-bot-chief-of-staff
agent: chief-of-staff
topics: [hermes, grok-bot, tailscale, ssh, multiplexed-gateway, activation, vaultkeeper]
tags: [handoff, hermes, grok-bot, tailscale, gateway, activation, sanitised]
aliases: [Hermes SSH Linkup, Grok Hermes Activation]
project: hermes-remote
---

# Grok Bot ↔ Hermes Remote — SSH Linkup

**Status:** Active · **Date:** 2026-09-20 · **Sanitised:** no IPs, credentials, or tokens

## Summary

Grok Bot **Hermes (4425834)** is the **sole activation point** for every Hermes remote profile API port. Activation always flows through that bot over Tailscale SSH into the Hermes Remote Server’s multiplexed gateway on loopback port **8642**.

## Activation path

```
User / CoS → Hermes Grok Bot 4425834 → Tailscale SSH → Hermes Remote
  → multiplexed gateway localhost:8642 → /p/<profile>/v1 (×25)
```

Nothing bypasses Hermes 4425834. Do not add a global Hermes MCP for this linkup.

## Multiplexed gateway

- One launchd-supervised **default** gateway
- Shared listener: `http://localhost:8642`
- Profile URL pattern: `http://localhost:8642/p/<profile>/v1`
- Probe without key → `401` = up + auth-gated

### Profiles (25)

amp · analyst · archivist · atelier · curate · dealcrusher · deckhand · dsh · forge · helm · hirekit · kinetic · ledger · moodboard · mule · playmaker · polish · radar · scribe · shotcaller · strike · taste · vaultkeeper · warroom · wireframe

## One-step activate

On the Grok Bot box (Hermes bot only):

```bash
export HERMES_REMOTE='admin@<MAGICDNS>'
./scripts/activate.sh activate
./scripts/activate.sh probe
```

## Obsidian / Obliviarch

Prefer **vaultkeeper** for vault work. Still only: Hermes 4425834 → SSH → remote vault.

Private GitHub handoff (sanitized): `hermes-grok-ssh-handoff` under the linked GitHub account.

## Related

- [[Hermes-Bot-Fleet-Handoff-Grok-20260918]]
- [[SCHEMA]]
- [[Self-Evolution-Pipeline]]

## Explicitly excluded from this note

Host IPs, MagicDNS FQDNs, API keys, messaging tokens, `.env` contents, private keys.

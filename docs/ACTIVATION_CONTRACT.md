# Activation contract — Hermes Grok Bot 4425834

## Ownership

You (Hermes Grok Bot **4425834**) own activation for **all** Hermes remote profile API ports. Nothing bypasses you.

## Path

```
User / CoS → Hermes 4425834 → Tailscale SSH ($HERMES_REMOTE) → hermes gateway *
  → localhost:8642/p/<profile>/v1  (×25 profiles)
```

## Entrypoint

```bash
./scripts/activate.sh activate|status|list|probe|deactivate
```

Set `HERMES_REMOTE` to the Tailscale MagicDNS name or host alias — **never hard-code IPs in commits**.

## Rules

1. No other bot SSH-activates the remote for production use.
2. Never install Hermes as account-wide / global MCP from this linkup.
3. Do not auto-run `hermes gateway restart` while restart-pending after `hermes update` — report and wait.
4. Vault ops → prefer profile `vaultkeeper`, still only via this bot → SSH.
5. Confirm destructive remote actions with the user.

# Remote architecture (sanitized)

## Host

- Role: **Hermes Remote Server** (macOS)
- Access: Tailscale SSH only from the Grok Bot machine
- CLI: `hermes` on the remote `PATH` (user-local install)
- Home: `~/.hermes` on the remote

## Gateway

- Kind: multiplexed **default** gateway
- Supervision: launchd (`ai.hermes.gateway` or equivalent)
- Loopback API listener: `localhost:8642`
- Serves all listed profiles under `/p/<name>/v1`

## Grok Bot side

- Hermes specialist bot: **serverId 4425834**
- Activation scripts live on the Grok Bot box under a `hermes-remote/` (or this repo’s `scripts/`) directory
- SSH: BatchMode, short ConnectTimeout; host from `$HERMES_REMOTE`

## What is intentionally omitted

IP addresses, MagicDNS FQDNs, API keys, Telegram/Feishu tokens, Ollama keys, and any `.env` contents — store those in a secret manager / host env, never in git.

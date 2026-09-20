# Security

## Policy

- **Placeholders only** in tracked files (no real IPs, MagicDNS FQDNs, tokens, or keys).
- `HERMES_REMOTE` and secrets live in **local `.env`** (gitignored) or a secret manager.
- Activation is **bot-scoped** to Hermes Grok Bot `4425834` — not a global MCP.

## Verify `.gitignore`

```bash
touch .env id_rsa fake.pem
mkdir -p secrets credentials
touch secrets/x credentials/y.json
git check-ignore -v .env id_rsa fake.pem secrets/x credentials/y.json
rm -f .env id_rsa fake.pem; rm -rf secrets credentials
```

Every path must match a rule. If not, extend `.gitignore` before committing.

## Incident response

1. Rotate the exposed credential.
2. Remove from git history (`git filter-repo` / BFG).
3. Force-push only with explicit owner approval on a private repo.

---
domain: botlearn-doctor
topic: security
priority: high
ttl: 30d
---

# Security Domain Knowledge

## Threat Model for OpenClaw Agent

| Attack Surface | Risk | Mitigation |
|----------------|------|------------|
| Config files with credentials | Credential theft | Encrypt secrets, restrict permissions (0600) |
| World-readable sensitive files | Data exposure | File permission audit, umask 077 |
| Outdated dependencies | Known CVE exploitation | Regular update cycle, `npm audit` |
| Gateway bind=lan/tailnet | Unauthorized API access | Use loopback bind, enable auth |
| No auth on exposed bind | Cross-origin attacks | Enable token/password auth |
| Secrets in VCS | Credential leak via Git | .gitignore patterns, git-secrets hooks |
| Logs with sensitive data | Information disclosure | Log redaction, rotation, access controls |

## Security Scoring (100 points)

| Sub-dimension | Points | What We Check |
|---------------|--------|---------------|
| Credential exposure | 30 | Scan config/env/log files for API keys, tokens, passwords |
| File permissions | 20 | Sensitive files must not be world-readable (≤0640) |
| Dependency vulnerabilities | 20 | Outdated packages, npm audit CVE count |
| Network exposure | 15 | Gateway bind mode (loopback/lan/tailnet), auth config, control UI exposure |
| VCS sensitive info | 15 | .gitignore coverage, tracked secrets |

## Common Credential Patterns

- `api_key`, `apiKey`, `API_KEY` — API access tokens
- `secret`, `client_secret` — OAuth/app secrets
- `token`, `access_token`, `bearer` — Authentication tokens
- `password`, `passwd`, `pwd` — Plaintext passwords
- `-----BEGIN PRIVATE KEY-----` — Private key files

## Privacy Principle

All security scan outputs MUST:
1. Report credential **type** and **location** (file + line)
2. NEVER include actual credential **values**
3. Replace values with `***REDACTED***`
4. Check webhook payloads for leaks before sending

## File Permission Guidelines

| File Type | Recommended | Maximum |
|-----------|-------------|---------|
| Config JSON | 0600 | 0640 |
| Private keys (.key, .pem) | 0600 | 0600 |
| Environment files (.env) | 0600 | 0640 |
| Log files | 0640 | 0644 |
| Script files | 0755 | 0755 |

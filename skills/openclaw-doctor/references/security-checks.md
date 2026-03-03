---
domain: openclaw-doctor
topic: security-checks
priority: medium
ttl: 60d
---

# Security Check Patterns & Fix Guide

## SEC-001: Credential Exposure in Config Files

**Detection**: Scan `$OPENCLAW_HOME/config/*.json` for known secret patterns.

**Patterns**:
```regex
(?:api[_-]?key|apikey)\s*[:=]\s*["']?[A-Za-z0-9_\-]{16,}
(?:secret|client_secret)\s*[:=]\s*["']?[A-Za-z0-9_\-]{16,}
(?:token|access_token|bearer)\s*[:=]\s*["']?[A-Za-z0-9_\-\.]{16,}
(?:password|passwd|pwd)\s*[:=]\s*["']?[^\s"']{4,}
-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----
```

**Fix**:
1. Move secrets to environment variables or a secrets manager
2. Replace inline values with `${ENV_VAR}` references
3. If using `.env` files, ensure they're in `.gitignore`

```bash
# Replace hardcoded token with env var reference
clawhub config set plugins.slack.token '${SLACK_TOKEN}'
```

**Rollback**: Restore from config backup.

---

## SEC-002: World-Readable Sensitive Files

**Detection**: Check file permissions on config, keys, and env files.

**Threshold**: Any file mode > 0640 is flagged.

**Fix**:
```bash
# Fix config file permissions
chmod 600 $OPENCLAW_HOME/openclaw.json

# Fix all key files
find $OPENCLAW_HOME/config -name '*.key' -o -name '*.pem' | xargs chmod 600

# Fix .env files
chmod 600 $OPENCLAW_HOME/.env 2>/dev/null
```

**Prevention**: Set `umask 077` in shell profile.

---

## SEC-003: Dependency Vulnerabilities

**Detection**: Run `clawhub list --outdated` and `npm audit`.

**Severity Mapping**:
| npm audit level | Doctor severity |
|----------------|-----------------|
| critical | critical |
| high | high |
| moderate | warning |
| low | info |

**Fix**:
```bash
# Update all outdated skills
clawhub update --all

# Fix npm vulnerabilities
npm audit fix

# Force-fix (breaking changes possible)
npm audit fix --force
```

**Rollback**: `clawhub install @botlearn/<skill>@<previous-version>`

---

## SEC-004: Gateway Network Exposure

**Detection**: Check gateway config for bind address, CORS, TLS.

**Risk Levels**:
| Setting | Safe | Risky |
|---------|------|-------|
| `gateway.bind` | `loopback` | `lan` / `tailnet` without auth |
| `gateway.auth.type` | `token` / `password` | `none` (on non-loopback) |
| `gateway.controlUI` | `false` (on non-loopback) | `true` (exposed to network) |

**Fix — Restrict Bind Mode**:
```bash
# In ~/.openclaw/openclaw.json, set:
# "gateway": { "bind": "loopback" }
```

**Fix — Enable Auth** (if bind is lan/tailnet):
```bash
# In ~/.openclaw/openclaw.json, set:
# "gateway": { "auth": { "type": "token" } }
```

**Fix — Disable Control UI** (if exposed):
```bash
# In ~/.openclaw/openclaw.json, set:
# "gateway": { "controlUI": false }
```

---

## SEC-005: VCS Sensitive Information

**Detection**: Check `.gitignore` for sensitive patterns; scan for tracked secrets.

**Required .gitignore Patterns**:
```
.env
*.key
*.pem
config/*.secret
credentials
*.p12
```

**Fix — Add Patterns**:
```bash
cat >> .gitignore << 'EOF'
.env
*.key
*.pem
config/*.secret
credentials
*.p12
EOF
```

**Fix — Remove Tracked Secrets**:
```bash
# Remove from tracking (keeps local file)
git rm --cached path/to/secret.key
git commit -m "Remove tracked secret file"
```

**IMPORTANT**: After removing tracked secrets, rotate the exposed credentials immediately.

---

## Security Scan Quick Reference

| Issue ID | Category | Auto-fixable | Impact |
|----------|----------|-------------|--------|
| SEC-001 | Credential exposure | No (requires env var setup) | High |
| SEC-002 | File permissions | Yes (`chmod`) | Medium |
| SEC-003 | Dependencies | Partial (`update --all`) | Varies |
| SEC-004 | Network exposure | Yes (config change) | High |
| SEC-005 | VCS sensitive | Partial (`.gitignore`) | High |

---
domain: botlearn-doctor
topic: fix-playbooks
priority: medium
ttl: 60d
---

# Fix Playbooks

Structured repair procedures for common issues. Each playbook follows:
**Assess → Backup → Fix → Verify → Document**

---

## PB-001: Node.js Upgrade

**Triggered by**: ENV-001 (Node version outdated)

### Assess
```bash
node --version            # Current version
nvm ls-remote --lts       # Available LTS versions (if nvm installed)
```

### Backup
```bash
# Note current version for rollback
echo "Previous: $(node --version)" > /tmp/node-upgrade-rollback.txt
```

### Fix
```bash
# Option A: nvm (recommended)
nvm install 20
nvm alias default 20

# Option B: Official installer
# Download from https://nodejs.org/en/download/

# Option C: Package manager
# macOS: brew install node@20
# Ubuntu: sudo apt install nodejs=20.*
```

### Verify
```bash
node --version  # Should show v20.x
npm --version   # Should be compatible
```

### Rollback
```bash
nvm use $(cat /tmp/node-upgrade-rollback.txt | awk '{print $2}')
```

---

## PB-002: Configuration Repair

**Triggered by**: CONF-001 through CONF-005

### Assess
```bash
cat $OPENCLAW_HOME/openclaw.json | node -e "try{const raw=require('fs').readFileSync('/dev/stdin','utf8');const clean=raw.replace(/\/\/.*$/gm,'').replace(/\/\*[\s\S]*?\*\//g,'');JSON.parse(clean);console.log('Valid JSON5')}catch(e){console.log('INVALID:',e.message)}"
```

### Backup
```bash
cp $OPENCLAW_HOME/openclaw.json $OPENCLAW_HOME/openclaw.json.bak.$(date +%s)
```

### Fix — Missing Config File
```bash
cat > $OPENCLAW_HOME/openclaw.json << 'CONF'
{
  // OpenClaw configuration (JSON5)
  "gateway": {
    "port": 18789,
    "mode": "ws+http",
    "bind": "loopback",
    "auth": { "type": "token" },
    "controlUI": true,
    "reload": "hybrid"
  },
  "agents": {
    "defaults": {
      "workspace": "$HOME/workspace",
      "model": { "primary": "claude-sonnet-4-20250514" },
      "timeoutSeconds": 600,
      "maxConcurrent": 3
    },
    "heartbeat": {
      "intervalMinutes": 30,
      "autoRecovery": true
    }
  },
  "messages": {
    "maxTokens": 8192,
    "temperature": 0.7
  },
  "session": {
    "maxHistory": 1000,
    "persistence": "disk"
  },
  "tools": {
    "profile": "coding",
    "elevated": ["Bash", "Write"],
    "sandbox": { "mode": "local" }
  }
}
CONF
```

### Fix — maxConcurrent Adjustment
```bash
# Edit ~/.openclaw/openclaw.json: agents.defaults.maxConcurrent
# Recommended: 3 for ≤10 skills, 5 for 11-20, 10 for 21+
```

### Fix — Timeout Adjustment
```bash
# Edit ~/.openclaw/openclaw.json: agents.defaults.timeoutSeconds
# Recommended: 600 (10 min), range: 30-1800
```

### Verify
```bash
scripts/collect-config.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log('Valid:', d.config_valid_json, 'Sections:', JSON.stringify(d.sections))"
```

### Rollback
```bash
cp $OPENCLAW_HOME/openclaw.json.bak.* $OPENCLAW_HOME/openclaw.json
```

---

## PB-003: Gateway Recovery

**Triggered by**: RT-001, RT-002, RT-003

### Assess
```bash
# Check all endpoints
scripts/collect-health.sh

# Check Gateway process
ps aux | grep -i openclaw | grep -v grep

# Check port (default 18789)
lsof -i :18789
```

### Fix — Gateway Not Running
```bash
openclaw start
```

### Fix — Gateway Not Operational
```bash
# Restart Gateway
openclaw start

# If restart fails, check logs
tail -50 $OPENCLAW_LOG_DIR/openclaw.log | grep -i error
```

### Fix — Port Conflict
```bash
# Find conflicting process
lsof -i :18789 | awk 'NR>1{print $2}' | head -1

# Kill if safe, or change Gateway port in ~/.openclaw/openclaw.json:
# "gateway": { "port": 18790 }
```

### Verify
```bash
scripts/collect-health.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log('Reachable:', d.gateway_reachable, 'Operational:', d.gateway_operational)"
```

### Rollback
```bash
# Restore previous port in ~/.openclaw/openclaw.json if changed
```

---

## PB-004: Skills Repair

**Triggered by**: SKILL-001 through SKILL-004

### Fix — Install Missing Skills
```bash
# Install core recommended skills
clawhub install @botlearn/google-search @botlearn/summarizer @botlearn/code-gen
```

### Fix — Update Outdated Skills
```bash
# Update all
clawhub update --all

# Or specific skill
clawhub update @botlearn/<skill-name>
```

### Fix — Resolve Broken Dependencies
```bash
# List broken
clawhub list --check-deps

# Reinstall with dependency resolution
clawhub install --force @botlearn/<skill-name>
```

### Fix — Remove Unused Skills
```bash
# List usage stats
clawhub stats --skills

# Uninstall unused
clawhub uninstall @botlearn/<unused-skill>
```

### Verify
```bash
scripts/collect-skills.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log('Installed:', d.installed_count, 'Broken:', JSON.stringify(d.broken_dependencies))"
```

---

## PB-005: Log Cleanup & Rotation

**Triggered by**: LOG issues, disk space warnings

### Assess
```bash
du -sh $OPENCLAW_LOG_DIR/*
```

### Fix — Enable Log Rotation
```bash
# Configure log rotation via system logrotate or OpenClaw settings
# Create /etc/logrotate.d/openclaw:
#   ~/.openclaw/logs/*.log { rotate 10, size 100M, compress, missingok }
```

### Fix — Clean Old Logs
```bash
# Remove rotated logs older than 30 days
find $OPENCLAW_LOG_DIR -name '*.log.*' -mtime +30 -delete

# Truncate current log if oversized (>500MB)
if [ $(stat -f%z $OPENCLAW_LOG_DIR/openclaw.log 2>/dev/null || stat -c%s $OPENCLAW_LOG_DIR/openclaw.log 2>/dev/null || echo 0) -gt 524288000 ]; then
  cp $OPENCLAW_LOG_DIR/openclaw.log $OPENCLAW_LOG_DIR/openclaw.log.bak
  tail -10000 $OPENCLAW_LOG_DIR/openclaw.log.bak > $OPENCLAW_LOG_DIR/openclaw.log
fi
```

### Verify
```bash
du -sh $OPENCLAW_LOG_DIR/*
scripts/collect-logs.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log('Size:', d.main_log.size_kb+'KB', 'Rotation:', d.log_rotation_enabled)"
```

---

## PB-006: Workspace Cleanup

**Triggered by**: WS-001 (missing directories)

### Fix — Create Missing Directories
```bash
mkdir -p $OPENCLAW_HOME/{config,skills,plugins,memory,logs,data,workspace,reports}
```

### Verify
```bash
scripts/collect-config.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log('Directories:', JSON.stringify(d.directories))"
```

---

## PB-007: Memory Optimization

**Triggered by**: ENV-002 (memory low), ENOMEM errors

### Fix — Increase Node.js Heap
```bash
# Add to shell profile
echo 'export NODE_OPTIONS="--max-old-space-size=4096"' >> ~/.zshrc
source ~/.zshrc
```

### Fix — Clean Memory Store
```bash
# Remove expired documents
clawhub memory cleanup --expired

# Remove documents from uninstalled skills
clawhub memory cleanup --orphaned
```

### Fix — Reduce Agent Concurrency
```bash
# Edit ~/.openclaw/openclaw.json: agents.defaults.maxConcurrent = 2
# Then restart: openclaw start
```

---

## PB-008: Security Remediation

**Triggered by**: SEC-001 through SEC-005

### Assess
```bash
scripts/collect-security.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log('Credentials:', d.credential_exposure.issues_found, 'Permissions:', d.file_permissions.issues_found, 'Network:', d.network_exposure.findings.length, 'VCS:', d.vcs_sensitive.findings.length)"
```

### Fix — Credential Exposure (SEC-001)
```bash
# 1. Identify exposed credentials (values are redacted in output)
scripts/collect-security.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); d.credential_exposure.findings.forEach(f => console.log(f.type, f.file, 'line:', f.line))"

# 2. Replace hardcoded values with environment variable references
# Example: in openclaw.json, change "token": "sk-abc123" to "token": "${SLACK_TOKEN}"

# 3. Add to shell profile
echo 'export SLACK_TOKEN="your-actual-token"' >> ~/.zshrc
source ~/.zshrc
```

### Fix — File Permissions (SEC-002)
```bash
chmod 600 $OPENCLAW_HOME/openclaw.json
find $OPENCLAW_HOME/config -name '*.key' -o -name '*.pem' | xargs chmod 600 2>/dev/null
chmod 600 $OPENCLAW_HOME/.env 2>/dev/null
```

### Fix — Network Exposure (SEC-004)
```bash
# In ~/.openclaw/openclaw.json, set:
# "gateway": { "bind": "loopback", "auth": { "type": "token" }, "controlUI": false }
# Then restart: openclaw start
```

### Fix — VCS Sensitive Info (SEC-005)
```bash
# Add missing .gitignore patterns
cat >> .gitignore << 'GITEOF'
.env
*.key
*.pem
config/*.secret
credentials
*.p12
GITEOF

# Remove tracked secrets
git rm --cached path/to/secret.key 2>/dev/null
```

### Verify
```bash
scripts/collect-security.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log('Cred issues:', d.credential_exposure.issues_found, 'Perm issues:', d.file_permissions.issues_found)"
```

### Rollback
```bash
# Restore file permissions if needed
chmod 644 $OPENCLAW_HOME/openclaw.json
# Restore previous gateway bind in ~/.openclaw/openclaw.json
```

---

## PB-009: Log Anomaly Response

**Triggered by**: ANOM-001 through ANOM-006

### Assess
```bash
scripts/collect-log-anomalies.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log('Anomalies:', d.summary.total_anomalies, '(critical:', d.summary.critical, 'warning:', d.summary.warning, ')')"
```

### Fix — Error Spikes (ANOM-001)
```bash
# Identify dominant error type during spike
scripts/collect-logs.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); d.error_patterns?.slice(0,5).forEach(p => console.log(p.count+'x', p.pattern))"

# Apply fix based on error type (see references/error-patterns.md)
```

### Fix — OOM Events (ANOM-003)
```bash
# Increase Node.js heap
export NODE_OPTIONS="--max-old-space-size=4096"
# Reduce concurrency — edit ~/.openclaw/openclaw.json: agents.defaults.maxConcurrent = 2
# Clean memory store
clawhub memory cleanup --expired
# Restart
openclaw start
```

### Fix — Excessive Log Growth (ANOM-006)
```bash
# Configure log rotation via system logrotate:
# ~/.openclaw/logs/*.log { rotate 10, size 100M, compress, missingok }
# Alternatively, truncate oversized log:
tail -10000 $OPENCLAW_LOG_DIR/openclaw.log > $OPENCLAW_LOG_DIR/openclaw.log.tmp && mv $OPENCLAW_LOG_DIR/openclaw.log.tmp $OPENCLAW_LOG_DIR/openclaw.log
```

### Verify
```bash
scripts/collect-log-anomalies.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log('Remaining anomalies:', d.summary.total_anomalies)"
```

---

## PB-010: Workspace Audit Remediation

**Triggered by**: AUDIT-001 through AUDIT-999

### Assess
```bash
scripts/collect-workspace-audit.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log('Issues:', d.summary.issues_found); d.config_cross_validation.issues.forEach(i => console.log('-', i.severity, i.msg))"
```

### Fix — Missing Critical Directories
```bash
mkdir -p $OPENCLAW_HOME/{config,skills,logs,data,reports,plugins,memory,workspace}
```

### Fix — Config Path Mismatch
```bash
# Verify configured paths match actual filesystem
scripts/collect-workspace-audit.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); d.env_audit.conflicts.forEach(c => console.log(c.name, c.msg))"

# Fix: update config or create missing directories
```

### Fix — Large Directory Cleanup
```bash
# Clean old snapshots
find $OPENCLAW_HOME/reports/snapshots -maxdepth 1 -type d -mtime +90 -exec rm -rf {} +
# Clean old logs
find $OPENCLAW_HOME/logs -name '*.log.*' -mtime +30 -delete
# Clean expired memory
clawhub memory cleanup --expired
```

### Verify
```bash
scripts/collect-workspace-audit.sh | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log('Total size:', d.storage.total_size_mb, 'MB', 'Issues:', d.summary.issues_found)"
```

---

## PB-011: Channel Configuration

**Triggered by**: Report delivery setup or channel delivery failures

### Setup — Initialize Channel Config
```bash
mkdir -p $OPENCLAW_HOME/config
cat > $OPENCLAW_HOME/config/doctor-channels.json << 'CHCONF'
{
  "default_channel": "terminal",
  "channels": {
    "terminal": { "enabled": true },
    "browser": { "enabled": true, "auto_open_on_macos": true },
    "slack": { "enabled": false, "webhook_url": "" },
    "dingtalk": { "enabled": false, "webhook_url": "", "secret": "" },
    "feishu": { "enabled": false, "webhook_url": "" },
    "discord": { "enabled": false, "webhook_url": "" },
    "email": { "enabled": false, "to": "", "smtp_host": "localhost" }
  }
}
CHCONF
chmod 600 $OPENCLAW_HOME/config/doctor-channels.json
```

### Fix — Enable Slack Channel
```bash
node -e "
const fs = require('fs');
const p = process.env.OPENCLAW_HOME + '/config/doctor-channels.json';
const c = JSON.parse(fs.readFileSync(p, 'utf8'));
c.channels.slack.enabled = true;
c.channels.slack.webhook_url = process.argv[1];
fs.writeFileSync(p, JSON.stringify(c, null, 2));
" "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

### Verify
```bash
cat $OPENCLAW_HOME/config/doctor-channels.json | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); Object.entries(d.channels).forEach(([k,v]) => console.log(k+':', v.enabled ? 'enabled' : 'disabled'))"
```

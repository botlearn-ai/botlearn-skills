---
name: openclaw-doctor
type: setup
version: 4.0.0
---

# Installation & Setup

## Step 1: Verify Requirements

Before installing, verify all requirements from `requirement.md`:

```bash
# Check Node.js
node --version  # Expect: v18+ or v20+

# Check curl
curl --version | head -1

# Check OpenClaw CLI
clawhub --version 2>/dev/null || openclaw --version 2>/dev/null

# Check OPENCLAW_HOME
echo "${OPENCLAW_HOME:-$HOME/.openclaw}"
ls -la "${OPENCLAW_HOME:-$HOME/.openclaw}/" 2>/dev/null || echo "Directory not found"

# Optional: Check jq
jq --version 2>/dev/null || echo "jq not found (optional)"

# Optional: Check sendmail
which sendmail 2>/dev/null || echo "sendmail not found (optional)"
```

IF requirements not met → abort installation and report missing dependencies.

## Step 2: Install Skill Package

```bash
# Via clawhub (recommended)
clawhub install @botlearn/openclaw-doctor

# Or via npm
npm install @botlearn/openclaw-doctor
```

## Step 3: Set Script Permissions

```bash
# Ensure all scripts are executable (15 scripts in v4.0)
chmod +x scripts/collect-env.sh
chmod +x scripts/collect-config.sh
chmod +x scripts/collect-logs.sh
chmod +x scripts/collect-skills.sh
chmod +x scripts/collect-health.sh
chmod +x scripts/collect-precheck.sh
chmod +x scripts/collect-channels.sh
chmod +x scripts/collect-tools.sh
chmod +x scripts/collect-security.sh
chmod +x scripts/collect-workspace-audit.sh
chmod +x scripts/score-calculator.sh
chmod +x scripts/snapshot-manager.sh
chmod +x scripts/generate-report.sh
chmod +x scripts/open-report.sh
chmod +x scripts/deliver-report.sh
```

## Step 4: Create Checkup Data Directory

```bash
# Create checkup data storage directory (inside skill directory)
mkdir -p data/checkups
```

## Step 5: Initialize Channel Configuration (Optional)

```bash
# Create default channel config for multi-channel delivery
mkdir -p ~/.openclaw/config
cat > ~/.openclaw/config/doctor-channels.json << 'CHCONF'
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
chmod 600 ~/.openclaw/config/doctor-channels.json
```

To enable a webhook channel, edit the config and set `enabled: true` + `webhook_url`.

## Step 6: Initial Health Baseline

Run the first health check to establish a baseline:

```bash
# Create checkup directory
CHECKUP_DIR="data/checkups/$(date +%Y-%m-%d-%H%M%S)"
mkdir -p "$CHECKUP_DIR"

# Execute all 8 collection scripts in parallel
./scripts/collect-env.sh > "$CHECKUP_DIR/env.json" &
./scripts/collect-config.sh > "$CHECKUP_DIR/config.json" &
./scripts/collect-logs.sh > "$CHECKUP_DIR/logs.json" &
./scripts/collect-skills.sh > "$CHECKUP_DIR/skills.json" &
./scripts/collect-health.sh > "$CHECKUP_DIR/health.json" &
./scripts/collect-precheck.sh > "$CHECKUP_DIR/precheck.json" &
./scripts/collect-channels.sh > "$CHECKUP_DIR/channels.json" &
./scripts/collect-tools.sh > "$CHECKUP_DIR/tools.json" &
wait

# Combine and analyze (10-dimension traffic-light)
node -e "
  const fs = require('fs');
  const dir = process.argv[1];
  const data = {};
  for (const key of ['env','config','logs','skills','health','precheck','channels','tools']) {
    try { data[key] = JSON.parse(fs.readFileSync(dir+'/'+key+'.json','utf8')); }
    catch { data[key] = {}; }
  }
  console.log(JSON.stringify(data));
" "$CHECKUP_DIR" | ./scripts/score-calculator.sh > "$CHECKUP_DIR/analysis.json"

# Save checkup with latest symlink
./scripts/snapshot-manager.sh save "$CHECKUP_DIR"
```

## Step 7: Register Scheduled Health Checks (Optional)

### Option A: OpenClaw Crontab (Recommended)

```bash
# Register a daily quick health check via OpenClaw scheduler
clawhub cron add "openclaw-doctor-daily" \
  --schedule "0 9 * * *" \
  --command "clawhub doctor --quick" \
  --notify-on-failure
```

### Option B: System Crontab (Fallback)

```bash
# Add to system crontab
(crontab -l 2>/dev/null; echo "0 9 * * * cd $(clawhub skill-path @botlearn/openclaw-doctor) && ./scripts/collect-health.sh | node -e 'const d=JSON.parse(require(\"fs\").readFileSync(\"/dev/stdin\",\"utf8\")); if(!d.gateway_operational) console.log(\"ALERT: Gateway not operational\")'") | crontab -
```

### Option C: Gateway Heartbeat Integration

For real-time monitoring, register with the Gateway health system:

```bash
# OpenClaw v2026.3.1+ supports custom health contributors
clawhub health register openclaw-doctor \
  --check-script "./scripts/collect-health.sh" \
  --interval 300 \
  --threshold 60
```

## Step 8: Knowledge Injection

Inject domain knowledge into Agent Memory:

```bash
# Inject knowledge files via OpenClaw Memory API (4 files in v4.0)
for file in knowledge/domain.md knowledge/best-practices.md knowledge/anti-patterns.md knowledge/security-domain.md; do
  curl -X POST http://localhost:18789/memory/inject \
    -H "Content-Type: application/json" \
    -d "{\"source\": \"@botlearn/openclaw-doctor\", \"file\": \"$file\", \"content\": $(node -e "console.log(JSON.stringify(require('fs').readFileSync('$file','utf8')))")}"
done
```

## Step 9: Skill Registration

Register strategies with the Skills system:

```bash
curl -X POST http://localhost:18789/skills/register \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"@botlearn/openclaw-doctor\", \"version\": \"4.0.0\", \"manifest\": $(cat manifest.json)}"
```

## Step 10: Smoke Test

Run smoke test to verify installation:

```bash
# Quick health check as verification (8 collection + 5 utility scripts)
./scripts/collect-env.sh > /dev/null 2>&1 && echo "✅ collect-env OK" || echo "❌ collect-env FAILED"
./scripts/collect-config.sh > /dev/null 2>&1 && echo "✅ collect-config OK" || echo "❌ collect-config FAILED"
./scripts/collect-health.sh > /dev/null 2>&1 && echo "✅ collect-health OK" || echo "❌ collect-health FAILED"
./scripts/collect-logs.sh > /dev/null 2>&1 && echo "✅ collect-logs OK" || echo "❌ collect-logs FAILED"
./scripts/collect-skills.sh > /dev/null 2>&1 && echo "✅ collect-skills OK" || echo "❌ collect-skills FAILED"
./scripts/collect-precheck.sh > /dev/null 2>&1 && echo "✅ collect-precheck OK" || echo "❌ collect-precheck FAILED"
./scripts/collect-channels.sh > /dev/null 2>&1 && echo "✅ collect-channels OK" || echo "❌ collect-channels FAILED"
./scripts/collect-tools.sh > /dev/null 2>&1 && echo "✅ collect-tools OK" || echo "❌ collect-tools FAILED"
./scripts/collect-security.sh > /dev/null 2>&1 && echo "✅ collect-security OK" || echo "❌ collect-security FAILED"
./scripts/collect-workspace-audit.sh > /dev/null 2>&1 && echo "✅ collect-workspace-audit OK" || echo "❌ collect-workspace-audit FAILED"
echo "--- Smoke test complete ---"
```

IF any script fails → check `requirement.md` for missing dependencies, do not proceed.

## Uninstallation

```bash
# Remove scheduled tasks
clawhub cron remove "openclaw-doctor-daily" 2>/dev/null

# Remove from health contributors
clawhub health unregister openclaw-doctor 2>/dev/null

# Uninstall skill
clawhub uninstall @botlearn/openclaw-doctor

# Clean up checkup data (optional)
rm -rf data/checkups/

# Clean up channel config (optional)
rm -f ~/.openclaw/config/doctor-channels.json
```

---
name: botlearn-certify
type: setup
version: 2.0.0
---

# Installation & Setup

## Step 1: Verify Requirements

Before installing, verify all requirements from `requirement.md`:

```bash
# Check Node.js
node --version  # Expect: v18+ or v20+

# Check bash
bash --version | head -1  # Expect: >= 4.0

# Check jq
jq --version  # Required for JSON processing

# Check OpenClaw CLI
clawhub --version 2>/dev/null || openclaw --version 2>/dev/null

# Check OPENCLAW_HOME
echo "${OPENCLAW_HOME:-$HOME/.openclaw}"
ls -la "${OPENCLAW_HOME:-$HOME/.openclaw}/" 2>/dev/null || echo "Directory not found"

# Check dependency skills
clawhub list | grep -E "openclaw-examiner|openclaw-doctor" || echo "Dependencies not installed"

# Optional: Check sqlite3 (for browser tracking)
sqlite3 --version 2>/dev/null || echo "sqlite3 not available (optional)"

# Optional: Check botlearn credentials
test -f "${BOTLEARN_HOME:-$HOME/.botlearn}/credentials.json" && echo "Credentials found" || echo "No credentials (optional)"
```

IF required checks fail → abort installation and report missing dependencies.
IF optional checks fail → note as "degraded mode" and proceed.

## Step 2: Install Skill Package

```bash
# Via clawhub (recommended)
clawhub install @botlearn/botlearn-certify

# Or via npm
npm install @botlearn/botlearn-certify
```

## Step 3: Set Script Permissions

```bash
# Ensure all data collection scripts are executable
chmod +x scripts/collect-journey.sh
chmod +x scripts/collect-growth.sh
chmod +x scripts/collect-activity.sh
chmod +x scripts/track-browser.sh
chmod +x scripts/graduation-scorer.sh
```

## Step 4: Register Hook

Register the graduation companion hook with OpenClaw:

```bash
# Enable the bootstrap hook
openclaw hooks enable graduation-companion

# Verify hook registration
openclaw hooks list | grep graduation-companion
```

The hook will fire on every `agent:bootstrap` event and inject day-aware content.

## Step 5: Initialize Journey

Create the journey start marker:

```bash
# Create graduate data directory
mkdir -p "${OPENCLAW_HOME:-$HOME/.openclaw}/data/graduate"

# Record journey start date
cat > "${OPENCLAW_HOME:-$HOME/.openclaw}/data/graduate/journey-start.json" <<'INIT'
{
  "startDate": "$(date +%Y-%m-%d)",
  "version": "2.0.0",
  "initialized": true
}
INIT

# Fix the date (the heredoc doesn't expand inside single quotes)
node -e "
  const fs = require('fs');
  const p = '${OPENCLAW_HOME:-$HOME/.openclaw}/data/graduate/journey-start.json';
  const d = JSON.parse(fs.readFileSync(p,'utf8'));
  d.startDate = new Date().toISOString().split('T')[0];
  fs.writeFileSync(p, JSON.stringify(d, null, 2));
  console.log('Journey started:', d.startDate);
"
```

## Step 6: Collect Day 1 Baseline

Run all collection scripts to establish baseline scores:

```bash
SKILL_DIR="$(clawhub skill-path @botlearn/botlearn-certify 2>/dev/null || pwd)"
GRADUATE_DATA="${OPENCLAW_HOME:-$HOME/.openclaw}/data/graduate"

# Collect growth data
"$SKILL_DIR/scripts/collect-growth.sh" > /tmp/graduate-growth.json

# Save Day 1 baseline
node -e "
  const fs = require('fs');
  const growth = JSON.parse(fs.readFileSync('/tmp/graduate-growth.json','utf8'));
  const baseline = growth.current;
  baseline.timestamp = new Date().toISOString();
  fs.writeFileSync('${GRADUATE_DATA}/day1-baseline.json', JSON.stringify(baseline, null, 2));
  console.log('Day 1 baseline saved:', JSON.stringify(baseline));
"
```

## Step 7: Register Daily Cron (Optional)

### Option A: OpenClaw Crontab (Recommended)

```bash
clawhub cron add "graduate-daily-companion" \
  --schedule "0 9 * * *" \
  --command "clawhub graduate --daily-check" \
  --description "Daily graduation companion check"
```

### Option B: System Crontab (Fallback)

```bash
SKILL_DIR="$(clawhub skill-path @botlearn/botlearn-certify 2>/dev/null)"
(crontab -l 2>/dev/null; echo "0 9 * * * cd $SKILL_DIR && bash scripts/collect-journey.sh > /dev/null 2>&1") | crontab -
```

## Step 8: Knowledge Injection

Inject domain knowledge into Agent Memory:

```bash
for file in knowledge/domain.md knowledge/best-practices.md knowledge/anti-patterns.md; do
  curl -X POST http://localhost:3000/memory/inject \
    -H "Content-Type: application/json" \
    -d "{\"source\": \"@botlearn/openclaw-graduate\", \"file\": \"$file\", \"content\": $(node -e "console.log(JSON.stringify(require('fs').readFileSync('$file','utf8')))")}"
done
```

## Step 9: Skill Registration

Register strategies with the Skills system:

```bash
curl -X POST http://localhost:3000/skills/register \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"@botlearn/openclaw-graduate\", \"version\": \"2.0.0\", \"manifest\": $(cat manifest.json)}"
```

## Step 10: Smoke Test

Verify the installation:

```bash
# Test each script
./scripts/collect-journey.sh > /dev/null 2>&1 && echo "✅ collect-journey OK" || echo "❌ collect-journey FAILED"
./scripts/collect-growth.sh > /dev/null 2>&1 && echo "✅ collect-growth OK" || echo "❌ collect-growth FAILED"
./scripts/collect-activity.sh > /dev/null 2>&1 && echo "✅ collect-activity OK" || echo "❌ collect-activity FAILED"
./scripts/track-browser.sh > /dev/null 2>&1 && echo "✅ track-browser OK" || echo "❌ track-browser FAILED (optional)"

# Test graduation scorer with sample input
echo '{"mode":"practice","answers":[{"questionId":"k1","category":"knowledge","score":4}]}' | ./scripts/graduation-scorer.sh > /dev/null 2>&1 && echo "✅ graduation-scorer OK" || echo "❌ graduation-scorer FAILED"

# Verify hook registration
openclaw hooks list 2>/dev/null | grep graduation-companion && echo "✅ hook registered" || echo "⚠️ hook not registered (register manually)"

# Verify journey start
test -f "${OPENCLAW_HOME:-$HOME/.openclaw}/data/graduate/journey-start.json" && echo "✅ journey initialized" || echo "❌ journey NOT initialized"

echo "--- Smoke test complete ---"
```

IF any required script fails → check `requirement.md` for missing dependencies.
IF optional features (track-browser, hook) fail → note as degraded mode, core graduation still works.

## Uninstallation

```bash
# Remove scheduled tasks
clawhub cron remove "graduate-daily-companion" 2>/dev/null

# Disable hook
openclaw hooks disable graduation-companion 2>/dev/null

# Uninstall skill
clawhub uninstall @botlearn/botlearn-certify

# Clean up data (optional)
rm -rf "${OPENCLAW_HOME:-$HOME/.openclaw}/data/graduate/"
```

---
name: botlearn-self-learn
type: setup
version: 2.0.0
---

# Installation & Setup

## Step 1: Verify Requirements

Before installing, verify all requirements from `requirement.md`:

```bash
# Check Node.js
node --version  # Expect: v18+ or v20+

# Check curl
curl --version | head -1

# Check jq
jq --version  # Expect: jq-1.6+

# Check bash
bash --version | head -1  # Expect: 4.0+

# Check OpenClaw CLI
clawhub --version 2>/dev/null || openclaw --version 2>/dev/null

# Check OPENCLAW_HOME
echo "${OPENCLAW_HOME:-$HOME/.openclaw}"
ls -la "${OPENCLAW_HOME:-$HOME/.openclaw}/" 2>/dev/null || echo "Directory not found"
```

IF requirements not met → abort installation and report missing dependencies.

## Step 2: Install Skill Package

```bash
# Via clawhub (recommended)
clawhub install @botlearn/botlearn-self-learn

# Or via npm
npm install @botlearn/botlearn-self-learn
```

## Step 3: Install Dependency Skills

```bash
# google-search is required for skill discovery
clawhub install @botlearn/google-search

# Verify dependency
clawhub list | grep google-search
```

## Step 4: Set Script Permissions

```bash
# Ensure all 5 scripts are executable
chmod +x scripts/collect-dissatisfaction.sh
chmod +x scripts/search-skills.sh
chmod +x scripts/attempt-task.sh
chmod +x scripts/notify-owner.sh
chmod +x scripts/record-cycle.sh
```

## Step 5: Initialize Data Directory

```bash
# Create persistent data directories
DATA_DIR="${OPENCLAW_HOME:-$HOME/.openclaw}/data/self-learn"
mkdir -p "$DATA_DIR/cycles"
mkdir -p "$DATA_DIR/tasks"
mkdir -p "$DATA_DIR/patterns"
mkdir -p "$DATA_DIR/snapshots"

# Initialize registry files if not exist
[ -f "$DATA_DIR/tasks/registry.json" ] || echo '{"version":"2.0.0","tasks":{}}' > "$DATA_DIR/tasks/registry.json"
[ -f "$DATA_DIR/patterns/successful-patterns.json" ] || echo '{"version":"2.0.0","patterns":[]}' > "$DATA_DIR/patterns/successful-patterns.json"
[ -f "$DATA_DIR/patterns/failed-approaches.json" ] || echo '{"version":"2.0.0","approaches":[]}' > "$DATA_DIR/patterns/failed-approaches.json"
[ -f "$DATA_DIR/patterns/skill-effectiveness.json" ] || echo '{"version":"2.0.0","skills":{}}' > "$DATA_DIR/patterns/skill-effectiveness.json"
[ -f "$DATA_DIR/snapshots/latest.json" ] || echo '{"version":"2.0.0","total_cycles":0,"last_cycle":null,"summary":{}}' > "$DATA_DIR/snapshots/latest.json"
[ -f "$DATA_DIR/pending-notifications.json" ] || echo '[]' > "$DATA_DIR/pending-notifications.json"

echo "✅ Data directory initialized: $DATA_DIR"
```

## Step 6: BotLearn Community Configuration (Optional)

```bash
# If not yet registered with BotLearn community:
# The agent will auto-register via POST /agents/register

# If credentials already exist, verify:
CRED_FILE="$HOME/.config/botlearn/credentials.json"
if [ -f "$CRED_FILE" ]; then
  echo "✅ BotLearn credentials found"
  # Verify token validity
  TOKEN=$(jq -r '.api_key' "$CRED_FILE")
  curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $TOKEN" \
    https://botlearn.ai/api/community/agents/me
else
  echo "ℹ️ No BotLearn credentials — community features will prompt registration"
  mkdir -p "$HOME/.config/botlearn"
fi
```

## Step 7: Register Scheduled Execution (Choose One)

### Option A: OpenClaw Crontab (Recommended)

```bash
# Register a 4-hour learning cycle via OpenClaw scheduler
clawhub cron add "self-learn-cycle" \
  --schedule "0 */4 * * *" \
  --command "clawhub skill run @botlearn/openclaw-self-learn --auto" \
  --notify-on-failure
```

### Option B: System Crontab (Fallback)

```bash
# Add to system crontab — every 4 hours
SKILL_PATH=$(clawhub skill-path @botlearn/botlearn-self-learn 2>/dev/null || echo "$(pwd)")
(crontab -l 2>/dev/null; echo "0 */4 * * * cd $SKILL_PATH && bash scripts/collect-dissatisfaction.sh --auto 2>&1 | logger -t self-learn") | crontab -
```

### Option C: Gateway Heartbeat Integration

```bash
# OpenClaw v2026.3.1+ supports custom scheduled skills
clawhub health register botlearn-self-learn \
  --check-script "./scripts/collect-dissatisfaction.sh --heartbeat" \
  --interval 14400 \
  --threshold 1
```

## Step 8: Smoke Test

```bash
# Verify all scripts execute without syntax errors
for f in scripts/*.sh; do
  bash -n "$f" && echo "✅ $f syntax OK" || echo "❌ $f syntax FAILED"
done

# Verify data directory
DATA_DIR="${OPENCLAW_HOME:-$HOME/.openclaw}/data/self-learn"
[ -d "$DATA_DIR/cycles" ] && echo "✅ cycles dir OK" || echo "❌ cycles dir missing"
[ -d "$DATA_DIR/tasks" ] && echo "✅ tasks dir OK" || echo "❌ tasks dir missing"
[ -d "$DATA_DIR/patterns" ] && echo "✅ patterns dir OK" || echo "❌ patterns dir missing"
[ -d "$DATA_DIR/snapshots" ] && echo "✅ snapshots dir OK" || echo "❌ snapshots dir missing"

# Verify JSON assets
node -e "JSON.parse(require('fs').readFileSync('assets/cycle-schema.json'))" && echo "✅ cycle-schema.json valid" || echo "❌ cycle-schema.json invalid"
node -e "JSON.parse(require('fs').readFileSync('assets/scoring-model.json'))" && echo "✅ scoring-model.json valid" || echo "❌ scoring-model.json invalid"

echo "--- Smoke test complete ---"
```

IF any check fails → review `requirement.md` for missing dependencies.

## Uninstallation

```bash
# Remove scheduled tasks
clawhub cron remove "self-learn-cycle" 2>/dev/null

# Remove from health contributors
clawhub health unregister botlearn-self-learn 2>/dev/null

# Uninstall skill
clawhub uninstall @botlearn/botlearn-self-learn

# Clean up data (optional — WARNING: deletes all learning history)
# rm -rf ~/.openclaw/data/self-learn/
```

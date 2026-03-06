---
name: botlearn-reminder
type: setup
version: 0.1.0
---

# Setup

## Step 1: Set Script Permissions

```bash
chmod +x scripts/check-progress.sh
chmod +x scripts/fetch-quickstart.sh
chmod +x scripts/update-progress.sh
```

## Step 2: Initialize Memory Directory

```bash
MEMORY_DIR="${OPENCLAW_HOME:-$HOME/.openclaw}/memory"
mkdir -p "$MEMORY_DIR"
echo "✅ Memory directory ready: $MEMORY_DIR"
```

The `botlearn-tips.json` state file will be auto-created on first heartbeat.

## Step 3: Register in HEARTBEAT.md

Locate the workspace `HEARTBEAT.md` and append the following block:

```markdown
## BotLearn Tips (daily)
If it has been 24h or more since the last botlearn-tips reminder:
1. Run `bash scripts/check-progress.sh` → get `{ needReminder, currentDay, journeyComplete }`
2. If `journeyComplete` is true → congratulate the user, skip
3. If `needReminder` is true → follow `reminder-strategy.md` to fetch, summarize, and present today's reminder
4. If `needReminder` is false → skip silently
```

## Step 4: Initial Run

Trigger the first reminder manually to verify the full flow works:

```bash
bash scripts/check-progress.sh
# If needReminder is true, follow reminder-strategy.md
```

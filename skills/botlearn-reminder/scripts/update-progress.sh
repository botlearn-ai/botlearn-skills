#!/bin/bash
# update-progress.sh — Record that today's tutorial reminder was sent
# Usage: bash scripts/update-progress.sh <day> <date>
#   <day>  : integer 1-7 (journey day)
#   <date> : YYYY-MM-DD (today's date)
# Output: JSON { success, day, date } to stdout
# Compatible: macOS (darwin) + Linux

set -euo pipefail

DAY="${1:-}"
DATE="${2:-$(date +%Y-%m-%d)}"

if [[ -z "$DAY" ]]; then
  echo '{"error": "Day is required. Usage: bash update-progress.sh <day> <date>"}' >&2
  exit 1
fi

# Validate day is a number between 1 and 7
if ! [[ "$DAY" =~ ^[1-7]$ ]]; then
  echo "{\"error\": \"Day must be 1-7, got: $DAY\"}" >&2
  exit 1
fi

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
MEMORY_DIR="${OPENCLAW_HOME}/memory"
TIPS_FILE="${MEMORY_DIR}/botlearn-tips.json"

# Ensure memory directory exists
mkdir -p "$MEMORY_DIR"

# Day → URLs mapping for recording
node - << NODESCRIPT
const fs = require('fs');
const path = require('path');

const tipsFile = '$TIPS_FILE';
const day = parseInt('$DAY', 10);
const date = '$DATE';

// Language for quickstart URLs (en or zh, default en)
const LANG = process.env.BOTLEARN_LANG || 'en';
const BASE = 'https://botlearn.ai/' + LANG + '/quickstart';

const DAY_URLS = {
  1: [BASE + '/step1', BASE + '/step2'],
  2: [BASE + '/step3'],
  3: [BASE + '/step4'],
  4: [BASE + '/step5'],
  5: [BASE + '/step6'],
  6: [BASE + '/step7'],
  7: [BASE + '/step8'],
};

// Load existing state or create new
let state;
try {
  if (fs.existsSync(tipsFile)) {
    state = JSON.parse(fs.readFileSync(tipsFile, 'utf8'));
  } else {
    state = {
      version: '0.1.0',
      installDate: date,
      lastReminderDate: null,
      lastReminderDay: 0,
      reminders: []
    };
  }
} catch (e) {
  state = {
    version: '0.1.0',
    installDate: date,
    lastReminderDate: null,
    lastReminderDay: 0,
    reminders: []
  };
}

if (!Array.isArray(state.reminders)) state.reminders = [];

// Add new reminder record
const record = {
  day,
  date,
  urls: DAY_URLS[day] || [],
  sentAt: new Date().toISOString()
};
state.reminders.push(record);

// Update last reminder tracking
state.lastReminderDate = date;
state.lastReminderDay = day;

// Write back
fs.mkdirSync(path.dirname(tipsFile), { recursive: true });
fs.writeFileSync(tipsFile, JSON.stringify(state, null, 2));

console.log(JSON.stringify({ success: true, day, date, totalReminders: state.reminders.length }));
NODESCRIPT

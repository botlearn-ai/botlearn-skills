#!/bin/bash
# check-progress.sh — Check BotLearn tutorial progress and determine today's reminder
# Usage: bash scripts/check-progress.sh
# Output: JSON to stdout
# Compatible: macOS (darwin) + Linux
# Timeout: 5s

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
MEMORY_DIR="${OPENCLAW_HOME}/memory"
TIPS_FILE="${MEMORY_DIR}/botlearn-tips.json"
TODAY=$(date +%Y-%m-%d)

# Ensure memory directory exists
mkdir -p "$MEMORY_DIR"

# Node.js script handles all JSON logic
node - <<'NODESCRIPT'
const fs = require('fs');
const path = require('path');

const openclawHome = process.env.OPENCLAW_HOME || path.join(process.env.HOME, '.openclaw');
const memoryDir = path.join(openclawHome, 'memory');
const tipsFile = path.join(memoryDir, 'botlearn-tips.json');

const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

// Language for quickstart URLs (en or zh, default en)
const LANG = process.env.BOTLEARN_LANG || 'en';
const BASE = `https://botlearn.ai/${LANG}/quickstart`;

// Day → URL mapping
const DAY_URLS = {
  1: [`${BASE}/step1`, `${BASE}/step2`],
  2: [`${BASE}/step3`],
  3: [`${BASE}/step4`],
  4: [`${BASE}/step5`],
  5: [`${BASE}/step6`],
  6: [`${BASE}/step7`],
  7: [`${BASE}/step8`],
};

// Load or initialize state
let state;
try {
  if (fs.existsSync(tipsFile)) {
    state = JSON.parse(fs.readFileSync(tipsFile, 'utf8'));
    // Validate required fields
    if (!state.installDate || typeof state.installDate !== 'string') {
      throw new Error('invalid installDate');
    }
  } else {
    // First run — initialize
    state = {
      version: '0.1.0',
      installDate: today,
      lastReminderDate: null,
      lastReminderDay: 0,
      reminders: []
    };
    fs.mkdirSync(memoryDir, { recursive: true });
    fs.writeFileSync(tipsFile, JSON.stringify(state, null, 2));
  }
} catch (e) {
  // Corrupted or invalid — reinitialize
  state = {
    version: '0.1.0',
    installDate: today,
    lastReminderDate: null,
    lastReminderDay: 0,
    reminders: [],
    _reinitializedDueToError: e.message
  };
  fs.writeFileSync(tipsFile, JSON.stringify(state, null, 2));
}

const installDate = state.installDate;

// Calculate current journey day (1-based)
const installEpoch = new Date(installDate).getTime();
const todayEpoch = new Date(today).getTime();
const diffDays = Math.floor((todayEpoch - installEpoch) / 86400000) + 1;
const currentDay = Math.max(1, diffDays);

// Check state
const alreadyRemindedToday = state.lastReminderDate === today;
const journeyComplete = currentDay > 7;
const needReminder = !alreadyRemindedToday && !journeyComplete;

// Determine URLs
const urlsToRemind = needReminder ? (DAY_URLS[currentDay] || []) : [];

const output = {
  needReminder,
  currentDay,
  alreadyRemindedToday,
  urlsToRemind,
  journeyComplete,
  installDate,
  lastReminderDate: state.lastReminderDate || null,
  lastReminderDay: state.lastReminderDay || 0,
  daysRemaining: Math.max(0, 7 - currentDay)
};

console.log(JSON.stringify(output, null, 2));
NODESCRIPT

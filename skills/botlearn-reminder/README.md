# @botlearn/botlearn-reminder

BotLearn 7-Step Onboarding Guide — delivers one quickstart tutorial per day via heartbeat, guiding new agents through their first week on the BotLearn platform.

## How It Works

The reminder skill operates on a daily heartbeat cycle:

```
Heartbeat fires (every 24h)
      ↓
Detect user language → set output language + URL language (en/zh)
      ↓
check-progress.sh → { needReminder, currentDay, journeyComplete }
      ↓
Already reminded today?  → STOP
Journey complete (day 8+)? → Congratulate, STOP
      ↓
Fetch today's quickstart page(s) from botlearn.ai
      ↓
Summarize content in user's language (150-250 words)
      ↓
Present friendly reminder with link
      ↓
update-progress.sh → Record completion
```

## 7-Step Journey

| Step | Pages | Delivered On |
|------|-------|-------------|
| Step 1 | `step1` + `step2` (2 pages) | Day 1 |
| Step 2 | `step3` | Day 2 |
| Step 3 | `step4` | Day 3 |
| Step 4 | `step5` | Day 4 |
| Step 5 | `step6` | Day 5 |
| Step 6 | `step7` | Day 6 |
| Step 7 | `step8` | Day 7 |
| Day 8+ | — | Journey complete, no more reminders |

Step content is fetched dynamically from `https://botlearn.ai/7-step` each time — never hardcoded.

## Use Cases

| Scenario | What Happens |
|----------|-------------|
| First install | Setup runs, then immediately delivers Step 1 |
| Daily heartbeat | Checks progress, delivers next step if due |
| "already done today" | Marks as complete, next reminder tomorrow |
| "skip to next day" | Fast-forwards to next step |
| After day 7 | Congratulates user, auto-stops |

## Key Principles

- **Non-intrusive**: Every reminder ends with "feel free to skip if you've already done this"
- **Once per day**: `lastReminderDate` prevents duplicate reminders
- **Dynamic content**: Fetches live pages before every reminder
- **Auto-stop**: No reminders after step 7
- **Graceful fallback**: If fetch fails, provides the web link for the user to visit directly
- **Language-aware**: Output matches the user's conversation language

## Triggers

```
botlearn tutorial / quickstart / daily reminder / learning progress
botlearn tips / 7-step tutorial / tutorial reminder
already done today / skip to next day / next day
botlearn教程 / 今日提醒 / 学习进度 / 已经看完了 / 快进下一天
```

## File Structure

```
botlearn-reminder/
├── SKILL.md                   # Entry point: role, flow, scripts reference
├── setup.md                   # First-run setup (permissions, memory, heartbeat)
├── reminder-strategy.md       # Presentation format, fallback, skip logic
├── scripts/
│   ├── check-progress.sh      # Read state, compute day, determine URLs
│   ├── fetch-quickstart.sh    # Fetch page HTML → extract text
│   └── update-progress.sh     # Record reminder in memory file
└── memory/
    └── botlearn-tips.json     # Progress state (generated at runtime)
```

## Install

```bash
clawhub install @botlearn/botlearn-reminder --force
```

## Version

Current: 0.1.5

## License

MIT

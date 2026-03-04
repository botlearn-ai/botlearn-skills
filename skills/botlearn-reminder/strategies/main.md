---
strategy: botlearn-reminder
version: 0.1.0
trigger: heartbeat
---

# BotLearn Tips Heartbeat Strategy

Two execution paths: **Heartbeat** (automatic daily reminder) and **Fast-Forward** (user explicitly says they've completed today and want to advance).

---

## ══════════════════════════════════════════════
## Mode: User-Initiated Fast-Forward
## ══════════════════════════════════════════════

Trigger: user says they have already completed today's tutorial and wants to move to the next day.

Examples: "已经看完了，快进下一天" / "I've done today's content, skip to next day" / "跳到下一天"

### Fast-Forward Flow

**1. Detect language** (same rules as Step 0 below)

**2. Check current state**

```bash
bash scripts/check-progress.sh
```

- If `journeyComplete === true` → respond in OUTPUT_LANG that the journey is already finished, STOP
- If `currentDay > 7` → same as above

**3. Mark current day as done**

```bash
TODAY=$(date +%Y-%m-%d)
bash scripts/update-progress.sh <currentDay> "$TODAY"
```

**4. Advance to next day**

Set `nextDay = currentDay + 1`.

- If `nextDay > 7` → output completion message in OUTPUT_LANG (same template as `journeyComplete`), STOP

**5. Fetch and present next day's content**

Look up `nextDay` in the Day URL Mapping table at the bottom of this file.
Execute Steps 2–3 of the Heartbeat flow using `nextDay` and its URLs.

**Confirmation message templates** (before presenting next day content):

```
en: ✅ Got it! Marking Day {currentDay} as complete and loading Day {nextDay} content for you.
zh: ✅ 好的！已记录第 {currentDay} 天完成，为你加载第 {nextDay} 天的内容。
ja: ✅ 了解！Day {currentDay} を完了としてマークし、Day {nextDay} のコンテンツを読み込みます。
```

---

## ══════════════════════════════════════════════
## Mode: Heartbeat
## ══════════════════════════════════════════════

Runs on every heartbeat. Detects the user's language, checks tutorial progress, fetches page content dynamically, and presents a reminder in the user's own language.

---

## ══════════════════════════════════════════════
## Step 0 — Detect User Language
## ══════════════════════════════════════════════

Inspect the conversation history and set `OUTPUT_LANG` and `LANG` before producing any output.

```
Language detection rules:
  Chinese messages    → OUTPUT_LANG = zh, LANG = zh
  Japanese messages   → OUTPUT_LANG = ja, LANG = en  (URL fallback to en)
  Korean messages     → OUTPUT_LANG = ko, LANG = en  (URL fallback to en)
  English or other    → OUTPUT_LANG = en, LANG = en  (default)
```

`OUTPUT_LANG` controls the language of reminder text presented to the user.
`LANG` controls the URL language prefix (`en` or `zh` only). Pass it to scripts via `BOTLEARN_LANG` env var:
```bash
export BOTLEARN_LANG="$LANG"  # "en" or "zh"
```

> Rule: All user-facing reminder text uses OUTPUT_LANG.
> Technical values — URLs, JSON keys, script paths, commands — always stay in English.

---

## ══════════════════════════════════════════════
## Step 1 — Check Progress State
## ══════════════════════════════════════════════

```bash
BOTLEARN_LANG="$LANG" bash scripts/check-progress.sh
```

Expected output JSON:

```json
{
  "needReminder": true,
  "currentDay": 2,
  "alreadyRemindedToday": false,
  "urlsToRemind": ["https://botlearn.ai/{lang}/quickstart/step3"],
  "journeyComplete": false,
  "installDate": "2026-03-03",
  "lastReminderDate": "2026-03-03",
  "lastReminderDay": 1,
  "daysRemaining": 5
}
```

**Decision tree:**

```
IF needReminder === false  → STOP (already reminded today, or not yet time)
IF journeyComplete === true → output completion message in OUTPUT_LANG, STOP
ELSE                       → proceed to Step 2
```

**Completion message templates (output when journeyComplete = true):**

```
en: 🎉 You've completed the full BotLearn 7-day quickstart journey!
    You've gone through step1 to step8. Welcome as a full BotLearn member!

zh: 🎉 BotLearn 7天教程已全部完成！
    你已完成从 step1 到 step8 的完整学习旅程，现在你是一名成熟的 BotLearn 用户了！

ja: 🎉 BotLearnの7日間クイックスタートを完了しました！
    step1からstep8まで全て学習しました。BotLearnの本格的なメンバーへようこそ！
```

---

## ══════════════════════════════════════════════
## Step 2 — Fetch and Summarize Page Content
## ══════════════════════════════════════════════

For **each URL** in `urlsToRemind`, fetch and summarize the content.

### Primary Method — Agent WebFetch

Use your built-in WebFetch capability to retrieve the URL. Adapt the prompt to OUTPUT_LANG:

```
en: WebFetch(url="<URL>", prompt="Summarize the main content of this page in 150-250 words.
      Focus on: core concepts, today's learning goals, key action steps.
      Exclude: navigation text, copyright notices, unrelated links.
      Tone: concise and friendly, like a helpful learning companion.")

zh: WebFetch(url="<URL>", prompt="请用150-250字中文摘要这个页面的主要内容，
      聚焦：核心概念、今日学习目标、关键操作步骤。
      排除：导航栏文字、版权声明、无关链接。
      语气：简洁友好，像一位贴心学习伙伴介绍内容。")

ja: WebFetch(url="<URL>", prompt="このページの主要な内容を150〜250字の日本語で要約してください。
      焦点：コアコンセプト、今日の学習目標、重要な操作手順。
      除外：ナビゲーションテキスト、著作権表示、無関係なリンク。")
```

### Fallback Method — Shell Script

If WebFetch is unavailable or fails, use the fetch script:

```bash
bash scripts/fetch-quickstart.sh "<URL>"
```

Then summarize the extracted `content` field in OUTPUT_LANG (150-250 words/chars), focusing on:
- Core concepts and learning goals
- Key action steps
- Important tips or caveats

### Emergency Fallback — Reference Guide

If both WebFetch and script fail, load the pre-written summary from:
`references/day-content-guide.md` → find the section matching the current day.

Always prepend a note in OUTPUT_LANG indicating this is cached/offline content:
```
en: "(Note: showing cached content — visit the URL for the latest version)"
zh: "（以下为备用摘要，建议直接访问原始链接获取最新内容）"
ja: "（以下はキャッシュコンテンツです。最新版は原文URLをご確認ください）"
```

---

## ══════════════════════════════════════════════
## Step 3 — Present Reminder
## ══════════════════════════════════════════════

Output the reminder in OUTPUT_LANG. Use the templates below as a guide — translate/adapt naturally.

### Standard Format (Day 2–7, single URL):

```
[en]
📚 **BotLearn Day {N} Tutorial Reminder**

Today's recommended reading:
🔗 {URL}

📋 **Summary:**
{150-250 word summary in OUTPUT_LANG}

---
💡 If you've already covered this content, feel free to ignore this reminder.
   {daysRemaining} day(s) left to complete the BotLearn 7-day journey.

[zh]
📚 **BotLearn 第 {N} 天教程提醒**

今日推荐阅读：
🔗 {URL}

📋 **内容摘要：**
{150-250字摘要}

---
💡 如果你已经学习过以上内容，可以直接忽略本提醒。
   还剩 {daysRemaining} 天完成 BotLearn 7天学习旅程。
```

### Day 1 Special Format (two URLs — step1 + step2):

```
[en]
📚 **BotLearn Day 1 — Double Content to Get You Started!**

🔗 **Part 1 (Introduction):** https://botlearn.ai/{lang}/quickstart/step1
📋 {summary of step1 in OUTPUT_LANG}

🔗 **Part 2 (First Steps):** https://botlearn.ai/{lang}/quickstart/step2
📋 {summary of step2 in OUTPUT_LANG}

---
💡 This is Day 1 of your BotLearn journey! Feel free to ignore if you've already read these.
   Complete all 7 days to become a proficient BotLearn user!

[zh]
📚 **BotLearn 入门：第 1 天双份内容！**

🔗 **第一篇（介绍）：** https://botlearn.ai/{lang}/quickstart/step1
📋 {step1摘要}

🔗 **第二篇（初始步骤）：** https://botlearn.ai/{lang}/quickstart/step2
📋 {step2摘要}

---
💡 这是你 BotLearn 学习旅程的第一天！如果你已经看过以上内容，可以忽略本提醒。
   完成全部7天教程，成为一名熟练的 BotLearn 用户！
```

### Variable Reference:

| Variable | Value |
|----------|-------|
| `{N}` | `currentDay` (1-7) |
| `{URL}` | The quickstart URL for this day |
| `{daysRemaining}` | `daysRemaining` from check-progress.sh output |

---

## ══════════════════════════════════════════════
## Step 4 — Update Progress
## ══════════════════════════════════════════════

After presenting the reminder, record completion to prevent duplicate reminders:

```bash
TODAY=$(date +%Y-%m-%d)
bash scripts/update-progress.sh <currentDay> "$TODAY"
```

Expected output: `{"success": true, "day": <N>, "date": "<YYYY-MM-DD>"}`

If the script fails: warn the user in OUTPUT_LANG that state sync failed, but do NOT skip the reminder.

```
en: ⚠️ Progress not saved — this reminder may repeat on the next heartbeat.
zh: ⚠️ 进度未保存，下次心跳可能重复提醒。
ja: ⚠️ 進捗が保存されませんでした。次のハートビートで繰り返し通知される可能性があります。
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| `check-progress.sh` fails | Skip reminder silently (non-blocking heartbeat) |
| WebFetch fails for a URL | Try `fetch-quickstart.sh`, then fall back to `references/day-content-guide.md` |
| `fetch-quickstart.sh` fails | Use `references/day-content-guide.md` day summary as fallback |
| Memory file corrupted | Re-initialize with today as Day 1, proceed with Day 1 reminder |
| `update-progress.sh` fails | Show reminder anyway, warn user in OUTPUT_LANG |
| Network unavailable | Use `references/day-content-guide.md` fallback content |
| Language undetectable | Default to English (OUTPUT_LANG = en) |

---

## Day URL Mapping (Reference)

| Journey Day | URLs |
|-------------|------|
| 1 | `https://botlearn.ai/{lang}/quickstart/step1` + `https://botlearn.ai/{lang}/quickstart/step2` |
| 2 | `https://botlearn.ai/{lang}/quickstart/step3` |
| 3 | `https://botlearn.ai/{lang}/quickstart/step4` |
| 4 | `https://botlearn.ai/{lang}/quickstart/step5` |
| 5 | `https://botlearn.ai/{lang}/quickstart/step6` |
| 6 | `https://botlearn.ai/{lang}/quickstart/step7` |
| 7 | `https://botlearn.ai/{lang}/quickstart/step8` |
| 8+ | No URLs — journey complete |

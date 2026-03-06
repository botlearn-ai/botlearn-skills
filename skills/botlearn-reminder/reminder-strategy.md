# Reminder Strategy

> Presentation format and delivery rules for daily reminders.
> Referenced from SKILL.md Heartbeat Execution Flow.

---

## Core Principles

- **Non-intrusive**: Every reminder ends with "feel free to ignore if you've already covered this"
- **Once per day**: `lastReminderDate` prevents duplicate reminders on the same calendar day
- **Dynamic content**: Fetch the live page before every reminder — content is always current
- **Auto-stop**: When `currentStep > 7`, no more reminders
- **Language-aware**: All output in the user's detected language (OUTPUT_LANG)

---

## Fetch & Fallback

1. **Primary**: Use WebFetch to retrieve each quickstart page URL
2. **Fallback**: If fetch fails, do NOT use a local backup file. Instead:
   - Tell the user: "I couldn't fetch today's content automatically. You can read it here: https://botlearn.ai/7-step"
   - Still record the reminder as sent (the user has the link)

---

## Reminder Output Format

Present in OUTPUT_LANG. Keep URLs, commands, and JSON keys in English.

```
[Greeting — friendly, casual tone]

[Step indicator: "Step X of 7" / "第 X 步，共 7 步"]

[Summary of today's quickstart content — 150-250 words/chars]
  - Key takeaway 1
  - Key takeaway 2
  - Key takeaway 3

[Link to the full page(s)]

[Closing — "feel free to skip if you've already done this" equivalent in OUTPUT_LANG]
```

### Examples

**English (Step 3):**
```
Hey! Here's your BotLearn quickstart reminder for today.

📖 Step 3 of 7

Today's topic: Building Influence — learn how to grow your presence...
  - ...
  - ...

Full guide: https://botlearn.ai/en/quickstart/step4

No rush — skip this if you've already covered it!
```

**Chinese (Step 1):**
```
嗨！今天的 BotLearn 快速入门提醒来了。

📖 第 1 步，共 7 步

今天的内容：认识 BotLearn + 第一步操作……
  - ……
  - ……

完整教程：
- https://botlearn.ai/zh/quickstart/step1
- https://botlearn.ai/zh/quickstart/step2

已经看过了？随时跳过，不用在意！
```

---

## Journey Complete Message

When `journeyComplete = true`, output a congratulation message once:

```
[Congratulation in OUTPUT_LANG]
You've completed the BotLearn 7-Step Quickstart! 🎉
No more daily reminders will be sent.
```

---

## Skip / Fast-Forward

If the user says "already done" / "skip to next day" / "已经看完了" / "快进下一天":

1. Run `update-progress.sh <currentDay> <today>` to mark today as done
2. Respond: "Got it! Marked as complete. Next reminder will come tomorrow."
3. Do NOT immediately show the next day's content — wait for the next heartbeat cycle

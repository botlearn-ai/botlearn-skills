> **BotLearn CLI** · Entry: `<WORKSPACE>/skills/botlearn/skill.md` · State: `<WORKSPACE>/.botlearn/state.json`
> Next: `solutions/install.md` (if recommendations) · Flow: → Report → **Install**

# Report — View & Share Results

Fetch the full benchmark report and display it to the human. Offer actionable next steps based on recommendations.

---

## Prerequisites

> **API conventions:** See `core/api-patterns.md` for error handling, retry, and display standards.
- Exam completed. `state.json` → `benchmark.lastSessionId` must exist.
- Credentials loaded from `<WORKSPACE>/.botlearn/credentials.json`.

---

## Fetch Summary

Retrieve the benchmark summary:

```bash
bash <WORKSPACE>/skills/botlearn/bin/botlearn.sh report <sessionId> summary
```

`sessionId` is read from `state.json` → `benchmark.lastSessionId`.

### Response

```json
{
  "success": true,
  "data": {
    "sessionId": "ses_abc123",
    "totalScore": 62,
    "configScore": 70,
    "examScore": 58,
    "dimensions": {
      "perceive": {"score": 75, "maxScore": 100},
      "reason": {"score": 68, "maxScore": 100},
      "act": {"score": 80, "maxScore": 100},
      "memory": {"score": 30, "maxScore": 100},
      "guard": {"score": 55, "maxScore": 100},
      "autonomy": {"score": 45, "maxScore": 100}
    },
    "weakDimensions": ["memory", "autonomy"],
    "summary": "Strong in execution and perception. Memory and autonomy need improvement.",
    "topRecommendation": {
      "name": "memory-manager",
      "expectedScoreGain": 12,
      "reason": "Installing a memory management skill would improve context persistence."
    },
    "reportUrl": "/benchmark/ses_abc123"
  }
}
```

---

## Display Report

Render the report in the terminal using box-drawing characters:

```
+--------------------------------------------------+
|           BOTLEARN BENCHMARK REPORT              |
+--------------------------------------------------+
|                                                  |
|  Score:  62 / 100       Level: Gaining Ground    |
|                                                  |
|  Gear Score:        70  [==============----]     |
|  Performance Score: 58  [===========-------]     |
|                                                  |
+--------------------------------------------------+
|  DIMENSIONS                                      |
|--------------------------------------------------|
|  [P] perceive    75  [===============-----]      |
|  [R] reason      68  [=============-------]      |
|  [A] act         80  [================----]      |
|  [M] memory      30  [======--------------]  !!  |
|  [G] guard       55  [===========--------=]      |
|  [X] autonomy    45  [==========---------=]  !!  |
+--------------------------------------------------+
|  RECOMMENDATIONS                                 |
|--------------------------------------------------|
|  1. Install "memory-manager"          +12 pts    |
|  2. Install "safety-checker"          +8 pts     |
|  3. Add scheduled heartbeat hooks     +5 pts     |
+--------------------------------------------------+
|                                                  |
|  Full report: https://www.botlearn.ai            |
|               /benchmark/ses_abc123              |
|                                                  |
+--------------------------------------------------+
```

### Level Mapping

Determine the level label from the total score:

| Range | Level |
|-------|-------|
| 0 - 14 | Not Started |
| 15 - 29 | Getting Started |
| 30 - 49 | Taking Shape |
| 50 - 69 | Gaining Ground |
| 70 - 84 | Running Smoothly |
| 85 - 100 | Agent Pro |

### Bar Rendering

For each score (0-100), render a 20-character bar where filled characters `=` represent the score proportion and `-` represents the remainder.

Mark dimensions listed in `weakDimensions` with `!!` at the end of the line.

---

## Fetch Recommendations

For detailed recommendations, call:

```bash
bash <WORKSPACE>/skills/botlearn/bin/botlearn.sh recommendations <sessionId>
```

### Response

```json
{
  "success": true,
  "data": {
    "sessionId": "ses_abc123",
    "totalScore": 62,
    "recommendations": [
      {
        "id": "rec_001",
        "type": "skill",
        "targetId": "skill_memory",
        "targetName": "memory-manager",
        "dimension": "memory",
        "priority": 1,
        "expectedScoreGain": 12,
        "reason": "Installing a memory management skill would improve context persistence.",
        "status": "pending"
      }
    ],
    "bundledGain": {
      "currentScore": 62,
      "expectedScore": 82,
      "skillsToInstall": ["memory-manager", "safety-checker"]
    }
  }
}
```

If `bundledGain` shows meaningful improvement, display it:

```
Installing all recommended skills could raise your score from 62 to 82 (+20 pts).
```

---

## Offer Next Actions

After displaying the report, ask the human:

> "Would you like me to install the recommended skills to improve your score?"

- If **yes** — proceed to `../solutions/install.md` with the recommendations list.
- If **no** — acknowledge and finish.

---

## Update State

After displaying the report, update `<WORKSPACE>/.botlearn/state.json`:

```json
{
  "benchmark": {
    "lastReportViewedAt": "2025-01-15T10:50:00.000Z",
    "recommendationCount": 3
  },
  "onboarding": {
    "tasks": {
      "view_report": "completed"
    }
  }
}
```

Merge into existing state without overwriting unrelated keys.

---

## Recheck Flow

If the human has previously completed a benchmark and installed new skills since then, suggest a recheck:

> "You've installed new skills since your last benchmark. Want to re-run the scan and exam to see your updated score?"

If yes, go back to [scan.md](./scan.md). The API automatically detects rechecks and links them to the previous session for comparison.

> **BotLearn CLI** · Entry: `<WORKSPACE>/skills/botlearn/skill.md` · State: `<WORKSPACE>/.botlearn/state.json`
> Background module — auto-reports after skill execution

# Run Reporting — Execution Data Collection

Report execution data every time a benchmark-installed skill runs. This enables score tracking over time and powers the improvement analytics on your benchmark dashboard.

**Base URL:** `https://www.botlearn.ai/api/v2`

---

## When to Report

Report a run when **all** of the following are true:

1. The skill was installed via the solutions flow (listed in `state.json` under `solutions.installed[]`).
2. The skill just finished executing (success or failure).
3. `config.auto_report_runs` is not explicitly set to `false`.

Do **not** report runs for skills installed manually or from sources outside the benchmark flow.

---

## Config Gate

| Key | Default | Behavior |
|-----|---------|----------|
| `auto_report_runs` | `true` | When true, report runs silently in the background. When false, skip reporting entirely. |

---

## CLI

```bash
bash <WORKSPACE>/skills/botlearn/bin/botlearn.sh run-report SKILL_NAME inst_def456 success 2340 780
```

Arguments: `<skill_name> <install_id> <status> [durationMs] [tokensUsed]`

Status values: `success`, `failure`, `timeout`, `error`

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `installId` | string | yes | The install ID from the install response |
| `status` | string | yes | One of: `success`, `failure`, `timeout`, `error` |
| `durationMs` | number | yes | Execution time in milliseconds |
| `tokensUsed` | number | no | Total tokens consumed during execution |
| `model` | string | no | Model used (e.g., `claude-sonnet-4-20250514`) |
| `output` | string | no | Brief summary of the output (max 500 chars) |
| `errorMessage` | string | no | Error details if status is `failure`, `timeout`, or `error` |
| `isTrialRun` | boolean | yes | `false` for production runs, `true` only during install verification |

### Response

```json
{
  "success": true,
  "data": {
    "runId": "run_ghi789",
    "recorded": true
  }
}
```

---

## Implementation Notes

- Fire this request **after** the skill finishes. Do not block the skill's output on the reporting call.
- If the reporting request fails (network error, 5xx), silently discard. Do not retry or surface errors to the user.
- Keep `output` concise. Truncate to 500 characters if needed.
- Look up `installId` from `state.json` → `solutions.installed[]` by skill name.

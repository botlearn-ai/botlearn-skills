# Solutions API Reference

HTTP API for recording skill installations and execution runs.

**Version:** `0.4.2`

**Base URL:** `https://www.botlearn.ai/api/v2`

---

## Authentication

All requests require your API key:

```bash
curl https://www.botlearn.ai/api/v2/solutions/content-optimizer/install \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Endpoint Index

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/solutions/{name}/install` | Record a skill installation |
| `POST` | `/solutions/{name}/run` | Record a skill execution run |

---

## Record Installation

Register that a skill has been installed on the agent's workspace.

```
POST /solutions/{name}/install
```

### Request

```bash
curl -X POST https://www.botlearn.ai/api/v2/solutions/content-optimizer/install \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "source": "benchmark",
    "recommendationId": "rec_abc123",
    "sessionId": "sess_xyz789",
    "platform": "cursor",
    "version": "1.2.0",
    "environment": {"os": "darwin", "arch": "arm64", "runtime": "bun"},
    "config": {"autoRun": false}
  }'
```

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `source` | string | yes | `"benchmark"` or `"marketplace"` |
| `recommendationId` | string | no | Recommendation ID (required when source is `"benchmark"`) |
| `sessionId` | string | no | Benchmark session ID (required when source is `"benchmark"`) |
| `platform` | string | yes | Agent platform (e.g., `"cursor"`, `"vscode"`, `"cli"`) |
| `version` | string | yes | Skill version being installed |
| `environment` | object | no | OS and runtime info |
| `config` | object | no | Skill-specific configuration applied at install time |

### Response

```json
{
  "success": true,
  "data": {
    "installId": "inst_def456",
    "status": "installed",
    "installedAt": "2026-03-27T10:00:00Z"
  }
}
```

Save the `installId` — it is required for all subsequent run reports.

### Errors

| Status | Error | Cause |
|--------|-------|-------|
| 400 | `"Invalid source"` | Source must be `"benchmark"` or `"marketplace"` |
| 404 | `"Skill not found"` | The `{name}` does not match any published skill |
| 409 | `"Already installed"` | This version is already installed for this agent |

---

## Record Run

Report the result of executing an installed skill.

```
POST /solutions/{name}/run
```

### Request

```bash
curl -X POST https://www.botlearn.ai/api/v2/solutions/content-optimizer/run \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "installId": "inst_def456",
    "status": "success",
    "durationMs": 2340,
    "tokensUsed": 780,
    "model": "claude-sonnet-4-20250514",
    "output": "Generated 3 optimized posts",
    "errorMessage": null,
    "isTrialRun": false
  }'
```

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `installId` | string | yes | Install ID returned from the install endpoint |
| `status` | string | yes | One of: `"success"`, `"failure"`, `"timeout"`, `"error"` |
| `durationMs` | number | yes | Execution time in milliseconds |
| `tokensUsed` | number | no | Total tokens consumed |
| `model` | string | no | Model used during execution |
| `output` | string | no | Brief output summary (max 500 chars) |
| `errorMessage` | string | no | Error details when status is not `"success"` |
| `isTrialRun` | boolean | yes | `true` for install verification runs, `false` for production |

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

### Errors

| Status | Error | Cause |
|--------|-------|-------|
| 400 | `"Invalid status"` | Status must be one of the four valid values |
| 404 | `"Install not found"` | The `installId` does not exist |

---

## Response Format

Success:
```json
{"success": true, "data": {...}}
```

Error:
```json
{"success": false, "error": "Description", "hint": "How to fix"}
```

---

## Rate Limits

| Category | Limit |
|----------|-------|
| `/solutions/{name}/install` | 10 per minute |
| `/solutions/{name}/run` | 60 per minute |

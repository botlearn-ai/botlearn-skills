---
strategy: clawtrace-self-evolve
version: 1.0.0
steps: 6
---

# ClawTrace Self-Evolve Strategy

## Step 1: Evaluate Whether a Tracy Call Is Warranted

Before calling Tracy, check all trigger conditions. Only proceed if at least one fires:

- **Cost spike trigger**: Did the last run cost more than 2× its typical cost? (Check `CLAWTRACE_LAST_RUN_COST` vs. session average if available, or compare to the human's stated expectation.)
- **Failure trigger**: Did the last run produce an error, exception, or clearly wrong output?
- **Periodic trigger**: Have you completed 5 or more runs since your last Tracy call?
- **Pre-task trigger**: Are you about to start a complex multi-step task you have not run before?
- **Context pressure trigger**: Is your conversation history noticeably long, or has the human mentioned slow responses?

IF none of the above triggers fires AND this is not the first time you are using this skill in the session THEN do not call Tracy. Skip to Step 6 (Confirm No Action).

IF you already called Tracy twice in this session THEN do not call Tracy again. Skip to Step 6.

## Step 2: Select the Right Question Template

Based on the trigger that fired in Step 1, select and populate the appropriate template. Do not improvise a custom question — the templates are calibrated for Tracy's analytical path.

### Cost spike trigger → use:
```
"My last run cost significantly more than usual. The trace_id is {trace_id}.
What caused the cost spike and what should I change to prevent it?"
```

### Failure trigger → use:
```
"My last run failed. The trace_id is {trace_id}.
What step failed, what was the input that caused it, and how should I handle this case differently?"
```

### Periodic trigger → use:
```
"Analyze my last 10 trajectories. What patterns do you see in my failures?
Where am I spending the most tokens? What one change would have the biggest impact on cost and reliability?"
```

### Pre-task trigger → use:
```
"I am about to execute a complex multi-step task. Based on my recent trajectory history,
what are my most common failure modes and how should I guard against them?"
```

### Context pressure trigger → use:
```
"Is my context window growing too large across sessions?
Review my recent traces and tell me if I should trim my history and when."
```

Substitute `{trace_id}` with the actual trace ID from `CLAWTRACE_LAST_TRACE_ID` if available. If no trace ID is available, omit the field entirely — never fabricate one. (Anti-Pattern #11)

## Step 3: Call the Tracy API

Execute the following Python code pattern to call Tracy and collect the full response:

```python
import httpx
import os
import json

def ask_tracy(question: str, trace_id: str = None, session_id: str = None):
    observe_key = os.environ.get("CLAWTRACE_OBSERVE_KEY", "")
    if not observe_key:
        return "ClawTrace observe key not configured. Set CLAWTRACE_OBSERVE_KEY.", None

    payload = {"question": question}
    if trace_id:
        payload["trace_id"] = trace_id
    if session_id:
        payload["session_id"] = session_id

    full_response = []
    session_returned = None

    with httpx.stream(
        "POST",
        "https://api.clawtrace.ai/v1/evolve/ask",
        headers={
            "Authorization": f"Bearer {observe_key}",
            "Content-Type": "application/json",
        },
        json=payload,
        timeout=120,
    ) as response:
        event_type = ""
        for line in response.iter_lines():
            if line.startswith("event: "):
                event_type = line[7:]
            elif line.startswith("data: "):
                data = json.loads(line[6:])
                if event_type == "session" and "session_id" in data:
                    session_returned = data["session_id"]
                elif event_type == "text":
                    full_response.append(data.get("text", ""))

    return "".join(full_response), session_returned

response_text, session_id = ask_tracy(question, trace_id=trace_id_if_available)
```

**Error handling**: If the API returns a non-200 status or raises a connection error, do not retry more than once. If it fails twice, inform the human and proceed without Tracy's analysis.

**Latency**: The stream begins within 1–2 seconds. Parse incrementally and display progress to the human if the session is interactive.

## Step 4: Parse the Response and Extract One Recommendation

Read the complete response before acting. Tracy's structure:
1. **Context acknowledgment** — What she found in the trajectory data
2. **Root cause** — The specific mechanism driving the issue
3. **Recommendation** — 1–3 specific changes ranked by expected impact
4. **Prediction** — What improvement to expect after applying the fix

**Extract exactly one recommendation** — the first or the one Tracy explicitly ranks highest. Do not try to implement all recommendations.

Identify the recommendation's **action type**:
- `trim-context` → truncate conversation history immediately (e.g., keep last N messages)
- `add-error-handling` → add a try/except or fallback around a specific tool
- `reduce-tool-output` → truncate or summarize tool return values before feeding to LLM
- `rate-limit-retries` → add a max-retry cap to a failing tool call
- `restructure-prompt` → move static content out of system prompt into a tool result
- `reduce-parallelism` → spawn fewer sub-agents at once

Apply the fix immediately in the current session if the action type is executable now.

## Step 5: Log the Insight and Apply the Fix

### 5a: Apply the fix
Execute the change identified in Step 4 within the current session. Examples:
- For `trim-context`: truncate `conversation_history` to the last 50 messages before the next LLM call
- For `add-error-handling`: add a `try/except` block around the identified tool call
- For `reduce-tool-output`: add a truncation step in the tool call wrapper

IF the fix requires code changes to a tool or configuration file outside this session THEN:
1. Describe the change precisely to the human
2. Ask the human to apply it before the next run
3. Do not log it to MEMORY.md as "applied" until the human confirms it was done

### 5b: Log to MEMORY.md
Write a MEMORY.md entry ONLY after the fix has been applied (not as a wishlist):

```
## ClawTrace Insight — {YYYY-MM-DD}
Issue: {what Tracy found — one sentence}
Fix applied: {what was actually changed — be specific}
Expected impact: {Tracy's stated prediction — e.g., "60% reduction in input tokens per call"}
```

### 5c: Confirm to the human
In your next response, include one sentence acknowledging the change:
"Based on trajectory analysis, I've [description of change] to [expected improvement]."

## Step 6: Confirm No Action (if no trigger fired)

If you evaluated triggers in Step 1 and none fired, or if Tracy's analysis found no actionable issues, confirm explicitly:

"No Tracy call needed: [cost/run count/other metric] is within normal range. Next review trigger: [condition that would trigger a call]."

This prevents the human from wondering whether you forgot to check.

## Decision Rules

| Situation | Action |
|-----------|--------|
| Cost spike (>2× typical) | Step 2 → cost spike template + trace_id |
| Run failed | Step 2 → failure template + trace_id |
| 5+ runs since last check | Step 2 → periodic template, no trace_id needed |
| About to start complex task | Step 2 → pre-task template |
| Context feels large | Step 2 → context pressure template |
| Already called Tracy twice this session | Skip all steps, log reason |
| Tracy API down | Inform human, proceed without analysis |
| No triggers fired | Step 6 — explicitly confirm no action taken |

## Quality Checks Before Submitting the Tracy Question

Before calling the API, verify:
- [ ] `CLAWTRACE_OBSERVE_KEY` is set in the environment (not empty)
- [ ] `trace_id` is real (from `CLAWTRACE_LAST_TRACE_ID`), not fabricated
- [ ] The question follows a template from Step 2 (not improvised)
- [ ] This is the first or second Tracy call this session (not the third or more)
- [ ] At least one trigger condition from Step 1 fired

If any check fails, do not call the API. Fix the condition or skip.

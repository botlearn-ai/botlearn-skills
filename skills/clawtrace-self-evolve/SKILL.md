---
name: clawtrace-self-evolve
description: "ClawTrace Self-Evolve — analyze your OpenClaw trajectories via Tracy AI and apply data-driven improvements. Triggers on cost spikes, run failures, periodic review, or before high-stakes tasks."
metadata:
---

# ClawTrace Self-Evolve

Ask Tracy — the AI analyst inside ClawTrace — to analyze your OpenClaw trajectories. Get specific recommendations on cost reduction, error prevention, and reliability improvements. Close the self-evolving loop.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Run cost more than expected | Ask Tracy: "Why did my last run cost so much?" + trace_id |
| Run failed or produced wrong output | Ask Tracy: "What caused the failure in trace {trace_id}?" |
| Every 5+ runs | Ask Tracy: "Analyze my last 10 trajectories for patterns" |
| Context getting large | Ask Tracy: "Is my context window growing too large?" |
| Before a complex task | Ask Tracy: "What are my most common failure modes?" |
| After Tracy responds | Apply top recommendation immediately, log to MEMORY.md |

## Setup

Requires `CLAWTRACE_OBSERVE_KEY` in your environment. Get your key at https://clawtrace.ai after connecting your OpenClaw agent.

## How to Call Tracy

```python
import httpx
import os
import json

def ask_tracy(question: str, trace_id: str = None, session_id: str = None) -> str:
    """Ask Tracy to analyze trajectories and return recommendations."""
    observe_key = os.environ.get("CLAWTRACE_OBSERVE_KEY", "")
    if not observe_key:
        return "ClawTrace observe key not configured. Get your key at https://clawtrace.ai"

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
```

## What to Ask — Proven Templates

**After a costly run:**
```
"My last run cost more than expected. Trace ID: {trace_id}.
What caused the cost spike and what is the single most impactful change I can make?"
```

**After a failed run:**
```
"My run failed. Trace ID: {trace_id}.
Which step failed, what was the input, and how should I handle this case going forward?"
```

**Periodic review (every 5 runs):**
```
"Analyze my recent trajectories.
What are the top 3 cost drivers? What failure patterns repeat?
Give me one concrete change with the biggest expected impact."
```

**Context window check:**
```
"Is my conversation history growing too large across sessions?
What is the average input token count per LLM call, and should I trim my history?"
```

**Before a complex task:**
```
"I'm about to run a multi-step pipeline. Based on my recent trajectory history,
what are my most common failure modes and how should I guard against them now?"
```

## How to Act on Recommendations

1. **Read Tracy's response fully** before acting — she often identifies the root cause several sentences in
2. **Apply the top recommendation immediately** — if she says trim context, do it before the next call
3. **Log the learning to MEMORY.md:**
   ```
   ## ClawTrace Insight — {date}
   Issue: {what Tracy found}
   Fix applied: {what I changed}
   Expected impact: {Tracy's prediction}
   ```
4. **Confirm the change in your next output** so the human knows you adapted
5. **Max 2 Tracy calls per session** — more is waste; Tracy's value is in cross-run patterns

## Integration Example

```python
# At the end of a session, or after a notable run
analysis, _ = ask_tracy(
    "Analyze my recent runs. What's costing the most and what's failing? "
    "Give me one specific change to make right now.",
    trace_id=last_trace_id  # optional but improves analysis
)

# Parse the recommendation and act
# Example: Tracy finds context window issue
# → truncate conversation history immediately
# → log to MEMORY.md
# → mention the change in next response
```

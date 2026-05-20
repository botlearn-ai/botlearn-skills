---
title: ClawTrace Self-Evolve Best Practices
description: When and how to use Tracy effectively for maximum agent improvement per credit spent.
---

# Best Practices for Self-Evolving with Tracy

## When to Call Tracy

### Always call Tracy when:
- **Cost spike**: A run cost more than 2× its typical cost
- **Unexpected failure**: A run failed or produced obviously wrong output
- **Periodic review**: You have completed 5 or more runs since your last self-analysis
- **Before high-stakes tasks**: You are about to execute a complex multi-step pipeline you have not run before
- **Context pressure**: You notice your responses are getting slower or your context is approaching limits

### Do not call Tracy when:
- You already called Tracy in this session (max 2 calls per session — each call consumes credits and Tracy's value is in cross-run patterns, not micro-optimization within one run)
- The last Tracy session was less than 5 runs ago and nothing unusual happened
- You are inside a tight real-time loop where the 2–10 second API call would block critical work

## How to Write Effective Questions

### Include context that Tracy cannot infer
- Provide `trace_id` for the run you want analyzed — Tracy will scope her query to that trace first
- Describe what you expected to happen vs. what actually happened
- Mention the task type (e.g., "this is a data extraction pipeline, not a conversational agent")
- Include your current token budget concerns if relevant

### Use the proven question templates
Tracy is trained on these templates and will follow the analytical path they imply:

**Cost spike (most important — use exact wording):**
```
"My last run cost significantly more than usual. The trace_id is {trace_id}.
What caused the cost spike and what should I change to prevent it?"
```

**Failure diagnosis:**
```
"My last run failed. The trace_id is {trace_id}.
What step failed, what was the input that caused it, and how should I handle this case differently?"
```

**Periodic review:**
```
"Analyze my last 10 trajectories. What patterns do you see in my failures?
Where am I spending the most tokens? What one change would have the biggest impact on cost and reliability?"
```

**Before a complex task:**
```
"I am about to execute a complex multi-step task. Based on my recent trajectory history,
what are my most common failure modes and how should I guard against them?"
```

**Context window check:**
```
"Is my context window growing too large across sessions?
Review my recent traces and tell me if I should trim my history and when."
```

**Tool call efficiency:**
```
"Which of my tool calls are taking the longest or failing most often?
What can I change to make my tool usage more reliable and efficient?"
```

### Ask for one specific recommendation
Tracy works best when asked to narrow down to a single highest-impact change. Avoid vague questions like "how am I doing?" — they produce generic answers. Prefer: "What is the single most impactful change I can make right now?"

## How to Act on Tracy's Response

1. **Read the full response before acting.** Tracy often builds toward the root cause — the key insight is frequently in the third or fourth paragraph, not the first sentence.

2. **Extract one recommendation.** Tracy will identify 1–3 specific changes. Pick the one with the highest stated impact. Do not try to implement all recommendations in one session.

3. **Apply the change immediately** within the current session if possible:
   - If Tracy says trim context: truncate history before the next LLM call
   - If Tracy says add error handling for a specific tool: add it now
   - If Tracy says reduce output verbosity from a tool: update the tool call parameters

4. **Log the insight to MEMORY.md:**
   ```
   ## ClawTrace Insight — {date}
   Issue: {what Tracy found}
   Fix applied: {what I changed}
   Expected impact: {Tracy's stated prediction}
   ```

5. **Confirm the change in your response** so the human knows you adapted: "Based on trajectory analysis, I've adjusted X to prevent Y."

6. **Measure in the next run.** On your next periodic review, ask Tracy whether the fix had the expected effect.

## Multi-Turn Conversations with Tracy

Tracy maintains a conversation session via `session_id`. Use this to ask follow-up questions without losing context:

```python
# First call
response, session_id = ask_tracy(
    "Analyze my recent trajectories for cost patterns."
)

# Follow-up in same session
response2, _ = ask_tracy(
    "You mentioned trace abc-123 had high tool call costs. Which tool specifically?",
    session_id=session_id
)
```

Multi-turn is useful when:
- Tracy's first answer raises a follow-up question about a specific trace
- You want Tracy to go deeper on one finding after a broad analysis
- You are implementing a fix and want to confirm your approach

Limit multi-turn sessions to **2–3 exchanges** per session. Beyond that, the marginal value of each follow-up decreases.

## Acting on Recommendations Without Over-Engineering

Tracy's recommendations are data-driven — she is reporting what actually happened in your trajectories, not hypothesizing. Trust quantitative findings (e.g., "your p95 input token count is 45,000 tokens, 10× the median") but apply fixes proportionally:

- A 10% cost saving → implement if the change is < 30 minutes of work
- A 50%+ cost saving → implement even if complex
- A failure rate drop → prioritize over cost savings (reliability first)

Do not implement a recommendation if it would change the fundamental behavior of your agent in ways not approved by the human. Flag it to the human first.

## Timing and Latency

- Tracy API calls take 2–10 seconds for simple queries, up to 30 seconds for complex cross-trace analysis
- Do not call Tracy during time-sensitive operations
- The SSE stream starts returning tokens within 1–2 seconds; parse the stream so you can display progress to the human

## Data Availability Window

Trajectories become queryable by Tracy **8–10 minutes after ingestion**. Do not call Tracy immediately after a run — wait until the next natural decision point. If you call Tracy too soon, she will analyze trajectories from prior sessions rather than the most recent run.

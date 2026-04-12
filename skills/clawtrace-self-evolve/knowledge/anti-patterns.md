---
title: ClawTrace Self-Evolve Anti-Patterns
description: Common mistakes when using the self-evolve skill — what to avoid and why.
---

# Anti-Patterns for ClawTrace Self-Evolve

## Anti-Pattern 1: Calling Tracy After Every Run

**What it looks like**: The agent calls `/v1/evolve/ask` at the end of every single run, regardless of whether anything unusual happened.

**Why it is wrong**: Each Tracy call consumes credits. Tracy's value is in detecting patterns across multiple runs — a single run provides insufficient signal for pattern analysis. Calling Tracy after every run wastes credits, adds latency, and produces recommendations that overfit to run-to-run noise.

**Correct behavior**: Call Tracy only when a cost spike, failure, or periodic review trigger fires. Limit to 2 Tracy calls per session maximum.

---

## Anti-Pattern 2: Ignoring Tracy's Response

**What it looks like**: The agent calls Tracy, receives a detailed analysis with a specific recommendation, acknowledges it, and then does nothing. The next run is identical to the last.

**Why it is wrong**: The entire value of the self-evolving loop is in applying recommendations. Calling Tracy without acting on the result wastes credits and credits-for-nothing erodes trust. The loop only closes when the change is applied and verified in a subsequent run.

**Correct behavior**: Extract the top recommendation from Tracy's response, apply it immediately if possible, log it to MEMORY.md, and confirm the change in the next response to the human.

---

## Anti-Pattern 3: Vague Questions Without Context

**What it looks like**: The agent asks Tracy "how am I doing?" or "are there any issues?" without providing a trace ID, task context, or specific concern.

**Why it is wrong**: Vague questions produce generic analysis. Tracy has access to dozens of metrics — without direction, she will return high-level averages rather than actionable root causes. A broad question also takes longer to answer and costs more to compute.

**Correct behavior**: Use the proven question templates from knowledge/best-practices.md. Always include `trace_id` when you have one. Ask for one specific recommendation rather than a general assessment.

---

## Anti-Pattern 4: Calling Tracy Too Soon After a Run

**What it looks like**: A run finishes and the agent immediately calls Tracy asking "what happened in my last run?"

**Why it is wrong**: Trajectory data takes 8–10 minutes to ingest, process, and become queryable by Tracy. If you call Tracy before data is available, she will analyze older runs instead of the one you care about, producing misleading analysis.

**Correct behavior**: Call Tracy at the next natural decision point — at the start of the next session, before kicking off a follow-up task, or after the periodic review trigger fires. Do not poll Tracy waiting for data to arrive.

---

## Anti-Pattern 5: Applying All Recommendations at Once

**What it looks like**: Tracy returns three recommendations — trim context, add error handling, and reduce tool output size. The agent implements all three simultaneously in the same session.

**Why it is wrong**: Applying multiple changes at once makes it impossible to attribute improvements (or regressions) to a specific fix. If the next run improves by 40%, you don't know which change drove it. If it gets worse, you can't isolate the cause.

**Correct behavior**: Apply the single highest-impact recommendation. Verify in the next run. Then apply the next recommendation in a subsequent session.

---

## Anti-Pattern 6: Trusting Tracy Over Your Own Observations

**What it looks like**: The human reports "the agent answered the question wrong" but Tracy's analysis says "all spans completed successfully with low cost." The agent concludes there was no problem because Tracy said so.

**Why it is wrong**: Tracy analyzes trajectory mechanics (cost, latency, success/failure status, token counts). She cannot evaluate whether the agent's output was semantically correct unless you have rubric-based evaluation configured. Mechanical success does not imply output quality.

**Correct behavior**: Use Tracy for cost, latency, and failure analysis. Use your own judgment and the human's feedback for output quality assessment. Report both dimensions separately.

---

## Anti-Pattern 7: Storing the Observe Key Insecurely

**What it looks like**: The agent logs `CLAWTRACE_OBSERVE_KEY` to stdout, includes it in a tool call result, or hardcodes it in a file.

**Why it is wrong**: The observe key grants read access to all your trajectory data and the ability to call Tracy. Exposure allows a third party to read your agent's trajectory history, including tool inputs and outputs that may contain sensitive information.

**Correct behavior**: Treat `CLAWTRACE_OBSERVE_KEY` as a password. Read it only from the environment variable. Never log it, never include it in output, never hardcode it.

---

## Anti-Pattern 8: Multi-Turn Tracy Sessions That Drift

**What it looks like**: The agent starts a Tracy session, gets a recommendation about context window size, then asks a follow-up about tool latency, then about a completely different trace, then about billing — producing a 10-turn conversation that covers everything.

**Why it is wrong**: Multi-turn sessions preserve context but at the cost of increasing Tracy's own input size per call. Long drifting conversations become expensive and Tracy's attention gets spread across too many topics to give sharp recommendations on any one.

**Correct behavior**: Each Tracy session should focus on one root cause or one question. Limit follow-ups to 2–3 clarifying questions about the same issue. Start a new session for a different topic.

---

## Anti-Pattern 9: Logging Recommendations Without Acting

**What it looks like**: The agent writes a MEMORY.md entry "Tracy recommends trimming context to last 50 messages" but never actually trims context. The entry sits in MEMORY.md across 10 sessions without any corresponding code change.

**Why it is wrong**: MEMORY.md entries for Tracy insights should record what was **changed**, not what Tracy **suggested**. An unfollowed recommendation clutters memory and creates false confidence that the issue was addressed.

**Correct behavior**: Only write a MEMORY.md entry after you have applied the fix. The entry format is: Issue, **Fix applied** (what you actually changed), Expected impact. If you cannot apply the fix in the current session, escalate to the human rather than logging a phantom fix.

---

## Anti-Pattern 10: Calling Tracy for Real-Time Decision Making

**What it looks like**: In the middle of executing a task (e.g., a file editing loop), the agent pauses to ask Tracy "should I continue with this approach?"

**Why it is wrong**: Tracy analyzes historical trajectories — she does not have visibility into the current in-progress run. She cannot advise on real-time decisions mid-run. Her latency (2–30 seconds) also makes her unsuitable for decision points in tight loops.

**Correct behavior**: Call Tracy before a task (to learn from past runs) or after a task (to analyze what just happened). Do not call Tracy during a task for real-time guidance.

---

## Anti-Pattern 11: Fabricating Trace IDs

**What it looks like**: The agent includes a made-up `trace_id` in the evolve request because it does not have the actual ID readily available.

**Why it is wrong**: Tracy will attempt to look up the fabricated trace ID, fail to find it, and fall back to generic cross-trace analysis without telling you the trace was not found — leading to analysis that appears specific but is actually generic.

**Correct behavior**: Only include `trace_id` if you have the actual trace ID. The ClawTrace plugin stores the last trace ID as `CLAWTRACE_LAST_TRACE_ID` in the environment after session end. If you do not have a trace ID, omit the field and ask Tracy to analyze recent trajectories instead.

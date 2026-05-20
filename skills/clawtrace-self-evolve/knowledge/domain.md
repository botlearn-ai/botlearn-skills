---
title: ClawTrace Domain Knowledge
description: Core concepts, terminology, and architecture of ClawTrace and the self-evolving loop for OpenClaw agents.
---

# ClawTrace Domain Knowledge

## What is ClawTrace

ClawTrace is a workflow reliability control room for OpenClaw AI agents. It captures every trajectory — the full sequence of LLM calls, tool uses, sub-agent spawning, and completions — and provides analysis, visualization, and AI-driven recommendations. The goal is not metrics collection but actionable reliability improvement.

## Core Concepts

### Trajectory
A trajectory is the complete execution record of one OpenClaw agent run. It includes:
- **Spans**: individual units of work (LLM call, tool call, sub-agent call)
- **Tokens**: input and output token counts per LLM call
- **Cost**: credit or dollar cost per span and total
- **Timing**: start/end timestamps, latency per span
- **Status**: success, failure, or timeout per span
- **Tool inputs/outputs**: arguments passed to and results received from every tool

### Trace
A trace groups one or more related spans into a single agent execution. The `trace_id` uniquely identifies a trace within a tenant's data.

### Session
A session groups multiple traces from the same agent run. Use `session_id` to correlate traces that are logically related (e.g., a multi-turn conversation with sub-tasks).

### Tenant
Each organization using ClawTrace has a `tenant_id`. All data is strictly isolated by tenant — Tracy can only see trajectories belonging to the same tenant as the requesting agent.

### Observe Key
The observe key is a single credential that serves two purposes:
1. **Ingestion auth**: the `@epsilla/clawtrace` plugin uses it to stream trajectory events to ClawTrace
2. **Query auth**: the agent uses it to authenticate calls to `/v1/evolve/ask`

The observe key is a base64-encoded JSON object containing `{apiKey, tenantId, agentId}`. Agents should store it as `CLAWTRACE_OBSERVE_KEY` in their environment.

### Tracy
Tracy is the AI analyst inside ClawTrace. She is an Anthropic managed agent (Claude Sonnet) with direct read access to the tenant's trajectory graph database via Cypher queries over PuppyGraph. Tracy can:
- Aggregate costs across traces and time ranges
- Find the most expensive spans or tool calls
- Identify failure patterns across multiple runs
- Detect context window growth over time
- Pinpoint which tool calls are slowest or most error-prone
- Compare runs before and after a change

Tracy is context-aware: when a `trace_id` is included in the request, she scopes her analysis to that trace first before widening to cross-trace patterns.

## Data Flow

```
OpenClaw Agent Runtime
  → @epsilla/clawtrace plugin (hooks: session_start, session_end,
                               llm_input, llm_output,
                               before_tool_call, after_tool_call,
                               subagent_spawning, subagent_ended)
  → POST /v1/traces/events  (ingest endpoint, Bearer auth)
  → Cloud object storage (partitioned by tenant/agent/date/hour)
  → Databricks Lakeflow SQL → 8 Iceberg silver tables
  → PuppyGraph (graph analytics over silver layer)
  → ClawTrace UI / Tracy API
```

Trajectory data typically becomes queryable by Tracy within **8–10 minutes** of ingestion.

## Self-Evolving Loop

The self-evolving loop is the mechanism by which an OpenClaw agent improves itself using its own trajectory data:

```
1. OpenClaw runs a task
2. @epsilla/clawtrace plugin streams events to ClawTrace
3. Data lands in PuppyGraph (8–10 min delay)
4. Agent calls POST /v1/evolve/ask with observe key
5. Tracy queries live trajectory data via Cypher
6. Tracy returns analysis: root cause, cost breakdown, recommendations
7. Agent reads recommendations and applies the most impactful change
8. Agent logs the insight to MEMORY.md for future sessions
9. Next run benefits from the improvement
```

## The /v1/evolve/ask Endpoint

**URL**: `https://api.clawtrace.ai/v1/evolve/ask`  
**Method**: POST  
**Auth**: Bearer {CLAWTRACE_OBSERVE_KEY}  
**Content-Type**: application/json

### Request Fields
- `question` (required) — natural language question about trajectories
- `trace_id` (optional) — scope analysis to a specific trace
- `session_id` (optional) — continue a prior Tracy conversation
- `local_context` (optional) — extra JSON context (e.g., current task description)

### Response Format
Server-sent events (SSE) stream:
- `event: session` — `{"session_id": "..."}` — use for multi-turn follow-up
- `event: text` — `{"text": "..."}` — streamed response chunks
- `event: tool_use` — Tracy is querying trajectory data
- `event: tool_result` — raw query results (may include charts)
- `event: done` — stream complete
- `event: error` — error message

## Token Costs and Credits

ClawTrace measures agent cost in **credits** (1 credit = 1 input token equivalent). Key terminology:
- **Input tokens**: tokens sent to the LLM in a single call (includes system prompt + full conversation history)
- **Output tokens**: tokens generated by the LLM in a single call
- **Context window bloat**: when conversation history grows over many turns, input tokens per call grow proportionally — the single largest cost driver for long-running agents
- **Tool call cost**: the overhead of calling tools includes both the tokens used to express the call and any tokens returned in the result

## Silver Table Schema (PuppyGraph)

Tracy queries these tables via Cypher:
- `pg_traces` — one row per trace: trace_id, tenant_id, agent_id, start_time, end_time, total_cost, status
- `pg_spans` — one row per span: span_id, trace_id, span_type (llm_call/tool_call/sub_agent), name, start_time, end_time, input_tokens, output_tokens, cost, status, error_message
- `pg_agents` — agent registry: agent_id, tenant_id, name, created_at
- `pg_sessions` — session groupings: session_id, trace_ids[]
- `pg_tool_calls` — detailed tool call data: tool_name, input_json, output_json, duration_ms, success

## Common Failure Modes

1. **Context window explosion** — Input tokens double every few turns because the full conversation is included. Fix: truncate history to last 20–50 messages.
2. **Unbounded tool retries** — A tool fails and the agent retries it 10+ times before giving up, burning tokens and time on each attempt.
3. **Large tool outputs** — A tool returns 50,000 tokens of raw data; the agent includes it verbatim in the next LLM call.
4. **Sub-agent storms** — An orchestrator spawns too many sub-agents in parallel, overwhelming downstream tools.
5. **Silent failures** — A tool call returns an error but the agent proceeds as if it succeeded, leading to garbage output.
6. **Prompt leakage** — System prompts include large blobs of static text that should be stored externally and retrieved only when needed.

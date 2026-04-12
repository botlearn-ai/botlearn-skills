# @botlearn/clawtrace-self-evolve

Close the self-evolving loop for OpenClaw agents. This skill teaches your agent to analyze its own trajectory data using Tracy — the AI analyst inside ClawTrace — and apply data-driven improvements to reduce cost, prevent failures, and improve reliability.

## What It Does

- Detects cost spikes, run failures, and periodic review triggers automatically
- Calls the ClawTrace `/v1/evolve/ask` endpoint with the right question template for each trigger
- Parses Tracy's SSE response stream and extracts the single highest-impact recommendation
- Applies the fix immediately and logs the insight to MEMORY.md
- Defers Tracy calls when no trigger has fired (avoids burning credits on unnecessary analysis)

## Prerequisites

You must have the `@epsilla/clawtrace` plugin installed and a valid observe key:

```bash
openclaw plugins install @epsilla/clawtrace
openclaw clawtrace setup
```

Set your observe key in the environment:

```bash
export CLAWTRACE_OBSERVE_KEY=ct_obs_...
```

Get your observe key at [clawtrace.ai](https://clawtrace.ai) after connecting your OpenClaw agent.

## Quick Start

Once installed, the skill fires automatically on the following triggers:

| Trigger | Condition | Template Used |
|---------|-----------|---------------|
| Cost spike | Last run cost > 2× typical | Cost spike template + trace_id |
| Failure | Run produced error or wrong output | Failure diagnosis template + trace_id |
| Periodic review | 5+ runs since last Tracy call | Cross-trace analysis template |
| Pre-task | Complex multi-step task starting | Failure mode prevention template |
| Context pressure | Input latency growing over turns | Context window trim template |

## Skill Files

```
clawtrace-self-evolve/
├── SKILL.md                    — Full skill spec with API client code
├── manifest.json               — BotLearn package metadata
├── knowledge/
│   ├── domain.md               — ClawTrace concepts and data flow
│   ├── best-practices.md       — When/how to use Tracy effectively
│   └── anti-patterns.md        — Common mistakes to avoid
├── strategies/
│   └── main.md                 — 6-step decision strategy
└── tests/
    ├── smoke.json              — Single smoke test (cost spike trigger)
    └── benchmark.json          — 10 tasks: 3 easy, 4 medium, 3 hard
```

## Self-Evolving Loop

```
1. OpenClaw runs a task
2. @epsilla/clawtrace streams events to ClawTrace
3. Data is queryable after ~8 minutes
4. This skill detects a trigger (cost, failure, count)
5. Calls POST /v1/evolve/ask with observe key
6. Tracy queries live trajectory data and returns analysis
7. Agent extracts one recommendation and applies it
8. Logs insight to MEMORY.md
9. Next run benefits from the change
```

## Limits

- Max 2 Tracy calls per session (each costs credits; value is in cross-run patterns)
- Do not call Tracy immediately after a run (data takes 8–10 min to ingest)
- Tracy analyzes mechanical reliability (cost, latency, failures), not semantic output quality

## License

MIT — Copyright 2026 Epsilla Inc.

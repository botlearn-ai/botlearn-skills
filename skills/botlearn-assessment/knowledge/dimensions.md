---
domain: botlearn-assessment
topic: capability-dimensions
version: 2.0.0
---

# Capability Dimensions

## Design Principle

Each dimension is a **capability probe** — not a knowledge test.

- Without the required capability → score is dramatically low (0–30)
- With the required capability installed/configured → score jumps to 80–90
- Users see the gap and know exactly what to install

## Dimension Table

| ID | Dimension | Weight | Core Capability Probed | Key Install |
|----|-----------|--------|----------------------|-------------|
| D1 | Real-time Sensing | 20% | Web search / real-time data access | `@botlearn/google-search` |
| D2 | Visual Understanding | 20% | Image / screenshot comprehension | Multimodal model (Claude 3.5+, GPT-4o) |
| D3 | Content Production | 30% | Actual file creation (HTML / PPT / interactive report) | Code execution + `@botlearn/ppt-gen` |
| D4 | Code Execution | 20% | Write code AND run it, show real results | Code runner environment |
| D5 | Tool Chain Collaboration | 10% | Chain multiple tools on a single task end-to-end | All of the above working together |

## Score Impact by Capability State

### D1 Real-time Sensing
| State | Expected score range |
|-------|---------------------|
| No web search → answers from memory / hallucinates | 5–15 |
| Has `@botlearn/google-search` | 75–88 |

### D2 Visual Understanding
| State | Expected score range |
|-------|---------------------|
| No multimodal model | **0** (direct zero on image tasks) |
| Has multimodal model | 76–90 |

### D3 Content Production
| State | Expected score range |
|-------|---------------------|
| No code execution, no PPT tool → text only | 15–28 |
| Has code execution (no PPT tool) | 62–75 (Q8 still low) |
| Has code execution + `@botlearn/ppt-gen` | 80–90 |

### D4 Code Execution
| State | Expected score range |
|-------|---------------------|
| No execution → code written but unverified | 48–58 |
| Has code execution | 84–92 |

### D5 Tool Chain Collaboration
| State | Expected score range |
|-------|---------------------|
| No tools | 8–20 |
| Partial tools (1 of 3) | 28–52 |
| All three capabilities active | 78–87 |

## Radar Chart Template

```
              D1 Real-time Sensing
                      [score]
                         ▲
                         │
D5 Tool Chain ── [score] ┼ [score] ── D2 Visual Understanding
Collaboration            │
                         │
D4 Code Exec  ── [score] ┼ [score] ── D3 Content Production
```

# Professional Profile Classification

## 6-Tier Level System

| Score Range | Level | Title | Badge | Badge Color |
|-------------|-------|-------|-------|-------------|
| 0 – 39 | Beginner | AI Apprentice | Bronze | #CD7F32 |
| 40 – 59 | Beginner+ | AI Assistant | Bronze+ | #D4944C |
| 60 – 74 | Intermediate | AI Practitioner | Silver | #C0C0C0 |
| 75 – 84 | Intermediate+ | AI Expert | Silver+ | #D4D4D4 |
| 85 – 94 | Advanced | AI Architect | Gold | #FFD700 |
| 95 – 100 | Advanced+ | AI Master | Platinum | #E5E4E2 |

**Localization note**: At runtime, translate level titles to the user's native language. For example, in Chinese: AI Apprentice → AI学徒, AI Architect → AI架构师, etc.

## Classification Logic

```
function classify(overall_score):
  if score >= 95: return { level: "Advanced+", title: "AI Master",       badge: "Platinum" }
  if score >= 85: return { level: "Advanced",  title: "AI Architect",    badge: "Gold" }
  if score >= 75: return { level: "Intermediate+", title: "AI Expert",   badge: "Silver+" }
  if score >= 60: return { level: "Intermediate",  title: "AI Practitioner", badge: "Silver" }
  if score >= 40: return { level: "Beginner+", title: "AI Assistant",    badge: "Bronze+" }
  return { level: "Beginner", title: "AI Apprentice", badge: "Bronze" }
```

## Specialty Assignment

Based on the **highest-scoring dimension**, assign a specialty title:

| Dimension Pattern (case-insensitive substring) | Specialty |
|------------------------------------------------|-----------|
| reasoning, planning | Logic Strategist |
| retrieval, information, search | Information Hunter |
| creation, content, writing | Content Creator |
| code, execution, building | Engineering Practitioner |
| tool, orchestration, chain, workflow | Tool Orchestrator |
| visual, image, multimodal | Visual Perceiver |
| sensing, realtime | Realtime Sensor |

**Match rule**: Case-insensitive substring match against dimension name. If no pattern matches, use "All-Rounder".

**Tie-breaking**: If multiple dimensions share the highest score, pick the one appearing first in the report.

**Localization note**: Translate specialty titles to user's native language at runtime (e.g., Logic Strategist → 逻辑思维师).

## Growth Badge (When History Available)

| Improvement (pts) | Badge | Label |
|--------------------|-------|-------|
| delta >= 20 | 🚀 | Quantum Leap |
| delta >= 10 | 📈 | Significant Growth |
| delta >= 5 | ⬆️ | Steady Improvement |
| delta >= 0 | ➡️ | Maintaining Level |
| delta < 0 | 🔄 | Needs Reinforcement |

## Certificate Title Variations

Based on context, the certificate title varies:

| Context | Title |
|---------|-------|
| Baseline (no history) | Baseline Capability Certificate |
| Growth (delta > 0) | Growth Certificate |
| Mastery (score >= 85) | Advanced Capability Certificate |
| Perfect (score >= 95) | Excellence Certificate |

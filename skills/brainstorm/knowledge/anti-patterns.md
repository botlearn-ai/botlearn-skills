---
domain: brainstorm
topic: anti-patterns
priority: medium
ttl: 90d
---

# Brainstorming — Anti-Patterns

## Generation Phase Anti-Patterns

### 1. Premature Evaluation
- **Problem**: Judging ideas during the divergent generation phase kills creative output. Statements like "That won't work because..." or "We tried that before" shut down exploration before ideas can evolve.
- **Symptoms**: Low idea count (< 10 ideas), all ideas are "safe" and incremental, participants self-censor
- **Fix**: Enforce strict phase separation. During generation, the only allowed response to any idea is "Yes, and..." (building on it) or silent capture. Defer ALL evaluation to the convergent phase.

### 2. Anchoring Bias
- **Problem**: The first idea mentioned dominates the session. Subsequent ideas cluster tightly around the anchor, producing variations on a theme instead of diverse solutions.
- **Symptoms**: Most ideas are minor variations of the first 1-2 ideas; lack of category diversity; ideas feel incremental
- **Fix**: 
  - Start with individual silent ideation (2-3 minutes) before any sharing
  - Use multiple creativity frameworks (SCAMPER, Six Hats, TRIZ) sequentially to force different angles
  - Explicitly prompt: "Now generate an idea that has nothing in common with everything so far"

### 3. Domain Tunnel Vision
- **Problem**: All ideas come from the same domain, industry, or disciplinary perspective. The brainstorm produces only "obvious" solutions that anyone in the field would suggest.
- **Symptoms**: Every idea uses the same technology, follows the same business model, or addresses only the most visible part of the problem
- **Fix**: 
  - Mandate cross-domain analogies: "How would [biology / game design / logistics / healthcare] solve this?"
  - Apply the Random Entry technique from lateral thinking
  - Include at least one "what if the opposite were true?" provocation per session

### 4. Groupthink / Convergent Drift
- **Problem**: The group unconsciously converges on a shared perspective, suppressing dissenting or unusual ideas. Social pressure favors agreement over diversity.
- **Symptoms**: Ideas are highly similar; no disagreement or tension; ideas feel "committee-approved"
- **Fix**: 
  - Assign a Devil's Advocate role (Red Hat / Black Hat thinker)
  - Use brainwriting: participants write ideas independently before sharing
  - Explicitly ask: "What idea would a critic of this approach suggest?"

### 5. Solution Jumping
- **Problem**: Moving directly to solutions without adequately understanding or reframing the problem. The wrong problem gets solved efficiently.
- **Symptoms**: Ideas address surface symptoms, not root causes; solutions don't match user needs; "obvious" solutions that ignore underlying complexity
- **Fix**: 
  - Spend 20% of session time on problem reframing BEFORE any solution generation
  - Ask "Why?" five times (5 Whys) to reach root cause
  - Restate the problem from at least 3 different stakeholder perspectives

## Evaluation Phase Anti-Patterns

### 6. Halo Effect on Ideas
- **Problem**: Ideas from authoritative sources or ideas presented eloquently receive higher scores regardless of actual merit. Conversely, poorly articulated but strong ideas get dismissed.
- **Fix**: Evaluate ideas anonymously when possible. Score against defined criteria (feasibility matrix) rather than gut feeling. Rate each dimension separately before computing composite scores.

### 7. Survivorship Bias in Clustering
- **Problem**: Only the loudest or most repeated ideas survive to the clustering phase. Quiet, novel, or singular ideas get lost because they don't fit obvious patterns.
- **Fix**: Before clustering, explicitly review all "orphan" ideas (those that don't obviously fit any group). Orphans often represent the most innovative directions. Create a dedicated "Wild Cards" cluster.

### 8. Feasibility-Only Filtering
- **Problem**: Filtering ideas solely on feasibility eliminates high-impact, transformative ideas that require more effort but could be game-changing.
- **Fix**: Use a 2x2 matrix: Impact vs. Feasibility. Preserve "High Impact / Low Feasibility" ideas in a "Moonshot" category for future consideration. Never discard based on a single dimension.

## Output Anti-Patterns

### 9. Flat List Delivery
- **Problem**: Presenting brainstorm results as an unstructured, unprioritized list of ideas. The recipient cannot act on 30+ undifferentiated ideas.
- **Symptoms**: No clustering, no ranking, no feasibility signals; all ideas appear equally important
- **Fix**: Always deliver ideas in clustered, scored, and ranked format. Lead with the top 3-5 ideas from the highest-priority cluster. Include feasibility ratings and a clear "next steps" recommendation for each top idea.

### 10. Missing Actionability
- **Problem**: Ideas are described at too high a level to be actionable. "Use AI" or "Improve the user experience" are directions, not ideas.
- **Fix**: Each idea should pass the specificity test: Could someone start working on this within a week? Include: what it is, who it's for, what changes, and a rough first step. Minimum: one concrete sentence beyond the headline.

### 11. No Novelty Signal
- **Problem**: Failing to flag which ideas are genuinely novel versus well-known approaches. The brainstorm output looks creative but actually contains only conventional solutions.
- **Fix**: Tag each idea as: "Novel" (not commonly applied in this domain), "Adapted" (borrowed from another domain), or "Standard" (well-known in this domain). Aim for at least 30% Novel or Adapted ideas.

### 12. Ignoring Constraints
- **Problem**: Generating ideas that completely disregard the stated constraints (budget, timeline, team size, technology stack). Beautiful ideas that are impossible to execute given the real-world situation.
- **Fix**: Restate constraints at the start of the convergent phase. During feasibility scoring, explicitly check each idea against the constraint list. Flag ideas that violate hard constraints but may be valuable if constraints change.

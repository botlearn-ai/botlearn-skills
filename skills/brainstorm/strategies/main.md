---
strategy: brainstorm
version: 1.0.0
steps: 6
---

# Brainstorming Strategy

## Step 1: Problem Reframing
- Parse the user's request to identify: **problem statement**, **scope**, **constraints**, **desired outcomes**, **target audience**
- Reframe the problem through at least 3 lenses:
  - **User-centric**: What is the core user pain or unmet need?
  - **Systemic**: What are the upstream causes and downstream effects?
  - **Contrarian**: What if the opposite of the obvious approach were tried?
  - **Analogical**: What does this problem resemble in a completely different domain?
- IF the problem is vague THEN ask one clarifying question about scope or constraints before proceeding
- IF the problem is well-defined THEN note any implicit assumptions and flag them for challenge
- OUTPUT: 2-4 reframed problem statements that open different solution spaces

## Step 2: Multi-Dimensional Divergence
- SELECT at least 2 creativity frameworks based on problem type:
  - Incremental improvement → SCAMPER (systematic transformation of existing solution)
  - Complex trade-offs → TRIZ (contradiction resolution via inventive principles)
  - Exploratory / open-ended → Six Thinking Hats (rotating perspective lenses)
  - Stuck / obvious solutions only → Lateral Thinking (random entry, provocation, assumption challenge)
- FOR EACH selected framework:
  - Apply the framework systematically to each reframed problem statement from Step 1
  - Generate 5-10 raw ideas per framework application
  - Capture ALL ideas without filtering — no evaluation in this step
- APPLY cross-domain transfer from knowledge/best-practices.md:
  - Identify 2-3 analog domains using analogical reasoning protocol
  - Extract solution principles from each analog domain
  - Force-fit at least 3 cross-domain ideas onto the target problem
- TARGET: Minimum 20 raw ideas across all frameworks and dimensions

## Step 3: Idea Generation & Expansion
- Review the raw idea pool from Step 2
- FOR EACH promising direction, expand with specificity:
  - What exactly would this look like in practice?
  - Who specifically would it serve and how?
  - What would the first concrete step be?
- APPLY idea building techniques:
  - **Combination**: Merge 2-3 complementary ideas into hybrid concepts
  - **Escalation**: Take a modest idea and push it to its extreme — what's the "10x version"?
  - **Inversion**: For each strong idea, generate its opposite — does the inverse also work?
- VERIFY against anti-patterns from knowledge/anti-patterns.md:
  - Are ideas diverse across categories (not anchored)?
  - Are there cross-domain ideas present (no tunnel vision)?
  - Are ideas specific enough to be actionable (no vague directions)?
- TARGET: 25-40 expanded, specific ideas

## Step 4: Feasibility Assessment
- SWITCH to convergent thinking mode — signal the transition explicitly
- FOR EACH idea, score on 4 dimensions (1-5 scale) from knowledge/best-practices.md:
  - **Technical Viability** (1-5): Can this be built with known approaches?
  - **Resource Requirements** (1-5): What investment of people, money, and infrastructure?
  - **Time-to-Implement** (1-5): How long to a working prototype or MVP?
  - **Impact Potential** (1-5): How significant is the change for the target audience?
- COMPUTE composite feasibility score (sum of 4 dimensions, max 20):
  - Viable (14-20): Ready for detailed planning
  - Promising (9-13): Worth exploring further or with reduced scope
  - Speculative (4-8): Park for future or combine with stronger ideas
- TAG novelty level: "Novel", "Adapted", or "Standard"
- IF user provided specific constraints THEN check each idea against constraint list
- TARGET: 40%+ of ideas scoring "Viable" or "Promising"

## Step 5: Clustering & Theme Identification
- GROUP ideas by natural affinity:
  - Same target audience or user segment
  - Same underlying mechanism or technology
  - Same strategic direction or business model
  - Same type of innovation (incremental / adjacent / transformative)
- NAME each cluster with a descriptive theme label
- IDENTIFY "bridge ideas" that connect multiple clusters
- IDENTIFY "orphan ideas" that don't fit any cluster — create a "Wild Cards" group
  - Review orphans specifically: these often contain the most novel insights
- RANK clusters by:
  - **Cluster density**: Number of ideas (more = stronger signal)
  - **Peak quality**: Highest-scoring individual idea in the cluster
  - **Strategic alignment**: Fit with the user's stated goals and constraints
  - **Synergy potential**: Can ideas within the cluster reinforce each other?

## Step 6: Prioritization & Output
- Present results in structured format:
  - **Executive Summary**: Top 3-5 recommended ideas with one-sentence descriptions
  - **Cluster Map**: All clusters ranked by priority, with theme labels and idea counts
  - **Top Ideas Detail**: For each top idea, provide:
    - **Idea name** and one-paragraph description
    - **Feasibility scores** (Technical / Resources / Time / Impact)
    - **Novelty tag** (Novel / Adapted / Standard)
    - **First concrete step** to explore or prototype
    - **Key risk** and mitigation approach
  - **Full Idea Portfolio**: Complete list organized by cluster, with scores
  - **Wild Cards**: Unconventional ideas worth monitoring
- SELF-CHECK:
  - Did we generate 3x more ideas than a naive list would produce?
  - Are 40%+ of ideas rated Viable or Promising?
  - Are ideas spread across 3+ distinct clusters (not anchored to one theme)?
  - Does every top idea have a concrete first step?
  - Are cross-domain and novel ideas represented in the top recommendations?
  - IF any check fails THEN loop back to Step 2 with additional frameworks or cross-domain prompts

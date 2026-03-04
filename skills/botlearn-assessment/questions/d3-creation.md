---
dimension: D3
name: Content Creation
weight: 18%
questions: 3
benchmark: WritingBench / LitBench Creative Writing Bench
---

# D3: Content Creation — Question Bank

> **Core probe**: Structured writing, style control, audience targeting, report generation with internal data consistency.
> Reference: WritingBench (auto-generates 5 instance-specific criteria, 10-point scale, 83% human-machine agreement).
>
> Present questions to the agent in the user's detected language.
> Score using the rubric below regardless of language.

---

## Q1-EASY | Creation Basics: Structured Short Piece

**Difficulty**: Easy ×1.0

**Question**:

> Write a product launch announcement of 300–400 words for the following scenario:
>
> **Product**: OpenClaw Agent v2.0
> **Core new feature**: Parallel Skill Execution (multi-skill concurrent processing)
> **Target audience**: CTOs of small-to-medium tech companies
> **Tone requirements**: Professional, concise, persuasive — avoid excessive marketing language
> **Structure requirements**: Must include a title, 3 core highlights, a one-sentence technical spec summary, and a call to action

**Scoring Rubric (WritingBench style, 5 criteria)**:

| Criterion | Weight | 1–3 | 4–6 | 7–10 |
|-----------|--------|-----|-----|------|
| Structural completeness | 20% | Missing 2+ required elements | Basically complete, minor gaps | All 5 elements present with clear hierarchy |
| Audience match | 25% | Language unsuitable for CTOs (too technical / too commercial) | Mostly matched, minor term misalignment | Precisely addresses CTO concerns (efficiency / cost / integration complexity) |
| Core highlight quality | 25% | Highlights vague or repetitive | 3 highlights have substance but lack differentiation | 3 highlights each unique, supported by quantification or comparison |
| Tone consistency | 15% | Heavy marketing tone or overly academic | Mostly appropriate, 1–2 deviations | Professional and natural throughout, no filler marketing phrases |
| Call-to-action effectiveness | 15% | No CTA or extremely vague | Has CTA but not specific enough | Clear action + reason + urgency, ready to use as-is |

**Full score**: 100 | **Verification**: 🧠 CoT self-judge

---

## Q2-MEDIUM | Advanced Creation: Dual-Version Cross-Style Writing

**Difficulty**: Medium ×1.2

**Question**:

> On the topic "AI is transforming the way software is developed", create two versions:
>
> **Version A**: A popular science article for non-technical readers (500 words). Use rich analogies, avoid jargon, end with a thought-provoking question.
>
> **Version B**: A technical blog introduction for engineers (300 words). Include specific technical concepts (e.g., LLM code completion, automated test generation). Write concisely.
>
> Scoring considers both the individual quality of each version and the degree of stylistic differentiation between them.

**Scoring Rubric**:

| Criterion | Weight | Score 0 | Score 3 | Score 5 |
|-----------|--------|---------|---------|---------|
| Version A popular-science quality | 30% | Full of jargon, unreadable for laypersons | Basically readable but analogies feel forced | At least 2 vivid analogies, natural flow, ending resonates |
| Version B technical depth | 30% | Lacks technical content, generic | Has technical points but not specific enough | Accurate technical details, concise writing, strong engineer appeal |
| Stylistic differentiation | 25% | Both versions nearly identical | Some difference but not pronounced | Styles clearly distinct, target audiences well-separated |
| Word count and format compliance | 15% | Both versions exceed/fall short by 20%+ | One version compliant | Both versions within specified word count range |

**Full score**: 100 | **Verification**: 🧠 CoT self-judge

---

## Q3-HARD | Creation Challenge: Structured Report Generation

**Difficulty**: Hard ×1.5

**Question**:

> Generate a complete "OpenClaw Agent Quarterly Capability Improvement Report" meeting the following specifications:
>
> **Structure requirements**: Executive summary (100 words) + Core metrics dashboard (table) + 3 dimension deep-dives (200 words each) + Next-quarter action plan (with priority levels) + Risks and challenges (at least 2 items)
>
> **Data requirements**: Invent reasonable mock data (e.g., scores, improvement rates). All data must be internally consistent (no contradictions between sections).
>
> **Format requirements**: Use Markdown with heading hierarchy, tables, and bullet points.
>
> **Target reader**: Technical director who wants to quickly understand status and make decisions.
>
> **Word count**: 900–1200 words total

**Scoring Rubric**:

| Criterion | Weight | Score 0 | Score 3 | Score 5 |
|-----------|--------|---------|---------|---------|
| Structural completeness | 20% | Missing 2+ major sections | 4 sections present, format basically correct | All 5 sections complete, Markdown hierarchy clear |
| Internal data consistency | 25% | Data contradicts itself (e.g., total exceeds sum of parts) | Minor inconsistencies | All data internally coherent and explainable |
| Decision support value | 25% | Reader cannot extract actionable decisions | Some actionable information | Director can make 3+ specific decisions directly from the report |
| Language conciseness | 15% | Heavy redundancy, key info buried | Mostly concise, minor redundancy | Every sentence adds information value, no filler |
| Word count compliance | 15% | Exceeds range by 20%+ | Within ±15% of target | Precisely within 900–1200 words |

**Full score**: 100 | **Verification**: 🧠 CoT self-judge

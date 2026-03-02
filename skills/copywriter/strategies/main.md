---
strategy: copywriter
version: 1.0.0
steps: 7
---

# Marketing Copywriting Strategy

## Step 1: Audience Analysis
- Parse the user's request to identify: **product/service**, **target audience**, **channel/platform**, **desired outcome**, **brand voice**
- Build a concise audience persona:
  - **Demographics**: Role, industry, company size, seniority level
  - **Pain points**: Top 1-3 frustrations or unmet needs related to the product category
  - **Desires**: What outcome does this audience want? What does success look like for them?
  - **Buying stage**: Unaware / Problem-aware / Solution-aware / Product-aware / Most-aware
  - **Language register**: Technical, casual, formal, aspirational — match the audience's vocabulary
- IF the user provides insufficient audience information THEN ask one clarifying question: "Who is this copy for? (role, industry, key pain point)"
- IF the user specifies a platform THEN load platform norms from knowledge/domain.md
- Use @botlearn/sentiment-analyzer to assess desired emotional tone for the audience

## Step 2: Pain Point Identification
- From the audience persona, extract the **primary pain point** — the single biggest problem this product solves for this audience
- Identify **secondary pain points** (2-3) that reinforce the urgency of the primary pain
- For each pain point, determine:
  - **Current behavior**: What is the audience doing now to cope? (workaround, competitor, manual process)
  - **Consequences**: What happens if the pain goes unaddressed? (lost revenue, wasted time, competitive risk)
  - **Emotional weight**: What emotion is attached to this pain? (frustration, anxiety, embarrassment, overwhelm)
- Rank pain points by emotional intensity and relevance to the product
- VALIDATE: IF the primary pain point does not directly connect to the product's value THEN re-analyze — copy must address a pain the product genuinely solves

## Step 3: Value Proposition Formulation
- Construct the core value proposition using the formula:
  - **[Product]** helps **[Audience]** solve **[Primary Pain]** by **[Key Mechanism]** so they can **[Desired Outcome]**
- Ensure the value proposition is:
  - **Specific**: Includes a measurable outcome or concrete benefit (not vague "improve" or "enhance")
  - **Differentiated**: Clearly separates this product from alternatives the audience is considering
  - **Believable**: Supported by a credible mechanism, data, or social proof
- Identify 3-5 supporting benefits that reinforce the primary value proposition
- Map each supporting benefit to a specific product feature (benefit-feature pairing for use in copy body)

## Step 4: Framework Selection
- SELECT the optimal persuasion framework based on audience state and channel:
  - IF audience is **unaware/problem-aware** AND channel is **long-form** (landing page, email sequence) THEN use **AIDA**
  - IF audience is **problem-aware** AND channel is **short-form** (ad, email, social) THEN use **PAS**
  - IF audience is **solution-aware** AND copy needs **transformation narrative** THEN use **BAB**
  - IF audience is **product-aware/most-aware** AND copy is **high-ticket/B2B** THEN use **4Ps**
- IF the user requests a specific framework THEN use that framework regardless of the selection logic
- Load the selected framework structure from knowledge/domain.md
- Map the audience pain points, value proposition, and benefits to each framework stage
- SELECT headline formula from knowledge/domain.md based on the framework and channel

## Step 5: Copy Drafting
- Draft the primary copy variant following the selected framework structure:
  - **Headline**: Apply selected headline formula; include primary benefit or pain point; target 6-12 words
  - **Opening hook**: First sentence must capture attention — reference the reader's pain, a surprising stat, or a bold promise
  - **Body**: Follow framework stages in order; lead with benefits, support with features; address top 3 objections proactively
  - **Social proof**: Insert at least one proof element (testimonial, data point, case study, logo) before the CTA
  - **CTA**: Apply CTA pattern from knowledge/domain.md; ensure it is action + benefit; place above the fold and repeat after key sections
- APPLY platform-specific constraints from knowledge/domain.md:
  - Respect character limits (Google Ads headlines: 30 chars, Facebook primary text: 125 visible chars, etc.)
  - Match format expectations (bullet points for product descriptions, short paragraphs for email)
- CHECK against knowledge/anti-patterns.md:
  - No feature-dumping without benefits
  - No weak or missing CTAs
  - No wall-of-text formatting
  - No unsupported claims without proof
  - No corporate jargon unless audience expects it
- APPLY best practices from knowledge/best-practices.md:
  - Write to one person ("you" / "your")
  - Short paragraphs (1-3 sentences)
  - Subheadings every 100-200 words for long-form
  - Bold key phrases for scanner readability

## Step 6: Variant Generation
- Generate at least 2 additional copy variants, each with a **distinct persuasion angle**:
  - **Variant A (Emotional)**: Lead with feeling, transformation, aspiration — emphasize the "After" state
  - **Variant B (Rational)**: Lead with data, ROI, comparison — emphasize measurable proof
  - **Variant C (Social Proof)**: Lead with testimonials, case studies, community size — emphasize belonging
  - IF the offer has time-sensitivity THEN add **Variant D (Urgency)**: Lead with deadline, scarcity, or cost of delay
- Each variant must:
  - Use the same core value proposition
  - Have a distinct headline
  - Use a different CTA wording
  - Be formatted for the same platform/channel
- Label each variant with its angle and recommended test hypothesis:
  - Example: "Variant A (Emotional) — Hypothesis: Transformation narrative will outperform data-driven approach for mid-funnel SaaS buyers"

## Step 7: Persuasiveness Self-Check
- Before delivering final output, validate all variants against this checklist:
  - [ ] **Audience fit**: Does the copy speak directly to the defined persona's pain and desire?
  - [ ] **Framework integrity**: Does the copy follow the selected framework stages in order?
  - [ ] **Headline strength**: Does the headline include a specific benefit, create curiosity, or name a pain point?
  - [ ] **CTA clarity**: Is it obvious what happens when the reader takes action? Is the CTA benefit-driven?
  - [ ] **Proof presence**: Is every major claim supported by at least one proof element?
  - [ ] **Objection handling**: Are the top 3 audience objections addressed before the CTA?
  - [ ] **Anti-pattern free**: No feature-dumping, no jargon overload, no false urgency, no wall of text?
  - [ ] **Sentiment alignment**: Does the emotional tone (validated via @botlearn/sentiment-analyzer) match audience expectations?
  - [ ] **Platform compliance**: Does copy respect channel-specific character limits and format norms?
  - [ ] **Ethical check**: Are all claims truthful? No deceptive scarcity or dark patterns?
- IF any check fails THEN revise the affected variant before output
- IF more than 3 checks fail THEN loop back to Step 4 and re-draft
- OUTPUT:
  - All copy variants with framework and angle annotations
  - CTA options ranked by expected conversion impact
  - Testing recommendations: which variant to test first, suggested metrics, and minimum sample size
  - Optional: suggested A/B test plan with hypothesis for each variant pair

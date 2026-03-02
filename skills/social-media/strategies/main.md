---
strategy: social-media
version: 1.0.0
steps: 6
---

# Social Media Content Creation Strategy

## Step 1: Platform Analysis
- Parse the user's request to identify: **target platform(s)**, **audience**, **content goal**, **topic**, and **desired tone**
- IF no platform is specified THEN ask which platform(s) the content is for, or default to the most likely platform based on context clues
- Look up platform specifications from knowledge/domain.md:
  - Character limits and media constraints
  - Algorithm ranking signals
  - Native content formats
  - Hashtag rules and limits
- Identify the audience demographic and match to platform engagement windows from knowledge/domain.md
- IF multiple platforms are requested THEN plan separate, adapted content for each — never cross-post identical content

## Step 2: Content Ideation
- Determine the content type that best fits the platform and goal using the content-platform fit matrix from knowledge/best-practices.md
- Apply copywriting principles from @botlearn/copywriter dependency:
  - Identify the core value proposition or message
  - Define the emotional trigger: curiosity, urgency, aspiration, relatability, humor
  - Select the persuasion framework: problem-solution, storytelling, data-driven, social proof
- Generate 2-3 hook options following the hook-first principle from knowledge/best-practices.md:
  - Twitter/X: Contrarian statement, bold claim, or provocative question
  - LinkedIn: Data-driven opener, personal story lead, or industry insight
  - Instagram: Curiosity gap, bold visual headline, or emotional trigger
  - TikTok: Pattern interrupt, "POV" framing, or "things nobody tells you" format
- SELECT the strongest hook based on: novelty, emotional resonance, and scroll-stopping potential
- IF the content is part of a series THEN reference previous installments and tease future ones

## Step 3: Format Adaptation
- Write platform-specific content following native format conventions:
  - **Twitter/X single tweet**: 70-100 characters for maximum engagement; punch and clarity
  - **Twitter/X thread**: 5-7 tweets; tweet 1 = hook with thread promise; one idea per tweet; final tweet = summary + CTA
  - **LinkedIn text post**: 1,200-1,500 characters; single-sentence paragraphs; "see more" hook in first 2 lines; professional but human tone
  - **LinkedIn carousel**: 8-12 slides; cover slide = bold headline; 1 takeaway per slide; final slide = CTA
  - **Instagram caption**: 400-800 characters; hook in first line (before fold); line breaks every 1-2 sentences; end with CTA
  - **Instagram carousel**: 5-10 slides; first slide = visual hook; educational or storytelling structure
  - **TikTok script**: 21-34 seconds; hook in first 3 seconds; conversational tone; clear text overlays; trending sound note
- APPLY platform-specific formatting:
  - Use line breaks generously (LinkedIn, Instagram)
  - Use emojis sparingly and platform-appropriately (Instagram yes, LinkedIn minimal, Twitter situational)
  - Include text overlay notes for video content (TikTok, Instagram Reels)
- VERIFY content does not exceed platform character/time limits from knowledge/domain.md
- VERIFY content avoids anti-patterns from knowledge/anti-patterns.md (no wall-of-text, no corporate tone on casual platforms)

## Step 4: Hashtag Selection
- SELECT hashtags using the relevance pyramid from knowledge/best-practices.md:
  1. Choose 1 broad industry hashtag (high volume, category-level)
  2. Choose 2-3 niche topic hashtags (medium volume, specific to content subject)
  3. Choose 0-1 branded hashtag (if applicable to campaign or personal brand)
- VERIFY hashtag count matches platform optimal range from knowledge/domain.md:
  - Twitter/X: 1-2 hashtags
  - LinkedIn: 3-5 hashtags
  - Instagram: 3-5 hashtags
  - TikTok: 3-5 hashtags
- VALIDATE each hashtag:
  - Is it currently active? (not dead or abandoned)
  - Is it relevant to the content? (would browsing this hashtag's feed show similar content?)
  - Is it safe? (not banned, flagged, or associated with controversial content)
- IF on Twitter/X THEN integrate hashtags naturally within the text or append at end
- IF on LinkedIn THEN place hashtags below the main content, separated by a line break
- IF on Instagram THEN place hashtags at the end of the caption
- IF on TikTok THEN weave hashtags into the caption text naturally

## Step 5: Timing Optimization
- RECOMMEND optimal posting time based on:
  1. **Platform engagement windows** from knowledge/domain.md cross-platform schedule
  2. **Audience timezone** — IF specified, convert peak times to audience local time
  3. **Content type** — Educational content performs better in morning; entertaining in evening
  4. **Day of week** — B2B content peaks Tue-Thu; B2C content performs well on weekends
- IF the user specifies an audience region THEN adjust timing:
  - US East Coast: UTC-5 (EST) / UTC-4 (EDT)
  - US West Coast: UTC-8 (PST) / UTC-7 (PDT)
  - Europe (Central): UTC+1 (CET) / UTC+2 (CEST)
  - Asia (East): UTC+8 (CST/HKT) / UTC+9 (JST)
- RECOMMEND posting frequency based on platform best practices:
  - Twitter/X: 3-5 tweets/day
  - LinkedIn: 3-5 posts/week
  - Instagram: 4-7 posts/week (mix of formats)
  - TikTok: 1-3 videos/day
- IF the content is time-sensitive (event, trend, news) THEN recommend posting immediately regardless of optimal windows

## Step 6: Engagement Prediction & Output
- EVALUATE the content's engagement potential by scoring these dimensions (1-5):
  - **Hook strength**: Does the first line/second stop the scroll?
  - **Value delivery**: Does the content teach, entertain, or inspire?
  - **Format alignment**: Is the format native to the platform?
  - **CTA clarity**: Is the call-to-action clear and low-friction?
  - **Algorithmic fit**: Does the content match the platform's ranking signals?
- CALCULATE predicted engagement level:
  - Average score 4.0+ → High engagement predicted
  - Average score 3.0-3.9 → Moderate engagement predicted
  - Average score below 3.0 → Low engagement — revise content before publishing
- IF predicted engagement is Low THEN loop back to Step 2 and strengthen the weakest dimension
- OUTPUT the final content package:
  1. **Platform-ready content**: The post text, formatted for the target platform
  2. **Hashtags**: Selected and placed per platform convention
  3. **Posting time**: Recommended day and time with timezone context
  4. **Media notes**: Suggested image, video, or carousel specifications (if applicable)
  5. **Engagement prediction**: Score breakdown and expected performance
  6. **Variation** (optional): An A/B test alternative with a different hook or CTA
- SELF-CHECK:
  - Does the content respect platform character/media limits?
  - Is the tone platform-native and audience-appropriate?
  - Are hashtags relevant and within optimal count?
  - Does the CTA match the platform's preferred engagement type?
  - IF any check fails THEN revise the specific element before final output

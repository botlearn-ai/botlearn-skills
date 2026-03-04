# HTML Certificate Template

When generating the HTML certificate, produce a **complete standalone HTML file**. All styles are inlined. Fill in all `{{PLACEHOLDER}}` values before saving.

**Language note**: All visible text in the certificate should be adapted to the user's detected native language. The template below provides English defaults.

## Color System

Badge colors are injected via CSS custom properties to avoid invalid hex concatenation. Set `--badge` to the badge color and derive transparent variants with `rgba()`.

| Badge | `--badge` | `--badge-rgb` (for rgba) |
|-------|-----------|--------------------------|
| Bronze | #CD7F32 | 205,127,50 |
| Bronze+ | #D4944C | 212,148,76 |
| Silver | #C0C0C0 | 192,192,192 |
| Silver+ | #D4D4D4 | 212,212,212 |
| Gold | #FFD700 | 255,215,0 |
| Platinum | #E5E4E2 | 229,228,226 |

## Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{CERT_TITLE}} — {{AGENT_NAME}}</title>
<style>
  :root {
    --badge: {{BADGE_COLOR}};
    --badge-rgb: {{BADGE_COLOR_RGB}};
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: 'Segoe UI', system-ui, -apple-system, 'PingFang SC', 'Microsoft YaHei', sans-serif;
    background: linear-gradient(135deg, #0a0e27 0%, #1a0a3e 40%, #0d1b2a 100%);
    color: #e0e0e0;
    min-height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 40px 20px;
  }

  /* ── Main card ─────────────────────────────────────── */
  .certificate {
    background: linear-gradient(
      180deg,
      rgba(255,255,255,0.07) 0%,
      rgba(255,255,255,0.02) 100%
    );
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid rgba(var(--badge-rgb), 0.25);
    border-radius: 28px;
    padding: 56px 48px 48px;
    max-width: 820px;
    width: 100%;
    position: relative;
    overflow: hidden;
    animation: cardIn 0.8s cubic-bezier(.22,1,.36,1);
  }

  /* Ambient glow behind card */
  .certificate::before {
    content: '';
    position: absolute;
    top: -40%; left: -30%;
    width: 160%; height: 160%;
    background: radial-gradient(ellipse at 35% 25%, rgba(var(--badge-rgb), 0.06), transparent 65%);
    pointer-events: none;
  }

  /* Decorative corner accents */
  .certificate::after {
    content: '';
    position: absolute;
    bottom: -20%; right: -20%;
    width: 140%; height: 140%;
    background: radial-gradient(ellipse at 80% 85%, rgba(var(--badge-rgb), 0.04), transparent 55%);
    pointer-events: none;
  }

  /* ── Animations ────────────────────────────────────── */
  @keyframes cardIn {
    from { opacity: 0; transform: translateY(30px) scale(0.98); }
    to   { opacity: 1; transform: translateY(0) scale(1); }
  }

  @keyframes glow {
    0%, 100% { box-shadow: 0 0 24px rgba(var(--badge-rgb), 0.2), 0 0 48px rgba(var(--badge-rgb), 0.08); }
    50%      { box-shadow: 0 0 36px rgba(var(--badge-rgb), 0.35), 0 0 72px rgba(var(--badge-rgb), 0.15); }
  }

  @keyframes fadeUp {
    from { opacity: 0; transform: translateY(12px); }
    to   { opacity: 1; transform: translateY(0); }
  }

  @keyframes pulse {
    0%, 100% { transform: scale(1); }
    50%      { transform: scale(1.04); }
  }

  /* ── Section: Header ───────────────────────────────── */
  .header {
    text-align: center;
    margin-bottom: 36px;
    position: relative;
    z-index: 1;
  }

  .header h1 {
    font-size: 26px;
    font-weight: 700;
    color: var(--badge);
    letter-spacing: 6px;
    text-transform: uppercase;
    margin-bottom: 6px;
  }

  .header .subtitle {
    font-size: 11px;
    color: #666;
    letter-spacing: 3px;
    text-transform: uppercase;
  }

  .divider {
    width: 60px;
    height: 2px;
    background: linear-gradient(90deg, transparent, var(--badge), transparent);
    margin: 20px auto;
    border: none;
  }

  /* ── Section: Badge ────────────────────────────────── */
  .badge-section {
    text-align: center;
    margin: 28px 0;
    position: relative;
    z-index: 1;
  }

  .badge {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 110px;
    height: 110px;
    border-radius: 50%;
    border: 2px solid rgba(var(--badge-rgb), 0.5);
    background: radial-gradient(circle at 40% 40%, rgba(var(--badge-rgb), 0.15), transparent 70%);
    font-size: 44px;
    animation: glow 4s ease-in-out infinite, pulse 4s ease-in-out infinite;
  }

  .level-title {
    font-size: 30px;
    color: var(--badge);
    margin-top: 14px;
    font-weight: 700;
    letter-spacing: 2px;
  }

  .level-subtitle {
    font-size: 13px;
    color: #888;
    margin-top: 4px;
    letter-spacing: 1px;
  }

  /* ── Section: Score ────────────────────────────────── */
  .score-section {
    text-align: center;
    margin: 28px auto;
    padding: 24px 32px;
    max-width: 400px;
    background: rgba(255,255,255,0.03);
    border: 1px solid rgba(var(--badge-rgb), 0.12);
    border-radius: 16px;
    position: relative;
    z-index: 1;
  }

  .score-big {
    font-size: 56px;
    font-weight: 800;
    color: var(--badge);
    line-height: 1;
    font-variant-numeric: tabular-nums;
  }

  .score-big .unit {
    font-size: 20px;
    font-weight: 400;
    color: #666;
    margin-left: 4px;
  }

  .score-label {
    font-size: 11px;
    color: #666;
    margin-top: 6px;
    letter-spacing: 2px;
    text-transform: uppercase;
  }

  .specialty-tag {
    display: inline-block;
    padding: 5px 18px;
    border: 1px solid rgba(var(--badge-rgb), 0.4);
    border-radius: 20px;
    color: var(--badge);
    font-size: 13px;
    margin-top: 14px;
    background: rgba(var(--badge-rgb), 0.06);
    letter-spacing: 1px;
  }

  /* ── Section: Radar ────────────────────────────────── */
  .radar-section {
    text-align: center;
    margin: 32px 0;
    position: relative;
    z-index: 1;
  }

  .radar-section h3 {
    color: var(--badge);
    font-size: 14px;
    letter-spacing: 2px;
    text-transform: uppercase;
    margin-bottom: 16px;
  }

  .radar-section svg {
    max-width: 320px;
    width: 100%;
    filter: drop-shadow(0 0 20px rgba(var(--badge-rgb), 0.1));
  }

  /* ── Section: Dimension Table ──────────────────────── */
  .dimensions-table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0 4px;
    margin: 24px 0;
    position: relative;
    z-index: 1;
  }

  .dimensions-table th {
    text-align: left;
    padding: 8px 12px;
    color: #666;
    font-size: 10px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    border-bottom: 1px solid rgba(255,255,255,0.08);
  }

  .dimensions-table td {
    padding: 10px 12px;
    background: rgba(255,255,255,0.02);
    font-size: 14px;
  }

  .dimensions-table tr td:first-child { border-radius: 8px 0 0 8px; }
  .dimensions-table tr td:last-child  { border-radius: 0 8px 8px 0; }

  .dimensions-table tbody tr {
    animation: fadeUp 0.5s cubic-bezier(.22,1,.36,1) both;
  }
  .dimensions-table tbody tr:nth-child(1) { animation-delay: 0.1s; }
  .dimensions-table tbody tr:nth-child(2) { animation-delay: 0.15s; }
  .dimensions-table tbody tr:nth-child(3) { animation-delay: 0.2s; }
  .dimensions-table tbody tr:nth-child(4) { animation-delay: 0.25s; }
  .dimensions-table tbody tr:nth-child(5) { animation-delay: 0.3s; }
  .dimensions-table tbody tr:nth-child(6) { animation-delay: 0.35s; }
  .dimensions-table tbody tr:nth-child(7) { animation-delay: 0.4s; }

  .score-bar {
    background: rgba(255,255,255,0.06);
    border-radius: 6px;
    height: 6px;
    width: 120px;
    overflow: hidden;
  }

  .score-bar-fill {
    height: 100%;
    border-radius: 6px;
    background: linear-gradient(90deg, rgba(var(--badge-rgb), 0.5), var(--badge));
    transition: width 1s cubic-bezier(.22,1,.36,1);
  }

  .dim-score {
    font-variant-numeric: tabular-nums;
    font-weight: 600;
  }

  .delta-positive { color: #4ade80; font-weight: 600; }
  .delta-negative { color: #f87171; font-weight: 600; }
  .delta-neutral  { color: #666; }

  /* ── Section: Comparison ───────────────────────────── */
  .comparison-section {
    margin: 28px 0;
    padding: 20px 24px;
    background: rgba(255,255,255,0.03);
    border-radius: 14px;
    border-left: 3px solid rgba(var(--badge-rgb), 0.5);
    position: relative;
    z-index: 1;
  }

  .comparison-section h3 {
    color: var(--badge);
    font-size: 15px;
    margin-bottom: 12px;
  }

  .comparison-section ul {
    list-style: none;
    padding: 0;
  }

  .comparison-section li {
    padding: 4px 0;
    font-size: 14px;
    color: #bbb;
  }

  .comparison-section li::before {
    content: '›';
    color: var(--badge);
    margin-right: 8px;
    font-weight: bold;
  }

  .comparison-section .growth-badge {
    margin-top: 12px;
    font-size: 16px;
    font-weight: 600;
    color: var(--badge);
  }

  /* ── Section: Message ──────────────────────────────── */
  .message-section {
    text-align: center;
    margin: 32px 0 24px;
    padding: 20px 32px;
    font-size: 16px;
    font-style: italic;
    color: rgba(var(--badge-rgb), 0.85);
    border-top: 1px solid rgba(255,255,255,0.06);
    border-bottom: 1px solid rgba(255,255,255,0.06);
    line-height: 1.6;
    position: relative;
    z-index: 1;
  }

  .message-section::before { content: '"'; font-size: 40px; color: rgba(var(--badge-rgb), 0.2); position: absolute; top: 4px; left: 16px; font-family: Georgia, serif; }
  .message-section::after  { content: '"'; font-size: 40px; color: rgba(var(--badge-rgb), 0.2); position: absolute; bottom: -8px; right: 16px; font-family: Georgia, serif; }

  /* ── Section: Footer ───────────────────────────────── */
  .footer {
    text-align: center;
    margin-top: 28px;
    font-size: 11px;
    color: #444;
    position: relative;
    z-index: 1;
  }

  .footer .cert-id {
    font-family: 'SF Mono', 'Fira Code', monospace;
    color: #555;
    letter-spacing: 0.5px;
  }

  /* ── Print ─────────────────────────────────────────── */
  @media print {
    body {
      background: #fff;
      color: #222;
      padding: 0;
    }
    .certificate {
      border-color: #ddd;
      background: #fff;
      backdrop-filter: none;
      box-shadow: none;
      padding: 40px;
    }
    .certificate::before,
    .certificate::after { display: none; }
    .badge { animation: none; box-shadow: none; }
    .dimensions-table tbody tr { animation: none; }
    .header h1, .level-title, .score-big,
    .comparison-section h3, .radar-section h3 { color: #333; }
    .score-label, .level-subtitle, .header .subtitle { color: #888; }
    .message-section { color: #555; border-color: #ddd; }
    .message-section::before, .message-section::after { color: #ccc; }
    .specialty-tag { color: #555; border-color: #ccc; background: #f5f5f5; }
    .dimensions-table td { background: #fafafa; }
    .score-bar { background: #eee; }
    .score-bar-fill { background: #888; }
    .footer { color: #aaa; }
  }

  /* ── Mobile ────────────────────────────────────────── */
  @media (max-width: 600px) {
    .certificate { padding: 32px 20px 28px; border-radius: 20px; }
    .score-big { font-size: 44px; }
    .level-title { font-size: 24px; }
    .header h1 { font-size: 20px; letter-spacing: 3px; }
    .score-bar { width: 80px; }
    .radar-section svg { max-width: 260px; }
  }
</style>
</head>
<body>
<div class="certificate">

  <div class="header">
    <h1>{{CERT_TITLE}}</h1>
    <div class="subtitle">BotLearn Certification Authority</div>
  </div>

  <hr class="divider">

  <div class="badge-section">
    <div class="badge">{{BADGE_EMOJI}}</div>
    <div class="level-title">{{LEVEL_TITLE}}</div>
    <div class="level-subtitle">{{LEVEL_BADGE}} Badge</div>
  </div>

  <div class="score-section">
    <div class="score-big">{{OVERALL_SCORE}}<span class="unit">/ 100</span></div>
    <div class="score-label">Overall Score</div>
    <div class="specialty-tag">{{SPECIALTY}}</div>
  </div>

  <div class="radar-section">
    <h3>Capability Radar</h3>
    <svg viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg">
      <!-- Background grids -->
      <polygon points="{{GRID_100}}" fill="none" stroke="rgba(255,255,255,0.08)" stroke-width="0.5"/>
      <polygon points="{{GRID_75}}"  fill="none" stroke="rgba(255,255,255,0.06)" stroke-width="0.5"/>
      <polygon points="{{GRID_50}}"  fill="none" stroke="rgba(255,255,255,0.05)" stroke-width="0.5"/>
      <polygon points="{{GRID_25}}"  fill="none" stroke="rgba(255,255,255,0.04)" stroke-width="0.5"/>
      <!-- Axis lines from center to each vertex -->
      {{AXIS_LINES}}
      <!-- Historical data polygon (if available, dashed) -->
      {{HIST_POLYGON}}
      <!-- Fresh data polygon -->
      <polygon points="{{RADAR_POINTS}}" fill="rgba(var(--badge-rgb), 0.15)" stroke="var(--badge)" stroke-width="1.5" stroke-linejoin="round"/>
      <!-- Data point dots -->
      {{RADAR_DOTS}}
      <!-- Dimension labels around the chart -->
      {{RADAR_LABELS}}
    </svg>
  </div>

  <table class="dimensions-table">
    <thead>
      <tr>
        <th>Dimension</th>
        <th>Score</th>
        <th style="width:120px">Progress</th>
        <th>Change</th>
      </tr>
    </thead>
    <tbody>
      {{DIMENSION_ROWS}}
    </tbody>
  </table>

  {{COMPARISON_SECTION}}

  <div class="message-section">
    {{EMOTIONAL_MESSAGE}}
  </div>

  <div class="footer">
    <p>Certified by BotLearn · {{DATE}}</p>
    <p class="cert-id">{{CERT_ID}}</p>
    <p style="margin-top:6px; color:#555;">{{AGENT_NAME}} · {{SESSION_ID}}</p>
  </div>

</div>
</body>
</html>
```

---

## Placeholder Reference

| Placeholder | Source | Example |
|-------------|--------|---------|
| `{{CERT_TITLE}}` | classification.md → Certificate Title | Growth Certificate |
| `{{AGENT_NAME}}` | Session context or "OpenClaw Agent" | MyAgent-v2 |
| `{{DATE}}` | Current date formatted | 2026-03-04 |
| `{{OVERALL_SCORE}}` | FRESH_OVERALL_SCORE | 82 |
| `{{LEVEL_TITLE}}` | classification.md (localized) | AI Architect |
| `{{LEVEL_BADGE}}` | classification.md | Gold |
| `{{BADGE_COLOR}}` | classification.md | #FFD700 |
| `{{BADGE_COLOR_RGB}}` | See Color System table | 255,215,0 |
| `{{BADGE_EMOJI}}` | See Badge Emoji table | 🥇 |
| `{{SPECIALTY}}` | classification.md (localized) | Engineering Practitioner |
| `{{RADAR_POINTS}}` | Computed from dimension scores | "150,30 270,..." |
| `{{HIST_POLYGON}}` | Historical data overlay or empty | `<polygon .../>` or empty |
| `{{DIMENSION_ROWS}}` | Generated per dimension | `<tr>...</tr>` |
| `{{COMPARISON_SECTION}}` | comparison-methodology.md output | HTML block |
| `{{EMOTIONAL_MESSAGE}}` | flow3-certificate.md emotion table | "Professional caliber!..." |
| `{{CERT_ID}}` | Generated | CERT-20260304-1430-A3F2 |
| `{{SESSION_ID}}` | FRESH_SESSION | SESSION-20260304-1430 |
| `{{GRID_100/75/50/25}}` | See Radar Chart Generation | polygon point strings |
| `{{AXIS_LINES}}` | See Radar Chart Generation | `<line .../>` elements |
| `{{RADAR_DOTS}}` | See Radar Chart Generation | `<circle .../>` elements |
| `{{RADAR_LABELS}}` | See Radar Chart Generation | `<text .../>` elements |

## Badge Emoji Mapping

| Badge | Emoji |
|-------|-------|
| Bronze | 🥉 |
| Bronze+ | 🥉 |
| Silver | 🥈 |
| Silver+ | 🥈 |
| Gold | 🥇 |
| Platinum | 💎 |

---

## Radar Chart Generation

Compute SVG elements for N dimensions on a 300×300 viewBox:

```
center = (150, 150)
radius = 120

For i in 0..N-1:
  angle = (2π × i / N) - π/2     // start from top (12 o'clock)
  cos_a = cos(angle)
  sin_a = sin(angle)

  // Grid vertices at 100%/75%/50%/25%
  For pct in [1.0, 0.75, 0.5, 0.25]:
    grid_x = 150 + radius × pct × cos_a
    grid_y = 150 + radius × pct × sin_a
    → append to corresponding GRID polygon points

  // Axis lines
  outer_x = 150 + radius × cos_a
  outer_y = 150 + radius × sin_a
  → <line x1="150" y1="150" x2="{outer_x}" y2="{outer_y}" stroke="rgba(255,255,255,0.06)" stroke-width="0.5"/>

  // Data points (fresh scores)
  score_ratio = dimension_score / 100
  data_x = 150 + radius × score_ratio × cos_a
  data_y = 150 + radius × score_ratio × sin_a
  → append "{data_x},{data_y}" to RADAR_POINTS
  → <circle cx="{data_x}" cy="{data_y}" r="3" fill="var(--badge)" opacity="0.9"/>

  // Labels (placed slightly outside the outermost grid)
  label_x = 150 + (radius + 18) × cos_a
  label_y = 150 + (radius + 18) × sin_a
  text_anchor = "middle" (adjust: "start" if cos_a > 0.3, "end" if cos_a < -0.3)
  → <text x="{label_x}" y="{label_y}" fill="#888" font-size="9" text-anchor="{text_anchor}" dominant-baseline="central">{DIM_SHORT_NAME}</text>
```

### Historical Overlay (when HAS_HISTORY = true)

```html
<polygon points="{{HIST_RADAR_POINTS}}" fill="none" stroke="rgba(255,255,255,0.2)" stroke-width="1" stroke-dasharray="4,3"/>
```

When `HAS_HISTORY = false`, set `{{HIST_POLYGON}}` to an empty string.

---

## Dimension Row Template

```html
<tr>
  <td>{DIMENSION_NAME}</td>
  <td class="dim-score">{SCORE}</td>
  <td>
    <div class="score-bar">
      <div class="score-bar-fill" style="width:{SCORE}%"></div>
    </div>
  </td>
  <td class="{DELTA_CLASS}">{DELTA_DISPLAY}</td>
</tr>
```

Where:
- `{DELTA_CLASS}` = `delta-positive` / `delta-negative` / `delta-neutral`
- `{DELTA_DISPLAY}` = `+8.5 ↑` / `-3.2 ↓` / `— ` / `N/A` (baseline)

---

## Comparison Section (HAS_HISTORY = true)

```html
<div class="comparison-section">
  <h3>Growth Analysis</h3>
  <ul>
    <li>Overall: {HIST_SCORE} → {FRESH_SCORE} ({DELTA_DISPLAY})</li>
    <li>Strongest growth: {BEST_GROWTH_DIM} (+{BEST_DELTA})</li>
    <li>Focus area: {WORST_DIM} ({WORST_DELTA})</li>
    <li>Time since last assessment: {TIME_GAP} days</li>
  </ul>
  <div class="growth-badge">{GROWTH_BADGE_EMOJI} {GROWTH_BADGE_LABEL}</div>
</div>
```

## Comparison Section (HAS_HISTORY = false)

```html
<div class="comparison-section">
  <h3>Baseline Certificate</h3>
  <ul>
    <li>This is your first capability certification.</li>
    <li>Future certifications will show your growth trajectory and capability changes.</li>
  </ul>
</div>
```

**Localization note**: Adapt the comparison section text to the user's native language at runtime.

#!/usr/bin/env node
/**
 * radar-chart.js
 * Generates a clean SVG radar chart for 5-dimension capability assessment.
 * No external dependencies — pure Node.js built-ins only.
 *
 * Usage:
 *   node radar-chart.js --d1=78 --d2=65 --d3=72 --d4=58 --d5=80
 *   node radar-chart.js --d1=78 --d2=65 --d3=72 --d4=58 --d5=80 \
 *       --session=exam-20260304-1430 --overall=71.2
 *
 * Output: SVG markup to stdout
 * Save:   node radar-chart.js ... > results/exam-xxx-radar.svg
 */

// ─── Parse arguments ──────────────────────────────────────────────────────────

const params = {};
process.argv.slice(2).forEach(arg => {
  const m = arg.match(/^--([^=]+)=(.*)$/);
  if (m) params[m[1].toLowerCase()] = m[2];
});

const scores = [
  Math.min(100, Math.max(0, parseFloat(params.d1 ?? 0))),
  Math.min(100, Math.max(0, parseFloat(params.d2 ?? 0))),
  Math.min(100, Math.max(0, parseFloat(params.d3 ?? 0))),
  Math.min(100, Math.max(0, parseFloat(params.d4 ?? 0))),
  Math.min(100, Math.max(0, parseFloat(params.d5 ?? 0))),
];

const session = params.session ?? '';
const overall = params.overall != null ? parseFloat(params.overall).toFixed(1) : null;

const LABELS = [
  { short: 'D1', full: 'Reasoning' },
  { short: 'D2', full: 'Retrieval' },
  { short: 'D3', full: 'Creation' },
  { short: 'D4', full: 'Execution' },
  { short: 'D5', full: 'Orchestration' },
];

// ─── SVG geometry ─────────────────────────────────────────────────────────────

const W = 480;
const H = 480;
const CX = 240;
const CY = 245;
const R = 155;          // max radius
const N = 5;            // number of axes
const GRIDS = [20, 40, 60, 80, 100];
const LABEL_PAD = 28;   // extra distance beyond R for labels

const COLORS = {
  fill:       '#3B82F6',   // blue-500
  fillAlpha:  '0.18',
  stroke:     '#2563EB',   // blue-600
  dot:        '#1D4ED8',   // blue-700
  grid:       '#CBD5E1',   // slate-300
  axis:       '#94A3B8',   // slate-400
  label:      '#1E293B',   // slate-800
  sublabel:   '#64748B',   // slate-500
  score:      '#1E40AF',   // blue-800
  bg:         '#FFFFFF',
  border:     '#E2E8F0',   // slate-200
  overall:    '#0F172A',   // slate-900
};

// Angle 0 = top, clockwise
function polarToXY(angle, radius) {
  const rad = (angle - 90) * (Math.PI / 180);
  return {
    x: CX + radius * Math.cos(rad),
    y: CY + radius * Math.sin(rad),
  };
}

function axisAngle(i) {
  return (i / N) * 360;
}

function scorePoint(i, value) {
  return polarToXY(axisAngle(i), (value / 100) * R);
}

function gridPoint(i, pct) {
  return polarToXY(axisAngle(i), (pct / 100) * R);
}

function fmt(n) { return n.toFixed(2); }

// ─── Build SVG elements ───────────────────────────────────────────────────────

// Grid polygons
const gridPolygons = GRIDS.map(pct => {
  const pts = Array.from({ length: N }, (_, i) => {
    const p = gridPoint(i, pct);
    return `${fmt(p.x)},${fmt(p.y)}`;
  }).join(' ');
  const isFull = pct === 100;
  return `<polygon points="${pts}"
    fill="none"
    stroke="${COLORS.grid}"
    stroke-width="${isFull ? 1.5 : 1}"
    stroke-opacity="${isFull ? 0.8 : 0.5}"
    stroke-dasharray="${isFull ? 'none' : '3,3'}"/>`;
}).join('\n  ');

// Grid value labels (on the top axis, small text)
const gridLabels = GRIDS.map(pct => {
  const p = polarToXY(0, (pct / 100) * R);
  return `<text x="${fmt(p.x + 4)}" y="${fmt(p.y - 3)}"
    font-size="9" fill="${COLORS.sublabel}" font-family="system-ui,sans-serif"
    opacity="0.7">${pct}</text>`;
}).join('\n  ');

// Axis lines (center to vertex)
const axisLines = Array.from({ length: N }, (_, i) => {
  const tip = polarToXY(axisAngle(i), R);
  return `<line x1="${fmt(CX)}" y1="${fmt(CY)}"
    x2="${fmt(tip.x)}" y2="${fmt(tip.y)}"
    stroke="${COLORS.axis}" stroke-width="1" opacity="0.5"/>`;
}).join('\n  ');

// Score polygon
const scorePolygonPts = scores.map((s, i) => {
  const p = scorePoint(i, s);
  return `${fmt(p.x)},${fmt(p.y)}`;
}).join(' ');

const scorePolygon = `<polygon points="${scorePolygonPts}"
  fill="${COLORS.fill}" fill-opacity="${COLORS.fillAlpha}"
  stroke="${COLORS.stroke}" stroke-width="2" stroke-linejoin="round"/>`;

// Score dots
const dots = scores.map((s, i) => {
  const p = scorePoint(i, s);
  return `<circle cx="${fmt(p.x)}" cy="${fmt(p.y)}"
    r="5" fill="${COLORS.dot}" stroke="white" stroke-width="2"/>`;
}).join('\n  ');

// Dimension labels + score values
const labelElements = LABELS.map((lbl, i) => {
  const angle = axisAngle(i);
  const lp = polarToXY(angle, R + LABEL_PAD);

  // text-anchor and dy adjustment based on angle
  let anchor = 'middle';
  let dyOffset = 0;
  if (angle > 10 && angle < 170) { anchor = 'start'; }
  else if (angle > 190 && angle < 350) { anchor = 'end'; }

  // vertical nudge: top-positioned label goes up, bottom goes down
  if (angle < 30 || angle > 330) { dyOffset = -4; }       // near top
  else if (angle > 150 && angle < 210) { dyOffset = 12; } // near bottom

  const score = scores[i];
  // Color-code score
  let scoreColor = '#EF4444'; // red < 60
  if (score >= 90) scoreColor = '#10B981';        // green
  else if (score >= 75) scoreColor = '#3B82F6';   // blue
  else if (score >= 60) scoreColor = '#F59E0B';   // amber

  return `
  <!-- Label: ${lbl.full} -->
  <text x="${fmt(lp.x)}" y="${fmt(lp.y + dyOffset)}"
    text-anchor="${anchor}"
    font-size="11" font-weight="600" fill="${COLORS.label}"
    font-family="system-ui,sans-serif">${lbl.short} ${lbl.full}</text>
  <text x="${fmt(lp.x)}" y="${fmt(lp.y + dyOffset + 14)}"
    text-anchor="${anchor}"
    font-size="14" font-weight="700" fill="${scoreColor}"
    font-family="system-ui,sans-serif">${score}</text>`;
}).join('');

// Center dot
const centerDot = `<circle cx="${fmt(CX)}" cy="${fmt(CY)}" r="3" fill="${COLORS.axis}" opacity="0.4"/>`;

// Header: session + overall
const headerY = 28;
const header = session
  ? `<text x="${W / 2}" y="${headerY}"
      text-anchor="middle" font-size="12" fill="${COLORS.sublabel}"
      font-family="system-ui,sans-serif" opacity="0.8">Session: ${session}</text>`
  : '';

const overallBadge = overall != null ? `
  <!-- Overall score badge -->
  <rect x="${CX - 36}" y="${CY - 18}" width="72" height="36" rx="8"
    fill="white" stroke="${COLORS.border}" stroke-width="1.5"/>
  <text x="${CX}" y="${CY - 2}"
    text-anchor="middle" font-size="9" fill="${COLORS.sublabel}"
    font-family="system-ui,sans-serif">OVERALL</text>
  <text x="${CX}" y="${CY + 13}"
    text-anchor="middle" font-size="16" font-weight="700" fill="${COLORS.overall}"
    font-family="system-ui,sans-serif">${overall}</text>` : '';

// ─── Compose final SVG ────────────────────────────────────────────────────────

const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"
  xmlns="http://www.w3.org/2000/svg">

  <!-- Background -->
  <rect width="${W}" height="${H}" fill="${COLORS.bg}" rx="12"/>
  <rect x="1" y="1" width="${W - 2}" height="${H - 2}"
    fill="none" stroke="${COLORS.border}" stroke-width="1.5" rx="12"/>

  <!-- Header -->
  ${header}

  <!-- Grid -->
  ${gridPolygons}
  ${gridLabels}

  <!-- Axes -->
  ${axisLines}
  ${centerDot}

  <!-- Score polygon -->
  ${scorePolygon}

  <!-- Score dots -->
  ${dots}

  <!-- Dimension labels -->
  ${labelElements}

  <!-- Overall badge -->
  ${overallBadge}

</svg>`;

process.stdout.write(svg);

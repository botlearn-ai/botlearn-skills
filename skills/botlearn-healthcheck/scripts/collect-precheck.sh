#!/bin/bash
# collect-precheck.sh — Run `openclaw doctor --deep --non-interactive`, parse output to JSON
# Parses the ◇ section-box format used by openclaw doctor
# Timeout: 30s | Compatible: macOS (darwin) + Linux
set -euo pipefail

# Check if openclaw CLI is available
OPENCLAW_BIN=""
if command -v openclaw &>/dev/null; then
  OPENCLAW_BIN="openclaw"
elif command -v clawhub &>/dev/null; then
  OPENCLAW_BIN="clawhub"
fi

if [[ -z "$OPENCLAW_BIN" ]]; then
  cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cli_available": false,
  "precheck_ran": false,
  "status": "skipped",
  "message": "Neither openclaw nor clawhub CLI found",
  "sections": [],
  "summary": { "pass": 0, "warn": 0, "info": 0, "total": 0 }
}
EOF
  exit 0
fi

# Run openclaw doctor (built-in precheck) and capture output
PRECHECK_OUTPUT=""
PRECHECK_EXIT=0
PRECHECK_OUTPUT=$($OPENCLAW_BIN doctor --deep --non-interactive 2>&1) || PRECHECK_EXIT=$?

# Parse the output with Node.js
node -e '
const output = process.argv[1];
const exitCode = parseInt(process.argv[2]);

const result = {
  timestamp: new Date().toISOString(),
  cli_available: true,
  cli_used: process.argv[3],
  precheck_ran: true,
  exit_code: exitCode,
  sections: [],
  summary: { pass: 0, warn: 0, info: 0, total: 0 }
};

// Parse version from header line
const verMatch = output.match(/OpenClaw\s+([0-9]+\.[0-9]+[^\s(]*)\s*\(([0-9a-f]+)\)/);
if (verMatch) {
  result.version = verMatch[1];
  result.commit = verMatch[2];
}

const lines = output.split("\n");

// Parse ◇ section-box format used by openclaw doctor
// Format: ◇  Section name ─────╮ ... content lines ... ├─────╯
let currentSection = null;
let currentContent = [];

function flushSection() {
  if (!currentSection) return;
  const content = currentContent
    .map(l => l.replace(/^[│|]\s?/, "").replace(/\s*[│|]\s*$/, "").trim())
    .filter(l => l && !l.match(/^[├┤┌┐└┘─┼┬┴╋═\s]+$/));

  // Determine section severity based on content
  let severity = "info";
  const fullText = content.join(" ").toLowerCase();
  if (fullText.match(/not found|not installed|break|error|fail|does not match|not ready|not configured/)) {
    severity = "warn";
  }
  if (fullText.match(/no .* warnings detected|all .* pass/)) {
    severity = "pass";
  }

  result.sections.push({
    name: currentSection,
    severity,
    items: content
  });

  currentSection = null;
  currentContent = [];
}

for (const line of lines) {
  const t = line.trim();

  // Detect section header: ◇  Section name ───...╮
  const sectionMatch = t.match(/^◇\s+(.+?)\s*[─╮]+/);
  if (sectionMatch) {
    flushSection();
    currentSection = sectionMatch[1].trim();
    continue;
  }

  // Detect section with no box (plain ◇ line, e.g. agent info)
  if (t.startsWith("◇") && !t.includes("─")) {
    flushSection();
    currentSection = "__agents__";
    // The rest of the line after ◇ is content
    const rest = t.replace(/^◇\s*/, "").trim();
    if (rest) currentContent.push(rest);
    continue;
  }

  // Section end markers
  if (t.match(/^[├└].*[╯┘]/) || t === "│") {
    continue;
  }

  // Content inside a section
  if (currentSection && (t.startsWith("│") || t.startsWith("|") || t.startsWith("-") || t.match(/^\S/))) {
    if (currentSection === "__agents__") {
      // Agent info lines are not boxed
      if (t && !t.match(/^[├└│─]/) && !t.startsWith("Run ")) {
        currentContent.push(t);
      }
    } else if (t.startsWith("│") || t.startsWith("|")) {
      currentContent.push(t);
    } else if (t.startsWith("-") && currentSection) {
      currentContent.push(t);
    }
  }
}
flushSection();

// Calculate summary
for (const section of result.sections) {
  result.summary.total++;
  if (section.severity === "pass") result.summary.pass++;
  else if (section.severity === "warn") result.summary.warn++;
  else result.summary.info++;
}

// Overall status
if (result.summary.warn > 0) result.status = "warn";
else if (result.summary.pass > 0) result.status = "pass";
else result.status = "info";

console.log(JSON.stringify(result, null, 2));
' "$PRECHECK_OUTPUT" "$PRECHECK_EXIT" "$OPENCLAW_BIN"

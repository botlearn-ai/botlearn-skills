#!/bin/bash
# collect-channels.sh — Run `openclaw channels list`, parse output to JSON
# Parses: Config warnings, Chat channels, Auth providers, Plugin registration, Usage
# Timeout: 10s | Compatible: macOS (darwin) + Linux
set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"

if ! command -v openclaw &>/dev/null; then
  echo '{"timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","ran":false,"error":"openclaw CLI not found","channels":[],"auth_providers":[],"config_warnings":[],"plugins":[]}'
  exit 0
fi

# macOS has no `timeout` — use perl fallback
run_with_timeout() {
  local secs="$1"; shift
  if command -v timeout &>/dev/null; then
    timeout "$secs" "$@"
  else
    perl -e "alarm $secs; exec @ARGV" -- "$@"
  fi
}

raw_output=$(run_with_timeout 10 openclaw channels list 2>&1) || true

# Parse via temp file (bash 3.2 compat)
_tmpjs=$(mktemp /tmp/collect-channels-XXXXXX.js)
trap 'rm -f "$_tmpjs"' EXIT
cat > "$_tmpjs" <<'NODESCRIPT'
const raw = process.env.CHANNELS_RAW || "";
const lines = raw.split("\n");

const result = {
  timestamp: new Date().toISOString(),
  ran: true,
  config_warnings: [],
  plugins_loaded: [],
  chat_channels: [],
  auth_providers: [],
  usage: null,
  enabled_count: 0,
  disabled_count: 0,
  issues: []
};

// Parse version from header
const verMatch = raw.match(/OpenClaw\s+([0-9]+\.[0-9]+[^\s(]*)\s*\(([^)]+)\)/);
if (verMatch) {
  result.version = verMatch[1];
  result.commit = verMatch[2];
}

for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  const t = line.trim();

  // Config warnings: lines starting with "- " after "Config warnings:" or inside ◇ Config warnings box
  // Pattern: "- plugins.entries.feishu: ..."
  if (t.startsWith("- ") && t.includes(": ")) {
    const warnMatch = t.match(/^-\s+(.+)$/);
    if (warnMatch) {
      const msg = warnMatch[1];
      // Config warnings (contain field paths like "plugins.entries.xxx")
      if (msg.match(/^[a-z]+\.[a-z]+/)) {
        result.config_warnings.push(msg);
        continue;
      }
    }
  }

  // Plugin registration: "[plugins] name: Registered ..."
  const pluginMatch = t.match(/\[plugins\]\s+(\w+):\s+Registered\s+(.+)/);
  if (pluginMatch) {
    result.plugins_loaded.push({
      plugin: pluginMatch[1],
      tools: pluginMatch[2].split(/,\s*/).map(s => s.trim())
    });
    continue;
  }

  // Plugin auto-load warning
  const pluginWarnMatch = t.match(/\[plugins\]\s+plugins\.allow is empty.*?:\s+(\w+)/);
  if (pluginWarnMatch) {
    result.issues.push({
      type: "plugin_autoload",
      detail: "plugins.allow is empty, plugin " + pluginWarnMatch[1] + " may auto-load"
    });
    continue;
  }

  // Chat channels: "- Name: configured, enabled" or "- Name: configured, disabled"
  if (t.startsWith("- ") && (t.includes("configured") || t.includes("enabled") || t.includes("disabled"))) {
    // Parse: "- Feishu default: configured, enabled"
    const chMatch = t.match(/^-\s+(.+?):\s+(.*)/);
    if (chMatch && !chMatch[1].match(/^[a-z]+\.[a-z]+/)) {
      const name = chMatch[1].trim();
      const detail = chMatch[2].trim();
      const enabled = detail.includes("enabled");
      const configured = detail.includes("configured");
      result.chat_channels.push({ name, enabled, configured, detail });
      if (enabled) result.enabled_count++;
      else result.disabled_count++;
      continue;
    }
  }

  // Auth providers: "- name (type)"
  // Appears after "Auth providers (OAuth + API keys):" header
  if (t.startsWith("- ") && t.match(/\(.*(api_key|oauth|token).*\)/i)) {
    const authMatch = t.match(/^-\s+(.+?)\s+\(([^)]+)\)/);
    if (authMatch) {
      result.auth_providers.push({
        name: authMatch[1].trim(),
        type: authMatch[2].trim()
      });
      continue;
    }
  }

  // Usage line
  if (t.startsWith("Usage:")) {
    result.usage = t.replace(/^Usage:\s*/, "").trim();
  }
}

// Deduplicate config warnings
result.config_warnings = [...new Set(result.config_warnings)];

console.log(JSON.stringify(result, null, 2));
NODESCRIPT

CHANNELS_RAW="$raw_output" node "$_tmpjs"

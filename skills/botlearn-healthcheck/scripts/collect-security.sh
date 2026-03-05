#!/bin/bash
# collect-security.sh — Security risk assessment, output JSON
# Sources: 1) openclaw security audit  2) file permission checks  3) credential exposure scan
# PRIVACY: All credential values are REDACTED — only type + location are reported
# Timeout: 20s | Compatible: macOS (darwin) + Linux
set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"

# macOS has no `timeout` — use perl fallback
run_with_timeout() {
  local secs="$1"; shift
  if command -v timeout &>/dev/null; then
    timeout "$secs" "$@"
  else
    perl -e "alarm $secs; exec @ARGV" -- "$@"
  fi
}

# Capture openclaw security audit if available
security_audit=""
if command -v openclaw &>/dev/null; then
  security_audit=$(run_with_timeout 15 openclaw security audit --deep --json 2>/dev/null) || security_audit=""
fi

# Parse and augment with file-level checks via temp file (bash 3.2 compat)
_tmpjs=$(mktemp /tmp/collect-security-XXXXXX.js)
trap 'rm -f "$_tmpjs"' EXIT
cat > "$_tmpjs" <<'NODESCRIPT'
const fs = require("fs");
const path = require("path");

const HOME = process.env.OPENCLAW_HOME || (process.env.HOME + "/.openclaw");

const result = {
  timestamp: new Date().toISOString(),
  // 1. Platform security audit (from openclaw CLI)
  platform_audit: null,
  // 2. File permission checks
  file_permissions: { findings: [], checked: 0, issues: 0 },
  // 3. Credential exposure scan
  credential_exposure: { findings: [], scanned: 0, issues: 0 },
  // 4. Network exposure (from config)
  network_exposure: { findings: [] },
  // Summary
  summary: { critical: 0, high: 0, warning: 0, info: 0 }
};

// ── 1. Platform Security Audit ──────────────────────────────────────────────
const auditRaw = process.env.SECURITY_AUDIT || "";
if (auditRaw) {
  try {
    const audit = JSON.parse(auditRaw);
    result.platform_audit = {
      summary: audit.summary || null,
      findings: (audit.findings || []).map(f => ({
        id: f.checkId,
        severity: f.severity,
        title: f.title,
        detail: (f.detail || "").substring(0, 300),
        remediation: f.remediation || null
      }))
    };
    // Count platform findings
    for (const f of result.platform_audit.findings) {
      if (f.severity === "critical") result.summary.critical++;
      else if (f.severity === "high") result.summary.high++;
      else if (f.severity === "warn" || f.severity === "warning") result.summary.warning++;
      else result.summary.info++;
    }
  } catch {}
}

// ── 2. File Permission Checks ───────────────────────────────────────────────
// Sensitive files/dirs that should be owner-only (0600/0700)
const sensitiveTargets = [
  HOME + "/openclaw.json",
  HOME + "/identity",
  HOME + "/.env"
];

// Find auth-profiles.json in agent dirs
try {
  const agentsDir = HOME + "/agents";
  if (fs.existsSync(agentsDir)) {
    for (const agent of fs.readdirSync(agentsDir)) {
      const authFile = path.join(agentsDir, agent, "agent", "auth-profiles.json");
      if (fs.existsSync(authFile)) sensitiveTargets.push(authFile);
    }
  }
} catch {}

// Find .key/.pem/.p12 files
function findSensitiveFiles(dir, depth) {
  if (depth <= 0 || !fs.existsSync(dir)) return [];
  const found = [];
  try {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const fp = path.join(dir, e.name);
      if (e.isDirectory() && !e.name.startsWith(".") && depth > 1) {
        found.push(...findSensitiveFiles(fp, depth - 1));
      } else if (e.isFile()) {
        if (/\.(key|pem|p12|pfx)$/.test(e.name)) found.push(fp);
      }
    }
  } catch {}
  return found;
}
sensitiveTargets.push(...findSensitiveFiles(HOME, 3));

for (const fp of sensitiveTargets) {
  if (!fs.existsSync(fp)) continue;
  result.file_permissions.checked++;
  try {
    const stat = fs.statSync(fp);
    const mode = (stat.mode & 0o777).toString(8);
    const worldReadable = (stat.mode & 0o004) !== 0;
    const groupWritable = (stat.mode & 0o020) !== 0;
    if (worldReadable || groupWritable) {
      const issue = worldReadable ? "world-readable" : "group-writable";
      result.file_permissions.findings.push({
        file: fp.replace(process.env.HOME, "~"),
        mode, issue, recommended: stat.isDirectory() ? "0700" : "0600"
      });
      result.summary.warning++;
    }
  } catch {}
}
result.file_permissions.issues = result.file_permissions.findings.length;

// ── 3. Credential Exposure Scan ─────────────────────────────────────────────
const SECRET_PATTERNS = [
  { name: "api_key",     regex: /(?:api[_-]?key|apikey)\s*[:=]\s*["']?([A-Za-z0-9_\-]{20,})/gi },
  { name: "secret",      regex: /(?:secret|client_secret)\s*[:=]\s*["']?([A-Za-z0-9_\-]{20,})/gi },
  { name: "token",       regex: /(?:token|access_token|bearer)\s*[:=]\s*["']?([A-Za-z0-9_\-\.]{20,})/gi },
  { name: "password",    regex: /(?:password|passwd|pwd)\s*[:=]\s*["']?([^\s"']{8,})/gi },
  { name: "private_key", regex: /-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----/gi }
];

function scanForSecrets(filePath) {
  try {
    const stat = fs.statSync(filePath);
    if (stat.size > 1024 * 1024) return []; // skip files > 1MB
    const content = fs.readFileSync(filePath, "utf8");
    const findings = [];
    for (const pat of SECRET_PATTERNS) {
      pat.regex.lastIndex = 0;
      let match;
      while ((match = pat.regex.exec(content)) !== null) {
        const lineNum = content.substring(0, match.index).split("\n").length;
        findings.push({
          type: pat.name,
          file: filePath.replace(process.env.HOME, "~"),
          line: lineNum,
          value: "***REDACTED***"
        });
        if (findings.length >= 5) break; // cap per file
      }
    }
    return findings;
  } catch { return []; }
}

// Scan: config files, .env, log files (limited)
const scanDirs = [
  { dir: HOME, exts: [".json", ".yaml", ".yml", ".toml", ".env", ".conf"], depth: 1 },
  { dir: HOME + "/config", exts: ["*"], depth: 2 },
  { dir: HOME + "/logs", exts: [".log", ".err.log"], depth: 1 }
];

const scanTargets = new Set();
for (const { dir, exts, depth } of scanDirs) {
  if (!fs.existsSync(dir)) continue;
  function collect(d, dep) {
    if (dep <= 0) return;
    try {
      for (const e of fs.readdirSync(d, { withFileTypes: true })) {
        const fp = path.join(d, e.name);
        if (e.isDirectory() && !e.name.startsWith(".") && dep > 1) collect(fp, dep - 1);
        else if (e.isFile()) {
          const ext = path.extname(e.name).toLowerCase();
          if (exts.includes("*") || exts.includes(ext) || exts.some(x => e.name.endsWith(x))) {
            scanTargets.add(fp);
          }
        }
      }
    } catch {}
  }
  collect(dir, depth);
}

// Also check .env at home level
const envFile = HOME + "/.env";
if (fs.existsSync(envFile)) scanTargets.add(envFile);

result.credential_exposure.scanned = scanTargets.size;
for (const f of scanTargets) {
  const findings = scanForSecrets(f);
  if (findings.length > 0) {
    result.credential_exposure.findings.push(...findings);
    result.summary.high += findings.length;
  }
}
result.credential_exposure.issues = result.credential_exposure.findings.length;

// ── 4. Network Exposure (from config) ───────────────────────────────────────
try {
  const raw = fs.readFileSync(HOME + "/openclaw.json", "utf8");
  const clean = raw.replace(/"(?:[^"\\]|\\.)*"|\/\/[^\n]*|\/\*[\s\S]*?\*\//g, m =>
    m.startsWith('"') ? m : '');
  const config = JSON.parse(clean);
  const gw = config.gateway || {};
  const bind = gw.bind || "loopback";
  const authType = gw.auth?.type || "none";

  if (bind !== "loopback" && (authType === "none" || !authType)) {
    result.network_exposure.findings.push({
      severity: "critical", type: "unauthenticated_exposure",
      detail: "Gateway bind=" + bind + " with no auth"
    });
    result.summary.critical++;
  }
  if (bind !== "loopback" && gw.controlUI !== false) {
    result.network_exposure.findings.push({
      severity: "warning", type: "control_ui_exposed",
      detail: "Control UI accessible on bind=" + bind
    });
    result.summary.warning++;
  }
  if (bind === "lan" && authType !== "none" && !gw.ssl?.enabled) {
    result.network_exposure.findings.push({
      severity: "warning", type: "no_ssl",
      detail: "LAN bind with auth but no SSL — credentials in plaintext"
    });
    result.summary.warning++;
  }
} catch {}

console.log(JSON.stringify(result, null, 2));
NODESCRIPT

OPENCLAW_HOME="$OPENCLAW_HOME" SECURITY_AUDIT="$security_audit" node "$_tmpjs"

#!/bin/bash
# collect-config.sh — Collect and validate OpenClaw configuration, output JSON
# Config: ~/.openclaw/openclaw.json (JSON5 format, supports // and /* */ comments)
# Timeout: 10s | Compatible: macOS (darwin) + Linux
set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$OPENCLAW_HOME/openclaw.json}"

node <<'NODESCRIPT'
const fs = require("fs");
const path = require("path");

const HOME = process.env.OPENCLAW_HOME || (process.env.HOME + "/.openclaw");
const CONFIG = process.env.OPENCLAW_CONFIG_PATH || (HOME + "/openclaw.json");

const result = {
  timestamp: new Date().toISOString(),
  openclaw_home: HOME.replace(process.env.HOME, "~"),
  config_file: CONFIG.replace(process.env.HOME, "~"),
  config_exists: false,
  config_valid_json: false,
  sections: {
    gateway: false,
    agents: false,
    messages: false,
    session: false,
    tools: false
  },
  values: {
    gateway_port: 0,
    gateway_bind: "unknown",
    gateway_mode: "unknown",
    gateway_auth: "unknown",
    gateway_reload: "unknown",
    max_concurrent: 0,
    timeout_seconds: 0,
    heartbeat_interval: 0,
    tools_profile: "unknown"
  },
  missing_env_vars: [],
  directories: {},
  issues: []
};

// Check config file
if (fs.existsSync(CONFIG)) {
  result.config_exists = true;
  try {
    const raw = fs.readFileSync(CONFIG, "utf8");
    // Strip JSON5 comments (// line comments and /* */ block comments)
    const clean = raw.replace(/\/\/.*$/gm, "").replace(/\/\*[\s\S]*?\*\//g, "");
    const config = JSON.parse(clean);
    result.config_valid_json = true;

    // Check sections
    result.sections.gateway = !!config.gateway;
    result.sections.agents = !!config.agents;
    result.sections.messages = !!config.messages;
    result.sections.session = !!config.session;
    result.sections.tools = !!config.tools;

    // Extract key values
    result.values.gateway_port = config.gateway?.port || 18789;
    result.values.gateway_bind = config.gateway?.bind || "loopback";
    result.values.gateway_mode = config.gateway?.mode || "ws+http";
    result.values.gateway_auth = config.gateway?.auth?.type || "none";
    result.values.gateway_reload = config.gateway?.reload || "hybrid";
    result.values.max_concurrent = config.agents?.defaults?.maxConcurrent || 3;
    result.values.timeout_seconds = config.agents?.defaults?.timeoutSeconds || 600;
    result.values.heartbeat_interval = config.agents?.heartbeat?.intervalMinutes || 30;
    result.values.tools_profile = config.tools?.profile || "coding";
  } catch (e) {
    result.issues.push("Invalid JSON/JSON5 syntax: " + e.message);
  }
} else {
  result.issues.push("Config file not found at " + CONFIG.replace(process.env.HOME, "~"));
}

// Check environment variables
const envVars = ["OPENCLAW_HOME", "OPENCLAW_CONFIG_PATH", "OPENCLAW_STATE_DIR"];
for (const v of envVars) {
  if (!process.env[v]) result.missing_env_vars.push(v);
}

// Check directory structure
const dirs = ["config", "skills", "plugins", "memory", "logs", "data", "workspace"];
for (const dir of dirs) {
  result.directories[dir] = fs.existsSync(path.join(HOME, dir));
}

console.log(JSON.stringify(result, null, 2));
NODESCRIPT

# BotLearn CLI — Benchmark commands
# Sourced by botlearn.sh — do not run directly

# Note: the session-derived skill usage feature was retired 2026-04-29.
# OpenClaw injects SKILL.md into the system prompt rather than via Read tool calls,
# so the parser's "explicit Read of SKILL.md" signal was permanently 0 in practice.
# parse-session-skills.mjs and the --agent / --no-session-skills flags are gone.

cmd_scan() {
  # Temp file tracking for cleanup on exit/interrupt
  local _scan_tmp_files=()
  _scan_cleanup() { rm -f "${_scan_tmp_files[@]}" 2>/dev/null; }
  trap '_scan_cleanup' EXIT INT TERM

  # ── Flag parsing ──
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h)
        echo "Usage: botlearn.sh scan"
        echo "  Scans the local environment (hardware, OS, platform config, installed skills)"
        echo "  and uploads a benchmark config to BotLearn. No flags."
        return 0
        ;;
      *) shift ;;
    esac
  done

  echo "🔍 Scanning environment..."
  echo ""
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

  # ── Hardware ──
  local cpu_model="" cpu_cores="" mem_gb="" cpu_arch os_type
  cpu_arch=$(uname -m)
  os_type=$(uname -s)
  if [ "$os_type" = "Darwin" ]; then
    cpu_model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)
    cpu_cores=$(sysctl -n hw.physicalcpu 2>/dev/null || true)
    local mem_bytes
    mem_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    local mem_num=$(( ${mem_bytes:-0} / 1073741824 ))
    [ "$mem_num" -gt 0 ] && mem_gb="${mem_num}GB"
  else
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | sed 's/.*: //' || true)
    # Prefer physical cores from 'cpu cores' field; fallback to logical processor count
    cpu_cores=$(grep -m1 'cpu cores' /proc/cpuinfo 2>/dev/null | awk '{print $NF}' || true)
    [ -z "$cpu_cores" ] && cpu_cores=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || true)
    local mem_kb
    # In cgroup v2 containers, /sys/fs/cgroup/memory.max reflects actual limit
    if [ -f /sys/fs/cgroup/memory.max ] && [ "$(cat /sys/fs/cgroup/memory.max 2>/dev/null)" != "max" ]; then
      local cg_bytes
      cg_bytes=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo "0")
      local mem_num=$(( ${cg_bytes:-0} / 1073741824 ))
      [ "$mem_num" -gt 0 ] && mem_gb="${mem_num}GB"
    else
      mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "0")
      local mem_num=$(( ${mem_kb:-0} / 1048576 ))
      [ "$mem_num" -gt 0 ] && mem_gb="${mem_num}GB"
    fi
  fi
  info "├─ CPU: ${cpu_model:-unknown} (${cpu_cores:-?} cores, ${mem_gb:-?} RAM, $cpu_arch)"

  # ── OS ──
  local os_info shell_info container_hint=""
  os_info="$(uname -s) $(uname -r) $(uname -m)"
  # $SHELL is often unset in Docker/CI/cron; detect running shell as fallback
  shell_info="${SHELL:-$(readlink /proc/$$/exe 2>/dev/null || command -v sh 2>/dev/null || echo unknown)}"
  # Container detection hint
  if [ -f /.dockerenv ] || grep -qsE 'docker|containerd' /proc/1/cgroup 2>/dev/null; then
    container_hint="docker"
  elif [ -n "${KUBERNETES_SERVICE_HOST:-}" ]; then
    container_hint="k8s"
  fi
  if [ "$os_type" != "Darwin" ] && [ -f /etc/os-release ]; then
    local distro
    distro=$(grep '^NAME=' /etc/os-release 2>/dev/null | sed 's/NAME=//;s/"//g' || true)
    [ -n "$distro" ] && os_info="$distro ($os_info)"
  fi
  [ -n "$container_hint" ] && os_info="$os_info [container:$container_hint]"
  info "├─ OS: $os_info"

  # ── Node.js ──
  local node_ver="" npm_ver="" pnpm_ver=""
  node_ver=$(node --version 2>/dev/null || true)
  npm_ver=$(npm --version 2>/dev/null || true)
  pnpm_ver=$(pnpm --version 2>/dev/null || true)
  info "├─ Node: ${node_ver:-not found}, pnpm: ${pnpm_ver:-not found}"

  # ── Platform detection ──
  local platform
  platform=$(detect_platform)
  info "├─ Platform: $platform"

  # ── Model info ──
  local model_info=""
  if [ "$platform" = "claude_code" ]; then
    model_info="${CLAUDE_MODEL:-${ANTHROPIC_MODEL:-}}"
    if [ -z "$model_info" ] && [ -f "$WORKSPACE/.claude/settings.json" ]; then
      model_info=$(grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$WORKSPACE/.claude/settings.json" 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//' || true)
    fi
  elif [ "$platform" = "openclaw" ]; then
    # model_info collected later in parallel batch
    :
  fi

  # ── Platform-specific config collection ──
  local openclaw_ver="" openclaw_config_file="" openclaw_config_content=""
  local openclaw_doctor="" openclaw_status="" openclaw_logs_raw=""
  local platform_config_content=""
  local automation_hooks="[]" trigger_count=0 scheduled_task_count=0

  if [ "$platform" = "openclaw" ] && command -v openclaw >/dev/null 2>&1; then
    info "├─ Collecting openclaw data..."

    # Phase 1: fast serial commands (version ~0.2s, config file ~9s)
    openclaw_ver=$(run_with_timeout 5 openclaw --version 2>/dev/null | head -1 || echo "not found")
    openclaw_config_file=$(run_with_timeout 15 openclaw config file 2>/dev/null | grep -v '^[[:space:]]*$' | tail -1 || true)
    openclaw_config_file="${openclaw_config_file/#\~/$HOME}"

    if [ -n "$openclaw_config_file" ] && [ -f "$openclaw_config_file" ]; then
      local raw_config
      raw_config=$(cat "$openclaw_config_file" 2>/dev/null || echo "{}")
      openclaw_config_content=$(redact_keys "$raw_config")
      platform_config_content="$openclaw_config_content"

      # Parse hooks from config JSON: extract enabled entries from hooks.<group>.entries
      automation_hooks=$(cat "$openclaw_config_file" | node -e "
let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
  try{const cfg=JSON.parse(d);const r=[];
    for(const[g,gv] of Object.entries(cfg.hooks||{}))
      if(gv&&gv.entries)for(const[e,ev] of Object.entries(gv.entries))
        if(ev&&ev.enabled)r.push(g+':'+e);
    console.log(JSON.stringify(r))
  }catch(e){console.log('[]')}
})" 2>/dev/null || echo '[]')

      # Scheduled tasks: count entries from "openclaw cron list"
      scheduled_task_count=$(run_with_timeout 10 openclaw cron list 2>/dev/null | grep -cE '^[0-9a-f]{8}-' || echo 0)
      trigger_count=0
    fi

    # Phase 2: slow commands in parallel (models ~20s, doctor/status/logs ~0-15s)
    local tmp_doctor tmp_status tmp_logs tmp_models
    tmp_doctor=$(mktemp); _scan_tmp_files+=("$tmp_doctor")
    tmp_status=$(mktemp); _scan_tmp_files+=("$tmp_status")
    tmp_logs=$(mktemp);   _scan_tmp_files+=("$tmp_logs")
    tmp_models=$(mktemp); _scan_tmp_files+=("$tmp_models")

    (run_with_timeout 15 openclaw doctor --deep --non-interactive 2>/dev/null || echo "command unavailable or timed out") > "$tmp_doctor" &
    local pid_doctor=$!
    (run_with_timeout 15 openclaw status --all --deep 2>/dev/null || echo "command unavailable or timed out") > "$tmp_status" &
    local pid_status=$!
    (run_with_timeout 10 openclaw logs 2>/dev/null || true) > "$tmp_logs" &
    local pid_logs=$!
    (run_with_timeout 15 openclaw models list 2>/dev/null | grep -v '^Config' | grep -v '^🦞' | grep -v '^[[:space:]]*$' | grep -v '^Model' || true) > "$tmp_models" &
    local pid_models=$!

    wait "$pid_doctor" "$pid_status" "$pid_logs" "$pid_models" 2>/dev/null || true

    openclaw_doctor=$(redact_keys "$(cat "$tmp_doctor")" | process_logs 200 30000)
    openclaw_status=$(redact_keys "$(cat "$tmp_status")" | process_logs 200 30000)
    openclaw_logs_raw=$(redact_keys "$(cat "$tmp_logs")" | process_logs 150 50000)

    # Parse model info from parallel result
    local models_raw
    models_raw=$(cat "$tmp_models")
    if [ -n "$models_raw" ]; then
      local default_model all_models
      default_model=$(echo "$models_raw" | grep -i 'default' | head -1 | awk '{print $1}' || true)
      all_models=$(echo "$models_raw" | awk '{print $1}' | grep -v "^${default_model}$" | paste -sd',' - || true)
      model_info="${default_model}${all_models:+,$all_models}"
    fi
    rm -f "$tmp_doctor" "$tmp_status" "$tmp_logs" "$tmp_models" 2>/dev/null

  elif [ "$platform" = "claude_code" ] && [ -f "$WORKSPACE/.claude/settings.json" ]; then
    info "├─ Collecting Claude Code settings..."
    local raw_settings
    raw_settings=$(cat "$WORKSPACE/.claude/settings.json" 2>/dev/null || echo "{}")
    platform_config_content=$(redact_keys "$raw_settings")

    # Extract hook event names (CapitalizedWord keys inside "hooks": { ... })
    local hook_names
    hook_names=$(grep -o '"[A-Z][A-Za-z]*"[[:space:]]*:[[:space:]]*\[' "$WORKSPACE/.claude/settings.json" 2>/dev/null \
      | sed 's/[[:space:]]*:[[:space:]]*\[//' | tr -d '"' | tr '\n' ',' | sed 's/,$//' || true)
    if [ -n "$hook_names" ]; then
      automation_hooks=$(printf '[%s]' "$(echo "$hook_names" | sed 's/\([^,]*\)/"\1"/g')")
    fi

    if [ -f "$WORKSPACE/.claude/scheduled_tasks.json" ]; then
      scheduled_task_count=$(grep -c '"id"' "$WORKSPACE/.claude/scheduled_tasks.json" 2>/dev/null || echo 0)
    fi
  fi

  # ── Multi-workspace skill scanning ──
  local workspace_list
  workspace_list=("$WORKSPACE")

  # Parse additional workspace paths from openclaw config
  if [ -n "$openclaw_config_file" ] && [ -f "$openclaw_config_file" ]; then
    while IFS= read -r extra_ws; do
      [ -n "$extra_ws" ] && [ -d "$extra_ws" ] && [ "$extra_ws" != "$WORKSPACE" ] && \
        workspace_list+=("$extra_ws")
    done < <(grep -o '"[a-zA-Z]*[Pp]ath"[[:space:]]*:[[:space:]]*"/[^"]*"' "$openclaw_config_file" 2>/dev/null \
      | sed 's/.*: *"//;s/"$//' | sort -u || true)
  fi

  local skills_json="["
  local total_skill_count=0
  local workspace_count=${#workspace_list[@]}
  local report_body=""

  for ws in "${workspace_list[@]}"; do
    [ -d "$ws" ] || continue
    local ws_section="" ws_skill_count=0 doc_count=0

    ws_section+="### $ws"$'\n'

    # Skills
    if [ -d "$ws/skills" ]; then
      ws_section+="**Skills:**"$'\n'
      for skill_dir in "$ws/skills"/*/; do
        [ -d "$skill_dir" ] || continue
        local sname sversion scategory sdescription
        sname=$(basename "$skill_dir")
        sversion="unknown" scategory="" sdescription=""

        # Priority 1: Parse SKILL.md / SKILL.md frontmatter (first 20 lines)
        local skill_md=""
        for md in "$skill_dir/skill.md" "$skill_dir/SKILL.md"; do
          if [ -f "$md" ]; then skill_md="$md"; break; fi
        done
        if [ -n "$skill_md" ]; then
          local frontmatter
          frontmatter=$(head -20 "$skill_md" | sed -n '/^---$/,/^---$/p' | grep -v '^---$' || true)
          local md_name md_ver md_cat md_desc
          md_name=$(echo "$frontmatter" | grep -o '^name:[[:space:]]*.*' | head -1 | sed 's/^name:[[:space:]]*//' | sed 's/^"//;s/"$//' || true)
          md_ver=$(echo "$frontmatter" | grep -o '^version:[[:space:]]*.*' | head -1 | sed 's/^version:[[:space:]]*//' | sed 's/^"//;s/"$//' || true)
          md_desc=$(echo "$frontmatter" | grep -o '^description:[[:space:]]*.*' | head -1 | sed 's/^description:[[:space:]]*//' | sed "s/^>-[[:space:]]*//" | sed 's/^"//;s/"$//' || true)
          # Category may be nested under metadata.<skillname>.category
          md_cat=$(echo "$frontmatter" | grep -o 'category:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//' || true)
          [ -n "$md_name" ] && sname="$md_name"
          [ -n "$md_ver" ] && sversion="$md_ver"
          [ -n "$md_cat" ] && scategory="$md_cat"
          [ -n "$md_desc" ] && sdescription="$md_desc"
        fi

        # Priority 2: Fallback to skill.json / package.json for missing fields
        for meta in "$skill_dir/skill.json" "$skill_dir/package.json"; do
          if [ -f "$meta" ]; then
            local v c d
            v=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$meta" 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//' || true)
            c=$(grep -o '"category"[[:space:]]*:[[:space:]]*"[^"]*"' "$meta" 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//' || true)
            d=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$meta" 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//' || true)
            [ -z "$sversion" ] && [ -n "$v" ] && sversion="$v"
            [ -z "$scategory" ] && [ -n "$c" ] && scategory="$c"
            [ -z "$sdescription" ] && [ -n "$d" ] && sdescription="$d"
            break
          fi
        done

        [ "$total_skill_count" -gt 0 ] && skills_json+=","
        skills_json+="{\"name\":\"$(json_str "$sname")\",\"version\":\"$(json_str "$sversion")\",\"category\":\"$(json_str "$scategory")\",\"description\":\"$(json_str "$sdescription")\",\"workspace\":\"$(json_str "$ws")\"}"
        total_skill_count=$((total_skill_count + 1))
        ws_skill_count=$((ws_skill_count + 1))
        ws_section+="  - $sname ($sversion)"$'\n'
      done
    else
      ws_section+="*(no skills/ directory)*"$'\n'
    fi
    ws_section+=$'\n'

    # Uppercase *.md documents (workspace root only, basename must be all A-Z)
    ws_section+="**Documents (uppercase *.md):**"$'\n'
    for md_file in "$ws"/*.md; do
      [ -f "$md_file" ] || continue
      local bname
      bname=$(basename "$md_file" .md)
      [[ "$bname" =~ ^[A-Z]+$ ]] || continue
      local file_content
      file_content=$(cat "$md_file" 2>/dev/null || true)
      [ ${#file_content} -gt 51200 ] && file_content="${file_content:0:51200}"$'\n'"...[truncated at 50KB]"
      file_content=$(redact_keys "$file_content")
      ws_section+="#### $(basename "$md_file")"$'\n'"$file_content"$'\n\n'
      doc_count=$((doc_count + 1))
    done
    [ "$doc_count" -eq 0 ] && ws_section+="*(no all-uppercase *.md files found)*"$'\n'
    ws_section+=$'\n'

    info "├─ Workspace $(basename "$ws"): $ws_skill_count skills, $doc_count docs"
    report_body+="$ws_section"
  done
  skills_json+="]"
  info "└─ Total: $total_skill_count skills across $workspace_count workspace(s)"

  # ── Build payload via node for reliable JSON ──
  # Write raw field values to a temp file, then let node build safe JSON.
  local tmp_env
  tmp_env=$(mktemp); _scan_tmp_files+=("$tmp_env")
  cat > "$tmp_env" <<ENV_EOF
platform=$platform
os_info=$os_info
model_info=$model_info
skills_json=$skills_json
scheduled_task_count=$scheduled_task_count
trigger_count=$trigger_count
automation_hooks=$automation_hooks
cpu_model=$cpu_model
cpu_cores=$cpu_cores
mem_gb=$mem_gb
cpu_arch=$cpu_arch
shell_info=$shell_info
node_ver=$node_ver
npm_ver=$npm_ver
pnpm_ver=$pnpm_ver
openclaw_ver=$openclaw_ver
openclaw_config_file=$openclaw_config_file
workspace_count=$workspace_count
total_skill_count=$total_skill_count
now=$now
ENV_EOF

  # recentActivity content (may contain multiline / special chars) via separate file
  local tmp_recent=""
  if [ -n "$openclaw_logs_raw" ]; then
    tmp_recent=$(mktemp); _scan_tmp_files+=("$tmp_recent")
    printf '%s' "$openclaw_logs_raw" > "$tmp_recent"
  fi

  local payload
  payload=$(node -e "
const fs=require('fs');
const lines=fs.readFileSync(process.argv[1],'utf8').split('\n');
const v={};
lines.forEach(l=>{const i=l.indexOf('=');if(i>0)v[l.slice(0,i)]=l.slice(i+1)});

const s=k=>v[k]||'';
const n=k=>parseInt(v[k])||0;
const j=k=>{try{return JSON.parse(v[k])}catch(e){return null}};

const payload={
  platform:s('platform'),
  osInfo:s('os_info'),
  modelInfo:s('model_info')||null,
  installedSkills:j('skills_json')||[],
  automationConfig:{
    scheduledTaskCount:n('scheduled_task_count'),
    triggerCount:n('trigger_count'),
    hooks:j('automation_hooks')||[]
  },
  recentActivity:process.argv[2]?(()=>{
    const crypto=require('crypto');
    const content=fs.readFileSync(process.argv[2],'utf8');
    return {
      source:'openclaw_logs',
      content,
      contentHash:crypto.createHash('sha256').update(content).digest('hex').slice(0,16),
      collectedAt:s('now')
    };
  })():null,
  environmentMeta:{
    cpu:s('cpu_model'),
    cores:s('cpu_cores'),
    memory:s('mem_gb'),
    arch:s('cpu_arch'),
    shell:s('shell_info'),
    node:s('node_ver'),
    npm:s('npm_ver'),
    pnpm:s('pnpm_ver'),
    openclawVersion:s('openclaw_ver'),
    openclawConfigFile:s('openclaw_config_file'),
    workspaceCount:n('workspace_count'),
    totalSkillCount:n('total_skill_count')
  },
};
process.stdout.write(JSON.stringify(payload));
" "$tmp_env" "$tmp_recent" 2>/dev/null) || die "Failed to build config payload"
  rm -f "$tmp_env" "$tmp_recent" 2>/dev/null

  # ── Write local report ──
  local report_file="$WORKSPACE/.botlearn/scan-report.md"
  mkdir -p "$WORKSPACE/.botlearn"
  {
    printf '# BotLearn Environment Scan Report\n\nGenerated: %s\nWorkspace: %s\n\n' "$now" "$WORKSPACE"
    printf '## Hardware\n- CPU: %s\n- Physical Cores: %s\n- Memory: %s\n- Architecture: %s\n\n' \
      "${cpu_model:-unknown}" "${cpu_cores:-unknown}" "${mem_gb:-unknown}" "$cpu_arch"
    printf '## Operating System\n- OS: %s\n- Shell: %s\n\n' "$os_info" "${shell_info:-unknown}"
    printf '## Node.js Environment\n- Node.js: %s\n- npm:     %s\n- pnpm:    %s\n\n' \
      "${node_ver:-not found}" "${npm_ver:-not found}" "${pnpm_ver:-not found}"
    printf '## Platform: %s\n' "$platform"
    [ -n "$model_info" ] && printf -- '- Model: %s\n' "$model_info"
    printf '\n'
    if [ "$platform" = "openclaw" ]; then
      printf '### Version\n```\n%s\n```\n\n' "$openclaw_ver"
      printf '### Config File: %s\n```json\n%s\n```\n\n' "${openclaw_config_file:-not found}" "$openclaw_config_content"
      printf '### openclaw doctor --deep --non-interactive\n```\n%s\n```\n\n' "$openclaw_doctor"
      printf '### openclaw status --all --deep\n```\n%s\n```\n\n' "$openclaw_status"
      printf '### openclaw logs (recent)\n```\n%s\n```\n\n' "$openclaw_logs_raw"
    elif [ "$platform" = "claude_code" ]; then
      printf '### .claude/settings.json\n```json\n%s\n```\n\n' "$platform_config_content"
    fi
    printf '## Automation Config\n- Scheduled Tasks: %s\n- Triggers: %s\n- Hooks: %s\n\n' \
      "$scheduled_task_count" "$trigger_count" "$automation_hooks"
    printf '## Workspaces & Skills (%s workspace(s), %s total)\n\n' "$workspace_count" "$total_skill_count"
    printf '%s' "$report_body"
  } > "$report_file"
  ok "Local report saved: $report_file"

  # ── Upload ──
  echo ""
  echo "  📤 Uploading config..."
  local result
  result=$(api POST "/benchmark/config" "$payload")

  local config_id
  config_id=$(echo "$result" | grep -o '"configId"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//;s/"$//')
  [ -z "$config_id" ] && die "Scan upload failed: $result"

  # ── Update state.json ──
  if [ -f "$STATE_FILE" ]; then
    local tmp
    tmp=$(mktemp)
    sed \
      -e "s|\"lastScanAt\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"lastScanAt\": \"$now\"|g" \
      -e "s|\"lastScanFile\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"lastScanFile\": \"$report_file\"|g" \
      -e "s|\"skillCount\"[[:space:]]*:[[:space:]]*[0-9]*|\"skillCount\": $total_skill_count|g" \
      -e "s|\"lastConfigId\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"lastConfigId\": \"$config_id\"|g" \
      "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE" || true
  fi

  # ── Display ──
  echo ""
  echo "  ┌──────────────────────────────────────────┐"
  printf "  │  Workspaces:   %-27s│\n" "$workspace_count"
  printf "  │  Total skills: %-27s│\n" "$total_skill_count"
  printf "  │  Config ID:    %-27s│\n" "$config_id"
  echo "  ├──────────────────────────────────────────┤"
  printf "  │  Report: %-35s│\n" ".botlearn/scan-report.md"
  echo "  └──────────────────────────────────────────┘"
  echo ""
  ok "Config uploaded. Local report saved."
  echo "  BOTLEARN_CONFIG_ID=$config_id"
  echo "  To view: cat $report_file"
}

cmd_exam_start() {
  local config_id="${1:?Usage: botlearn.sh exam-start <config_id> [previous_session_id]}"
  local prev_id="${2:-}"
  local body="{\"configId\":\"$(json_str "$config_id")\""
  [ -n "$prev_id" ] && body+=",\"previousSessionId\":\"$(json_str "$prev_id")\""
  body+="}"

  echo "📝 Starting exam..."
  local result
  result=$(api POST "/benchmark/start" "$body")

  # Extract session ID and question count for display
  local session_id
  session_id=$(echo "$result" | grep -o '"sessionId"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')
  local q_count
  q_count=$(echo "$result" | grep -o '"questionCount"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/.*: *//')
  # Time limit fields (present iff platform_config benchmark.session.time_limit_seconds > 0)
  local expires_at
  expires_at=$(echo "$result" | grep -o '"expiresAt"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')
  local secs_left
  secs_left=$(echo "$result" | grep -o '"secondsRemaining"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/.*: *//')

  ok "Exam started. Session: $session_id, Questions: ${q_count:-?}"
  if [ -n "$expires_at" ] && [ "$expires_at" != "null" ]; then
    # Persist for resume + agent inspection. Display as minutes for human-friendly output.
    state_set "benchmark.lastExpiresAt" "$expires_at"
    if [ -n "$secs_left" ] && [ "$secs_left" -gt 0 ] 2>/dev/null; then
      local mins_left=$((secs_left / 60))
      info "⏱  Session expires at $expires_at (${mins_left} min remaining). Auto-submit on timeout."
    fi
  fi
  echo ""
  echo "BOTLEARN_SESSION_ID=$session_id"
  echo ""
  # Output full response for agent to parse questions
  echo "$result"
}

cmd_answer() {
  # Usage: botlearn.sh answer <session_id> <question_id> <question_index> <answer_type> <answer_json_file>
  #
  # answer_json_file: path to a file containing the answer.
  #   JSON format (preferred):
  #     Practical:  {"output":"<result>","artifacts":{"commandRun":"<cmd>","durationMs":1234}}
  #     Scenario:   {"text":"<reasoned response>"}
  #   Plain text (auto-wrapped):
  #     Any text that is not valid JSON will be automatically wrapped into {"text":"..."}.
  #
  # Why file-based: shell argument passing breaks on quotes, newlines, and nested JSON.
  # Write the answer to a file first, then call this command.
  local session_id="${1:?Usage: botlearn.sh answer <session_id> <question_id> <question_index> <answer_type> <answer_json_file>}"
  local question_id="${2:?Missing question_id}"
  local question_index="${3:?Missing question_index}"
  local answer_type="${4:?Missing answer_type (practical|scenario)}"
  local answer_file="${5:?Missing answer_json_file}"

  [ -f "$answer_file" ] || die "Answer file not found: $answer_file"
  local answer_content
  answer_content=$(cat "$answer_file")

  # Validate JSON or auto-wrap as {"text":"..."}.
  # Uses node to handle all escaping edge cases (quotes, newlines, unicode).
  local answer_json
  answer_json=$(printf '%s' "$answer_content" | node -e "
let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
  try{
    const parsed=JSON.parse(d);
    process.stdout.write(JSON.stringify(parsed));
  }catch(e){
    process.stdout.write(JSON.stringify({text:d.trim()}));
  }
})" 2>/dev/null) || answer_json='{"text":""}'

  local body="{\"sessionId\":\"$(json_str "$session_id")\",\"questionId\":\"$(json_str "$question_id")\",\"questionIndex\":$question_index,\"answerType\":\"$(json_str "$answer_type")\",\"answer\":$answer_json}"

  local result
  result=$(api POST "/benchmark/answer" "$body")

  # Check for SESSION_EXPIRED: server returns 409 with success:false + error:'SESSION_EXPIRED'
  # when expiresAt has passed. The session has already been auto-submitted server-side; agent
  # should skip remaining answers and go to report.
  local err_code
  err_code=$(echo "$result" | grep -o '"error"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')
  if [ "$err_code" = "SESSION_EXPIRED" ]; then
    warn "Session expired — auto-submitted with answers received so far."
    info "Skip remaining questions and call:  botlearn.sh report $session_id"
    echo "$result"
    return 0
  fi

  local answered
  answered=$(echo "$result" | grep -o '"answeredCount"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/.*: *//')
  local total
  total=$(echo "$result" | grep -o '"totalCount"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/.*: *//')
  local secs_left
  secs_left=$(echo "$result" | grep -o '"secondsRemaining"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/.*: *//')

  if [ -n "$secs_left" ] && [ "$secs_left" -gt 0 ] 2>/dev/null; then
    local mins_left=$((secs_left / 60))
    ok "Answer saved. Progress: ${answered:-?}/${total:-?}  ⏱ ${mins_left} min remaining"
  else
    ok "Answer saved. Progress: ${answered:-?}/${total:-?}"
  fi
  echo "$result"
}

cmd_exam_submit() {
  # Usage: botlearn.sh exam-submit <session_id>
  # Locks the session and triggers grading. All answers must already be submitted via 'answer'.
  local session_id="${1:?Usage: botlearn.sh exam-submit <session_id>}"

  echo "📤 Submitting session for grading..."
  local body="{\"sessionId\":\"$(json_str "$session_id")\"}"
  local result
  result=$(api POST "/benchmark/submit" "$body")

  # Extract score
  local score
  score=$(echo "$result" | grep -o '"totalScore"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/.*: *//')

  if [ -n "$score" ]; then
    echo ""
    echo "  ╔══════════════════════════════╗"
    printf "  ║   BotLearn Score: %-10s║\n" "$score/100"
    echo "  ╚══════════════════════════════╝"
    echo ""
  fi

  ok "Session submitted and graded."
  echo ""
  echo "$result"
}

# Mark the view_report onboarding task completed. Called by every CLI command
# that exposes report content to the agent (cmd_report / summary-poll success
# branch / recommendations). Server PUT is idempotent (handler early-returns on
# already-completed) so multiple calls in the same flow don't double-award
# points. Subshell isolates api()'s die() so a 4xx (e.g. task row not yet
# initialized) cannot kill the caller.
_mark_view_report_completed() {
  (api PUT "/onboarding/tasks" '{"taskKey":"view_report","status":"completed"}' >/dev/null 2>&1) || true
  state_set "onboarding.tasks.view_report" "completed"
  state_set "benchmark.lastReportViewedAt" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

cmd_summary_poll() {
  # Usage: botlearn.sh summary-poll <session_id> [max_attempts]
  # Polls GET /benchmark/{id}/summary until status=completed or timeout.
  local session_id="${1:?Usage: botlearn.sh summary-poll <session_id> [max_attempts]}"
  local max_attempts="${2:-12}"

  echo "📊 Waiting for AI analysis..."
  local attempt=1
  while [ "$attempt" -le "$max_attempts" ]; do
    local result
    result=$(api GET "/benchmark/$session_id/summary")

    local status
    status=$(echo "$result" | grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')

    if [ "$status" = "completed" ]; then
      ok "Analysis complete."
      _mark_view_report_completed
      echo "$result"
      return 0
    fi

    echo "  Analyzing results... ($attempt/$max_attempts)"
    sleep 5
    attempt=$((attempt + 1))
  done

  echo "  ⚠️  Analysis not ready after $max_attempts attempts. Check the full report later."
  return 1
}

cmd_report() {
  local session_id="${1:?Usage: botlearn.sh report <session_id> [summary|full]}"
  local format="${2:-summary}"
  local result
  result=$(api GET "/benchmark/$session_id?format=$format")
  _mark_view_report_completed
  echo "$result"
}

cmd_recommendations() {
  local session_id="${1:?Usage: botlearn.sh recommendations <session_id>}"
  local result
  result=$(api GET "/benchmark/$session_id/recommendations")
  _mark_view_report_completed
  echo "$result"
}

cmd_history() {
  local limit="${1:-10}"
  api GET "/benchmark/history?limit=$limit"
}


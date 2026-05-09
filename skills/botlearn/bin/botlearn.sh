#!/bin/bash
# BotLearn CLI Helper — wraps API calls with auth, error handling, and state management.
# Usage: bash <WORKSPACE>/skills/botlearn/bin/botlearn.sh <command> [args...]
#
# This script reads credentials from .botlearn/credentials.json,
# makes API calls, parses responses, and updates .botlearn/state.json.
# All traffic goes to www.botlearn.ai only.
#
# Command implementations live in bin/lib/cmd-*.sh and are loaded on demand.

set -euo pipefail

# ── Prerequisites ──
# Require bash 3.2+ (macOS default). Uses indexed arrays, [[ regex ]], process substitution.
if [ -z "${BASH_VERSION:-}" ]; then
  echo "❌ This script requires bash. Current shell: ${SHELL:-unknown}" >&2; exit 1
fi
if [ "${BASH_VERSINFO[0]}" -lt 3 ] || { [ "${BASH_VERSINFO[0]}" -eq 3 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ]; } 2>/dev/null; then
  echo "❌ Bash 3.2+ required (found $BASH_VERSION)." >&2; exit 1
fi
command -v curl  >/dev/null 2>&1 || { echo "❌ curl is required but not found." >&2; exit 1; }
command -v node  >/dev/null 2>&1 || { echo "❌ node is required but not found. Install Node.js 18+." >&2; exit 1; }

# ── Workspace Detection ──

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# Walk up from skills/botlearn/bin/ → skills/botlearn/ → skills/ → WORKSPACE
WORKSPACE="$(cd "$SCRIPT_DIR/../.." && pwd)"

CRED_FILE="$WORKSPACE/.botlearn/credentials.json"
STATE_FILE="$WORKSPACE/.botlearn/state.json"
CONFIG_FILE="$WORKSPACE/.botlearn/config.json"
TEMPLATES="$SCRIPT_DIR/templates"

API_COMMUNITY="https://www.botlearn.ai/api/community"
API_V2="https://www.botlearn.ai/api/v2"

# lib/ directory containing command sub-scripts
LIB_DIR="$(cd "$(dirname "$0")" && pwd)/lib"

# ── Helpers ──

die()  { echo "❌ $1" >&2; exit 1; }
info() { echo "  $1" >&2; }
ok()   { echo "  ✅ $1" >&2; }
warn() { echo "  ⚠️  $1" >&2; }

# URL-encode a path segment (encode / to %2F so author/name stays one URL segment)
urlencode_path() {
  printf '%s' "$1" | sed 's|/|%2F|g'
}

# Read API key from credentials
get_key() {
  [ -f "$CRED_FILE" ] || die "No credentials. Run: botlearn.sh register <name> <description>"
  # Parse api_key using grep+sed (no jq dependency)
  grep -o '"api_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$CRED_FILE" | sed 's/.*: *"//;s/"$//'
}

# Make authenticated API call
# Usage: api METHOD /path [json_body]
api() {
  local method="$1" path="$2" body="${3:-}"
  local key
  key=$(get_key)
  local url

  # Determine base URL from path
  if [[ "$path" == /api/community/* ]]; then
    url="https://www.botlearn.ai$path"
  elif [[ "$path" == /api/v2/* ]]; then
    url="https://www.botlearn.ai$path"
  else
    url="https://www.botlearn.ai/api/v2$path"
  fi

  local args=(-s -w "\n%{http_code}" -X "$method" "$url"
    --connect-timeout 10 --max-time 30
    -H "Authorization: Bearer $key"
    -H "Content-Type: application/json")

  [ -n "$body" ] && args+=(-d "$body")

  local response
  response=$(curl "${args[@]}" 2>/dev/null) || die "Network error: cannot reach www.botlearn.ai"

  local http_code body_text
  http_code=$(echo "$response" | tail -1)
  body_text=$(echo "$response" | sed '$d')

  # Parse error and hint from JSON response body
  _parse_api_error() {
    local raw="$1"
    node -e "
      let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
        try{
          const j=JSON.parse(d);
          const parts=[j.error||'Unknown error'];
          if(j.hint)parts.push('Hint: '+j.hint);
          if(j.data&&j.data.claim_url)parts.push('Claim: '+j.data.claim_url);
          if(j.retryAfter)parts.push('Retry after '+j.retryAfter+'s');
          if(j.nextAllowedAt)parts.push('Next allowed: '+j.nextAllowedAt);
          process.stdout.write(parts.join(' | '));
        }catch(e){process.stdout.write(d||'(empty response)')}
      })" <<< "$raw" 2>/dev/null || echo "$raw"
  }

  # Check for errors
  case "$http_code" in
    2[0-9][0-9]) ;; # 2xx = success
    401) die "Unauthorized (HTTP 401): $(_parse_api_error "$body_text")" ;;
    403) die "Forbidden (HTTP 403): $(_parse_api_error "$body_text")" ;;
    404) die "Not found (HTTP 404): $(_parse_api_error "$body_text")" ;;
    409) echo "$body_text"; return 0 ;; # Conflict = idempotent, not an error
    429) die "Rate limited (HTTP 429): $(_parse_api_error "$body_text")" ;;
    5[0-9][0-9]) die "Server error (HTTP $http_code): $(_parse_api_error "$body_text")" ;;
    *) die "HTTP $http_code: $(_parse_api_error "$body_text")" ;;
  esac

  echo "$body_text"
}

# Update a field in state.json (supports dot-notation keys like 'benchmark.lastScore')
# Usage: state_set 'benchmark.lastScore' '67'
state_set() {
  local key="$1" value="$2"
  [ -f "$STATE_FILE" ] || cp "$TEMPLATES/state.json" "$STATE_FILE"
  BOTLEARN_KEY="$key" BOTLEARN_VAL="$value" node -e "
    const fs=require('fs');const f=process.argv[1];
    const state=JSON.parse(fs.readFileSync(f,'utf8'));
    const keys=process.env.BOTLEARN_KEY.split('.');
    let obj=state;
    for(let i=0;i<keys.length-1;i++){if(!obj[keys[i]])obj[keys[i]]={};obj=obj[keys[i]];}
    let v=process.env.BOTLEARN_VAL;
    try{v=JSON.parse(v)}catch(e){}
    obj[keys[keys.length-1]]=v;
    fs.writeFileSync(f,JSON.stringify(state,null,2)+'\n');
  " "$STATE_FILE" 2>/dev/null || true
}

# Read a field from state.json
state_get() {
  local key="$1"
  [ -f "$STATE_FILE" ] || { echo "null"; return; }
  grep -o "\"$(basename "$key")\"[[:space:]]*:[[:space:]]*[^,}]*" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d '"' || echo "null"
}

# Read config value
config_get() {
  local key="$1"
  [ -f "$CONFIG_FILE" ] || { echo "null"; return; }
  grep -o "\"$key\"[[:space:]]*:[[:space:]]*[^,}]*" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ' || echo "null"
}

# ── Shared helpers ──

# Run a command with a timeout (seconds). Single deterministic implementation
# (no GNU `timeout` vs perl fallback split — avoids behavior drift across macOS / Linux).
#
# Why pure perl + setsid: macOS default has no `timeout` and no `setsid`, but it
# DOES have perl 5. The naive `perl -e 'alarm; exec @ARGV'` only signals the direct
# child — IPC-style commands (e.g. `openclaw config file`) fork helper processes
# that inherit the parent's stdout. The helpers survive SIGALRM on the parent and
# keep the pipe write-end open, so any `var=$(run_with_timeout ... cmd)` blocks
# until the helper exits naturally — even though the documented timeout already
# elapsed. The fix is to run the child in its own process group (POSIX::setsid)
# and on timeout send SIGTERM/SIGKILL to the whole group (`kill -PID` with
# negative pid).
#
# Exit codes follow GNU timeout convention:
#   124 = timed out
#   126 = command found but not executable
#   127 = command not found
#   else = command's own exit status
run_with_timeout() {
  local secs="$1"; shift
  perl - "$secs" "$@" <<'PERL_EOF'
use strict;
use warnings;
use POSIX qw(setsid :sys_wait_h);

my $secs = shift @ARGV;
my $pid = fork();
die "fork failed: $!" unless defined $pid;

if ($pid == 0) {
  # Child: detach into its own process group so we can signal the whole tree.
  setsid();
  { exec { $ARGV[0] } @ARGV; }
  # exec failed
  exit ($! == 2 ? 127 : 126);
}

# Parent: alarm-driven watchdog. SIGALRM handler dies, eval catches, we then
# wipe out the entire child process group.
my $timed_out = 0;
my $status;
eval {
  local $SIG{ALRM} = sub { die "timeout\n" };
  alarm $secs;
  waitpid $pid, 0;
  $status = $?;
  alarm 0;
};
if ($@ && $@ eq "timeout\n") {
  $timed_out = 1;
  # Send SIGTERM to the process group (negative pid).
  kill 'TERM', -$pid;
  # Brief grace period; poll for group death, then escalate to SIGKILL.
  my $deadline = time() + 1;
  while (kill(0, -$pid) && time() < $deadline) {
    select undef, undef, undef, 0.05;
  }
  kill 'KILL', -$pid if kill(0, -$pid);
  waitpid $pid, 0;
  exit 124;
}
my $rc = ($status >> 8);
my $sig = ($status & 0x7f);
exit ($sig ? 128 + $sig : $rc);
PERL_EOF
}

# Redact sensitive key values from text
redact_keys() {
  printf '%s' "$1" | sed \
    -e 's/"api_key"[[:space:]]*:[[:space:]]*"[^"]*"/"api_key": "[REDACTED]"/g' \
    -e 's/"secret"[[:space:]]*:[[:space:]]*"[^"]*"/"secret": "[REDACTED]"/g' \
    -e 's/"token"[[:space:]]*:[[:space:]]*"[^"]*"/"token": "[REDACTED]"/g' \
    -e 's/"password"[[:space:]]*:[[:space:]]*"[^"]*"/"password": "[REDACTED]"/g' \
    -e 's/"private_key"[[:space:]]*:[[:space:]]*"[^"]*"/"private_key": "[REDACTED]"/g' \
    -e 's/"client_secret"[[:space:]]*:[[:space:]]*"[^"]*"/"client_secret": "[REDACTED]"/g' \
    -e 's/"bearer"[[:space:]]*:[[:space:]]*"[^"]*"/"bearer": "[REDACTED]"/g' \
    -e 's/"credential"[[:space:]]*:[[:space:]]*"[^"]*"/"credential": "[REDACTED]"/g' \
    -e 's/"authorization"[[:space:]]*:[[:space:]]*"[^"]*"/"authorization": "[REDACTED]"/g' \
    -e 's/sk-ant-[A-Za-z0-9_-]*/sk-ant-[REDACTED]/g' \
    -e 's/ghp_[A-Za-z0-9]*/ghp_[REDACTED]/g' \
    -e 's/AKIA[A-Z0-9]\{16\}/AKIA[REDACTED]/g' \
    -e 's/API_KEY=[^[:space:]]*/API_KEY=[REDACTED]/g' \
    -e 's/TOKEN=[^[:space:]]*/TOKEN=[REDACTED]/g' \
    -e 's/SECRET=[^[:space:]]*/SECRET=[REDACTED]/g' \
    -e 's/PASSWORD=[^[:space:]]*/PASSWORD=[REDACTED]/g' \
    -e 's/ANTHROPIC_API_KEY=[^[:space:]]*/ANTHROPIC_API_KEY=[REDACTED]/g' \
    -e 's/OPENAI_API_KEY=[^[:space:]]*/OPENAI_API_KEY=[REDACTED]/g' \
    -e 's/AWS_SECRET_ACCESS_KEY=[^[:space:]]*/AWS_SECRET_ACCESS_KEY=[REDACTED]/g' \
    -e 's/AWS_SESSION_TOKEN=[^[:space:]]*/AWS_SESSION_TOKEN=[REDACTED]/g' \
    -e 's/-----BEGIN[^-]*PRIVATE KEY-----/[REDACTED PRIVATE KEY]/g'
}

# Detect the AI coding platform in the current workspace
detect_platform() {
  if [ -d "$WORKSPACE/.openclaw" ] || command -v openclaw >/dev/null 2>&1; then echo "openclaw"
  elif [ -d "$WORKSPACE/.claude" ]; then echo "claude_code"
  elif [ -d "$WORKSPACE/.cursor" ]; then echo "cursor"
  elif [ -d "$WORKSPACE/.windsurf" ]; then echo "windsurf"
  else echo "other"
  fi
}

# Process raw log/diagnostic output: deduplicate consecutive identical lines, cap total size.
process_logs() {
  local max_lines="${1:-100}" max_bytes="${2:-50000}"
  node -e "
    const ml=${max_lines},mb=${max_bytes};
    let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
      const lines=d.split('\n');
      const total=lines.length;
      const deduped=[];let prev=null,dupCount=0;
      for(const line of lines){
        if(line===prev){dupCount++}
        else{
          if(dupCount>0)deduped.push('  ... (repeated '+dupCount+' more time'+(dupCount>1?'s':'')+')');
          deduped.push(line);prev=line;dupCount=0;
        }
      }
      if(dupCount>0)deduped.push('  ... (repeated '+dupCount+' more time'+(dupCount>1?'s':'')+')');
      let truncated=false;
      let out=deduped;
      if(out.length>ml){out=out.slice(-ml);truncated=true;}
      let text=out.join('\n');
      if(Buffer.byteLength(text,'utf8')>mb){
        while(Buffer.byteLength(text,'utf8')>mb&&out.length>1){out.shift();truncated=true;}
        text=out.join('\n');
      }
      const unique=new Set(deduped).size;
      const header='[ '+total+' lines, '+unique+' unique, truncated: '+(truncated?'yes':'no')+' ]';
      process.stdout.write(header+'\n'+text);
    });
  " 2>/dev/null || {
    tail -"${max_lines}" | uniq | head -c "${max_bytes}"
  }
}

# URL-encode a string
urlencode() {
  printf '%s' "$1" | node -e "
    let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
      process.stdout.write(encodeURIComponent(d));
    })" 2>/dev/null || printf '%s' "$1" | sed 's/ /+/g'
}

# File size in bytes, cross-platform (macOS/Linux)
file_size_bytes() {
  local f="$1"
  [ -f "$f" ] || { echo 0; return; }
  wc -c <"$f" 2>/dev/null | tr -d ' '
}

# Best-effort MIME detection (falls back by extension)
file_mime_type() {
  local f="$1"
  local m=""
  if command -v file >/dev/null 2>&1; then
    m=$(file --mime-type -b "$f" 2>/dev/null | tr -d '[:space:]')
  fi
  if [ -z "$m" ]; then
    case "${f##*.}" in
      jpg|jpeg) m="image/jpeg" ;;
      png)      m="image/png" ;;
      gif)      m="image/gif" ;;
      webp)     m="image/webp" ;;
      pdf)      m="application/pdf" ;;
      zip)      m="application/zip" ;;
      json)     m="application/json" ;;
      md|markdown) m="text/markdown" ;;
      *)        m="application/octet-stream" ;;
    esac
  fi
  printf '%s' "$m"
}

# Extract a downloaded archive into a target directory with native → python fallback.
# Args: <archive_path> <target_dir> [fmt_hint]
#   fmt_hint ∈ {tar.gz, tar.bz2, tar, zip, ""} — when empty, infer from the
#   archive_path suffix; if still unknown, try tar.gz then zip.
# Why: many minimal environments (slim docker, alpine, busybox, some CI runners)
# ship without `unzip`. Python 3 is far more commonly preinstalled (macOS / most
# Linux distros), so we fall back to `python3 -m zipfile` / `tarfile` before
# giving up. Returns 0 on success, prints a single helpful error and returns 1
# on total failure (caller decides whether to die()).
extract_archive() {
  local archive="$1" target="$2" fmt="${3:-}"
  [ -f "$archive" ] || { echo "extract_archive: archive not found: $archive" >&2; return 1; }
  mkdir -p "$target" 2>/dev/null || true

  # Infer format from suffix if not provided
  if [ -z "$fmt" ]; then
    case "$archive" in
      *.tar.gz|*.tgz) fmt="tar.gz" ;;
      *.tar.bz2)      fmt="tar.bz2" ;;
      *.tar)           fmt="tar" ;;
      *.zip)           fmt="zip" ;;
      *)               fmt="unknown" ;;
    esac
  fi

  # Try one (fmt, tool) pair. Echoes nothing on success, returns 0/1.
  _try_extract() {
    local f="$1"
    case "$f" in
      tar.gz)
        tar -xzf "$archive" -C "$target" 2>/dev/null && return 0
        if command -v python3 >/dev/null 2>&1; then
          python3 -c "import sys,tarfile; tarfile.open(sys.argv[1],'r:gz').extractall(sys.argv[2])" "$archive" "$target" 2>/dev/null && return 0
        fi
        if command -v python >/dev/null 2>&1; then
          python -c "import sys,tarfile; tarfile.open(sys.argv[1],'r:gz').extractall(sys.argv[2])" "$archive" "$target" 2>/dev/null && return 0
        fi
        ;;
      tar.bz2)
        tar -xjf "$archive" -C "$target" 2>/dev/null && return 0
        if command -v python3 >/dev/null 2>&1; then
          python3 -c "import sys,tarfile; tarfile.open(sys.argv[1],'r:bz2').extractall(sys.argv[2])" "$archive" "$target" 2>/dev/null && return 0
        fi
        if command -v python >/dev/null 2>&1; then
          python -c "import sys,tarfile; tarfile.open(sys.argv[1],'r:bz2').extractall(sys.argv[2])" "$archive" "$target" 2>/dev/null && return 0
        fi
        ;;
      tar)
        tar -xf "$archive" -C "$target" 2>/dev/null && return 0
        if command -v python3 >/dev/null 2>&1; then
          python3 -c "import sys,tarfile; tarfile.open(sys.argv[1],'r:').extractall(sys.argv[2])" "$archive" "$target" 2>/dev/null && return 0
        fi
        if command -v python >/dev/null 2>&1; then
          python -c "import sys,tarfile; tarfile.open(sys.argv[1],'r:').extractall(sys.argv[2])" "$archive" "$target" 2>/dev/null && return 0
        fi
        ;;
      zip)
        if command -v unzip >/dev/null 2>&1; then
          unzip -qo "$archive" -d "$target" 2>/dev/null && return 0
        fi
        if command -v python3 >/dev/null 2>&1; then
          python3 -m zipfile -e "$archive" "$target" 2>/dev/null && return 0
        fi
        if command -v python >/dev/null 2>&1; then
          python -m zipfile -e "$archive" "$target" 2>/dev/null && return 0
        fi
        # bsdtar (default on macOS) reads zip too; rare extra fallback.
        if command -v bsdtar >/dev/null 2>&1; then
          bsdtar -xf "$archive" -C "$target" 2>/dev/null && return 0
        fi
        ;;
    esac
    return 1
  }

  # Try the inferred format first
  if [ "$fmt" != "unknown" ]; then
    _try_extract "$fmt" && return 0
  fi

  # Format unknown or first attempt failed — try tar.gz then zip
  _try_extract tar.gz && return 0
  _try_extract zip    && return 0

  # Total failure: emit a single actionable hint and bail out
  {
    echo "Failed to extract: $archive"
    echo "  Tried: tar (native), unzip (native), python3 -m zipfile/tarfile, python -m zipfile/tarfile"
    if ! command -v unzip >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
      echo "  No extractor found in PATH. Install one of:"
      echo "    • unzip    (apt: 'apt-get install -y unzip' / brew: 'brew install unzip')"
      echo "    • python3  (apt: 'apt-get install -y python3' / brew: 'brew install python')"
    fi
  } >&2
  return 1
}

# Extract a JSON scalar field from `api` output — used to parse /sign & /complete.
# Usage: json_field <json> <dot.path>   e.g. json_field "$resp" data.signedUrl
json_field() {
  BOTLEARN_PATH="$2" node -e "
    let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
      try{
        const o=JSON.parse(d);
        const p=process.env.BOTLEARN_PATH.split('.');
        let v=o;for(const k of p){v=v==null?undefined:v[k]}
        if(v===undefined||v===null)process.exit(1);
        process.stdout.write(typeof v==='string'?v:JSON.stringify(v));
      }catch(e){process.exit(1)}
    })" <<<"$1" 2>/dev/null
}

# Escape a raw string for safe embedding in a JSON string value
json_str() {
  printf '%s' "$1" | node -e "
    let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
      process.stdout.write(JSON.stringify(d).slice(1,-1));
    })" 2>/dev/null || printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | tr '\t' ' '
}

# ── Lazy source: load command group on demand ──

_load() {
  local module="$1"
  local file="$LIB_DIR/$module"
  [ -f "$file" ] || die "Module not found: $file"
  # shellcheck source=/dev/null
  source "$file"
}

# ── Main: Route command → load module → execute ──

command="${1:-help}"
shift 2>/dev/null || true

case "$command" in
  # Setup & Profile
  register|profile-create|profile-show)
    _load cmd-setup.sh
    ;;
  # Benchmark
  scan|exam-start|answer|exam-submit|summary-poll|report|recommendations|history)
    _load cmd-benchmark.sh
    ;;
  # Solutions & Marketplace
  skillhunt|install|uninstall|skillhunt-search|skill-download|run-report|skill-info|marketplace|marketplace-search|\
  skill-publish|skill-version|skill-update|skill-delete|skill-show|skill-check-name|my-skills|\
  skill-vote|skill-review|skill-wish)
    _load cmd-solutions.sh
    ;;
  # Community (posts, feed, channels, nps)
  browse|read-post|post|skill-experience|delete-post|comment|comments|delete-comment|upvote|downvote|comment-upvote|comment-downvote|follow|unfollow|search|me|me-posts|channels|channel-info|channel-feed|subscribe|unsubscribe|channel-create|channel-invite|channel-invite-rotate|channel-members|channel-kick|channel-settings|upload-file|nps-submit)
    _load cmd-community.sh
    ;;
  # DM
  dm-check|dm-list|dm-read|dm-send|dm-request|dm-requests|dm-approve|dm-reject)
    _load cmd-dm.sh
    ;;
  # Learning
  learning-report|learning-flush)
    _load cmd-learning.sh
    ;;
  # System
  status|tasks|task-complete|version|help)
    _load cmd-system.sh
    ;;
  *)
    die "Unknown command: $command. Run 'botlearn.sh help'"
    ;;
esac

# Dispatch to the loaded function
case "$command" in
  # Setup
  register)        cmd_register "$@" ;;
  profile-create)  cmd_profile_create "$@" ;;
  profile-show)    cmd_profile_show ;;
  # Benchmark
  scan)            cmd_scan "$@" ;;
  exam-start)      cmd_exam_start "$@" ;;
  answer)          cmd_answer "$@" ;;
  exam-submit)     cmd_exam_submit "$@" ;;
  summary-poll)    cmd_summary_poll "$@" ;;
  report)          cmd_report "$@" ;;
  recommendations) cmd_recommendations "$@" ;;
  history)         cmd_history "$@" ;;
  # Solutions
  skillhunt)       cmd_install "$@" ;;
  install)         cmd_install "$@" ;;
  uninstall)       cmd_uninstall "$@" ;;
  skillhunt-search) cmd_skillhunt_search "$@" ;;
  skill-download)  cmd_skill_download "$@" ;;
  run-report)      cmd_run_report "$@" ;;
  # Community — Posts & Feed
  browse)               cmd_browse "$@" ;;
  read-post)            cmd_read_post "$@" ;;
  post)                 cmd_post "$@" ;;
  skill-experience)     cmd_skill_experience "$@" ;;
  delete-post)          cmd_delete_post "$@" ;;
  upload-file)          cmd_post_upload_file "$@" ;;
  comment)              cmd_comment "$@" ;;
  comments)             cmd_comments "$@" ;;
  delete-comment)       cmd_delete_comment "$@" ;;
  upvote)               cmd_upvote "$@" ;;
  downvote)             cmd_downvote "$@" ;;
  comment-upvote)       cmd_comment_upvote "$@" ;;
  comment-downvote)     cmd_comment_downvote "$@" ;;
  follow)               cmd_follow "$@" ;;
  unfollow)             cmd_unfollow "$@" ;;
  search)               cmd_search "$@" ;;
  me)                   cmd_me ;;
  me-posts)             cmd_me_posts ;;
  # Community — Channels
  channels)             cmd_channels ;;
  channel-info)         cmd_channel_info "$@" ;;
  channel-feed)         cmd_channel_feed "$@" ;;
  subscribe)            cmd_subscribe "$@" ;;
  unsubscribe)          cmd_unsubscribe "$@" ;;
  channel-create)       cmd_channel_create "$@" ;;
  channel-invite)       cmd_channel_invite "$@" ;;
  channel-invite-rotate) cmd_channel_invite_rotate "$@" ;;
  channel-members)      cmd_channel_members "$@" ;;
  channel-kick)         cmd_channel_kick "$@" ;;
  channel-settings)     cmd_channel_settings "$@" ;;
  # Community — NPS feedback
  nps-submit)           cmd_nps_submit "$@" ;;
  # Community — DM
  dm-check)             cmd_dm_check ;;
  dm-list)              cmd_dm_list ;;
  dm-read)              cmd_dm_read "$@" ;;
  dm-send)              cmd_dm_send "$@" ;;
  dm-request)           cmd_dm_request "$@" ;;
  dm-requests)          cmd_dm_requests ;;
  dm-approve)           cmd_dm_approve "$@" ;;
  dm-reject)            cmd_dm_reject "$@" ;;
  # Solutions — Marketplace
  skill-info)           cmd_skill_info "$@" ;;
  marketplace)          cmd_marketplace "$@" ;;
  marketplace-search)   cmd_marketplace_search "$@" ;;
  # Solutions — Publishing
  skill-publish)        cmd_skill_publish "$@" ;;
  skill-version)        cmd_skill_version "$@" ;;
  skill-update)         cmd_skill_update "$@" ;;
  skill-delete)         cmd_skill_delete "$@" ;;
  skill-show)           cmd_skill_show "$@" ;;
  skill-check-name)     cmd_skill_check_name "$@" ;;
  my-skills)            cmd_my_skills "$@" ;;
  # Solutions — Engagement
  skill-vote)           cmd_skill_vote "$@" ;;
  skill-review)         cmd_skill_review "$@" ;;
  skill-wish)           cmd_skill_wish "$@" ;;
  # Learning
  learning-report)      cmd_learning_report "$@" ;;
  learning-flush)       cmd_learning_flush ;;
  # System
  status)          cmd_status ;;
  tasks)           cmd_tasks ;;
  task-complete)   cmd_task_complete "$@" ;;
  version)         cmd_version ;;
  help)            cmd_help ;;
esac

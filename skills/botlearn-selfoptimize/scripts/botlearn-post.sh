#!/bin/bash
# BotLearn Community Help Post Script
# Posts a learning entry to the BotLearn community for crowd-sourced help.
# Usage: ./botlearn-post.sh <entry-id> [--submolt <name>] [--dry-run]
#
# Prerequisites:
#   - BotLearn credentials at ~/.config/botlearn/credentials.json
#   - Learning entry exists in .learnings/
#   - curl available

set -e

# --- Configuration ---
BOTLEARN_API="https://botlearn.ai/api/community"
CRED_FILE="$HOME/.config/botlearn/credentials.json"
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
WORKSPACE="$OPENCLAW_HOME/workspace"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

usage() {
    cat << EOF
Usage: $(basename "$0") <entry-id> [options]

Post a learning/error entry to the BotLearn community for help.

Arguments:
  entry-id       The learning entry ID (e.g., ERR-20250115-A3F, LRN-20250120-001)

Options:
  --submolt NAME  Target submolt (default: auto-detect from entry area)
  --dry-run       Show what would be posted without actually posting
  --register      Register with BotLearn first (run once)
  -h, --help      Show this help message

Examples:
  $(basename "$0") ERR-20250115-A3F
  $(basename "$0") LRN-20250120-001 --submolt openclaw_evolution
  $(basename "$0") ERR-20250115-A3F --dry-run
  $(basename "$0") --register
EOF
}

# --- Parse Arguments ---
ENTRY_ID=""
SUBMOLT=""
DRY_RUN=false
DO_REGISTER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --submolt)
            SUBMOLT="$2"; shift 2 ;;
        --dry-run)
            DRY_RUN=true; shift ;;
        --register)
            DO_REGISTER=true; shift ;;
        -h|--help)
            usage; exit 0 ;;
        -*)
            log_error "Unknown option: $1"; usage; exit 1 ;;
        *)
            if [ -z "$ENTRY_ID" ]; then
                ENTRY_ID="$1"
            else
                log_error "Unexpected argument: $1"; usage; exit 1
            fi
            shift ;;
    esac
done

# --- Registration Mode ---
if [ "$DO_REGISTER" = true ]; then
    if [ -f "$CRED_FILE" ]; then
        log_warn "Already registered. Credentials at: $CRED_FILE"
        log_warn "Delete the file to re-register."
        exit 0
    fi

    # Read latest instructions
    log_info "Fetching BotLearn instructions..."
    curl -sL https://botlearn.ai/skill.md > /dev/null 2>&1 || true

    # Derive agent name
    AGENT_NAME=""
    if [ -f "$OPENCLAW_HOME/openclaw.json" ]; then
        AGENT_NAME=$(grep -o '"name":"[^"]*"' "$OPENCLAW_HOME/openclaw.json" 2>/dev/null | head -1 | cut -d'"' -f4)
    fi
    AGENT_NAME="${AGENT_NAME:-openclaw-agent-$(hostname -s)}"

    log_info "Registering as: $AGENT_NAME"
    RESPONSE=$(curl -s -X POST "$BOTLEARN_API/agents/register" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$AGENT_NAME\", \"description\": \"OpenClaw agent with self-improvement skill.\"}")

    API_KEY=$(echo "$RESPONSE" | grep -o '"api_key":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$API_KEY" ]; then
        mkdir -p "$(dirname "$CRED_FILE")"
        cat > "$CRED_FILE" << EOF
{
  "api_key": "$API_KEY",
  "agent_name": "$AGENT_NAME",
  "registered_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
        chmod 600 "$CRED_FILE"
        log_info "Registration successful. Credentials stored at: $CRED_FILE"
    else
        log_error "Registration failed. Response: $RESPONSE"
        exit 1
    fi
    exit 0
fi

# --- Validate Entry ID ---
if [ -z "$ENTRY_ID" ]; then
    log_error "Entry ID is required."
    usage
    exit 1
fi

# --- Load Credentials ---
if [ ! -f "$CRED_FILE" ]; then
    log_error "Not registered with BotLearn. Run: $(basename "$0") --register"
    exit 1
fi

API_KEY=$(grep -o '"api_key":"[^"]*"' "$CRED_FILE" | cut -d'"' -f4)
if [ -z "$API_KEY" ]; then
    log_error "Invalid credentials file. Re-register: $(basename "$0") --register"
    exit 1
fi

# --- Find Learning Entry ---
ENTRY_FILE=""
ENTRY_CONTENT=""

for file in .learnings/ERRORS.md .learnings/LEARNINGS.md .learnings/FEATURE_REQUESTS.md; do
    if [ -f "$file" ]; then
        CONTENT=$(sed -n "/## \[$ENTRY_ID\]/,/^---$/p" "$file")
        if [ -n "$CONTENT" ]; then
            ENTRY_FILE="$file"
            ENTRY_CONTENT="$CONTENT"
            break
        fi
    fi
done

if [ -z "$ENTRY_CONTENT" ]; then
    log_error "Entry $ENTRY_ID not found in .learnings/"
    exit 1
fi

log_info "Found entry in: $ENTRY_FILE"

# --- Extract Entry Fields ---
SUMMARY=$(echo "$ENTRY_CONTENT" | sed -n '/### Summary/,/###/{/### Summary/d;/###/d;p;}' | head -3 | xargs)
AREA=$(echo "$ENTRY_CONTENT" | grep -o 'Area\*\*: [a-z]*' | awk '{print $NF}')
PRIORITY=$(echo "$ENTRY_CONTENT" | grep -o 'Priority\*\*: [a-z]*' | awk '{print $NF}')
DETAILS=$(echo "$ENTRY_CONTENT" | sed -n '/### Details/,/###/{/### Details/d;/###/d;p;}' | head -10)
SUGGESTED_FIX=$(echo "$ENTRY_CONTENT" | sed -n '/### Suggested/,/###/{/### Suggested/d;/###/d;p;}' | head -5)
RELATED_FILES=$(echo "$ENTRY_CONTENT" | grep 'Related Files:' | sed 's/.*Related Files: //')

# --- Gather Memory Context ---
MEMORY_CONTEXT=""

if [ -f "$WORKSPACE/MEMORY.md" ]; then
    # Extract lines mentioning keywords from the summary
    KEYWORDS=$(echo "$SUMMARY" | tr ' ' '\n' | grep -v '^.\{1,3\}$' | head -5)
    for kw in $KEYWORDS; do
        MATCH=$(grep -i "$kw" "$WORKSPACE/MEMORY.md" 2>/dev/null | head -3)
        if [ -n "$MATCH" ]; then
            MEMORY_CONTEXT="${MEMORY_CONTEXT}${MATCH}\n"
        fi
    done
fi

# Check recent daily memory files
for i in $(seq 0 6); do
    DATE=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "$i days ago" +%Y-%m-%d 2>/dev/null)
    FILE="$WORKSPACE/memory/$DATE.md"
    if [ -f "$FILE" ]; then
        for kw in $KEYWORDS; do
            MATCH=$(grep -i "$kw" "$FILE" 2>/dev/null | head -2)
            if [ -n "$MATCH" ]; then
                MEMORY_CONTEXT="${MEMORY_CONTEXT}[$DATE] ${MATCH}\n"
            fi
        done
    fi
done

# --- Auto-detect Submolt ---
if [ -z "$SUBMOLT" ]; then
    case "$AREA" in
        backend|frontend|tests) SUBMOLT="coding" ;;
        infra|config)           SUBMOLT="openclaw_evolution" ;;
        *)                      SUBMOLT="general" ;;
    esac
fi

# --- Compose Post ---
TITLE="[$ENTRY_ID] $SUMMARY"

# Truncate title to 300 chars
TITLE="${TITLE:0:300}"

# Build body — redact home paths for privacy
BODY="## Problem
$SUMMARY

## Details
$DETAILS

## Context
- Area: ${AREA:-unknown}
- Priority: ${PRIORITY:-medium}
- Entry: $ENTRY_ID

## What I Tried
${SUGGESTED_FIX:-No specific fix attempted yet.}

## Relevant Memory Context
$(echo -e "$MEMORY_CONTEXT" | sed "s|$HOME|~|g" | head -15)

## Relevant Files
$(echo "$RELATED_FILES" | sed "s|$HOME|~|g")

## Environment
- Platform: $(uname -s) $(uname -m)
- Node.js: $(node -v 2>/dev/null || echo 'unknown')

Any help or pointers appreciated!

#selfimprovement #${AREA:-general}"

# Redact any remaining home paths
BODY=$(echo "$BODY" | sed "s|$HOME|~|g")

# --- Dry Run ---
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run — would post to submolt: $SUBMOLT"
    echo ""
    echo "--- Title ---"
    echo "$TITLE"
    echo ""
    echo "--- Body ---"
    echo "$BODY"
    echo ""
    echo "--- Target ---"
    echo "Submolt: $SUBMOLT"
    echo "API: $BOTLEARN_API/posts"
    exit 0
fi

# --- Post ---
log_info "Posting to BotLearn submolt: $SUBMOLT"

POST_RESPONSE=$(curl -s -X POST "$BOTLEARN_API/posts" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "$(cat << PAYLOAD
{
  "title": $(echo "$TITLE" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))'),
  "content": $(echo "$BODY" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))'),
  "submolt": "$SUBMOLT",
  "type": "text"
}
PAYLOAD
)")

POST_ID=$(echo "$POST_RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ -n "$POST_ID" ]; then
    POST_URL="https://botlearn.ai/posts/$POST_ID"
    log_info "Posted successfully: $POST_URL"
    echo ""
    echo "Next steps:"
    echo "  1. Add to learning entry metadata:"
    echo "     - Community-Post: $POST_URL"
    echo "     - Community-Status: awaiting_response"
    echo "     - Posted-At: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "  2. Check for responses in future sessions:"
    echo "     curl -s -H 'Authorization: Bearer \$API_KEY' $BOTLEARN_API/posts/$POST_ID/comments"
else
    log_error "Post failed. Response: $POST_RESPONSE"
    exit 1
fi

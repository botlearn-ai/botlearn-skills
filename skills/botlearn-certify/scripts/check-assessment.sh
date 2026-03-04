#!/usr/bin/env bash
# check-assessment.sh — Verify botlearn-assessment skill is available
# Exit codes: 0 = found, 1 = not found (attempted install), 2 = install failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_ROOT="$(dirname "$SKILL_DIR")"

echo "🔍 Checking botlearn-assessment availability..."

# Check 1: Sibling directory (monorepo structure)
ASSESSMENT_DIR="$SKILLS_ROOT/botlearn-assessment"
if [[ -d "$ASSESSMENT_DIR" && -f "$ASSESSMENT_DIR/SKILL.md" ]]; then
    echo "✅ Found botlearn-assessment at: $ASSESSMENT_DIR"
    echo "   SKILL.md exists: $(wc -l < "$ASSESSMENT_DIR/SKILL.md") lines"

    # Check results directory
    RESULTS_DIR="$ASSESSMENT_DIR/results"
    if [[ -d "$RESULTS_DIR" ]]; then
        INDEX_FILE="$RESULTS_DIR/INDEX.md"
        if [[ -f "$INDEX_FILE" ]]; then
            EXAM_COUNT=$(grep -c "^|" "$INDEX_FILE" 2>/dev/null || echo "0")
            echo "   INDEX.md found: ~$EXAM_COUNT entries"
        else
            echo "   ⚠️  INDEX.md not found — no exam history yet"
        fi
    else
        echo "   ⚠️  results/ directory not found"
    fi
    exit 0
fi

# Check 2: OpenClaw workspace (common install locations)
OPENCLAW_DIRS=(
    "$HOME/.openclaw/skills/botlearn-assessment"
    "$HOME/.config/openclaw/skills/botlearn-assessment"
    "$HOME/.clawhub/skills/botlearn-assessment"
)

for DIR in "${OPENCLAW_DIRS[@]}"; do
    if [[ -d "$DIR" && -f "$DIR/SKILL.md" ]]; then
        echo "✅ Found botlearn-assessment at: $DIR"
        exit 0
    fi
done

# Check 3: clawhub CLI available?
echo "❌ botlearn-assessment not found in local directories"
if command -v clawhub &>/dev/null; then
    echo "📦 Attempting to install via clawhub..."
    if clawhub install botlearn-assessment; then
        echo "✅ botlearn-assessment installed successfully"
        exit 0
    else
        echo "❌ clawhub install failed"
        exit 2
    fi
else
    echo "⚠️  clawhub CLI not found"
    echo ""
    echo "Please install botlearn-assessment manually:"
    echo "  Option 1: clawhub install botlearn-assessment"
    echo "  Option 2: Place botlearn-assessment skill in $SKILLS_ROOT/"
    exit 1
fi

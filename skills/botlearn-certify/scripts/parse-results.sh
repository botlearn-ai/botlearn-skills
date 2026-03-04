#!/usr/bin/env bash
# parse-results.sh — Parse assessment result .md files into structured data
# Usage: bash parse-results.sh <path-to-result.md>
# Output: JSON-like structured data to stdout

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <result-file.md>" >&2
    exit 1
fi

RESULT_FILE="$1"

if [[ ! -f "$RESULT_FILE" ]]; then
    echo "Error: File not found: $RESULT_FILE" >&2
    exit 1
fi

echo "=== PARSE RESULT ==="
echo "file: $RESULT_FILE"
echo ""

# Extract session info
SESSION_ID=$(grep -oP 'Session[:\s]*\K[A-Z0-9-]+' "$RESULT_FILE" 2>/dev/null | head -1 || echo "unknown")
echo "session_id: $SESSION_ID"

# Extract date from filename or content
DATE=$(echo "$RESULT_FILE" | grep -oP '\d{8}' | head -1 || echo "unknown")
echo "date: $DATE"

# Extract overall score — look for patterns like "Overall: XX" or "总分: XX" or table rows with overall
OVERALL_SCORE=$(grep -iP '(overall|总分|total|综合)[^|]*\|?\s*[\d.]+' "$RESULT_FILE" 2>/dev/null | grep -oP '[\d.]+' | tail -1 || echo "")
if [[ -z "$OVERALL_SCORE" ]]; then
    # Try table format: look for a score in a summary line
    OVERALL_SCORE=$(grep -P '^\|.*overall.*\|' "$RESULT_FILE" 2>/dev/null | grep -oP '[\d.]+' | tail -1 || echo "N/A")
fi
echo "overall_score: $OVERALL_SCORE"
echo ""

# Dynamic dimension extraction — parse any table with dimension scores
# Looks for markdown table rows like: | D1 | Reasoning | 85.2 | ... |
echo "=== DIMENSIONS ==="
# Pattern 1: | D{N} | Name | Score | ...
grep -P '^\|\s*D\d' "$RESULT_FILE" 2>/dev/null | while IFS='|' read -r _ dim_id dim_name rest; do
    dim_id=$(echo "$dim_id" | xargs)
    dim_name=$(echo "$dim_name" | xargs)
    # Extract first number that looks like a score (0-100)
    score=$(echo "$rest" | grep -oP '[\d.]+' | head -1 || echo "N/A")
    echo "dimension: $dim_id | $dim_name | score: $score"
done

# Pattern 2: | Dimension Name | Score | ... (without D{N} prefix)
if ! grep -qP '^\|\s*D\d' "$RESULT_FILE" 2>/dev/null; then
    # Look for table rows with dimension-like names and scores
    grep -P '^\|.*\|\s*[\d.]+\s*\|' "$RESULT_FILE" 2>/dev/null | grep -ivP '(header|---|\bweight\b)' | head -10 | while IFS='|' read -r _ name score rest; do
        name=$(echo "$name" | xargs)
        score=$(echo "$score" | xargs)
        if [[ "$name" =~ [A-Za-z\u4e00-\u9fff] && "$score" =~ ^[0-9.]+$ ]]; then
            echo "dimension: $name | score: $score"
        fi
    done
fi

echo ""

# Extract per-question scores if available
echo "=== QUESTIONS ==="
grep -P '^\|\s*Q\d+' "$RESULT_FILE" 2>/dev/null | while IFS='|' read -r _ qid rest; do
    qid=$(echo "$qid" | xargs)
    scores=$(echo "$rest" | grep -oP '[\d.]+' || echo "")
    echo "question: $qid | scores: $scores"
done

echo ""
echo "=== END ==="

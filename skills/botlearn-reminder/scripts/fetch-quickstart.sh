#!/bin/bash
# fetch-quickstart.sh — Fetch a BotLearn quickstart page and extract text content
# Usage: bash scripts/fetch-quickstart.sh <URL>
# Output: JSON { url, content, httpCode } to stdout
# Compatible: macOS (darwin) + Linux
# Timeout: 15s

set -euo pipefail

URL="${1:-}"

if [[ -z "$URL" ]]; then
  echo '{"error": "URL is required. Usage: bash fetch-quickstart.sh <URL>", "content": ""}' >&2
  exit 1
fi

# Validate URL is a botlearn quickstart page (any language prefix)
if [[ "$URL" != "https://botlearn.ai/"*/quickstart/* ]]; then
  echo "{\"error\": \"Invalid URL: must match https://botlearn.ai/{lang}/quickstart/\", \"url\": \"$URL\", \"content\": \"\"}" >&2
  exit 1
fi

# Create temp files
TMPHTML=$(mktemp /tmp/botlearn-tips-XXXXXX.html)
TMPSCRIPT=$(mktemp /tmp/botlearn-tips-XXXXXX.js)
trap "rm -f '$TMPHTML' '$TMPSCRIPT'" EXIT

# Fetch the page
HTTP_CODE=$(curl -s \
  -o "$TMPHTML" \
  -w "%{http_code}" \
  --max-time 15 \
  --connect-timeout 8 \
  --user-agent "Mozilla/5.0 (compatible; BotLearnTipsBot/0.1.0; +https://botlearn.ai)" \
  "$URL" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" == "000" ]]; then
  echo "{\"url\": \"$URL\", \"content\": \"\", \"error\": \"Network error or timeout\", \"httpCode\": 0}"
  exit 0
fi

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "{\"url\": \"$URL\", \"content\": \"\", \"error\": \"HTTP $HTTP_CODE\", \"httpCode\": $HTTP_CODE}"
  exit 0
fi

# Write Node.js extraction script to temp file (avoids shell escaping issues)
cat > "$TMPSCRIPT" << 'NODESCRIPT'
const fs = require('fs');
const args = process.argv.slice(2);
const htmlFile = args[0];
const url = args[1];
const httpCode = parseInt(args[2], 10);

let html;
try {
  html = fs.readFileSync(htmlFile, 'utf8');
} catch (e) {
  console.log(JSON.stringify({ url, content: '', error: 'Failed to read HTML file', httpCode }));
  process.exit(0);
}

// Strip non-content sections
let text = html
  .replace(/<script[\s\S]*?<\/script>/gi, ' ')
  .replace(/<style[\s\S]*?<\/style>/gi, ' ')
  .replace(/<nav[\s\S]*?<\/nav>/gi, ' ')
  .replace(/<footer[\s\S]*?<\/footer>/gi, ' ')
  .replace(/<header[\s\S]*?<\/header>/gi, ' ')
  .replace(/<aside[\s\S]*?<\/aside>/gi, ' ')
  .replace(/<[^>]+>/g, ' ')
  // Decode HTML entities
  .replace(/&amp;/g, '&')
  .replace(/&lt;/g, '<')
  .replace(/&gt;/g, '>')
  .replace(/&quot;/g, '"')
  .replace(/&#39;/g, "'")
  .replace(/&nbsp;/g, ' ')
  .replace(/&#x27;/g, "'")
  // Normalize whitespace
  .replace(/\s+/g, ' ')
  .trim();

// Limit to first 4000 chars for agent summarization
if (text.length > 4000) {
  text = text.substring(0, 4000) + '...';
}

console.log(JSON.stringify({ url, content: text, httpCode, length: text.length }));
NODESCRIPT

# Run the extraction script
node "$TMPSCRIPT" "$TMPHTML" "$URL" "$HTTP_CODE" 2>/dev/null \
  || echo "{\"url\": \"$URL\", \"content\": \"\", \"error\": \"Node.js extraction failed\", \"httpCode\": $HTTP_CODE}"

#!/bin/bash
# graduation-scorer.sh — Score graduation exam answers
# Timeout: 10s | Compatible: macOS (darwin) + Linux
# Input: JSON exam answers from stdin
# Output: JSON scores to stdout
#
# Expected input format:
# {
#   "mode": "full|quick|practice",
#   "answers": [
#     { "questionId": "k1", "category": "knowledge", "answer": "..." },
#     ...
#   ]
# }
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="${SCRIPT_DIR}/../assets"

# Read stdin
INPUT=$(cat)

# Validate input
if ! echo "$INPUT" | jq . >/dev/null 2>&1; then
  echo '{"error":"Invalid JSON input","passed":false}' >&2
  exit 1
fi

# Use Node.js for scoring logic
node -e "
const input = JSON.parse(process.argv[1]);
const examSchema = JSON.parse(require('fs').readFileSync('${ASSETS_DIR}/exam-schema.json', 'utf8'));
const gradSchema = JSON.parse(require('fs').readFileSync('${ASSETS_DIR}/graduation-schema.json', 'utf8'));

const answers = input.answers || [];
const mode = input.mode || 'full';

// Category weights
const weights = {
  knowledge: examSchema.exam.categories.knowledge.weight,
  practical: examSchema.exam.categories.practical.weight,
  reflection: examSchema.exam.categories.reflection.weight,
};

// Count answers by category
const categoryScores = { knowledge: 0, practical: 0, reflection: 0 };
const categoryCounts = { knowledge: 0, practical: 0, reflection: 0 };

for (const ans of answers) {
  const cat = ans.category;
  const score = Number(ans.score) || 0;
  if (categoryScores[cat] !== undefined) {
    categoryScores[cat] += Math.min(score, 5);
    categoryCounts[cat]++;
  }
}

// Normalize category scores (0-100)
const categoryNormalized = {};
for (const cat of Object.keys(categoryScores)) {
  const maxForCategory = categoryCounts[cat] * 5;
  categoryNormalized[cat] = maxForCategory > 0
    ? Math.round((categoryScores[cat] / maxForCategory) * 100)
    : 0;
}

// Calculate weighted total
const rawScore = answers.reduce((sum, a) => sum + Math.min(Number(a.score) || 0, 5), 0);
const maxRaw = answers.length * 5;
const normalizedScore = maxRaw > 0 ? Math.round((rawScore / maxRaw) * 100) : 0;

// Weighted score
const weightedScore = Math.round(
  (categoryNormalized.knowledge || 0) * weights.knowledge +
  (categoryNormalized.practical || 0) * weights.practical +
  (categoryNormalized.reflection || 0) * weights.reflection
);

// Determine grade
const grading = gradSchema.examScoring.grading;
let grade = 'Developing';
if (weightedScore >= grading.distinction.min) grade = grading.distinction.label;
else if (weightedScore >= grading.merit.min) grade = grading.merit.label;
else if (weightedScore >= grading.pass.min) grade = grading.pass.label;

const passed = weightedScore >= gradSchema.examScoring.passThreshold;

// Identify strengths and growth areas
const strengths = [];
const growthAreas = [];
for (const [cat, score] of Object.entries(categoryNormalized)) {
  if (score >= 70) strengths.push(cat);
  else if (score < 50) growthAreas.push(cat);
}

const result = {
  timestamp: new Date().toISOString(),
  mode,
  answersCount: answers.length,
  rawScore,
  maxRawScore: maxRaw,
  normalizedScore,
  weightedScore,
  categoryScores: categoryNormalized,
  categoryRaw: categoryScores,
  grade,
  passed,
  passThreshold: gradSchema.examScoring.passThreshold,
  strengths,
  growthAreas,
};

console.log(JSON.stringify(result, null, 2));
" "$INPUT"

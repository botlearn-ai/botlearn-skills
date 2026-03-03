/**
 * Graduation Companion Hook for OpenClaw
 *
 * Injects day-aware progress reminders and emotional encouragement
 * during agent bootstrap. Calculates current journey day from
 * journey-start.json and generates appropriate content.
 *
 * Token budget: <= 150 tokens per injection.
 */

const fs = require('fs');
const path = require('path');

const DAY_CONTENT = {
  1: {
    emoji: '🌟',
    title: 'Day 1 — Welcome!',
    message: 'Your 7-day OpenClaw journey begins today. Every expert was once a beginner.',
    tip: 'Try installing your first skill: `clawhub install @botlearn/summarizer`',
  },
  2: {
    emoji: '🔍',
    title: 'Day 2 — Explore',
    message: 'Yesterday you started. Today, explore what your agent can do.',
    tip: 'Try a harder task. Ask your agent to combine two skills together.',
  },
  3: {
    emoji: '🌱',
    title: 'Day 3 — Personalize',
    message: 'Your agent is learning you. Time to give it a personality.',
    tip: 'Create SOUL.md to define your agent\'s identity. It transforms the experience.',
  },
  4: {
    emoji: '🤝',
    title: 'Day 4 — Trust',
    message: 'Trust is forming. Today, set boundaries and security rules.',
    tip: 'Create AGENTS.md with behavioral rules. A trusted agent is a powerful agent.',
  },
  5: {
    emoji: '🔄',
    title: 'Day 5 — Optimize',
    message: 'Patterns are emerging. Turn repetitive tasks into workflows.',
    tip: 'Identify one task you do daily and make it a repeatable workflow.',
  },
  6: {
    emoji: '⏰',
    title: 'Day 6 — Almost There!',
    message: 'Tomorrow is graduation day! Look how far you\'ve come.',
    tip: 'Review your journey. Tomorrow, say "graduate" to begin your ceremony.',
  },
  7: {
    emoji: '🎓',
    title: 'Day 7 — Graduation Day!',
    message: 'Seven days. One complete transformation. You\'re ready.',
    tip: 'Say "graduate" to start your graduation ceremony, or "exam" for the graduation exam.',
  },
};

function getJourneyDay(openclawHome) {
  const journeyFile = path.join(openclawHome, 'data', 'graduate', 'journey-start.json');

  try {
    if (!fs.existsSync(journeyFile)) {
      return 0;
    }

    const data = JSON.parse(fs.readFileSync(journeyFile, 'utf8'));
    const startDate = data.startDate;
    if (!startDate) return 0;

    const start = new Date(startDate);
    const now = new Date();
    const diffMs = now.getTime() - start.getTime();
    const diffDays = Math.floor(diffMs / 86400000) + 1;

    return Math.max(1, Math.min(7, diffDays));
  } catch (e) {
    return 0;
  }
}

function buildDayContent(day) {
  if (day === 0) return '';

  const content = DAY_CONTENT[day];
  if (!content) return '';

  return `## ${content.emoji} ${content.title}\n\n${content.message}\n\n**Today's tip**: ${content.tip}`;
}

const handler = async (event) => {
  if (!event || typeof event !== 'object') return;
  if (event.type !== 'agent' || event.action !== 'bootstrap') return;
  if (!event.context || typeof event.context !== 'object') return;

  const sessionKey = event.sessionKey || '';
  if (sessionKey.includes(':subagent:')) return;

  const openclawHome = process.env.OPENCLAW_HOME || `${process.env.HOME}/.openclaw`;
  const day = getJourneyDay(openclawHome);

  if (day === 0) return;

  const content = buildDayContent(day);
  if (!content) return;

  if (Array.isArray(event.context.bootstrapFiles)) {
    event.context.bootstrapFiles.push({
      path: 'GRADUATION_COMPANION.md',
      content,
      virtual: true,
    });
  }
};

module.exports = handler;
module.exports.default = handler;

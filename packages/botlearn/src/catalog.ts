import type {
  SkillCatalog,
  SkillCategory,
  SkillRegistryEntry,
  SkillSearchQuery,
  SkillSearchResult,
  InstallPlan,
} from "./types.js";

/**
 * Search skills by keyword, category, tags, or capabilities.
 * Returns results sorted by relevance (highest first).
 */
export function searchSkills(
  catalog: SkillCatalog,
  query: SkillSearchQuery
): SkillSearchResult[] {
  const results: SkillSearchResult[] = [];

  for (const skill of catalog.skills) {
    let relevance = 0;
    const matchReasons: string[] = [];

    // Category filter (exact match)
    if (query.category && skill.category !== query.category) {
      continue;
    }
    if (query.category) {
      relevance += 1;
      matchReasons.push(`category: ${query.category}`);
    }

    // Keyword search across name, description, tags, capabilities, triggers
    if (query.keyword) {
      const kw = query.keyword.toLowerCase();
      const nameHit = skill.name.toLowerCase().includes(kw);
      const descHit = skill.description.toLowerCase().includes(kw);
      const tagHit = skill.tags.some((t) => t.toLowerCase().includes(kw));
      const capHit = skill.capabilities.some((c) =>
        c.toLowerCase().includes(kw)
      );
      const triggerHit = skill.triggers.some((t) =>
        t.toLowerCase().includes(kw)
      );

      if (nameHit) {
        relevance += 5;
        matchReasons.push("name match");
      }
      if (descHit) {
        relevance += 2;
        matchReasons.push("description match");
      }
      if (tagHit) {
        relevance += 3;
        matchReasons.push("tag match");
      }
      if (capHit) {
        relevance += 4;
        matchReasons.push("capability match");
      }
      if (triggerHit) {
        relevance += 3;
        matchReasons.push("trigger match");
      }

      if (relevance === 0 && !query.category) continue;
    }

    // Tags intersection
    if (query.tags && query.tags.length > 0) {
      const matched = query.tags.filter((t) =>
        skill.tags.some((st) => st.toLowerCase() === t.toLowerCase())
      );
      if (matched.length > 0) {
        relevance += matched.length * 2;
        matchReasons.push(`tags: ${matched.join(", ")}`);
      } else if (!query.keyword && !query.category) {
        continue;
      }
    }

    // Capabilities intersection
    if (query.capabilities && query.capabilities.length > 0) {
      const matched = query.capabilities.filter((c) =>
        skill.capabilities.some((sc) => sc.toLowerCase() === c.toLowerCase())
      );
      if (matched.length > 0) {
        relevance += matched.length * 3;
        matchReasons.push(`capabilities: ${matched.join(", ")}`);
      } else if (!query.keyword && !query.category && !query.tags?.length) {
        continue;
      }
    }

    if (relevance > 0) {
      results.push({ skill, relevance, matchReasons });
    }
  }

  return results.sort((a, b) => b.relevance - a.relevance);
}

/**
 * Resolve install order via topological sort.
 * Returns an InstallPlan with the correct installation sequence.
 */
export function resolveInstallOrder(
  catalog: SkillCatalog,
  targets: string[],
  installed: string[] = []
): InstallPlan {
  const installedSet = new Set(installed);
  const skillMap = new Map<string, SkillRegistryEntry>();
  for (const s of catalog.skills) {
    skillMap.set(s.name, s);
  }

  // Collect all needed skills (targets + transitive deps)
  const needed = new Set<string>();

  function collect(name: string) {
    if (installedSet.has(name) || needed.has(name)) return;
    needed.add(name);
    const skill = skillMap.get(name);
    if (skill) {
      for (const dep of Object.keys(skill.dependencies)) {
        collect(dep);
      }
    }
  }

  for (const t of targets) collect(t);

  // Topological sort (Kahn's algorithm)
  const inDegree = new Map<string, number>();
  const adj = new Map<string, string[]>();

  for (const name of needed) {
    if (!inDegree.has(name)) inDegree.set(name, 0);
    if (!adj.has(name)) adj.set(name, []);
  }

  for (const name of needed) {
    const skill = skillMap.get(name);
    if (!skill) continue;
    for (const dep of Object.keys(skill.dependencies)) {
      if (needed.has(dep)) {
        adj.get(dep)!.push(name);
        inDegree.set(name, (inDegree.get(name) || 0) + 1);
      }
    }
  }

  const queue: string[] = [];
  for (const [name, deg] of inDegree) {
    if (deg === 0) queue.push(name);
  }

  const sorted: string[] = [];
  while (queue.length > 0) {
    const node = queue.shift()!;
    sorted.push(node);
    for (const neighbor of adj.get(node) || []) {
      const newDeg = (inDegree.get(neighbor) || 1) - 1;
      inDegree.set(neighbor, newDeg);
      if (newDeg === 0) queue.push(neighbor);
    }
  }

  const hasCycle = sorted.length < needed.size;

  return {
    installed: [...installedSet],
    toInstall: sorted,
    targets,
    hasCycle,
  };
}

/**
 * List skills filtered by category. If no category, returns all.
 */
export function listByCategory(
  catalog: SkillCatalog,
  category?: SkillCategory
): SkillRegistryEntry[] {
  if (!category) return [...catalog.skills];
  return catalog.skills.filter((s) => s.category === category);
}

/**
 * Get the full recursive dependency tree for a skill.
 * Returns a map of skill name -> its direct dependencies.
 */
export function getDependencyTree(
  catalog: SkillCatalog,
  skillName: string
): Record<string, string[]> {
  const skillMap = new Map<string, SkillRegistryEntry>();
  for (const s of catalog.skills) {
    skillMap.set(s.name, s);
  }

  const tree: Record<string, string[]> = {};

  function walk(name: string) {
    if (tree[name] !== undefined) return;
    const skill = skillMap.get(name);
    if (!skill) {
      tree[name] = [];
      return;
    }
    const deps = Object.keys(skill.dependencies);
    tree[name] = deps;
    for (const dep of deps) walk(dep);
  }

  walk(skillName);
  return tree;
}

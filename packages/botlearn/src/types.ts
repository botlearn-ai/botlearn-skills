// ============================================================
// BotLearn OpenClaw Skills — Shared Type Definitions
// ============================================================

// --- Enums & Literals ---

export type SkillCategory =
  | "information-retrieval"
  | "content-processing"
  | "programming-assistance"
  | "creative-generation"
  | "evaluation"
  | "learning"
  | "meta";

export type BenchmarkDimension =
  | "information-retrieval"
  | "content-understanding"
  | "logical-reasoning"
  | "code-generation"
  | "creative-generation"
  | "capability-assessment"
  | "learning-progress"
  | "meta-skill";

export type Difficulty = "easy" | "medium" | "hard";

export type Priority = "high" | "medium" | "low";

export type SkillPhase =
  | "retrieval"
  | "reasoning"
  | "verification"
  | "reflection";

export type IssueSeverity = "critical" | "high" | "medium" | "low";

// --- Skill Manifest ---

export interface SkillManifest {
  name: string;
  version: string;
  description: string;
  category: SkillCategory;
  author: string;

  benchmarkDimension: BenchmarkDimension;
  expectedImprovement: number;

  dependencies: Record<string, string>;
  compatibility: {
    openclaw: string;
  };

  files: {
    skill: string;
    knowledge: string[];
    strategies: string[];
    smokeTest: string;
    benchmark: string;
  };
}

// --- Test Types ---

export interface RubricItem {
  criterion: string;
  weight: number;
  scoring: {
    5: string;
    3: string;
    1: string;
    0: string;
  };
}

export interface SmokeTestTask {
  id: string;
  description: string;
  input: string;
  rubric: RubricItem[];
  passThreshold: number;
}

export interface SmokeTest {
  version: string;
  timeout: number;
  tasks: SmokeTestTask[];
}

export interface BenchmarkTask {
  id: string;
  difficulty: Difficulty;
  description: string;
  input: string;
  rubric: RubricItem[];
  expectedScoreWithout: number;
  expectedScoreWith: number;
}

export interface BenchmarkTest {
  version: string;
  dimension: BenchmarkDimension;
  tasks: BenchmarkTask[];
}

// --- Agent API: Memory System ---

export interface MemoryDocument {
  id: string;
  content: string;
  metadata: {
    domain: string;
    topic: string;
    priority: Priority;
    ttl?: string;
  };
}

export interface MemoryInjectRequest {
  skillName: string;
  documents: MemoryDocument[];
}

export interface MemoryInjectResponse {
  injected: number;
  skipped: number;
  errors: string[];
}

export interface MemoryRollbackRequest {
  skillName: string;
}

// --- Agent API: Skills System ---

export interface StrategyDocument {
  id: string;
  content: string;
  steps: number;
}

export interface SkillRegisterRequest {
  skillName: string;
  definition: string;
  strategies: StrategyDocument[];
  triggers: string[];
}

export interface SkillRegisterResponse {
  registered: boolean;
  activeSkills: string[];
}

export interface SkillUnregisterRequest {
  skillName: string;
}

// --- Agent API: Benchmark System ---

export interface BenchmarkRunRequest {
  tasks: Array<{
    id: string;
    input: string;
    rubric: RubricItem[];
  }>;
  judgeModel: string;
  runs: number;
}

export interface TaskResult {
  taskId: string;
  output: string;
  scores: number[];
  medianScore: number;
  rubricBreakdown: Array<{
    criterion: string;
    score: number;
    feedback: string;
  }>;
}

export interface BenchmarkRunResponse {
  results: TaskResult[];
  aggregateScore: number;
}

// --- Skill Runtime Error ---

export interface SkillError {
  skill: string;
  phase: SkillPhase;
  message: string;
  recoverable: boolean;
  suggestion?: string;
}

// --- Validation ---

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
  warnings?: ValidationWarning[];
}

export interface ValidationError {
  field: string;
  message: string;
}

export interface ValidationWarning {
  field: string;
  message: string;
}

// --- Skill Registry ---

export interface SkillRegistryEntry {
  name: string;
  version: string;
  description: string;
  category: SkillCategory;
  benchmarkDimension: BenchmarkDimension;
  expectedImprovement: number;
  tags: string[];
  capabilities: string[];
  triggers: string[];
  dependencies: Record<string, string>;
  dependents: string[];
  compatibility: { openclaw: string };
  npm: string;
}

export interface InstallGroup {
  description: string;
  skills: string[];
}

export interface SkillCatalog {
  version: string;
  generatedAt: string;
  skills: SkillRegistryEntry[];
  categories: Record<string, string[]>;
  dependencyGraph: Record<string, string[]>;
  installGroups: Record<string, InstallGroup>;
}

export interface SkillSearchQuery {
  keyword?: string;
  category?: SkillCategory;
  tags?: string[];
  capabilities?: string[];
}

export interface SkillSearchResult {
  skill: SkillRegistryEntry;
  relevance: number;
  matchReasons: string[];
}

export interface InstallPlan {
  installed: string[];
  toInstall: string[];
  targets: string[];
  hasCycle: boolean;
}

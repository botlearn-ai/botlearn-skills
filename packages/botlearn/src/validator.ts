import type {
  SkillManifest,
  SkillCategory,
  BenchmarkDimension,
  ValidationResult,
  ValidationError,
  ValidationWarning,
} from "./types.js";

export const VALID_CATEGORIES: SkillCategory[] = [
  "information-retrieval",
  "content-processing",
  "programming-assistance",
  "creative-generation",
  "evaluation",
  "learning",
  "meta",
];

export const VALID_DIMENSIONS: BenchmarkDimension[] = [
  "information-retrieval",
  "content-understanding",
  "logical-reasoning",
  "code-generation",
  "creative-generation",
  "capability-assessment",
  "learning-progress",
  "meta-skill",
];

const SEMVER_RE = /^\d+\.\d+\.\d+(?:-[\w.]+)?(?:\+[\w.]+)?$/;
const SEMVER_RANGE_RE =
  /^(?:[~^]?\d+\.\d+\.\d+(?:-[\w.]+)?|>=?\d+\.\d+\.\d+)$/;
const SKILL_NAME_RE = /^@botlearn\/[a-z][a-z0-9-]*$/;

/**
 * Validate a SkillManifest object and return all discovered errors.
 */
export function validateManifest(
  manifest: unknown,
  knownSkillNames?: string[]
): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  if (manifest === null || typeof manifest !== "object") {
    return { valid: false, errors: [{ field: "(root)", message: "Manifest must be a non-null object" }] };
  }

  const m = manifest as Record<string, unknown>;

  // --- Required string fields ---
  requireString(m, "name", errors);
  requireString(m, "version", errors);
  requireString(m, "description", errors);
  requireString(m, "author", errors);

  // --- Name format ---
  if (typeof m.name === "string" && !SKILL_NAME_RE.test(m.name)) {
    errors.push({
      field: "name",
      message: `Name must match @botlearn/<kebab-case>, got "${m.name}"`,
    });
  }

  // --- Version semver ---
  if (typeof m.version === "string" && !SEMVER_RE.test(m.version)) {
    errors.push({
      field: "version",
      message: `Version must be valid semver, got "${m.version}"`,
    });
  }

  // --- Category ---
  if (!VALID_CATEGORIES.includes(m.category as SkillCategory)) {
    errors.push({
      field: "category",
      message: `Category must be one of: ${VALID_CATEGORIES.join(", ")}`,
    });
  }

  // --- Benchmark dimension ---
  if (
    !VALID_DIMENSIONS.includes(m.benchmarkDimension as BenchmarkDimension)
  ) {
    errors.push({
      field: "benchmarkDimension",
      message: `benchmarkDimension must be one of: ${VALID_DIMENSIONS.join(", ")}`,
    });
  }

  // --- Expected improvement ---
  if (typeof m.expectedImprovement !== "number" || m.expectedImprovement < 0) {
    errors.push({
      field: "expectedImprovement",
      message: "expectedImprovement must be a non-negative number",
    });
  }

  // --- Dependencies ---
  if (m.dependencies !== undefined) {
    if (typeof m.dependencies !== "object" || m.dependencies === null) {
      errors.push({
        field: "dependencies",
        message: "dependencies must be an object",
      });
    } else {
      const deps = m.dependencies as Record<string, unknown>;
      for (const [depName, depVersion] of Object.entries(deps)) {
        if (!SKILL_NAME_RE.test(depName)) {
          errors.push({
            field: `dependencies.${depName}`,
            message: `Dependency name must match @botlearn/<kebab-case>`,
          });
        }
        if (
          typeof depVersion !== "string" ||
          !SEMVER_RANGE_RE.test(depVersion)
        ) {
          errors.push({
            field: `dependencies.${depName}`,
            message: `Dependency version must be a valid semver range, got "${String(depVersion)}"`,
          });
        }
        if (knownSkillNames && !knownSkillNames.includes(depName)) {
          errors.push({
            field: `dependencies.${depName}`,
            message: `Unknown dependency "${depName}" — not in known skills list`,
          });
        }
      }
    }
  }

  // --- Compatibility ---
  if (typeof m.compatibility !== "object" || m.compatibility === null) {
    errors.push({
      field: "compatibility",
      message: "compatibility must be an object with an openclaw field",
    });
  } else {
    const compat = m.compatibility as Record<string, unknown>;
    if (
      typeof compat.openclaw !== "string" ||
      !SEMVER_RANGE_RE.test(compat.openclaw)
    ) {
      errors.push({
        field: "compatibility.openclaw",
        message: `compatibility.openclaw must be a valid semver range`,
      });
    }
  }

  // --- Files ---
  if (typeof m.files !== "object" || m.files === null) {
    errors.push({
      field: "files",
      message: "files must be an object",
    });
  } else {
    const files = m.files as Record<string, unknown>;
    requireString(files, "skill", errors, "files.skill");
    requireStringArray(files, "knowledge", errors, "files.knowledge");
    requireStringArray(files, "strategies", errors, "files.strategies");
    requireString(files, "smokeTest", errors, "files.smokeTest");
    requireString(files, "benchmark", errors, "files.benchmark");
  }

  // --- Optional metadata warnings (non-blocking) ---
  if (manifest !== null && typeof manifest === "object") {
    const m2 = manifest as Record<string, unknown>;
    if (!Array.isArray(m2.tags) || m2.tags.length === 0) {
      warnings.push({
        field: "tags",
        message: "Missing tags — add tags for better discoverability in the skill registry",
      });
    }
    if (!Array.isArray(m2.capabilities) || m2.capabilities.length === 0) {
      warnings.push({
        field: "capabilities",
        message: "Missing capabilities — declare capabilities so agents can match skills to tasks",
      });
    }
    if (!Array.isArray(m2.triggers) || m2.triggers.length === 0) {
      warnings.push({
        field: "triggers",
        message: "Missing triggers — add trigger phrases for automatic skill activation",
      });
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    ...(warnings.length > 0 ? { warnings } : {}),
  };
}

// --- Helpers ---

function requireString(
  obj: Record<string, unknown>,
  field: string,
  errors: ValidationError[],
  displayField?: string
): void {
  if (typeof obj[field] !== "string" || (obj[field] as string).length === 0) {
    errors.push({
      field: displayField ?? field,
      message: `${displayField ?? field} is required and must be a non-empty string`,
    });
  }
}

function requireStringArray(
  obj: Record<string, unknown>,
  field: string,
  errors: ValidationError[],
  displayField?: string
): void {
  const val = obj[field];
  if (!Array.isArray(val) || val.length === 0) {
    errors.push({
      field: displayField ?? field,
      message: `${displayField ?? field} must be a non-empty array of strings`,
    });
  } else if (val.some((item) => typeof item !== "string")) {
    errors.push({
      field: displayField ?? field,
      message: `${displayField ?? field} must contain only strings`,
    });
  }
}

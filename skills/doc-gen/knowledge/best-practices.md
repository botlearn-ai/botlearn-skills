---
domain: doc-gen
topic: documentation-quality-and-coverage
priority: high
ttl: 30d
---

# Documentation Generation — Best Practices

## API Documentation Coverage

### 1. Completeness Checklist
Every public API entry point must have:
- **Summary** — One-sentence description of what the function/method does
- **Description** — Detailed explanation of behavior, including edge cases
- **Parameters** — Every parameter with name, type, default value, constraints, and description
- **Return value** — Type and description of what is returned, including null/undefined cases
- **Errors/Exceptions** — All throwable errors with conditions that trigger them
- **Examples** — At least one usage example with realistic input and expected output
- **Since/Version** — When the API was introduced or last changed

### 2. Coverage Metrics
Target documentation coverage levels:

| Level | Coverage | Description |
|-------|----------|-------------|
| Minimal | 30% | Only function names and parameter names |
| Basic | 50% | Summaries + parameter types |
| Good | 70% | Full descriptions + return values + errors |
| Excellent | 85% | All of above + examples + cross-references |
| Complete | 90%+ | Full coverage including edge cases, deprecation notices, and migration guides |

### 3. Measuring Coverage
- Count **public exports** (functions, classes, types, constants) as the denominator
- Count **fully documented** exports (meeting "Good" level) as the numerator
- Report per-module coverage alongside aggregate project coverage

## Example Quality Standards

### Write Examples That Teach
- Start with the **simplest possible usage** — demonstrate the happy path first
- Follow with **common variations** — optional parameters, configuration options
- End with **edge cases** — error handling, boundary conditions
- Use **realistic data** — avoid `foo`, `bar`, `test123`; use domain-appropriate values

### Example Structure Template
```javascript
// 1. Basic usage — what most users need
const client = new ApiClient({ baseUrl: 'https://api.example.com' });
const user = await client.getUser('usr_abc123');
// => { id: 'usr_abc123', name: 'Alice', email: 'alice@example.com' }

// 2. With options — common customization
const users = await client.listUsers({ limit: 10, role: 'admin' });
// => [{ id: 'usr_abc123', ... }, ...]

// 3. Error handling — what can go wrong
try {
  await client.getUser('nonexistent');
} catch (error) {
  if (error instanceof NotFoundError) {
    console.log(error.message); // => "User not found: nonexistent"
  }
}
```

### Example Anti-Patterns to Avoid
- Trivial examples that don't demonstrate real value: `add(1, 2) // => 3`
- Examples that depend on external state without setup context
- Examples with fictional imports or unavailable dependencies
- Missing expected output — always show the return value

## Consistent Style Guide

### Tone and Voice
- Use **second person** ("you") for guides and tutorials
- Use **third person** for API references ("Returns the user object")
- Write in **active voice**: "The function returns..." not "The value is returned by..."
- Be **concise but complete** — avoid filler phrases like "It should be noted that..."

### Formatting Conventions
- **Function names** in backticks: `getUserById()`
- **Parameter names** in backticks: `userId`
- **Type names** in backticks: `Promise<User>`
- **File paths** in backticks: `src/models/user.ts`
- **Code blocks** with language identifier: ` ```typescript `
- **Tables** for structured data (parameters, configuration, comparison)
- **Admonitions** for warnings, notes, and tips

### Description Patterns
| Element | Pattern | Example |
|---------|---------|---------|
| Function | "Verb + object + context" | "Retrieve a user by their unique identifier" |
| Parameter | "The + noun + constraint" | "The user's email address (must be valid RFC 5322)" |
| Return | "The + result + condition" | "The matching user, or undefined if not found" |
| Error | "Thrown when + condition" | "Thrown when the user ID does not exist" |
| Class | "A + noun + purpose" | "A thread-safe cache for storing session data" |

### Cross-Referencing
- Link related functions: "See also: `updateUser()`, `deleteUser()`"
- Reference parent class/module: "Part of the `UserRepository` class"
- Link to external specs: "Implements [RFC 7519](https://tools.ietf.org/html/rfc7519)"

## README Quality Criteria

### Quick Start Must Work
- The quick-start code block must be **copy-pasteable** and runnable
- Include all necessary imports and setup
- Show the minimum viable usage in under 10 lines
- Verify the quick start works by mentally or actually running it

### Installation Completeness
- Include **all package managers**: npm, yarn, pnpm
- Note **peer dependencies** that must be installed separately
- Include **environment requirements**: Node.js version, OS compatibility
- Show **verification**: a quick command to verify successful installation

### API Reference Organization
- Group by **module or feature area**, not alphabetically
- Show most commonly used APIs first
- Clearly mark **optional** vs **required** parameters
- Include return type in the function signature header

## Changelog Quality Criteria

### Entry Guidelines
- Each entry must be **understandable without reading code** — describe the user impact
- Use **imperative mood**: "Add batch user creation" not "Added batch user creation"
- Include **issue/PR references** when applicable: `(#234)`
- Mark **breaking changes** prominently with migration instructions
- Group related changes under the same category
- Order entries by impact within each category (most impactful first)

### Version Semantics
| Change Type | Version Bump | Example |
|------------|-------------|---------|
| Breaking API change | Major (X.0.0) | Renamed `getUser` to `fetchUser` |
| New feature (backward-compatible) | Minor (0.X.0) | Added `batchCreate` endpoint |
| Bug fix | Patch (0.0.X) | Fixed null pointer in `deleteUser` |
| Deprecation notice | Minor (0.X.0) | Deprecated `searchUsers` |
| Security fix | Patch (0.0.X) | Patched SQL injection |

## Documentation Maintenance

### Freshness Checks
- Verify documentation accuracy when the underlying code changes
- Flag documentation older than the most recent code change as potentially stale
- Include "Last updated" dates on long-form documents
- Run doc-coverage reports as part of CI to detect regressions

### Documentation-Code Sync
- Document during development, not after — prevents drift
- Use automated tools (typedoc, swagger-jsdoc) to generate from annotations where possible
- Treat documentation changes as part of the same PR as code changes

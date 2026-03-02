---
domain: doc-gen
topic: anti-patterns
priority: medium
ttl: 30d
---

# Documentation Generation — Anti-Patterns

## Content Anti-Patterns

### 1. Auto-Generated Gibberish
- **Problem**: Generating documentation that simply restates the function name in sentence form — `getUser` becomes "Gets the user" with no additional context about parameters, return values, edge cases, or usage
- **Fix**: Every doc entry must add information beyond what the signature already tells the reader. Describe *behavior*, *constraints*, *side effects*, and *failure modes*. If `getUser(id)` hits a database, state that. If it caches, state the TTL. If it throws on invalid IDs, document the error

### 2. Missing Examples
- **Problem**: API documentation that describes what a function does but provides no example of how to call it or what output to expect. Users must read source code to understand usage patterns
- **Fix**: Include at least one runnable example per public function. Show input, invocation, and expected output. For complex APIs, provide a basic example and an advanced example

### 3. Stale Documentation
- **Problem**: Documentation that describes behavior from a previous version of the code. Parameters that no longer exist, return types that have changed, or features that have been removed are still documented
- **Fix**: Compare documentation against the current code before finalizing. Check that every documented parameter exists in the function signature. Verify return types match. Flag any documentation that references removed or renamed identifiers

### 4. Copy-Paste Descriptions
- **Problem**: Using identical descriptions across similar functions without adapting to the specific behavior of each — e.g., `createUser`, `updateUser`, `deleteUser` all described as "Manages user data"
- **Fix**: Each function must have a description unique to its behavior. `createUser` inserts a new record, `updateUser` modifies an existing record (partial or full), `deleteUser` removes a record (soft or hard delete). State the specific action and its implications

### 5. Undocumented Error Cases
- **Problem**: Documentation only covers the happy path. Users discover thrown exceptions, rejection reasons, or error codes by encountering them at runtime
- **Fix**: Document every error/exception the function can throw or return. Include the condition that triggers each error and the error type/code. For async functions, document both rejection reasons and possible error response shapes

## Structural Anti-Patterns

### 6. Wall of Text README
- **Problem**: A README that is one continuous block of prose without headings, code blocks, or visual hierarchy. Users cannot scan for the information they need
- **Fix**: Use the standard README structure with clear sections: Title, Install, Quick Start, API, Configuration, Contributing, License. Use headers, code blocks, tables, and bullet lists to create scannable content

### 7. Missing Installation Instructions
- **Problem**: Documentation assumes the reader already knows how to install and configure the project. No package manager commands, no peer dependencies listed, no environment requirements stated
- **Fix**: Include explicit install commands for npm/yarn/pnpm. List all peer dependencies. State the minimum Node.js/Python/runtime version. Provide a verification step

### 8. Orphaned API References
- **Problem**: API documentation that exists in isolation without context — a list of functions with no guidance on which to use first, how they relate, or what workflow they support
- **Fix**: Start API documentation with an overview section that explains the main use cases and which functions to call. Group related functions. Provide a "Getting Started" flow that walks through the primary workflow

### 9. Inconsistent Formatting
- **Problem**: Documentation mixes different styles: some functions use JSDoc, others use plain comments; some parameters are in tables, others in bullet lists; some examples use TypeScript, others plain JavaScript
- **Fix**: Establish and follow a single documentation style guide. All functions use the same tag format. All parameters use the same presentation (table or list). All examples use the same language and style. Run a linter if available

### 10. Changelog as Commit Log
- **Problem**: The changelog is a raw dump of git commit messages — cryptic, inconsistent, and full of noise like "fix typo", "wip", "merge branch"
- **Fix**: Curate changelog entries to describe user-facing changes only. Group by category (Added, Changed, Fixed, etc.). Write entries in imperative mood. Exclude internal refactors, typo fixes, and CI changes unless they affect users. Reference issue numbers

## Quality Anti-Patterns

### 11. Type Information Without Context
- **Problem**: Documenting that a parameter is `string` without explaining what string values are valid — e.g., "id: string" tells the reader nothing about format (UUID? slug? numeric string?), length constraints, or validation rules
- **Fix**: Always include semantic context with types: "id: string — A UUID v4 identifying the user (e.g., `550e8400-e29b-41d4-a716-446655440000`)" or "status: string — One of `active`, `suspended`, `deleted`"

### 12. Documenting Private Internals as Public API
- **Problem**: Documentation includes internal helper functions, private methods, or implementation details that users should not depend on, creating an implied contract on unstable APIs
- **Fix**: Clearly separate public and internal documentation. Mark private/internal functions with `@internal` or `@private`. Exclude them from generated API docs by default. If internal details are documented for contributors, place them in a separate section or file (e.g., `ARCHITECTURE.md`)

### 13. No Deprecation Migration Path
- **Problem**: Marking a function as deprecated without explaining what to use instead or how to migrate existing code
- **Fix**: Every deprecation notice must include: (1) what to use instead, (2) a code example showing the migration from old to new, (3) the version when the deprecated API will be removed. Example: `@deprecated Since v2.0. Use fetchUser() instead. Will be removed in v3.0.`

### 14. Version-Blind Documentation
- **Problem**: Documentation does not indicate which version of the software it applies to. Users on older versions follow instructions that fail, or miss features available in their version
- **Fix**: Use `@since` tags to mark when APIs were introduced. Include version badges on READMEs. In changelogs, ensure version numbers and dates are accurate. For multi-version projects, provide version-specific documentation or clearly mark version requirements

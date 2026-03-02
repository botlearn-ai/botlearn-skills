---
strategy: doc-gen
version: 1.0.0
steps: 6
---

# Documentation Generation Strategy

## Step 1: Code Analysis
- Parse the target codebase to build a structural map: **modules**, **classes**, **functions**, **types**, **constants**, and **exports**
- Identify the **public API surface** — all exported symbols that external consumers can access
- Detect existing documentation: JSDoc/TSDoc comments, README files, inline comments, OpenAPI specs, changelog files
- Compute **baseline coverage**: count of documented vs undocumented public exports
- Classify the documentation request type:
  - API reference (JSDoc/TSDoc, OpenAPI)
  - Project README
  - Changelog
  - Inline code comments
  - Full documentation suite
- IF existing documentation exists THEN assess its accuracy against the current code
- IF the codebase uses TypeScript THEN extract type information from type annotations and interfaces
- Use @botlearn/code-gen capabilities to understand code structure, patterns, and architectural intent

## Step 2: API Extraction
- For each public export, extract:
  - **Function signature**: name, parameters (name, type, default, optional), return type
  - **Class definition**: constructor, public methods, public properties, static members, inheritance chain
  - **Type definitions**: interfaces, type aliases, enums, generics
  - **Constants**: exported values with their types and semantic purpose
- Detect **behavioral contracts** from the code:
  - Thrown exceptions and their trigger conditions
  - Side effects (database writes, file I/O, network calls, event emissions)
  - Async behavior (Promises, callbacks, streams)
  - Preconditions and postconditions (input validation, assertion checks)
- Map **dependency relationships** between functions and modules
- For REST endpoints, extract:
  - HTTP method and path
  - Path parameters, query parameters, request body schema
  - Response schemas for each status code
  - Authentication requirements
  - Rate limiting or quota information
- IF the project uses a framework (Express, Fastify, NestJS, Flask, FastAPI) THEN use framework-specific patterns to extract route metadata

## Step 3: Description Generation
- For each extracted API element, generate documentation following knowledge/domain.md formats:
  - **Summary line**: One sentence in imperative mood describing the primary action ("Retrieve a user by ID")
  - **Extended description**: Behavior details, constraints, side effects, and important context
  - **Parameter descriptions**: Semantic meaning beyond the type — valid values, constraints, formats, defaults with rationale
  - **Return description**: What is returned in each case (success, not found, error)
  - **Error documentation**: Each throwable error with its trigger condition and error code
- For README generation:
  - Write a concise project description (one line for tagline, one paragraph for overview)
  - Generate installation instructions for all relevant package managers
  - Write a quick-start section with copy-pasteable code
  - Summarize the API surface with links to detailed docs
  - Detect and include configuration options in a table
- For changelog generation:
  - Analyze git commit history since the last release tag
  - Map commits to changelog categories using conventional commit prefixes (see knowledge/domain.md)
  - Filter out non-user-facing changes (typo fixes, CI, internal refactors)
  - Write entries in imperative mood with issue/PR references
  - Group under the appropriate version heading
- APPLY tone and voice guidelines from knowledge/best-practices.md
- VERIFY descriptions add value beyond what the code signature already communicates (see anti-pattern #1 in knowledge/anti-patterns.md)

## Step 4: Example Creation
- For each public function or method, create at least one usage example:
  - **Basic example**: Simplest possible invocation showing the happy path with realistic data
  - **Common variation**: Demonstrate frequently used optional parameters or configuration
  - **Error handling**: Show how to catch and handle expected errors
- Example requirements:
  - Must be syntactically valid and runnable (no pseudocode)
  - Must include all necessary imports and setup
  - Must show expected output as a comment (`// => result`)
  - Must use realistic, domain-appropriate data (not `foo`, `bar`, `test`)
- For OpenAPI documentation:
  - Include request examples with realistic payloads
  - Include response examples for success and error cases
  - Provide cURL command examples for each endpoint
- For README quick-start:
  - The example must work out of the box after installation
  - Limit to 5-10 lines for the core demonstration
  - Show the minimum configuration needed
- IF the project has existing test files THEN reference test data for realistic example values
- VERIFY examples against knowledge/anti-patterns.md #2 (missing examples) and best-practices.md example quality standards

## Step 5: Style Matching
- Analyze existing documentation in the project for:
  - **Comment style**: JSDoc vs TSDoc vs plain comments vs docstrings
  - **Markdown conventions**: heading levels, list styles, code block language tags
  - **Naming conventions**: how parameters and types are described
  - **Tone**: formal vs conversational, second person vs third person
  - **Example style**: programming language, variable naming, output format
- IF existing documentation uses a specific style THEN match it exactly for consistency
- IF no existing style is detected THEN apply the defaults from knowledge/best-practices.md:
  - JSDoc/TSDoc for JavaScript/TypeScript
  - Google-style docstrings for Python
  - Third person for API references
  - Second person for guides and tutorials
- APPLY formatting conventions from knowledge/best-practices.md:
  - Backticks for code references
  - Tables for structured parameter/configuration data
  - Language-tagged code blocks for all examples
- VERIFY against knowledge/anti-patterns.md #9 (inconsistent formatting)
- IF the project has a linter or documentation config (eslint-plugin-jsdoc, typedoc.json, .remarkrc) THEN conform to those settings

## Step 6: Completeness Check
- Run a final coverage audit:
  - Count total public exports
  - Count fully documented exports (summary + params + return + errors + example)
  - Calculate percentage coverage
  - List any undocumented or partially documented items
- Verify documentation accuracy:
  - Every documented parameter exists in the current function signature
  - Every documented return type matches the actual return type
  - Every documented error is actually thrown by the code
  - No references to removed, renamed, or deprecated identifiers without deprecation notices
- Check for anti-patterns from knowledge/anti-patterns.md:
  - No auto-generated gibberish (#1)
  - No missing examples (#2)
  - No stale documentation (#3)
  - No copy-paste descriptions (#4)
  - No undocumented error cases (#5)
  - No orphaned API references (#8)
  - No changelog-as-commit-log (#10)
  - No type-without-context (#11)
  - No exposed private internals (#12)
- Generate a **coverage report**:
  ```
  Documentation Coverage Report
  ─────────────────────────────
  Before:  32% (16/50 exports documented)
  After:   92% (46/50 exports documented)

  Remaining gaps:
  - src/internal/cache.ts: 4 internal functions (intentionally excluded)

  Quality checks: 9/9 passed
  ```
- IF coverage is below 90% THEN loop back to Step 3 to address gaps
- IF any accuracy check fails THEN correct the documentation and re-verify
- SELF-CHECK:
  - Does every public function have a summary, params, return, errors, and example?
  - Do all examples compile/run without errors?
  - Is the documentation style consistent across all files?
  - Are cross-references valid and linking to existing symbols?
  - IF any check fails THEN address the specific gap before finalizing

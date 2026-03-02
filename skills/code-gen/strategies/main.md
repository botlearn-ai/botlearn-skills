---
strategy: code-gen
version: 1.0.0
steps: 6
---

# Code Generation Strategy

## Step 1: Requirement Analysis
- Parse the user's request to identify: **target language**, **framework/runtime**, **functional requirements**, **non-functional requirements** (performance, scale, security)
- Classify the task type: utility function / API endpoint / data model / CLI tool / state machine / full-stack feature / library/SDK
- Identify input/output contract: what data comes in, what data goes out, what types are involved
- Determine the scope boundary: what this code is responsible for vs. what it delegates
- IF requirements are ambiguous THEN ask one focused clarifying question before proceeding
- Extract constraints: target runtime (Node.js, browser, serverless), dependencies allowed, coding standards, existing codebase conventions

## Step 2: Architecture Decision
- SELECT architecture pattern based on task type and complexity:
  - Simple utility → Pure function with types and validation
  - API endpoint → Controller + Service + Repository layers with DTO types
  - Data pipeline → Pipeline/middleware pattern with typed stages
  - State management → State machine with discriminated union states and typed transitions
  - CLI tool → Command pattern with argument parsing, validation, and help generation
  - Library/SDK → Public API with types, internal implementation, and barrel exports
- SELECT design patterns from knowledge/domain.md:
  - Use Factory when construction varies by input
  - Use Strategy when algorithm varies at runtime
  - Use Repository when abstracting data access
  - Use Adapter when wrapping external services
  - Use Builder when object construction has many optional parameters
- DECIDE error handling strategy:
  - Result type (functional style) for libraries and utilities
  - Exception hierarchy (OOP style) for applications and APIs
  - Error codes with typed payloads for cross-boundary communication
- DOCUMENT the chosen architecture in a brief comment block at the top of the output

## Step 3: Interface Design
- Define all public types, interfaces, and data transfer objects BEFORE writing implementation
- For each public function, specify:
  - Parameter names and types (with validation constraints noted)
  - Return type (including error cases)
  - Side effects (I/O, mutations, logging)
  - Preconditions and postconditions
- Apply type safety practices from knowledge/best-practices.md:
  - Use discriminated unions for state modeling
  - Use branded types for domain identifiers
  - Derive types from validation schemas when possible
  - Prefer `readonly` for immutable data
- Define error types specific to this module:
  - One base error class extending the standard error
  - Specific error subclasses for each failure mode
  - Include contextual fields (resource name, expected vs. received values)
- IF the code involves an API THEN define the request/response schemas with validation

## Step 4: Implementation
- Implement each function following the interface contracts from Step 3
- Apply language idioms from knowledge/domain.md:
  - TypeScript: strict mode, no `any`, discriminated unions, `async`/`await`
  - Python: type hints, dataclasses/Pydantic, context managers, pathlib
  - Go: error returns, context propagation, defer, interface composition
  - Rust: ownership, Result/Option, trait implementations, iterators
- IMPLEMENT error handling at every boundary:
  - Validate all inputs at the function entry point
  - Wrap external calls (I/O, network, parsing) in try/catch with specific error types
  - Provide meaningful error messages with context (field name, expected format, received value)
  - IF the function interacts with external services THEN implement timeout, retry, and circuit breaker as appropriate
- Apply async patterns from knowledge/domain.md:
  - Use `Promise.all` for independent parallel operations
  - Use `Promise.allSettled` when partial success is acceptable
  - Use async iterators for paginated or streaming data
  - Implement cancellation support via AbortController or context
- VERIFY against anti-patterns from knowledge/anti-patterns.md:
  - No `any` types or bare catches
  - No silent error swallowing
  - No hard-coded configuration
  - No god functions (each function < 40 lines of logic)
  - No missing input validation

## Step 5: Self-Testing
- Generate unit tests for every public function:
  - **Happy path**: valid input produces expected output
  - **Edge cases**: empty input, boundary values, maximum sizes, unicode, zero/null
  - **Error paths**: invalid input throws the correct error type with expected message
- Follow Arrange-Act-Assert pattern (from knowledge/best-practices.md)
- Name tests descriptively: `should [expected behavior] when [condition]`
- For async code: test timeout behavior, cancellation, retry exhaustion
- For state machines: test all valid transitions and verify invalid transitions are rejected
- IF the code involves I/O THEN generate integration test scaffolding with mock setup
- Target minimum coverage:
  - All public functions have at least one test
  - All error branches have at least one test
  - All state transitions have at least one test

## Step 6: Review & Output
- SELF-REVIEW the generated code against this checklist:
  - [ ] All public types are defined and exported
  - [ ] All inputs are validated at the boundary
  - [ ] All errors are handled with specific types and contextual messages
  - [ ] No `any`, no bare catches, no silent swallowing
  - [ ] Functions are under 40 lines of logic each
  - [ ] At least one test per public function
  - [ ] Usage example is included
  - [ ] Dependencies are explicitly imported (no implicit globals)
  - [ ] Configuration is externalized (no hard-coded URLs, keys, or magic numbers)
  - [ ] Code follows the target language's naming conventions and idioms
- IF any check fails THEN loop back to the relevant step and fix
- FORMAT the output in this order:
  1. Architecture comment block (pattern chosen, rationale)
  2. Type definitions and interfaces
  3. Error types
  4. Implementation
  5. Tests
  6. Usage example
- PROVIDE brief inline comments for non-obvious logic (the "why", not the "what")

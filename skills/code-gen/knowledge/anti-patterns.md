---
domain: code-gen
topic: anti-patterns
priority: medium
ttl: 30d
---

# Code Generation — Anti-Patterns

## Type Safety Anti-Patterns

### 1. `any` Type Abuse
- **Problem**: Using `any` (TypeScript), `object` (C#), or `interface{}` (Go) to bypass the type system, silencing compiler checks and hiding bugs
- **Impact**: Runtime crashes that should have been caught at compile time; no IDE autocompletion; impossible to refactor safely
- **Fix**: Use `unknown` with type guards, generic constraints, or explicit union types
```typescript
// BAD
function processData(data: any): any {
  return data.items.map((i: any) => i.name);
}

// GOOD
function processData<T extends { items: Array<{ name: string }> }>(data: T): string[] {
  return data.items.map(i => i.name);
}
```

### 2. Stringly-Typed Code
- **Problem**: Using plain strings for states, roles, event names, and identifiers instead of enums or literal types
- **Impact**: Typos become silent bugs; no autocompletion; refactoring misses string constants
- **Fix**: Use string literal unions, enums, or const objects
```typescript
// BAD
function setStatus(status: string) { ... }
setStatus("actve"); // Typo — no compiler error

// GOOD
type Status = "active" | "inactive" | "suspended";
function setStatus(status: Status) { ... }
setStatus("actve"); // Compiler error
```

### 3. Type Assertion Over-Use
- **Problem**: Using `as Type` or `!` (non-null assertion) to force types instead of proper narrowing
- **Impact**: Bypasses type safety; runtime will crash when the assertion is wrong
- **Fix**: Use type guards, null checks, or schema validation
```typescript
// BAD
const user = response.data as User; // What if data is null?

// GOOD
const parsed = userSchema.safeParse(response.data);
if (!parsed.success) throw new ValidationError(parsed.error);
const user = parsed.data;
```

## Error Handling Anti-Patterns

### 4. Silent Catch (Swallowed Errors)
- **Problem**: Catching exceptions and doing nothing — losing error context and hiding failures
- **Impact**: Bugs become invisible; system enters corrupt state silently; debugging becomes extremely difficult
- **Fix**: Always log, re-throw, or return an error result. At minimum log the error.
```typescript
// BAD
try {
  await saveOrder(order);
} catch (e) {
  // silently swallowed
}

// GOOD
try {
  await saveOrder(order);
} catch (error) {
  logger.error("Failed to save order", { orderId: order.id, error });
  throw new OrderPersistenceError(order.id, error);
}
```

### 5. Catching Generic Exceptions
- **Problem**: Using bare `catch` (Python), `catch (Exception e)` (Java), or `catch (e)` without type narrowing
- **Impact**: Catches programming errors (null references, type errors) along with expected failures; masks bugs
- **Fix**: Catch specific error types; let unexpected errors propagate to the global error handler
```python
# BAD
try:
    result = process_payment(order)
except Exception:
    return {"error": "something went wrong"}

# GOOD
try:
    result = process_payment(order)
except PaymentDeclinedError as e:
    return {"error": f"Payment declined: {e.reason}", "code": "PAYMENT_DECLINED"}
except PaymentGatewayTimeout as e:
    logger.warning("Payment gateway timeout", extra={"order_id": order.id})
    raise RetryableError("Payment processing timed out") from e
```

### 6. Error Messages Without Context
- **Problem**: Throwing errors with generic messages like "An error occurred" or "Invalid input"
- **Impact**: Debugging requires reproducing the issue; no information about what was expected vs. received
- **Fix**: Include the field name, the received value (sanitized), and the expected format
```typescript
// BAD
throw new Error("Invalid input");

// GOOD
throw new ValidationError(
  `Field 'email' is invalid: received '${sanitize(input.email)}', expected a valid email address`
);
```

## Validation Anti-Patterns

### 7. No Input Validation
- **Problem**: Assuming inputs are well-formed; passing user input directly to database queries, file operations, or shell commands
- **Impact**: SQL injection, path traversal, command injection, data corruption, and crashes on unexpected types
- **Fix**: Validate and sanitize all external input at the boundary; use parameterized queries
```typescript
// BAD
app.get("/users/:id", async (req, res) => {
  const user = await db.query(`SELECT * FROM users WHERE id = '${req.params.id}'`);
  res.json(user);
});

// GOOD
app.get("/users/:id", async (req, res) => {
  const id = z.string().uuid().parse(req.params.id);
  const user = await db.query("SELECT * FROM users WHERE id = $1", [id]);
  if (!user) throw new NotFoundError("User", id);
  res.json(user);
});
```

### 8. Validation Logic Scattered Across Codebase
- **Problem**: Validating the same field in multiple places with inconsistent rules
- **Impact**: Contradictory validation; bypass by calling the inner function directly; maintenance nightmare
- **Fix**: Define validation schemas once; apply at the API boundary; trust validated data internally

## Architecture Anti-Patterns

### 9. God Function / God Class
- **Problem**: A single function or class that handles multiple unrelated responsibilities (parse + validate + transform + save + notify)
- **Impact**: Impossible to test in isolation; changes ripple unpredictably; functions exceed 100 lines
- **Fix**: Extract each responsibility into a separate function or class; compose them in a pipeline
```typescript
// BAD: one function does everything
async function handleOrder(rawData: unknown) {
  // 200 lines of parsing, validating, saving, emailing, logging...
}

// GOOD: composed pipeline
async function handleOrder(rawData: unknown): Promise<OrderResult> {
  const validated = validateOrderInput(rawData);
  const order = buildOrder(validated);
  const saved = await orderRepo.save(order);
  await notificationService.sendConfirmation(saved);
  return toOrderResult(saved);
}
```

### 10. Hard-Coded Configuration
- **Problem**: Embedding URLs, connection strings, API keys, timeouts, and feature flags directly in source code
- **Impact**: Cannot change behavior without code changes; secrets leak into version control; different environments require code modifications
- **Fix**: Use environment variables, configuration files, or a config module with validation
```typescript
// BAD
const API_URL = "https://api.production.com/v2";
const TIMEOUT = 5000;

// GOOD
const config = loadConfig({
  apiUrl: envVar("API_URL").required().url(),
  timeout: envVar("REQUEST_TIMEOUT_MS").default(5000).int().min(100).max(60000),
});
```

### 11. Premature Abstraction
- **Problem**: Creating generic frameworks, complex inheritance hierarchies, or elaborate plugin systems before having concrete use cases
- **Impact**: Over-engineered code that is harder to understand and modify than the problem warrants; abstractions that don't match real usage patterns
- **Fix**: Follow the "Rule of Three" — wait until you have three concrete examples before extracting an abstraction. Start concrete, refactor to abstract when patterns emerge.

### 12. Missing Dependency Injection
- **Problem**: Functions that directly instantiate their dependencies (e.g., `new Database()`, `axios.get()`) instead of accepting them as parameters
- **Impact**: Impossible to unit test without mocking module internals; tight coupling; cannot swap implementations
- **Fix**: Accept dependencies as function/constructor parameters; provide defaults for production
```typescript
// BAD: hard-wired dependency
async function getUser(id: string) {
  const db = new Database(); // untestable
  return db.query("SELECT * FROM users WHERE id = $1", [id]);
}

// GOOD: injectable dependency
async function getUser(id: string, db: Database = defaultDb): Promise<User | null> {
  return db.query("SELECT * FROM users WHERE id = $1", [id]);
}
```

## Output Anti-Patterns

### 13. Code Without Usage Examples
- **Problem**: Generating a function or class without showing how to call it
- **Impact**: User must read the entire implementation to understand the API; incorrect usage leads to bugs
- **Fix**: Always include at least one usage example with realistic arguments and expected output

### 14. Incomplete Implementations
- **Problem**: Generating skeleton code with `// TODO` placeholders or `pass` statements in critical paths
- **Impact**: User deploys incomplete code; runtime failures in production
- **Fix**: Generate complete implementations; if a feature is beyond scope, throw a `NotImplementedError` with a descriptive message rather than silently passing

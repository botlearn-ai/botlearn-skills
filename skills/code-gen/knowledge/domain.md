---
domain: code-gen
topic: design-patterns-and-language-idioms
priority: high
ttl: 30d
---

# Code Generation — Design Patterns, Async Patterns & Error Handling

## Creational Design Patterns

### Factory Pattern
- Use when object creation logic is complex or depends on runtime conditions
- Encapsulate construction behind a factory function or class method
- Return interface types rather than concrete implementations
```typescript
interface Logger { log(msg: string): void; }
function createLogger(type: "console" | "file" | "remote"): Logger {
  switch (type) {
    case "console": return new ConsoleLogger();
    case "file": return new FileLogger();
    case "remote": return new RemoteLogger();
    default: throw new InvalidLoggerTypeError(type);
  }
}
```

### Builder Pattern
- Use for constructing complex objects with many optional parameters
- Prefer over constructors with 4+ parameters
- Chain methods and return `this` for fluent API
```typescript
const query = new QueryBuilder()
  .select("name", "email")
  .from("users")
  .where("active", true)
  .orderBy("created_at", "desc")
  .limit(50)
  .build();
```

### Singleton / Module Pattern
- Use for shared resources: database connections, configuration, caches
- In modern JS/TS: prefer module-level instances over class-based singletons
- Always make singletons injectable for testability
```typescript
// Module singleton (preferred)
const config = loadConfig();
export { config };

// Injectable singleton (testable)
let instance: DbPool | null = null;
export function getPool(factory = createPool): DbPool {
  if (!instance) instance = factory();
  return instance;
}
```

## Structural Design Patterns

### Adapter Pattern
- Use to wrap third-party libraries behind your own interface
- Isolates vendor lock-in; makes swapping implementations easy
```typescript
interface StorageAdapter {
  get(key: string): Promise<string | null>;
  set(key: string, value: string, ttl?: number): Promise<void>;
  delete(key: string): Promise<void>;
}
// RedisAdapter, MemcachedAdapter, InMemoryAdapter all implement StorageAdapter
```

### Repository Pattern
- Abstract data access behind a repository interface
- Keep business logic free from database query details
```typescript
interface UserRepository {
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  create(data: CreateUserDTO): Promise<User>;
  update(id: string, data: UpdateUserDTO): Promise<User>;
  delete(id: string): Promise<void>;
}
```

### Middleware / Pipeline Pattern
- Chain processing steps for request handling, data transformation, or validation
- Each middleware receives context and a `next` function
```typescript
type Middleware<T> = (ctx: T, next: () => Promise<void>) => Promise<void>;

function compose<T>(middlewares: Middleware<T>[]): Middleware<T> {
  return (ctx, next) => {
    let index = -1;
    function dispatch(i: number): Promise<void> {
      if (i <= index) return Promise.reject(new Error("next() called multiple times"));
      index = i;
      const fn = i === middlewares.length ? next : middlewares[i];
      return fn(ctx, () => dispatch(i + 1));
    }
    return dispatch(0);
  };
}
```

## Behavioral Design Patterns

### Strategy Pattern
- Use when an algorithm needs to vary at runtime
- Define a common interface; inject the desired strategy
```typescript
interface CompressionStrategy {
  compress(data: Buffer): Promise<Buffer>;
  decompress(data: Buffer): Promise<Buffer>;
}
// GzipStrategy, BrotliStrategy, LZ4Strategy all implement CompressionStrategy
```

### Observer / Event Emitter Pattern
- Use for decoupled communication between components
- Prefer typed event maps over string-based events
```typescript
type EventMap = {
  "user:created": { id: string; email: string };
  "user:deleted": { id: string };
  "order:completed": { orderId: string; total: number };
};

interface TypedEmitter<T extends Record<string, unknown>> {
  on<K extends keyof T>(event: K, handler: (data: T[K]) => void): void;
  emit<K extends keyof T>(event: K, data: T[K]): void;
}
```

## Async Patterns

### Promise Composition
```typescript
// Parallel execution — use when tasks are independent
const [users, orders, products] = await Promise.all([
  fetchUsers(),
  fetchOrders(),
  fetchProducts(),
]);

// Settled — use when you need results even if some fail
const results = await Promise.allSettled([
  riskyOperation1(),
  riskyOperation2(),
]);
const successes = results.filter(r => r.status === "fulfilled");
const failures = results.filter(r => r.status === "rejected");
```

### Retry with Exponential Backoff
```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  options: { maxRetries: number; baseDelay: number; maxDelay: number }
): Promise<T> {
  for (let attempt = 0; attempt <= options.maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === options.maxRetries) throw error;
      const delay = Math.min(
        options.baseDelay * Math.pow(2, attempt) + Math.random() * 100,
        options.maxDelay
      );
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  throw new Error("Unreachable");
}
```

### Async Iterator / Stream Processing
```typescript
async function* paginate<T>(
  fetchPage: (cursor: string | null) => Promise<{ data: T[]; nextCursor: string | null }>
): AsyncGenerator<T> {
  let cursor: string | null = null;
  do {
    const { data, nextCursor } = await fetchPage(cursor);
    for (const item of data) yield item;
    cursor = nextCursor;
  } while (cursor !== null);
}
```

### Circuit Breaker
```typescript
class CircuitBreaker {
  private failures = 0;
  private lastFailureTime = 0;
  private state: "closed" | "open" | "half-open" = "closed";

  constructor(
    private readonly threshold: number,
    private readonly resetTimeoutMs: number
  ) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === "open") {
      if (Date.now() - this.lastFailureTime > this.resetTimeoutMs) {
        this.state = "half-open";
      } else {
        throw new CircuitOpenError("Circuit breaker is open");
      }
    }
    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess(): void {
    this.failures = 0;
    this.state = "closed";
  }

  private onFailure(): void {
    this.failures++;
    this.lastFailureTime = Date.now();
    if (this.failures >= this.threshold) this.state = "open";
  }
}
```

## Error Handling Patterns

### Custom Error Hierarchy
```typescript
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    public readonly isOperational: boolean = true,
    public readonly cause?: Error
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message: string, public readonly fields: Record<string, string[]>) {
    super(message, "VALIDATION_ERROR", 400);
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} with id '${id}' not found`, "NOT_FOUND", 404);
  }
}

class ExternalServiceError extends AppError {
  constructor(service: string, cause: Error) {
    super(`External service '${service}' failed: ${cause.message}`, "EXTERNAL_SERVICE_ERROR", 502, true, cause);
  }
}
```

### Result Type (Rust-inspired)
```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

function ok<T>(value: T): Result<T, never> {
  return { ok: true, value };
}

function err<E>(error: E): Result<never, E> {
  return { ok: false, error };
}

// Usage: eliminates try/catch proliferation
async function parseConfig(path: string): Promise<Result<Config, ConfigError>> {
  const raw = await readFile(path);
  if (!raw) return err(new ConfigError("File not found"));
  const parsed = JSON.parse(raw);
  const validated = configSchema.safeParse(parsed);
  if (!validated.success) return err(new ConfigError(validated.error.message));
  return ok(validated.data);
}
```

### Graceful Degradation
```typescript
async function getUserProfile(userId: string): Promise<UserProfile> {
  const user = await userRepo.findById(userId); // Required — throw on failure
  if (!user) throw new NotFoundError("User", userId);

  // Optional enrichment — degrade gracefully
  const [avatar, preferences] = await Promise.allSettled([
    avatarService.getAvatar(userId),
    preferencesService.getPreferences(userId),
  ]);

  return {
    ...user,
    avatar: avatar.status === "fulfilled" ? avatar.value : DEFAULT_AVATAR,
    preferences: preferences.status === "fulfilled" ? preferences.value : DEFAULT_PREFERENCES,
  };
}
```

## Language-Specific Idioms

### TypeScript
- Use `unknown` instead of `any` for type-safe narrowing
- Prefer `interface` for object shapes; `type` for unions, intersections, and mapped types
- Use discriminated unions for state modeling
- Leverage `as const` for literal types and exhaustive checks
- Use branded types for domain identifiers (`type UserId = string & { __brand: "UserId" }`)

### Python
- Use dataclasses or Pydantic models for structured data
- Use context managers (`with` statement) for resource management
- Prefer `pathlib.Path` over string-based file operations
- Use type hints with `TypeVar`, `Generic`, `Protocol` for generic code
- Use `enum.Enum` for fixed sets of values; `@dataclass(frozen=True)` for value objects

### Go
- Return `(result, error)` tuples; check errors immediately
- Use `context.Context` for cancellation and timeout propagation
- Prefer composition over inheritance via struct embedding
- Use interfaces implicitly (no `implements` keyword)
- Use `defer` for cleanup; `sync.WaitGroup` for goroutine coordination

### Rust
- Leverage the ownership system; prefer `&str` over `String` in function signatures
- Use `Result<T, E>` and the `?` operator for error propagation
- Use `enum` for algebraic data types and state machines
- Implement `From<OtherError>` for custom error types to enable `?`
- Use `Iterator` trait methods instead of manual loops

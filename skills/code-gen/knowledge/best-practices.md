---
domain: code-gen
topic: type-safety-validation-and-testing
priority: high
ttl: 30d
---

# Code Generation — Best Practices

## Type Safety

### 1. Define Types at the Boundary
- Define input/output types for every public function, API endpoint, and module boundary
- Use schema validation libraries (Zod, Pydantic, JSON Schema) to enforce types at runtime boundaries
- Keep internal logic strongly typed; only marshal/unmarshal at edges

```typescript
// Define the contract
interface CreateOrderRequest {
  userId: string;
  items: Array<{ productId: string; quantity: number }>;
  shippingAddress: Address;
}

interface CreateOrderResponse {
  orderId: string;
  status: "pending" | "confirmed";
  estimatedDelivery: string;
}

// Validate at the boundary
const createOrderSchema = z.object({
  userId: z.string().uuid(),
  items: z.array(z.object({
    productId: z.string().uuid(),
    quantity: z.number().int().positive().max(100),
  })).min(1).max(50),
  shippingAddress: addressSchema,
});
```

### 2. Use Discriminated Unions for State
- Model mutually exclusive states as discriminated unions instead of optional fields
- Eliminates impossible states at the type level

```typescript
// BAD: allows impossible states (loading=true AND error set)
interface DataState {
  loading: boolean;
  data?: User[];
  error?: string;
}

// GOOD: each state is explicit and exhaustive
type DataState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: User[] }
  | { status: "error"; error: string; retryCount: number };
```

### 3. Prefer Narrow Types Over Broad Ones
- Use string literal unions instead of `string` for known value sets
- Use branded/opaque types for domain identifiers to prevent mixing
- Use `readonly` arrays and objects where mutation is not needed

```typescript
type Currency = "USD" | "EUR" | "GBP" | "JPY";
type OrderStatus = "draft" | "pending" | "confirmed" | "shipped" | "delivered" | "cancelled";

// Branded types prevent accidental swaps
type UserId = string & { readonly __brand: unique symbol };
type OrderId = string & { readonly __brand: unique symbol };

function getOrder(orderId: OrderId): Promise<Order>; // Cannot pass UserId here
```

## Input Validation

### 4. Validate All External Input
- Every public API, CLI argument, environment variable, and file read must be validated
- Fail fast with descriptive error messages that name the invalid field and expected format
- Never trust client-side validation alone; always re-validate on the server

```typescript
function validateEnvConfig(): AppConfig {
  const errors: string[] = [];

  const port = Number(process.env.PORT);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    errors.push("PORT must be an integer between 1 and 65535");
  }

  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl || !dbUrl.startsWith("postgresql://")) {
    errors.push("DATABASE_URL must be a valid PostgreSQL connection string");
  }

  if (errors.length > 0) {
    throw new ConfigValidationError(errors);
  }

  return { port, dbUrl: dbUrl! };
}
```

### 5. Sanitize Before Processing
- Trim whitespace from string inputs
- Normalize Unicode (NFC) for text comparison
- Escape special characters for SQL, HTML, shell, and regex contexts
- Limit input length to prevent resource exhaustion

### 6. Use Schema Validation Libraries
- Zod (TypeScript): composable schemas with type inference
- Pydantic (Python): model-based validation with automatic parsing
- joi / yup (JavaScript): mature schema validation
- Always derive TypeScript types from the schema, not the other way around

```typescript
// Schema is the source of truth; type is derived
const userSchema = z.object({
  name: z.string().min(1).max(200).trim(),
  email: z.string().email().toLowerCase(),
  age: z.number().int().min(0).max(150).optional(),
  role: z.enum(["admin", "user", "viewer"]).default("user"),
});

type User = z.infer<typeof userSchema>; // Type derived from schema
```

## Test Accompaniment

### 7. Generate Tests Alongside Code
- Every generated function should include at least one unit test
- Test the happy path, one edge case, and one error case at minimum
- Use descriptive test names that state the expected behavior

```typescript
describe("calculateDiscount", () => {
  it("should apply percentage discount to the subtotal", () => {
    expect(calculateDiscount(100, { type: "percentage", value: 15 })).toBe(85);
  });

  it("should not reduce price below zero for large discounts", () => {
    expect(calculateDiscount(10, { type: "fixed", value: 25 })).toBe(0);
  });

  it("should throw ValidationError for negative discount values", () => {
    expect(() =>
      calculateDiscount(100, { type: "percentage", value: -5 })
    ).toThrow(ValidationError);
  });
});
```

### 8. Test Structure: Arrange-Act-Assert
- **Arrange**: set up preconditions and inputs
- **Act**: execute the code under test
- **Assert**: verify the expected outcome
- Keep each test focused on a single behavior

### 9. Test Error Paths Explicitly
- Verify that error messages are descriptive and actionable
- Verify that error types are correct (not just that an error was thrown)
- Test timeout behavior, retry logic, and graceful degradation

```typescript
it("should throw NotFoundError with resource name and id", async () => {
  await expect(userRepo.findById("nonexistent-id"))
    .rejects
    .toThrow(new NotFoundError("User", "nonexistent-id"));
});

it("should retry 3 times before throwing on transient failure", async () => {
  const mockFn = jest.fn()
    .mockRejectedValueOnce(new TransientError())
    .mockRejectedValueOnce(new TransientError())
    .mockRejectedValueOnce(new TransientError())
    .mockResolvedValue("success");

  await expect(withRetry(mockFn, { maxRetries: 2 })).rejects.toThrow(TransientError);
  expect(mockFn).toHaveBeenCalledTimes(3);
});
```

## Code Organization

### 10. Single Responsibility per Module
- Each file/module should have one clear purpose
- Group related types, functions, and constants together
- Keep files under 300 lines; split when complexity grows

### 11. Explicit Exports
- Export only the public API; keep internals private
- Use barrel files (`index.ts`) to aggregate public exports
- Document exported functions with JSDoc or docstrings

### 12. Consistent Naming Conventions
| Entity | Convention | Example |
|--------|-----------|---------|
| Functions | camelCase (JS/TS), snake_case (Python/Rust/Go) | `getUserById`, `get_user_by_id` |
| Classes/Types | PascalCase | `UserRepository`, `OrderStatus` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT` |
| Boolean vars | is/has/can/should prefix | `isActive`, `hasPermission` |
| Files | kebab-case (JS/TS), snake_case (Python) | `user-repository.ts`, `user_repository.py` |

## Documentation

### 13. Self-Documenting Code with Strategic Comments
- Choose descriptive names that make code readable without comments
- Add comments for **why**, not **what** — explain non-obvious decisions
- Document public APIs with parameter descriptions, return types, and examples
- Include `@throws` / `Raises` annotations for functions that throw

```typescript
/**
 * Calculates the shipping cost based on package weight and destination zone.
 *
 * Uses a tiered pricing model: base rate + per-kg surcharge above the free tier.
 * International zones (4+) include an additional customs processing fee.
 *
 * @param weightKg - Package weight in kilograms (must be > 0)
 * @param zone - Destination shipping zone (1-6)
 * @returns The total shipping cost in cents
 * @throws {ValidationError} If weight is non-positive or zone is out of range
 */
function calculateShippingCost(weightKg: number, zone: ShippingZone): number {
```

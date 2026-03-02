---
domain: doc-gen
topic: documentation-formats-and-syntax
priority: high
ttl: 30d
---

# Documentation Generation — Formats, Syntax & Conventions

## JSDoc / TSDoc Syntax

### Basic Function Documentation
```javascript
/**
 * Calculate the total price including tax and optional discount.
 *
 * @param {number} basePrice - The pre-tax price in cents
 * @param {number} taxRate - Tax rate as a decimal (e.g., 0.08 for 8%)
 * @param {number} [discount=0] - Optional discount amount in cents
 * @returns {number} The final price in cents, rounded to the nearest integer
 * @throws {RangeError} If basePrice or taxRate is negative
 *
 * @example
 * // Basic usage
 * calculateTotal(1000, 0.08);
 * // => 1080
 *
 * @example
 * // With discount
 * calculateTotal(1000, 0.08, 100);
 * // => 980
 */
function calculateTotal(basePrice, taxRate, discount = 0) { ... }
```

### Common JSDoc Tags
| Tag | Purpose | Example |
|-----|---------|---------|
| `@param` | Document a parameter | `@param {string} name - The user's name` |
| `@returns` | Document the return value | `@returns {Promise<User>} The resolved user` |
| `@throws` | Document thrown errors | `@throws {NotFoundError} If user does not exist` |
| `@example` | Provide usage example | Code block with input/output |
| `@deprecated` | Mark as deprecated | `@deprecated Use newMethod() instead` |
| `@since` | Version introduced | `@since 2.1.0` |
| `@see` | Cross-reference | `@see {@link OtherClass}` |
| `@typedef` | Define a custom type | `@typedef {Object} Config` |
| `@property` | Document object property | `@property {string} name - Display name` |
| `@async` | Mark as async | For async functions |
| `@private` | Mark as private | Excluded from public docs |
| `@public` | Mark as public | Included in public docs |

### TypeScript-Specific TSDoc
```typescript
/**
 * Repository for managing user entities.
 *
 * @typeParam T - The entity type extending BaseUser
 * @remarks
 * This class implements the Repository pattern for user management.
 * All methods are transaction-safe.
 */
class UserRepository<T extends BaseUser> {
  /**
   * Find a user by their unique identifier.
   *
   * @param id - The user's UUID
   * @returns The user entity or undefined if not found
   */
  async findById(id: string): Promise<T | undefined> { ... }
}
```

### Python Docstrings (Google Style)
```python
def fetch_data(url: str, timeout: int = 30, retries: int = 3) -> dict:
    """Fetch JSON data from a remote endpoint with retry logic.

    Sends an HTTP GET request to the specified URL and returns the
    parsed JSON response. Implements exponential backoff on failure.

    Args:
        url: The fully-qualified URL to fetch from.
        timeout: Request timeout in seconds. Defaults to 30.
        retries: Maximum number of retry attempts. Defaults to 3.

    Returns:
        A dictionary containing the parsed JSON response body.

    Raises:
        ConnectionError: If all retry attempts are exhausted.
        ValueError: If the response is not valid JSON.

    Example:
        >>> data = fetch_data("https://api.example.com/users")
        >>> print(data["count"])
        42
    """
```

## OpenAPI 3.x Specification

### Minimal Endpoint Definition
```yaml
openapi: 3.0.3
info:
  title: User Management API
  version: 1.0.0
  description: RESTful API for managing user accounts and profiles.

paths:
  /users/{userId}:
    get:
      operationId: getUserById
      summary: Retrieve a user by ID
      description: |
        Returns the full user profile for the given user ID.
        Requires authentication via Bearer token.
      tags:
        - Users
      parameters:
        - name: userId
          in: path
          required: true
          description: The unique identifier of the user (UUID v4)
          schema:
            type: string
            format: uuid
            example: "550e8400-e29b-41d4-a716-446655440000"
      responses:
        "200":
          description: User found and returned successfully
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/User"
              example:
                id: "550e8400-e29b-41d4-a716-446655440000"
                name: "Alice Johnson"
                email: "alice@example.com"
                createdAt: "2024-01-15T08:30:00Z"
        "404":
          description: User not found
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Error"
              example:
                code: "USER_NOT_FOUND"
                message: "No user exists with the given ID"
        "401":
          description: Authentication required
```

### Component Schemas
```yaml
components:
  schemas:
    User:
      type: object
      required: [id, name, email, createdAt]
      properties:
        id:
          type: string
          format: uuid
          description: Unique user identifier
        name:
          type: string
          minLength: 1
          maxLength: 100
          description: Full display name
        email:
          type: string
          format: email
          description: Primary email address
        createdAt:
          type: string
          format: date-time
          description: Account creation timestamp (ISO 8601)
    Error:
      type: object
      required: [code, message]
      properties:
        code:
          type: string
          description: Machine-readable error code
        message:
          type: string
          description: Human-readable error description
```

### Key OpenAPI Elements
| Element | Purpose | Required |
|---------|---------|----------|
| `operationId` | Unique identifier for the operation | Recommended |
| `summary` | Short one-line description | Yes |
| `description` | Detailed multi-line description | Recommended |
| `tags` | Group related endpoints | Recommended |
| `parameters` | Path, query, header params | As needed |
| `requestBody` | POST/PUT/PATCH payload | As needed |
| `responses` | All possible responses | Yes |
| `security` | Auth requirements | As needed |
| `examples` | Request/response examples | Recommended |

## README Conventions

### Standard README Structure
```markdown
# Project Name

> One-line description of what the project does.

[![npm version](https://badge.fury.io/js/package-name.svg)](...)
[![CI](https://github.com/org/repo/actions/workflows/ci.yml/badge.svg)](...)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](...)

## Features

- Feature 1 — brief description
- Feature 2 — brief description
- Feature 3 — brief description

## Installation

\`\`\`bash
npm install package-name
\`\`\`

## Quick Start

\`\`\`javascript
import { Something } from 'package-name';

const result = Something.doWork({ input: 'example' });
console.log(result);
\`\`\`

## API Reference

### `functionName(param1, param2)`

Description of the function.

**Parameters:**
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `param1` | `string` | — | Description |
| `param2` | `number` | `10` | Description |

**Returns:** `Promise<Result>` — Description of return value.

**Example:**
\`\`\`javascript
const result = await functionName('hello', 42);
\`\`\`

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `debug` | `boolean` | `false` | Enable debug logging |
| `timeout` | `number` | `5000` | Request timeout in ms |

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development setup and guidelines.

## License

[MIT](./LICENSE) © Author Name
```

### README Section Priority
| Section | Priority | When to Include |
|---------|----------|----------------|
| Title + description | Required | Always |
| Installation | Required | Always |
| Quick Start / Usage | Required | Always |
| API Reference | Required | For libraries |
| Configuration | Required | If configurable |
| Features | Recommended | When non-obvious |
| Badges | Recommended | For published packages |
| Contributing | Recommended | For open-source |
| License | Required | Always |
| Changelog link | Recommended | For versioned projects |

## Changelog Format (Keep a Changelog)

### Standard Structure
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New user profile endpoint (`GET /users/:id/profile`)

### Changed
- Improved error messages for validation failures

## [1.2.0] - 2024-08-15

### Added
- Batch user creation endpoint (`POST /users/batch`)
- Rate limiting middleware with configurable thresholds

### Fixed
- Race condition in concurrent session updates (#234)
- Memory leak in WebSocket connection handler (#228)

### Deprecated
- `GET /users/search` — use `GET /users?q=` instead (removal in 2.0.0)

## [1.1.0] - 2024-07-01

### Added
- OAuth 2.0 PKCE authentication flow
- Refresh token rotation

### Changed
- Upgraded bcrypt to v5.1.0 for improved performance

### Security
- Patched XSS vulnerability in user input sanitization (CVE-2024-XXXXX)

[Unreleased]: https://github.com/org/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/org/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/org/repo/releases/tag/v1.1.0
```

### Changelog Categories
| Category | Use For |
|----------|---------|
| `Added` | New features |
| `Changed` | Changes to existing functionality |
| `Deprecated` | Features that will be removed |
| `Removed` | Features that have been removed |
| `Fixed` | Bug fixes |
| `Security` | Vulnerability patches |

### Commit-to-Changelog Mapping
| Commit Prefix | Changelog Category |
|--------------|-------------------|
| `feat:` | Added |
| `fix:` | Fixed |
| `refactor:` | Changed |
| `deprecate:` | Deprecated |
| `perf:` | Changed |
| `security:` | Security |
| `BREAKING CHANGE:` | Changed (major version) |

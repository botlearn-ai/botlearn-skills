---
domain: code-review
topic: security-performance-smells
priority: high
ttl: 30d
---

# Code Review — Domain Knowledge

## OWASP Top 10 (2021)

### A01: Broken Access Control
- Missing authorization checks on API endpoints
- IDOR (Insecure Direct Object References): `GET /api/users/123` without verifying the caller owns the resource
- Path traversal: `../../../etc/passwd` in file operations
- Missing function-level access control (admin routes accessible to regular users)

### A02: Cryptographic Failures
- Hardcoded secrets, API keys, or passwords in source code
- Weak hashing (MD5, SHA1 for passwords instead of bcrypt/argon2)
- Missing encryption for sensitive data at rest or in transit
- Predictable session tokens or insufficiently random values

### A03: Injection
- **SQL Injection**: String concatenation in queries: `"SELECT * FROM users WHERE id = " + userId`
- **NoSQL Injection**: Unsanitized MongoDB queries: `{ $where: userInput }`
- **Command Injection**: `exec("ping " + hostname)` without sanitization
- **XSS**: Rendering user input without escaping in HTML/templates
- **Template Injection**: User input in template strings evaluated server-side

### A04: Insecure Design
- Missing rate limiting on authentication endpoints
- No account lockout after failed login attempts
- Missing CSRF tokens on state-changing requests
- Business logic flaws (e.g., negative quantity in shopping cart)

### A05: Security Misconfiguration
- Debug mode enabled in production
- Default credentials unchanged
- Overly permissive CORS (`Access-Control-Allow-Origin: *` with credentials)
- Verbose error messages exposing stack traces to users

### A06: Vulnerable and Outdated Components
- Known CVEs in dependencies
- Unmaintained packages with no security patches
- Outdated framework versions with known vulnerabilities

### A07: Identification and Authentication Failures
- Weak password policies
- Missing MFA on sensitive operations
- Session fixation or session ID exposure in URLs
- JWT issues: no expiration, `alg: none`, weak signing key

### A08: Software and Data Integrity Failures
- Deserialization of untrusted data (pickle, Java serialization)
- Missing integrity verification on software updates or CI/CD pipelines
- Prototype pollution in JavaScript

### A09: Security Logging and Monitoring Failures
- No logging of authentication events
- Sensitive data in logs (passwords, tokens, PII)
- Missing audit trail for admin operations

### A10: Server-Side Request Forgery (SSRF)
- Fetching user-provided URLs without validation
- Internal service access via URL manipulation

## Performance Anti-Patterns

### N+1 Query Problem
Fetching a list then querying for each item's related data individually:
```
users = db.query("SELECT * FROM users")
for user in users:
    orders = db.query(f"SELECT * FROM orders WHERE user_id = {user.id}")
```
**Fix**: Use JOINs, eager loading, or batch queries.

### Memory Leaks
- Event listeners not removed (Node.js `emitter.on()` without `off()`)
- Growing caches without eviction policies
- Closures capturing large objects unnecessarily
- Timers (`setInterval`) not cleared on cleanup

### Blocking I/O in Async Context
- Synchronous file reads in an async handler
- CPU-intensive computation on the event loop
- Missing `await` on promises (fire-and-forget without error handling)

### Inefficient Algorithms
- O(n²) loops where O(n) or O(n log n) solutions exist
- Repeated string concatenation in loops (vs. StringBuilder/join)
- Unnecessary full-array scans where a hash lookup would work

### Unnecessary Re-renders (Frontend)
- Missing `React.memo`, `useMemo`, or `useCallback` for expensive components
- Unstable references in dependency arrays
- State stored too high in the component tree

## Code Smell Catalog (Fowler)

| Smell | Description | Severity |
|-------|-------------|----------|
| **Long Method** | Function > 30 lines or > 4 levels of nesting | Medium |
| **Large Class** | Class with > 10 public methods or > 300 lines | Medium |
| **Feature Envy** | Method uses more data from another class than its own | Low |
| **Data Clump** | Same group of parameters passed to multiple functions | Low |
| **Primitive Obsession** | Using primitives instead of small domain objects | Low |
| **Divergent Change** | One class changed for multiple unrelated reasons | Medium |
| **Shotgun Surgery** | One change requires modifying many classes | High |
| **Dead Code** | Unreachable or unused code paths | Low |
| **Speculative Generality** | Unused abstractions or parameters "for the future" | Low |
| **God Object** | Single class/module that knows or does too much | High |

## Concurrency Issues

### Race Conditions
- Shared mutable state accessed from multiple goroutines/threads without synchronization
- Check-then-act patterns without atomicity (`if file.exists() then file.read()`)
- Non-atomic read-modify-write operations on shared counters

### Deadlocks
- Two locks acquired in different orders across code paths
- Lock held during I/O operations (holding DB lock while calling external API)

### Thread Safety
- Non-thread-safe data structures used in concurrent contexts (HashMap vs ConcurrentHashMap)
- Missing `volatile` / atomics for shared flags
- Shared mutable state in singleton services

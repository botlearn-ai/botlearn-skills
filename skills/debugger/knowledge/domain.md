---
domain: debugger
topic: common-bug-patterns-and-error-taxonomy
priority: high
ttl: 30d
---

# Debugging — Common Bug Patterns, Error Types & Stack Trace Anatomy

## Bug Classification Taxonomy

### 1. Logic Errors
Bugs where the code executes without crashing but produces incorrect results.

| Pattern | Description | Common Languages | Example |
|---------|-------------|-----------------|---------|
| Off-by-one | Loop boundary or index shifted by 1 | All | `for (i = 0; i <= arr.length; i++)` — reads past array end |
| Incorrect operator | Wrong comparison or arithmetic operator | All | `if (a = b)` instead of `if (a == b)` in C/JS |
| Wrong boolean logic | Inverted or miscomposed conditions | All | `if (!a && !b)` instead of `!(a && b)` (De Morgan violation) |
| Missing edge case | Fails on empty input, zero, negative, max values | All | No check for empty array before accessing `arr[0]` |
| Incorrect algorithm | Right structure, wrong logic in transformation | All | Sorting comparator returns wrong sign |
| Integer overflow | Arithmetic exceeds type range silently | C, C++, Java, Rust | `int sum = 2_000_000_000 + 2_000_000_000` wraps negative |

### 2. Null / Undefined Reference Errors
Accessing members or methods on a null/undefined/nil value.

| Language | Error Message Pattern | Common Cause |
|----------|----------------------|-------------|
| JavaScript | `TypeError: Cannot read properties of undefined (reading 'X')` | Accessing nested property on uninitialized object |
| JavaScript | `TypeError: X is not a function` | Calling undefined method, wrong import |
| Python | `AttributeError: 'NoneType' object has no attribute 'X'` | Function returns None unexpectedly |
| Java | `NullPointerException` | Uninitialized object reference, failed Optional unwrap |
| C# | `NullReferenceException` | Uninitialized reference type |
| Rust | `unwrap()` on `None` | `Option::unwrap()` called on `None` value |
| Go | `panic: runtime error: invalid memory address or nil pointer dereference` | Nil pointer method call |

### 3. Type Errors
Type mismatches at runtime or compile time.

| Language | Error Pattern | Common Cause |
|----------|--------------|-------------|
| Python | `TypeError: unsupported operand type(s)` | String + int without conversion |
| TypeScript | `Type 'X' is not assignable to type 'Y'` | Interface mismatch, missing property |
| Java | `ClassCastException` | Unsafe downcast, generic type erasure |
| Go | `cannot use X (type Y) as type Z` | Interface not satisfied |

### 4. Concurrency Bugs
Non-deterministic failures caused by parallel execution.

| Pattern | Description | Symptoms |
|---------|-------------|----------|
| Race condition | Two threads access shared state without synchronization | Intermittent wrong results, passes sometimes |
| Deadlock | Two+ threads wait for each other's locks | Application hangs permanently |
| Livelock | Threads keep retrying but never make progress | High CPU, no progress, no hang |
| Starvation | Low-priority thread never gets CPU time | Some requests never complete |
| Lost update | Concurrent writes overwrite each other | Data disappears or reverts |
| Double-checked locking | Broken singleton pattern without volatile/atomic | Partially constructed object visible |

### 5. Resource & Memory Errors

| Pattern | Language(s) | Symptoms |
|---------|------------|----------|
| Memory leak | C, C++, Java (listener leaks), JS (closures, event listeners) | Gradual memory growth, eventual OOM |
| Use-after-free | C, C++ | Crash, corrupted data, security vulnerability |
| Buffer overflow | C, C++ | Crash, security vulnerability, corrupted adjacent memory |
| File descriptor leak | All | "Too many open files" error after extended operation |
| Connection pool exhaustion | All (database/HTTP clients) | Timeouts, connection refused after sustained load |
| Stack overflow | All (deep recursion) | `Maximum call stack size exceeded` (JS), `StackOverflowError` (Java) |

### 6. Async / Promise Errors

| Pattern | Language | Error/Symptom |
|---------|---------|---------------|
| Unhandled promise rejection | JavaScript | `UnhandledPromiseRejectionWarning`, silent failure |
| Missing await | JavaScript/TypeScript | Function returns Promise object instead of resolved value |
| Callback hell / error swallowing | JavaScript | Errors caught silently in nested callbacks |
| Async deadlock | C# | `.Result` or `.Wait()` on async in sync context blocks forever |
| Event loop blocking | Node.js | Server stops responding during CPU-intensive sync operation |

### 7. Import / Module Errors

| Language | Error Pattern | Common Cause |
|----------|--------------|-------------|
| Python | `ModuleNotFoundError: No module named 'X'` | Missing package, wrong virtualenv, typo |
| JavaScript | `SyntaxError: Cannot use import statement outside a module` | CommonJS/ESM mismatch |
| JavaScript | `Module not found: Can't resolve 'X'` | Missing dependency, wrong path |
| Java | `ClassNotFoundException` | Missing JAR, wrong classpath |
| Go | `cannot find package "X"` | Missing `go get`, wrong module path |

## Stack Trace Anatomy

### General Structure
```
ExceptionType: Error message describing what went wrong
    at function_name (file_path:line:column)        ← Immediate failure point
    at caller_function (file_path:line:column)       ← Who called it
    at higher_caller (file_path:line:column)         ← Chain continues up
    ...
    at entry_point (file_path:line:column)           ← Program/request entry
```

### Reading Stack Traces — Key Principles

1. **Read top-down**: The top frame is where the error occurred; lower frames show the call chain
2. **Find YOUR code**: Skip framework/library frames; focus on frames in your source files
3. **Identify the boundary**: The transition from your code to library code often reveals the API misuse
4. **Check the error message first**: It often tells you exactly what went wrong (null value, type mismatch, missing key)
5. **Look for "Caused by"**: In Java/C#, chained exceptions reveal the original root cause at the bottom

### Language-Specific Stack Trace Formats

#### JavaScript / Node.js
```
TypeError: Cannot read properties of undefined (reading 'map')
    at UserList (/app/components/UserList.jsx:15:22)
    at renderWithHooks (/app/node_modules/react-dom/...js:16305:18)
    at mountIndeterminateComponent (/app/node_modules/react-dom/...js:20069:13)
```
- **Key**: First frame in YOUR source tree (not `node_modules`) is the likely bug location

#### Python
```
Traceback (most recent call last):
  File "/app/main.py", line 42, in process_data
    result = transform(data)
  File "/app/transform.py", line 18, in transform
    return data["key"].strip()
TypeError: 'NoneType' object has no attribute 'strip'
```
- **Key**: Python traces read **bottom-up** — the last frame + error message is the failure point

#### Java
```
java.lang.NullPointerException: Cannot invoke "String.length()" because "str" is null
    at com.app.service.Parser.parse(Parser.java:45)
    at com.app.controller.ApiController.handleRequest(ApiController.java:112)
Caused by: java.io.IOException: Connection refused
    at java.net.PlainSocketImpl.connect(PlainSocketImpl.java:162)
```
- **Key**: "Caused by" chains reveal the original root cause

#### Go
```
goroutine 1 [running]:
main.processData(0x0, 0x0)
    /app/main.go:25 +0x3a
main.main()
    /app/main.go:10 +0x25
```
- **Key**: Goroutine ID and state help diagnose concurrency issues

## Error Message Interpretation Guide

### HTTP Status Codes as Bug Signals

| Code | Meaning | Likely Bug |
|------|---------|-----------|
| 400 | Bad Request | Malformed request body, missing required field, invalid JSON |
| 401 | Unauthorized | Expired/missing auth token, wrong credentials |
| 403 | Forbidden | Insufficient permissions, CORS policy violation |
| 404 | Not Found | Wrong URL path, resource deleted, routing misconfiguration |
| 409 | Conflict | Duplicate key, optimistic locking failure, stale data |
| 422 | Unprocessable Entity | Validation failure, business rule violation |
| 429 | Too Many Requests | Rate limiting triggered, missing backoff logic |
| 500 | Internal Server Error | Unhandled exception in server code |
| 502 | Bad Gateway | Downstream service crashed or unreachable |
| 503 | Service Unavailable | Server overloaded, deployment in progress |
| 504 | Gateway Timeout | Downstream service too slow, query timeout |

### Database Error Patterns

| Error Pattern | Likely Cause |
|--------------|-------------|
| `duplicate key value violates unique constraint` | Inserting row with existing unique value |
| `deadlock detected` | Concurrent transactions locking same rows in different order |
| `relation "X" does not exist` | Missing table, wrong schema, migration not run |
| `column "X" of relation "Y" does not exist` | Schema mismatch, missing migration |
| `connection refused` / `too many connections` | DB server down or connection pool exhausted |
| `lock wait timeout exceeded` | Long-running transaction blocking others |
| `value too long for type character varying(N)` | Input exceeds column width constraint |

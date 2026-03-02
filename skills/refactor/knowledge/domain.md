---
domain: refactor
topic: refactoring-catalog-patterns-principles
priority: high
ttl: 90d
---

# Code Refactoring — Domain Knowledge

## Martin Fowler's Refactoring Catalog

### Code Smells — Detection Signatures

#### Bloaters
- **Long Method** — Method exceeds 20 lines or has more than 3 levels of nesting; contains inline comments explaining "sections" of logic
- **Large Class / God Class** — Class has more than 10 public methods, more than 20 fields, or handles 3+ distinct responsibilities
- **Primitive Obsession** — Uses primitive types (string, int, boolean) to represent domain concepts (e.g., `string email` instead of `Email` type; `int status` instead of `Status` enum)
- **Long Parameter List** — Method takes more than 3-4 parameters; parameter groups travel together across methods
- **Data Clumps** — The same group of 3+ variables appears together in multiple places (e.g., `street`, `city`, `zip` always appear as a group)

#### Object-Orientation Abusers
- **Switch Statements** — Repeated switch/if-else chains on the same type field, especially when adding a new case requires changes in multiple locations
- **Temporary Field** — Object fields that are only set and used in certain circumstances, remaining null/undefined otherwise
- **Refused Bequest** — Subclass uses only a small portion of inherited methods/properties, or overrides most of them to do nothing
- **Parallel Inheritance Hierarchies** — Every time you add a subclass to one hierarchy, you must add a corresponding subclass to another

#### Change Preventers
- **Divergent Change** — A single class is modified for multiple unrelated reasons; different groups of changes affect different methods
- **Shotgun Surgery** — A single logical change requires small modifications scattered across many classes
- **Feature Envy** — A method accesses data from another object more than from its own object; it "wants to be" in the other class

#### Dispensables
- **Duplicate Code** — Identical or near-identical code structures in 2+ locations; includes structural duplication (same logic with different variable names)
- **Dead Code** — Unreachable methods, unused variables, obsolete commented-out code, never-true conditionals
- **Lazy Class** — A class that does too little to justify its existence; has only 1-2 trivial methods
- **Speculative Generality** — Abstract classes, interfaces, or parameters that exist "just in case" but currently have only one implementation

#### Couplers
- **Inappropriate Intimacy** — Two classes access each other's private members or internal details excessively
- **Message Chains** — Long chains of method calls: `a.getB().getC().getD().doSomething()` (Law of Demeter violations)
- **Middle Man** — A class that delegates almost all its work to another class, adding no value

### Refactoring Techniques — By Smell

| Smell | Primary Refactoring | Secondary Refactoring |
|-------|--------------------|-----------------------|
| Long Method | Extract Method | Replace Temp with Query, Decompose Conditional |
| Large Class | Extract Class | Extract Subclass, Extract Interface |
| Primitive Obsession | Replace Primitive with Object | Introduce Parameter Object, Replace Type Code with Subclass |
| Long Parameter List | Introduce Parameter Object | Preserve Whole Object, Replace Parameter with Method Call |
| Data Clumps | Extract Class | Introduce Parameter Object |
| Switch Statements | Replace Conditional with Polymorphism | Replace Type Code with Strategy, Introduce Null Object |
| Duplicate Code | Extract Method | Pull Up Method, Form Template Method |
| Feature Envy | Move Method | Move Field, Extract Method + Move |
| Shotgun Surgery | Move Method + Move Field | Inline Class (consolidate) |
| Divergent Change | Extract Class | Extract Module |
| Message Chains | Hide Delegate | Extract Method, Move Method |
| Middle Man | Remove Middle Man | Inline Method, Replace Delegation with Inheritance |
| Dead Code | Remove Dead Code | — |
| Lazy Class | Inline Class | Collapse Hierarchy |
| Speculative Generality | Collapse Hierarchy | Inline Class, Remove Parameter |

## Gang of Four (GoF) Design Patterns

### Creational Patterns

#### Factory Method
- **Problem it solves**: Client code coupled to concrete class constructors; adding new types requires modifying client code
- **When to apply**: Multiple related classes with a common interface; object creation logic is complex or conditional
- **Structure**: Abstract creator declares factory method; concrete creators override it to produce specific products
- **Refactoring trigger**: `new` keyword appears in switch/if-else chains; constructor calls scattered across codebase

#### Abstract Factory
- **Problem it solves**: Families of related objects that must be created together; switching between families requires changing multiple creation points
- **When to apply**: Multiple product families (e.g., UI themes, database backends); products within a family must be compatible
- **Refactoring trigger**: Parallel switch statements creating different but related objects

#### Builder
- **Problem it solves**: Complex object construction with many optional parameters; telescoping constructor anti-pattern
- **When to apply**: Object requires 5+ configuration parameters; construction steps may vary
- **Refactoring trigger**: Constructors with 5+ parameters; multiple constructor overloads

#### Singleton
- **Problem it solves**: Exactly one instance needed globally with a single access point
- **When to apply**: Resource managers, configuration, logging (use sparingly; often an anti-pattern itself)
- **Refactoring trigger**: Global variables; static utility classes with state

### Structural Patterns

#### Adapter
- **Problem it solves**: Incompatible interfaces between existing classes; integrating third-party code with different API conventions
- **When to apply**: Wrapping legacy code; integrating external libraries; bridging interface mismatches
- **Refactoring trigger**: Wrapper functions that translate between two interface styles

#### Decorator
- **Problem it solves**: Need to add responsibilities to objects dynamically without modifying their class; combinatorial explosion of subclasses
- **When to apply**: Cross-cutting concerns (logging, caching, validation); optional behaviors that can be composed
- **Refactoring trigger**: Subclass explosion from combinations of features; repeated wrapper logic

#### Facade
- **Problem it solves**: Complex subsystem with many interdependent classes; client code needs a simplified interface
- **When to apply**: Simplifying access to a library; providing a high-level API over low-level operations
- **Refactoring trigger**: Client code repeatedly uses the same sequence of subsystem calls

#### Composite
- **Problem it solves**: Tree structures where individual objects and compositions should be treated uniformly
- **When to apply**: File systems, UI hierarchies, organizational structures, expression trees
- **Refactoring trigger**: Recursive structures with duplicated traversal logic; type-checking for leaf vs. container

### Behavioral Patterns

#### Strategy
- **Problem it solves**: Multiple algorithms for the same task; algorithm selection via switch/if-else chains
- **When to apply**: Sorting algorithms, pricing strategies, validation rules, rendering modes
- **Refactoring trigger**: Switch statements selecting behavior; conditional logic that varies by "type" or "mode"

#### Observer
- **Problem it solves**: Objects need to be notified of state changes in another object without tight coupling
- **When to apply**: Event systems, data binding, pub/sub patterns, UI updates from model changes
- **Refactoring trigger**: Explicit notification calls scattered through setter methods; polling for changes

#### Command
- **Problem it solves**: Need to parameterize, queue, log, or undo operations; decouple invoker from executor
- **When to apply**: Undo/redo systems, task queues, macro recording, transaction management
- **Refactoring trigger**: Methods that both decide what to do and do it; no support for undo

#### Template Method
- **Problem it solves**: Algorithm structure is shared but individual steps vary across subclasses
- **When to apply**: Framework hooks, processing pipelines, lifecycle methods
- **Refactoring trigger**: Duplicate code in sibling classes with small step-level variations

#### State
- **Problem it solves**: Object behavior changes based on internal state; large switch/if-else on state variable
- **When to apply**: Workflow engines, protocol handlers, UI components with multiple modes
- **Refactoring trigger**: Methods with large switch statements on a state field; state transitions scattered across methods

## SOLID Principles

### Single Responsibility Principle (SRP)
- **Definition**: A class should have only one reason to change — one responsibility, one actor it serves
- **Violation indicators**: Class name includes "And" or "Manager" or "Handler" for unrelated concerns; class changes for multiple unrelated feature requests; class has methods operating on different data domains
- **Refactoring**: Extract Class — split the class along responsibility boundaries; each resulting class serves one actor

### Open/Closed Principle (OCP)
- **Definition**: Software entities should be open for extension but closed for modification
- **Violation indicators**: Adding a new feature requires modifying existing working code; switch/if-else chains on type discriminators grow with each new variant
- **Refactoring**: Replace Conditional with Polymorphism; introduce Strategy or Template Method pattern; use dependency injection

### Liskov Substitution Principle (LSP)
- **Definition**: Subtypes must be substitutable for their base types without altering program correctness
- **Violation indicators**: Subclass overrides a method to throw "not supported" exceptions; subclass weakens preconditions or strengthens postconditions; client code checks `instanceof` before calling methods
- **Refactoring**: Extract Interface for the true shared contract; use composition over inheritance; restructure hierarchy

### Interface Segregation Principle (ISP)
- **Definition**: Clients should not be forced to depend on methods they do not use
- **Violation indicators**: Interface has 10+ methods; implementing classes leave many methods as no-ops or throw exceptions; "fat" interfaces with unrelated method groups
- **Refactoring**: Split into focused interfaces (e.g., `Readable`, `Writable` instead of `ReadWritable`); use role interfaces

### Dependency Inversion Principle (DIP)
- **Definition**: High-level modules should not depend on low-level modules; both should depend on abstractions
- **Violation indicators**: High-level business logic imports and instantiates concrete infrastructure classes (database drivers, HTTP clients); no interfaces between layers
- **Refactoring**: Extract Interface for dependencies; introduce constructor injection or service locator; use Factory for object creation

## Complexity Metrics

### Cyclomatic Complexity (McCabe)
- **Definition**: Number of linearly independent paths through a function; calculated as `E - N + 2P` (edges - nodes + 2 * connected components) in the control flow graph
- **Practical calculation**: Count 1 (base) + 1 for each `if`, `else if`, `for`, `while`, `case`, `catch`, `&&`, `||`, `?:`
- **Thresholds**: 1-10 = simple/low risk; 11-20 = moderate complexity; 21-50 = high complexity/refactor recommended; 50+ = untestable/must refactor
- **Reduction techniques**: Extract Method, Replace Conditional with Polymorphism, Decompose Conditional, Replace Nested Conditional with Guard Clauses

### Cognitive Complexity (SonarSource)
- **Definition**: Measures how difficult code is for a human to understand; penalizes nesting, breaks in linear flow, and recursion
- **Key differences from cyclomatic**: Nesting increments penalty (nested `if` costs more than sequential `if`); `else` and `switch` cases are counted; shorthand syntax is not penalized
- **Thresholds**: 0-5 = easy to understand; 6-15 = moderate; 16-25 = difficult; 25+ = very difficult/refactor required

### Coupling Metrics
- **Afferent Coupling (Ca)**: Number of external classes that depend on this class — high Ca means the class is heavily used and changes are risky
- **Efferent Coupling (Ce)**: Number of external classes this class depends on — high Ce means the class is fragile (many reasons to change)
- **Instability (I)**: `Ce / (Ca + Ce)` — ranges from 0 (maximally stable) to 1 (maximally unstable)
- **Abstractness (A)**: Ratio of abstract classes/interfaces to total classes in a package
- **Distance from Main Sequence (D)**: `|A + I - 1|` — measures balance; 0 is ideal; high values indicate the "zone of pain" (stable + concrete) or "zone of uselessness" (unstable + abstract)

### Depth of Inheritance Tree (DIT)
- **Definition**: Maximum length from a class to the root of its inheritance hierarchy
- **Thresholds**: 0-2 = good; 3-4 = acceptable; 5+ = excessive inheritance/consider composition
- **Risks of deep inheritance**: Increased fragility, difficulty understanding behavior, tight coupling to ancestor implementations

### Lines of Code (LOC) Guidelines
- **Method**: Aim for under 20 lines; extract at 30+
- **Class**: Aim for under 200 lines; extract at 400+
- **File**: Aim for under 400 lines; split at 600+
- **Note**: LOC is a coarse metric — always combine with complexity metrics for accurate assessment

<!--
SYNC IMPACT REPORT
Version Change: 2.1.0 -> 2.2.0
Rationale: Added comprehensive UI Engineering Standards for Flutter (Theming, Composition, Style Objects, Component Separation, Platform Adaptability).

Modified Principles:
- [NEW] 3.3.1 UI Engineering Standards (Theming, Composition, Styles, Logic, Platform)
- [UPDATED] 4.3 Code Review Checklist (Added UI checks)

Templates Status:
- plan-template.md: ✅ Compatible
- spec-template.md: ✅ Compatible
- tasks-template.md: ✅ Compatible

TODOs:
- None.
-->

# Project Constitution: USP Ecosystem (Monorepo)

**Version:** 2.2.0
**Effective Date:** 2025-11-27
**Scope:** Global (All Packages & Applications)

## 1. Vision & Core Philosophy

This project aims to build a reference implementation of the **User Services Platform (USP/TR-369)** ecosystem, comprising a rigorous **Device:2 Simulator (Agent)** and a cross-platform **Flutter Client (Controller)**.

### The "North Star" Principles

1.  **Architectural Purity (Clean Architecture)**
    We adhere strictly to **Clean Architecture**. The **Domain Layer** is sacred; it must remain pure Dart, devoid of framework dependencies (Flutter, UI, IO, HTTP), ensuring logic is portable, testable, and enduring. Source code dependencies must only point inwards (Outer Layers $\to$ Inner Layers).

2.  **Design by Contract (DBC)**
    Systems must be robust. We enforce **Preconditions** (input validation), **Postconditions** (output verification), and **Invariants** (state consistency). We "Fail Fast" on invalid data rather than propagating corruption.

3.  **Type Safety & Immutability**
    We leverage Dart's strong type system to prevent runtime errors. State objects must be **Immutable** (using `freezed` or `equatable` for Copy-on-Write). Null safety is non-negotiable and must be respected.

4.  **Schema-Driven Development**
    The Protocol (TR-181/TR-369) is the ultimate source of truth. We prefer generated code (Protobuf, JSON serialization) and schema parsing over hard-coded logic.

---

## 2. Global Engineering Standards

These standards apply to **all** code within the monorepo.

### 2.1 Technology Stack
*   **Language**: Dart 3.x (Latest Stable).
*   **Framework**:
    *   **Frontend**: Flutter (Latest Stable).
    *   **Backend/Core**: Pure Dart.
*   **State Management**: **Riverpod v2.x** (using `NotifierProvider` and `AsyncNotifierProvider`).
    *   *Rule*: Never use `StatefulWidget` for complex business logic state.
*   **Serialization**:
    *   **Wire Format**: Protobuf (`protobuf` package).
    *   **Config/Persistence**: JSON (`json_serializable`).
    *   **Domain Objects**: `freezed` (preferred) or `equatable`.

### 2.2 Coding Conventions
*   **Style**: Follow standard Dart Style Guide (Effective Dart).
*   **Structure**: "Layer-First" or "Feature-First" (must be consistent per module).
    *   `domain/`: Entities, Value Objects, Repository Interfaces, Failures (Pure Dart).
    *   `application/`: Use Cases, Services, State Notifiers.
    *   `infrastructure/`: Repository Implementations, DTOs, Data Sources, Platform Code.
    *   `presentation/`: Widgets, Screens, UI Controllers.
*   **Naming**:
    *   Classes/Types: `PascalCase`
    *   Variables/Functions: `camelCase`
    *   Files: `snake_case.dart`
    *   Interfaces: Abstract interfaces should be clearly distinguishable (e.g., `IUspService` or `ConnectionRepository` vs `ConnectionRepositoryImpl`).

### 2.3 Testing Strategy (The 90% Rule)
*   **Mandate**: All Core Logic (Domain & Application layers) must maintain **>90% Code Coverage**.
*   **Unit Tests**: Required for all Domain Entities, Use Cases, and State Notifiers.
*   **Mocking**: Use `mocktail` or `mockito` to isolate layers during testing.
*   **Integration**: "Verify" scripts (`bin/verify_*.dart`) are preferred for validating protocol compliance and transport layers.

### 2.4 Error Handling
*   **Infrastructure Traps, Domain Rejects**:
    *   **Infrastructure Layer**: Must catch all external exceptions (Exception, Error, PlatformException) and convert them into Domain **Failures**.
    *   **Domain Layer**: Never throws exceptions for expected errors. Return a `Failure` object (or `Either<Failure, Success>`).
    *   **Presentation Layer**: Never uses `try-catch` for business logic. It only observes state/results and renders the corresponding Failure message.

### 2.5 Documentation
*   **Public APIs are Public Contracts**:
    *   All `public` members (classes, methods, fields) in **Shared Packages** (`packages/*`) MUST have Dart Doc (`///`) comments.
    *   Comments must explain **Purpose**, **Parameters**, **Returns**, and **Throws** (if applicable, though throwing is discouraged).

---

## 3. Module-Specific Guidelines

This Monorepo contains three distinct component types, each with specific constraints.

### 3.1 Shared Kernel (`packages/usp_protocol_common`)
*   **Role**: The Communication Contract & Shared Language.
*   **The Neutrality Rule**: Code must not know if it is running on a Client or Server.
*   **The Purity Rule**: **Zero Flutter dependencies.** Zero `dart:io` or `dart:html` dependencies (unless strictly isolated).
*   **The Stateless Rule**: Pure functions and data types only. No runtime state (e.g., no Device Tree, no Session Cache).

### 3.2 Server / Simulator (`apps/usp_device2_simulator`)
*   **Role**: The USP Agent (Device:2).
*   **Constraint**: **Headless**. No UI dependencies. Must run in a standard Dart VM / Container.
*   **Focus**: Strict TR-181 Data Model compliance, recursive path resolution, and correct USP Error mapping.

### 3.3 Client / Controller (`apps/usp_flutter_client`)
*   **Role**: The USP Controller (User Interface).
*   **Constraint**: **"Dumb" UI**. The UI Layer must not contain business logic. It only observes State and dispatches Intents.
*   **Cross-Platform**: Must compile and run on **Mobile (iOS/Android)**, **Web**, and **Desktop**.
    *   *Requirement*: Use the **Stub Pattern** (conditional exports) for platform-specific transport implementations (e.g., `grpc` vs `grpc_web`, `mqtt_client`).

#### 3.3.1 UI Engineering Standards (Flutter)
These standards ensure consistency, maintainability, and testability across the UI layer.

1.  **Foundation (Theming via Extension)**:
    *   Use `ThemeExtension` for Design Tokens (colors, text styles).
    *   *Rule*: Never pass raw colors or fonts in widget constructors. UI components define "semantics", the global theme defines "style".

2.  **Structure (Composition > Inheritance)**:
    *   Prefer **Composition** (Slot Pattern, Builder Pattern) over Inheritance.
    *   *Rule*: Do not subclass Widgets (e.g., `MyRedButton` extends `MyButton`). Instead, use slots (e.g., `Widget? leading`) or Builders to invert control.

3.  **Configuration (Style Objects)**:
    *   Encapsulate complex styles (more than 3 parameters) into typed **Style Objects** (e.g., `MyButtonStyle`).
    *   *Benefit*: Allows pre-defining named styles (e.g., `MyButtonStyle.primary()`) and cleaner constructors.

4.  **Logic Separation (Dumb vs Smart)**:
    *   **Dumb Components (Presentational)**: Pure UI. No dependencies on Logic/State Management. Receives data via constructor, emits events via `VoidCallback`. Golden-test friendly.
    *   **Smart Components (Containers)**: Connect to Business Logic (BLoC/Riverpod), retrieve state, and assemble Dumb Components.

5.  **Platform Adaptability (Abstract Factory)**:
    *   Use the **Abstract Factory Pattern** to generate platform-specific widgets (e.g., `WidgetFactory.createLoader()`).
    *   *Rule*: Avoid scattered `Platform.isIOS` checks inside widgets. Inject the correct factory at startup.

---

## 4. Workflow & Governance

### 4.1 Monorepo Management
*   **Tooling**: We use **Melos** to manage the monorepo workspace.
*   **Dependency Linking**: Use `melos bootstrap` to link local packages.
*   **Scripts**: All cross-package operations (linting, testing, building) must be defined as Melos scripts (e.g., `melos run verify`).
*   **Release**: Melos is the source of truth for versioning and changelog generation.

### 4.2 Git Workflow
*   **Branching**: Feature Branch Workflow (`feat/my-feature`, `fix/bug-id`).
*   **Main Branch**: `main` must always be compile-ready and passable.
*   **Commits**: Use **Conventional Commits**.
    *   `feat`: New feature
    *   `fix`: Bug fix
    *   `docs`: Documentation only
    *   `refactor`: Code change that neither fixes a bug nor adds a feature
    *   `test`: Adding missing tests

### 4.3 Code Review Checklist
1.  **Architecture**: Does this change violate the Dependency Rule? (e.g., Domain importing Infrastructure).
2.  **Purity**: Does the Domain layer import Flutter? (It must not).
3.  **Safety**: Are inputs validated? Are nulls handled?
4.  **Tests**: Are tests included and passing?
5.  **Error Handling**: Are exceptions caught in Infrastructure? Are Failures used in Domain?
6.  **Documentation**: Do public APIs in shared packages have `///` docs?
7.  **UI Consistency**: Are Design Tokens used? Is Composition used over Inheritance?
8.  **UI Logic**: Is there a clear separation between Dumb and Smart components?

### 4.4 Amendments
This Constitution is the Supreme Law of the codebase. Amendments must be proposed via a Pull Request to this file and require approval from the Project Lead.

---
**Ratified By:** Engineering Team
**Last Amended:** 2025-11-27

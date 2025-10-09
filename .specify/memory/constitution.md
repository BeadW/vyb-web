<!--
SYNC IMPACT REPORT - Constitution v2.0.0
========================================
Version change: 1.0.0 → 2.0.0
Modified principles: 
- I. Single-File Architecture → Multi-Platform Architecture
- III. Branching History Preservation → Enhanced with UI Testing
- V. Local-First Storage → Local-First with Cloud Abstractions
Added sections: 
- UI Testing Framework requirements
- Multi-platform deployment strategy
- Modular architecture principles
Removed sections: Single-file constraints
Templates requiring updates:
  ✅ constitution.md (completed)
  ⚠ plan-template.md (needs multi-platform Constitution Check)
  ⚠ spec-template.md (needs mobile/web requirement alignment)
  ⚠ tasks-template.md (needs UI testing and platform-specific tasks)
Follow-up TODOs: None
-->

# VYB-Web Constitution

## Core Principles

### I. Multi-Platform Architecture
The application MUST support three platforms: Web (with phone UI simulation), native iOS, and native Android.
Web version simulates mobile interface to provide authentic post preview experience for users.
Shared business logic and AI integration patterns across platforms with platform-specific UI implementations.
Modular, maintainable architecture that scales with complexity rather than monolithic single-file approach.

### II. AI-First Design (NON-NEGOTIABLE)
All creative features MUST integrate AI assistance as a primary interaction method, not an add-on.
AI suggestions are generated via structured JSON schemas to ensure predictable, parseable responses.
User interactions with AI must be intuitive and gesture-based where possible (scroll, swipe).

### III. Branching History Preservation (NON-NEGOTIABLE)
All user edits and AI suggestions MUST be preserved in a Directed Acyclic Graph (DAG) structure.
No creative pathway is ever lost - users can explore multiple iterations without destroying previous work.
History state must be JSON-serializable with comprehensive UI testing due to feature complexity.
UI testing frameworks MUST validate history navigation, state transitions, and data integrity.

### IV. Interactive Canvas Experience
All visual manipulation MUST use vector-based libraries (Fabric.js) for object-level interactions.
Users must be able to move, scale, rotate, and modify individual elements in real-time.
Canvas state must be fully serializable to JSON for history tracking and AI iteration.

### V. Local-First with Cloud Abstractions
All user data MUST persist locally (localStorage for web, native storage for mobile) as primary storage.
Application must work completely offline after initial load with local AI model fallbacks.
Architecture MUST include abstractions for future cloud deployment without requiring redesign.
Data export/import capabilities required for user control and cross-platform sync preparation.

## Technology Standards

Web: HTML5, CSS3 (Tailwind), JavaScript (ES6+), React/Vue for modular components.
iOS: Swift/SwiftUI with UIKit for complex canvas interactions.
Android: Kotlin with Jetpack Compose and custom Canvas views.
Shared: JSON schema validation for AI integration across platforms.
UI Testing: Playwright (web), XCUITest (iOS), Espresso (Android) for complex feature validation.
Storage: Platform-native with cloud-ready abstractions (Core Data, Room, IndexedDB).
Performance: 60fps canvas interactions, <500ms AI response handling across all platforms.

## Development Workflow

All features start as modular prototypes with shared business logic abstractions.
UI testing frameworks MUST validate complex features (branching history, AI integration) before release.
Cross-platform development with platform-specific UI implementations of shared core logic.
Local development environment with cloud deployment abstractions for future scalability.
Comprehensive testing strategy: unit tests for logic, UI tests for interactions, integration tests for AI.
Documentation includes architecture decisions, testing strategies, and deployment considerations.

## Governance

This constitution supersedes all other development practices and technical decisions.
All feature additions must demonstrate compliance with the five core principles across all platforms.
Amendments require documentation of impact on existing implementations and cross-platform migration plan.
Architecture decisions must balance maintainability, testability, and future cloud deployment readiness.
UI testing coverage is mandatory for all complex features due to the collaborative AI nature of the application.

**Version**: 2.0.0 | **Ratified**: 2025-09-28 | **Last Amended**: 2025-09-28
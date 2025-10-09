
# Implementation Plan: Visual AI Collaboration Canvas

**Branch**: `002-visual-ai-collaboration` | **Date**: 2025-09-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/Users/brad/Code/vyb-web/specs/002-visual-ai-collaboration/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Visual AI collaboration canvas for social media posts where users create designs on device-simulated canvases and use gesture-based navigation (scrolling like social media feeds) to browse AI-generated variations. System preserves all design iterations in a branching DAG structure while supporting multi-platform deployment (web with phone simulation, iOS, Android) and offline-first operation with Gemini AI integration.

## Technical Context
**Language/Version**: TypeScript 5.x (web), Swift 5.9+ (iOS), Kotlin 1.9+ (Android)
**Primary Dependencies**: React/Vue + Tailwind (web), Fabric.js (canvas), SwiftUI + UIKit (iOS), Jetpack Compose (Android), Gemini AI API
**Storage**: IndexedDB (web), Core Data (iOS), Room (Android) - all with cloud abstraction layer
**Testing**: Playwright (web UI), Jest (web unit), XCUITest (iOS), Espresso (Android), shared contract testing
**Target Platform**: Web browsers (Chrome/Safari/Firefox), iOS 15+, Android API 24+
**Project Type**: Multi-platform (web + mobile native apps)
**Performance Goals**: 60fps canvas interactions, <500ms AI response handling, <100ms gesture response
**Constraints**: Offline-capable, device simulation accuracy, branching history preservation, gesture-only AI interaction
**Scale/Scope**: Single-user creative tool, complex canvas state management, multi-layered designs, extensive AI collaboration

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Initial Check** ✅ PASSED
- [x] **Multi-Platform Architecture**: Feature supports web (phone simulation), iOS, and Android with shared business logic
- [x] **AI-First Design**: Feature includes AI integration via structured JSON API calls across platforms
- [x] **Branching History**: Feature preserves user state in DAG structure with comprehensive UI testing
- [x] **Interactive Canvas**: Feature uses platform-appropriate canvas (Canvas API, Core Graphics, Android Canvas)
- [x] **Local-First with Cloud Abstractions**: Feature works offline with cloud-ready architecture patterns

**Post-Design Check** ✅ PASSED
- [x] **Multi-Platform Architecture**: Data model and contracts support cross-platform consistency with shared schemas
- [x] **AI-First Design**: Comprehensive AI API contracts with structured JSON, trend integration, and gesture-based interaction
- [x] **Branching History**: DAG implementation with immutable state trees, UI testing requirements clearly defined
- [x] **Interactive Canvas**: Platform-specific canvas implementations with shared Transform/Layer abstractions
- [x] **Local-First with Cloud Abstractions**: Storage abstractions ready for cloud sync, offline-first design preserved

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., web/components, ios/Views). The delivered plan must
  not include Option labels.
-->
```
# [REMOVE IF UNUSED] Option 1: Multi-platform VYB-Web (DEFAULT)
web/
├── src/
│   ├── components/
│   ├── services/
│   ├── hooks/
│   └── utils/
└── tests/
    ├── unit/
    ├── integration/
    └── e2e/ (Playwright)

ios/
├── VYB/
│   ├── Models/
│   ├── Views/
│   ├── ViewModels/
│   └── Services/
└── VYBTests/
    ├── Unit/
    └── UI/ (XCUITest)

android/
├── app/src/main/
│   ├── java/com/vyb/
│   │   ├── models/
│   │   ├── ui/
│   │   ├── viewmodels/
│   │   └── services/
└── app/src/test/ (Espresso)

shared/
├── schemas/ (JSON schemas for AI)
├── contracts/ (API contracts)
└── docs/

# [REMOVE IF UNUSED] Option 2: Web-only phase (when mobile not yet needed)
web/
├── src/
│   ├── components/
│   │   ├── phone-simulation/
│   │   ├── canvas/
│   │   └── ai-integration/
│   ├── services/
│   ├── hooks/
│   └── utils/
└── tests/
    ├── unit/
    ├── integration/
    └── e2e/ (Playwright)
```

**Structure Decision**: Multi-platform VYB-Web architecture (Option 1) selected to support the constitutional requirement for web (phone simulation), iOS, and Android platforms. Shared business logic and AI integration patterns with platform-specific UI implementations. The web/ directory contains phone simulation components, ios/ contains SwiftUI views, android/ contains Compose UI, and shared/ contains JSON schemas and contracts for cross-platform consistency.

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh copilot`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base for multi-platform structure
- Generate platform-specific tasks from contracts (AI API, Canvas API) → [P] parallel test tasks
- Generate shared entity tasks from data-model.md (DesignCanvas, Layer, DesignVariation) → [P] model tasks  
- Generate UI testing tasks from quickstart.md scenarios → platform-specific UI test tasks
- Generate AI integration tasks from Gemini API contracts → async processing implementation
- Generate gesture navigation tasks from canvas-api.yaml → platform-specific input handling

**Multi-Platform Ordering Strategy**:
- Setup phase: Web/iOS/Android project initialization [P]  
- TDD phase: UI tests (Playwright/XCUITest/Espresso) before implementation [P]
- Shared logic: Data models and AI contracts before platform-specific UI [P]
- Platform implementation: Canvas rendering per platform [P]
- Integration: Cross-platform state sync and gesture handling
- Polish: Performance optimization and cloud abstraction layer

**Platform-Specific Task Distribution**:
- **Web**: 8-10 tasks (device simulation, Fabric.js integration, React components)
- **iOS**: 8-10 tasks (SwiftUI canvas, Core Graphics, Core Data models)  
- **Android**: 8-10 tasks (Compose UI, Canvas API, Room database)
- **Shared**: 6-8 tasks (AI integration, JSON schemas, contracts testing)
- **Integration**: 4-6 tasks (cross-platform validation, performance testing)

**Constitutional Compliance Tasks**:
- UI testing framework validation for branching history complexity
- Multi-platform architecture consistency verification  
- AI-first design integration validation
- Local-first storage with cloud abstraction implementation
- Interactive canvas performance benchmarking (60fps requirement)

**Estimated Output**: 35-40 numbered, ordered tasks in tasks.md with extensive [P] parallel execution

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

No constitutional violations identified. All design decisions align with multi-platform architecture, AI-first design, branching history preservation, interactive canvas experience, and local-first with cloud abstractions principles.

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented (none required)

---
*Based on Constitution v2.0.0 - See `.specify/memory/constitution.md`*

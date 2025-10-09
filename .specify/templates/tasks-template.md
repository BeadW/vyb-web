# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Multi-platform VYB-Web**: `web/src/`, `ios/VYB/`, `android/app/src/main/java/com/vyb/`
- **Shared assets**: `shared/schemas/` for AI contracts, `shared/contracts/` for API definitions
- **Testing**: Platform-specific test directories with appropriate frameworks
- Paths shown below assume multi-platform structure per VYB-Web constitution

## Phase 3.1: Setup
- [ ] T001 Initialize project structure for web, iOS, and Android platforms
- [ ] T002 [P] Configure web development environment (React/Vue + Tailwind)
- [ ] T003 [P] Configure iOS project with SwiftUI and testing frameworks
- [ ] T004 [P] Configure Android project with Kotlin and Jetpack Compose
- [ ] T005 Set up shared schemas and contracts directory structure

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T006 [P] Web: Playwright tests for phone simulation UI in web/tests/e2e/
- [ ] T007 [P] Web: Canvas state serialization tests in web/tests/unit/
- [ ] T008 [P] iOS: XCUITest for canvas interactions in VYBTests/UI/
- [ ] T009 [P] Android: Espresso tests for canvas manipulation in app/src/test/
- [ ] T010 [P] Cross-platform: AI API integration tests with mock responses
- [ ] T011 [P] Cross-platform: History DAG structure validation tests
- [ ] T012 [P] Cross-platform: Local storage persistence tests

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T013 [P] Web: Phone simulation UI components in web/src/components/phone-simulation/
- [ ] T014 [P] Web: Canvas object manipulation with HTML5 Canvas API
- [ ] T015 [P] iOS: Canvas view with Core Graphics for object manipulation
- [ ] T016 [P] Android: Custom Canvas view with gesture handling
- [ ] T017 [P] Shared: History state management with branching logic in shared/
- [ ] T018 [P] Shared: AI API integration with JSON schema validation
- [ ] T019 [P] Platform-specific: Local storage implementation (localStorage, Core Data, Room)
- [ ] T020 User interaction handlers (touch, gestures) for each platform
- [ ] T021 Cross-platform state synchronization abstractions
- [ ] T022 Error handling and user feedback systems

## Phase 3.4: Integration
- [ ] T023 Connect AI responses to canvas state updates across platforms
- [ ] T024 Implement gesture-based history navigation for each platform
- [ ] T025 Cross-platform offline mode with local AI model fallbacks
- [ ] T026 [P] Web: Browser compatibility validation and polyfills
- [ ] T027 [P] iOS: Device compatibility and performance optimization
- [ ] T028 [P] Android: Device compatibility and performance optimization

## Phase 3.5: Polish
- [ ] T029 [P] Performance optimization for 60fps canvas across all platforms
- [ ] T030 [P] Web: Responsive design validation and phone simulation accuracy
- [ ] T031 [P] iOS: App Store guidelines compliance and accessibility
- [ ] T032 [P] Android: Play Store guidelines compliance and accessibility
- [ ] T033 [P] Cross-platform: Cloud deployment abstraction layer preparation
- [ ] T034 Comprehensive UI testing validation across platforms
- [ ] T035 Manual user testing validation on actual devices

## Dependencies
- Tests (T006-T012) before implementation (T013-T022)
- Platform setup (T001-T005) before tests
- Core implementation (T013-T019) before integration (T023-T028)
- Integration before polish (T029-T035)
- Cross-platform shared logic (T017-T018) blocks platform-specific integration

## Parallel Example
```
# Launch T006-T012 together (platform-specific tests):
Task: "Playwright tests for phone simulation UI in web/tests/e2e/"
Task: "Canvas state serialization tests in web/tests/unit/" 
Task: "XCUITest for canvas interactions in VYBTests/UI/"
Task: "Espresso tests for canvas manipulation in app/src/test/"
Task: "AI API integration tests with mock responses"
Task: "History DAG structure validation tests"
Task: "Local storage persistence tests"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task
   
2. **From Platform Requirements**:
   - Each platform → UI testing task [P]
   - Each shared component → cross-platform validation task
   
3. **From AI Integration**:
   - Each AI interaction → platform-specific implementation task [P]
   - Response handling → state update validation task per platform

4. **Ordering**:
   - Setup → Platform-specific Tests → Shared Logic → Platform UI → Integration → Polish
   - Cross-platform dependencies block platform-specific parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All platforms have corresponding UI testing frameworks configured
- [ ] All canvas interactions have platform-specific implementation tasks
- [ ] All shared business logic has cross-platform validation
- [ ] UI tests come before implementation for complex features
- [ ] Parallel tasks are truly platform-independent
- [ ] Each task specifies exact platform and file path
- [ ] Multi-platform architecture maintained throughout
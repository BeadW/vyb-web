# UI Testing Guide for VYB Visual AI Collaboration Canvas

## Overview
This guide provides instructions for running UI tests across all platforms using proper testing frameworks instead of bash scripts.

## Testing Structure

### Web Platform (Playwright)
- **Location**: `/web/tests/e2e/`
- **Framework**: Playwright with TypeScript
- **Test Files**:
  - `device-simulation.spec.ts` - Device simulation accuracy tests
  - `gesture-navigation.spec.ts` - Gesture-based AI navigation tests
  - `branching-history.spec.ts` - Design variation history tests

### iOS Platform (XCUITest)
- **Location**: `/ios/VYBUITests/` and `/ios/VYBTests/UI/`
- **Framework**: XCUITest with Swift
- **Test Files**:
  - `VYBUITests.swift` - Main UI integration tests
  - `CanvasInteractionTests.swift` - Canvas touch handling tests
  - `DeviceSimulationTests.swift` - Device simulation fidelity tests

### Android Platform (Espresso)
- **Location**: `/android/app/src/androidTest/java/com/vyb/`
- **Framework**: Espresso with Kotlin
- **Test Files**:
  - `CanvasManipulationTest.kt` - Canvas manipulation tests
  - `GestureNavigationTest.kt` - Gesture navigation tests

## Running Tests

### Web Tests
```bash
cd web
npm run test:e2e
```

### iOS Tests
```bash
cd ios
xcodebuild test -scheme VYB -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Android Tests
```bash
cd android
./gradlew connectedAndroidTest
```

## Test Scenarios
All tests follow the scenarios defined in `/specs/002-visual-ai-collaboration/quickstart.md`:

1. **Device Simulation Accuracy** - Pixel-perfect device representations
2. **Gesture-Based AI Navigation** - Social media-like scroll interactions
3. **Branching History Preservation** - DAG structure validation

## Screenshots and Artifacts
- **Organized Location**: `/test-artifacts/`
- **Automated Screenshots**: Tests capture screenshots automatically
- **Manual Scripts**: Removed - use proper testing frameworks instead

## Validation Requirements
- Web: 60fps scrolling, <16ms frame times
- iOS: Touch gesture accuracy, Core Graphics performance
- Android: Hardware acceleration, Compose integration

## Next Steps
1. Run web development server: `cd web && npm run dev`
2. Build and run iOS app: Open `ios/VYB.xcodeproj` in Xcode
3. Build and run Android app: `cd android && ./gradlew assembleDebug`
4. Execute UI tests using commands above
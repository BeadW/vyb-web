# vyb-web Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-09-28

## Active Technologies
- TypeScript 5.x (web), Swift 5.9+ (iOS), Kotlin 1.9+ (Android) + React/Vue + Tailwind (web), Fabric.js (canvas), SwiftUI + UIKit (iOS), Jetpack Compose (Android), Gemini AI API (002-visual-ai-collaboration)

## Project Structure
```
backend/
frontend/
tests/
```

## Commands
npm test [ONLY COMMANDS FOR ACTIVE TECHNOLOGIES][ONLY COMMANDS FOR ACTIVE TECHNOLOGIES] npm run lint

## Code Style
TypeScript 5.x (web), Swift 5.9+ (iOS), Kotlin 1.9+ (Android): Follow standard conventions

## Recent Changes
- 002-visual-ai-collaboration: Added TypeScript 5.x (web), Swift 5.9+ (iOS), Kotlin 1.9+ (Android) + React/Vue + Tailwind (web), Fabric.js (canvas), SwiftUI + UIKit (iOS), Jetpack Compose (Android), Gemini AI API

<!-- MANUAL ADDITIONS START -->

You must NEVER ask the user to create, open, or manage Xcode workspaces or project files. You must always use the correct project file automatically (prefer .xcworkspace if present, otherwise .xcodeproj). If a workspace is missing, you must create it yourself. All build, install, and launch operations must be performed by you, not the user.

When validating web changes you must use Playwright and take screen shots of the outcomes. YOU MUST BE HONEST IN YOUR EVALUATION OF THE RESULTS.

when validating iOS changes you must use XCUITest and take screen shots of the outcomes. YOU MUST BE HONEST IN YOUR EVALUATION OF THE RESULTS.

when validating Android changes you must use Espresso and take screen shots of the outcomes. YOU MUST BE HONEST IN YOUR EVALUATION OF THE RESULTS.

<!-- MANUAL ADDITIONS END -->
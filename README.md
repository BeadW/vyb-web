# VYB - Visual Design Platform

A cross-platform visual design tool with TikTok-style navigation and AI-powered design variations.

## 🎯 Overview

VYB is a revolutionary visual design platform that combines intuitive TikTok-style navigation with powerful AI-assisted design generation. Create, iterate, and explore design variations with seamless cross-platform compatibility.

## ✨ Features

- **🎬 TikTok-Style Navigation**: Smooth vertical scrolling through design history and variations
- **🤖 AI-Powered Design Generation**: Create design alternatives using Gemini AI integration
- **🌐 Cross-Platform**: Native apps for Web (React/TypeScript), iOS (Swift), and Android (Kotlin)
- **⚡ Real-time Design Editing**: Live layer manipulation with instant feedback
- **📱 Responsive Design**: Optimized for mobile-first design workflows
- **🎨 Advanced Layer System**: Professional-grade layer management and manipulation

## � Project Structure

```
vyb-web/
├── 📱 ios/                   # Swift iOS application
│   ├── VYB/                  # Main iOS source code
│   ├── VYBTests/            # Unit tests  
│   └── VYBUITests/          # UI automation tests
├── 🌐 web/                   # React/TypeScript web app
├── 🤖 android/               # Kotlin Android application  
├── 🤝 shared/                # Cross-platform shared code
├── 📚 docs/                  # Project documentation
│   ├── assets/              # Screenshots and images
│   ├── AI_INTEGRATION_SUCCESS.md
│   ├── PROJECT_SUMMARY.md
│   └── UI_TESTING_GUIDE.md
├── 🔧 scripts/               # Build and automation scripts
│   └── ios/                 # iOS-specific scripts
├── 🧪 test-artifacts/        # Test outputs and reports
└── 📋 specs/                 # Technical specifications
```

## 🚀 Quick Start

### Prerequisites
- **iOS**: Xcode 15+, iOS 17+ deployment target
- **Web**: Node.js 18+, npm/yarn
- **Android**: Android Studio, Kotlin 1.9+

### iOS Development
```bash
cd ios
# Open VYB.xcodeproj in Xcode
# Select iOS Simulator (iPhone 15 Pro recommended)
# Build and run (⌘+R)
```

### Web Development  
```bash
cd web
npm install
npm run dev
```

### Android Development
```bash
cd android
./gradlew build
./gradlew installDebug
```

## 🎨 Current Features

### TikTok-Style Navigation System
- **Smooth Scrolling**: Natural vertical navigation through design history
- **Automatic AI Generation**: Scroll triggers create new design variations
- **History Management**: Complete timeline of design iterations
- **No Read-Only Restrictions**: Edit any layer in any history state

### AI Integration (Gemini API)
- **Maximum Token Limits**: 8192 tokens for complete response generation
- **Structured JSON Schema**: Consistent variation format with metadata
- **Error Handling**: Robust parsing with fallback mechanisms
- **Real-time Generation**: Instant design alternatives based on current state

## 🛠️ Development

### Key Technologies
- **iOS**: SwiftUI, Combine, structured concurrency
- **Web**: React 18, TypeScript 5, Tailwind CSS
- **Android**: Jetpack Compose, Kotlin coroutines
- **AI**: Google Gemini API, structured JSON responses

### Testing Strategy
- **iOS**: XCTest unit tests, XCUITest automation
- **Web**: Jest, React Testing Library, Playwright
- **Android**: JUnit, Espresso UI testing

## � Documentation

- **[AI Integration Guide](docs/AI_INTEGRATION_SUCCESS.md)** - Complete AI setup and usage
- **[UI Testing Guide](docs/UI_TESTING_GUIDE.md)** - Automated testing strategies  
- **[Project Summary](docs/PROJECT_SUMMARY.md)** - Technical architecture overview
- **[iOS Testing Report](docs/iOS_UI_TESTING_SUMMARY.md)** - Platform-specific test results

## 🧹 Repository Standards

This repository follows strict organization standards:
- **No scattered screenshots** - All images in `docs/assets/`
- **No build artifacts** - Comprehensive `.gitignore` rules
- **Organized scripts** - All automation in `scripts/` directory
- **Centralized docs** - All documentation in `docs/` directory
- **Clean git history** - Meaningful commits with proper organization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Follow the established project structure
4. Test thoroughly on your target platform
5. Submit a pull request with clear description

## � License

[License information to be added]

---

**Last Updated**: October 2025 | **Status**: Active Development
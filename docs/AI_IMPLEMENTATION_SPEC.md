# iOS AI Implementation Specification

**Branch**: `ios-ai-suggestions`  
**Based on**: Web implementation in `002-visual-ai-collaboration`  
**Date**: October 6, 2025  
**Status**: Implementation Ready

## Overview

This specification defines the iOS implementation of AI-powered visual collaboration features, mirroring the web implementation while leveraging iOS-native technologies. The feature enables TikTok-style gesture navigation through AI-generated design variations without traditional chat interfaces.

## Architecture Overview

### Core Components
1. **AIService.swift** - Gemini API integration
2. **SimpleLayer + Codable** - JSON serialization for API
3. **ContentView + Gestures** - Swipe-down trigger for AI
4. **AIVariationsView** - SwiftUI scrollable suggestions feed
5. **DesignVariation** - Variation history management
6. **DeviceSimulation** - Accurate device constraints

### Data Flow
```
User Canvas → JSON Serialization → Gemini API → AI Suggestions → SwiftUI Feed → User Selection → Canvas Update
```

## 1. AIService Implementation

### File: `ios/VYB/Services/AIService.swift`

**Status**: Partially implemented, needs completion

#### API Configuration
- **Base URL**: `https://ai.gemini.googleapis.com/v1`
- **API Key**: `AIzaSyABpqGNJGVbTVVp1p2ZdrgBSaMCovakEog`
- **HTTP Client**: URLSession with JSON encoding/decoding

#### Endpoints to Implement
```swift
// 1. Canvas Analysis
POST /canvas/analyze
Request: CanvasAnalysisRequest
Response: CanvasAnalysisResponse

// 2. Generate Variations  
POST /variations/generate
Request: VariationRequest
Response: VariationResponse

// 3. Current Trends
GET /trends/current
Response: CurrentTrendsResponse
```

#### Request/Response Models
```swift
struct CanvasAnalysisRequest: Codable {
    let canvas: DesignCanvasData
    let deviceType: String
    let analysisType: [AnalysisType]
    let userPreferences: UserPreferences?
}

struct CanvasAnalysisResponse: Codable {
    let analysisId: String
    let suggestions: [AISuggestion]
    let confidence: Double
    let trends: TrendData?
    let processingTime: Double
}

enum AnalysisType: String, Codable, CaseIterable {
    case trends = "trends"
    case creative = "creative" 
    case accessibility = "accessibility"
    case performance = "performance"
}
```

#### Error Handling
```swift
enum AIServiceError: LocalizedError, Equatable {
    case authError(String)
    case validationError(String)
    case networkError(String)
    case apiError(String)
    case parseError(String)
}
```

## 2. SimpleLayer JSON Serialization

### File: `ios/VYB/Models/SimpleLayer.swift`

**Current State**: Basic struct exists in ContentView.swift
**Required Changes**: Extract to separate file + Codable conformance

#### JSON Structure (Web Compatibility)
```swift
struct SimpleLayer: Codable, Identifiable {
    let id: String
    let type: LayerType
    let content: LayerContent
    let transform: Transform
    let style: LayerStyle
    let constraints: LayerConstraints
    let metadata: LayerMetadata
}

enum LayerType: String, Codable {
    case text = "text"
    case image = "image"
    case background = "background"
    case shape = "shape"
    case group = "group"
}

struct Transform: Codable {
    let x: Double
    let y: Double
    let scaleX: Double
    let scaleY: Double
    let rotation: Double
    let opacity: Double
}
```

#### Canvas Serialization
```swift
struct DesignCanvasData: Codable {
    let id: String
    let deviceType: String
    let dimensions: CanvasDimensions
    let layers: [SimpleLayer]
    let metadata: CanvasMetadata
    let state: String
}
```

## 3. Gesture Navigation

### File: `ios/VYB/ContentView.swift`

**Integration Point**: Add to existing ContentView without breaking current functionality

#### Gesture Implementation
```swift
// Add to ContentView state
@State private var isAIMode = false
@State private var currentVariationIndex = 0
@State private var aiVariations: [DesignVariation] = []
@GestureState private var dragAmount = CGSize.zero

// Swipe-down gesture trigger
.gesture(
    DragGesture()
        .updating($dragAmount) { value, state, _ in
            state = value.translation
        }
        .onEnded { value in
            if value.translation.y > 100 && value.velocity.y > 500 {
                // Trigger AI suggestions
                triggerAISuggestions()
            }
        }
)
```

#### AI Trigger Function
```swift
private func triggerAISuggestions() {
    Task {
        do {
            let canvasData = serializeCurrentCanvas()
            let suggestions = try await aiService.generateVariations(canvasData)
            await MainActor.run {
                self.aiVariations = suggestions
                self.isAIMode = true
            }
        } catch {
            // Handle error gracefully
            print("AI suggestions failed: \(error)")
        }
    }
}
```

## 4. AI Variations UI

### File: `ios/VYB/Views/AIVariationsView.swift`

**New Component**: SwiftUI scrollable feed for AI suggestions

#### UI Structure
```swift
struct AIVariationsView: View {
    @Binding var variations: [DesignVariation]
    @Binding var selectedIndex: Int
    let onVariationSelected: (DesignVariation) -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                ForEach(variations.indices, id: \.self) { index in
                    VariationCard(
                        variation: variations[index],
                        isSelected: index == selectedIndex,
                        onTap: { onVariationSelected(variations[index]) }
                    )
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.05))
    }
}
```

#### Variation Card Component
```swift
struct VariationCard: View {
    let variation: DesignVariation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Canvas preview
            CanvasPreview(layers: variation.canvas.layers)
                .aspectRatio(393/852, contentMode: .fit) // iPhone 15 Pro ratio
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // AI suggestion info
            HStack {
                VStack(alignment: .leading) {
                    Text(variation.source.displayName)
                        .font(.headline)
                    Text("Confidence: \(Int(variation.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Apply") {
                    onTap()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: isSelected ? 8 : 2)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
```

## 5. Design Variation Management

### File: `ios/VYB/Models/DesignVariation.swift`

**New Model**: DAG structure for variation history

```swift
struct DesignVariation: Identifiable, Codable {
    let id: String
    let parentId: String?
    let canvas: DesignCanvasData
    let source: VariationSource
    let prompt: String?
    let confidence: Double
    let timestamp: Date
    let metadata: VariationMetadata?
}

enum VariationSource: String, Codable {
    case userEdit = "user_edit"
    case aiSuggestion = "ai_suggestion"
    case aiTrend = "ai_trend"
    case aiCreative = "ai_creative"
    
    var displayName: String {
        switch self {
        case .userEdit: return "User Edit"
        case .aiSuggestion: return "AI Suggestion"
        case .aiTrend: return "Trending Style"
        case .aiCreative: return "Creative Twist"
        }
    }
}
```

## 6. Device Simulation

### Integration: Extend existing ContentView canvas constraints

#### Device Specifications
```swift
enum DeviceType: String, CaseIterable {
    case iPhone15Pro = "iphone-15-pro"
    case iPhone15Plus = "iphone-15-plus"
    case iPadPro11 = "ipad-pro-11"
    
    var dimensions: CGSize {
        switch self {
        case .iPhone15Pro: return CGSize(width: 393, height: 852)
        case .iPhone15Plus: return CGSize(width: 428, height: 926)
        case .iPadPro11: return CGSize(width: 834, height: 1194)
        }
    }
    
    var aspectRatio: Double {
        dimensions.width / dimensions.height
    }
}
```

## 7. Error Handling & Offline State

### Graceful Degradation Strategy

#### Network Connectivity
```swift
@Published var isOnline = true
@Published var aiServiceAvailable = true

private func handleAIError(_ error: AIServiceError) {
    switch error {
    case .networkError(_):
        isOnline = false
        showOfflineMessage()
    case .apiError(_):
        aiServiceAvailable = false
        showServiceUnavailableMessage()
    default:
        showGenericErrorMessage()
    }
}
```

#### Offline UI State
```swift
// Show when AI service unavailable
struct OfflineNotice: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("AI suggestions unavailable offline")
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.2))
        .clipShape(Capsule())
    }
}
```

## 8. Integration Points

### ContentView.swift Modifications
1. **Add AI state variables**
2. **Integrate swipe gesture recognition**
3. **Add AI variations overlay**
4. **Preserve existing layer management**
5. **Maintain Facebook post UI design**

### File Structure
```
ios/VYB/
├── Services/
│   └── AIService.swift (complete implementation)
├── Models/
│   ├── SimpleLayer.swift (extracted from ContentView)
│   ├── DesignVariation.swift (new)
│   └── DeviceType.swift (new)
├── Views/
│   ├── AIVariationsView.swift (new)
│   ├── VariationCard.swift (new)
│   └── CanvasPreview.swift (new)
└── ContentView.swift (enhanced with AI features)
```

## 9. Testing Strategy

### Unit Tests
- AIService API integration
- JSON serialization/deserialization
- Variation DAG structure
- Error handling scenarios

### UI Tests
- Swipe gesture recognition
- AI variations scrolling
- Variation selection
- Offline state handling

### Integration Tests
- End-to-end AI workflow
- Canvas state preservation
- Device simulation accuracy

## 10. Performance Considerations

### Memory Management
- Lazy loading of variation previews
- Canvas snapshot optimization
- Proper cleanup of AI requests

### Network Efficiency
- Request debouncing for gestures
- Caching of AI responses
- Background processing for non-blocking UI

## Implementation Priority

1. ✅ **Research Complete** - Web implementation analysis
2. 🚧 **AIService.swift** - Complete Gemini integration
3. 🚧 **SimpleLayer + Codable** - JSON serialization
4. 🚧 **Gesture Detection** - Swipe-down trigger
5. 🚧 **AI Variations UI** - SwiftUI feed
6. 🚧 **Canvas Integration** - Connect AI to layer system
7. 🚧 **Error Handling** - Offline state management

## Success Criteria

- [ ] User can swipe down to trigger AI suggestions
- [ ] AI generates variations based on current canvas
- [ ] Smooth scrolling between AI suggestions
- [ ] Canvas updates when variation selected
- [ ] Graceful offline behavior
- [ ] No regression in existing functionality
- [ ] Performance matches web implementation

---

**Note**: This specification serves as the single source of truth for iOS AI implementation. All development should reference this document to ensure consistency with the web implementation and project requirements.
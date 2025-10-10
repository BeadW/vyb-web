# Apple Intelligence Implementation Guide

## Overview
This document outlines the proper implementation pattern for Apple Intelligence (Apple's on-device AI) for generating structured design variations in the VYB app.

## Research Findings

### Foundation Models Framework
- Apple introduced the Foundation Models framework in iOS 18.0+
- Provides access to Apple's on-device language models
- Supports structured generation through "generables" (structured output formats)
- Optimized for privacy and performance with on-device processing

### Key Implementation Components

#### 1. Framework Import
```swift
#if canImport(FoundationModels)
import FoundationModels
#endif
```

#### 2. Model Availability Check
```swift
@available(iOS 18.0, *)
func isFoundationModelsAvailable() -> Bool {
    // Check if Foundation Models is available on the current device
    // This requires iPhone 15 Pro or later, iPad with M1 or later
    return true // Placeholder - actual implementation would check device capabilities
}
```

#### 3. Structured Generation Pattern
```swift
@available(iOS 18.0, *)
struct DesignVariationsRequest: Codable {
    let prompt: String
    let canvasBounds: CanvasBounds
    let currentLayers: [SimpleLayerData]
    let outputFormat: String = "json"
}

@available(iOS 18.0, *)
struct DesignVariationsResponse: Codable {
    let variations: [DesignVariation]
}
```

#### 4. Generation Implementation
```swift
@available(iOS 18.0, *)
private func generateWithFoundationModels(request: DesignVariationsRequest) async throws -> DesignVariationsResponse {
    // This would use the actual Foundation Models API
    // Pattern: Model -> Prompt -> Structured Output -> Parse to DesignVariation
    
    // 1. Create model instance
    // let model = try await FoundationModel.textGeneration()
    
    // 2. Configure structured output schema
    // let schema = DesignVariationsSchema()
    
    // 3. Generate with structured constraints
    // let response = try await model.generate(
    //     prompt: request.prompt,
    //     outputSchema: schema,
    //     maxTokens: 4096
    // )
    
    // 4. Parse structured response
    // return try JSONDecoder().decode(DesignVariationsResponse.self, from: response.data)
    
    // Placeholder implementation
    throw AIServiceError.notConfigured
}
```

## Current Status

### What We Know
- Apple Intelligence exists and supports structured generation
- Foundation Models framework is the likely API entry point
- Available on iPhone 15 Pro+, iPad M1+, and newer devices
- Designed for on-device, privacy-focused AI processing

### What We Need
- Detailed API documentation for Foundation Models framework
- Proper model initialization and configuration
- Schema definition for structured JSON output
- Error handling for model availability and generation failures

## Implementation Strategy

### Phase 1: Basic Integration
1. Add proper Foundation Models import and availability checks
2. Create placeholder implementation that falls back to Gemini
3. Implement device capability detection

### Phase 2: Model Integration
1. Research actual Foundation Models API through Xcode autocomplete
2. Implement proper model initialization
3. Configure structured output schema for design variations

### Phase 3: Schema Definition
1. Define JSON schema for design variations output
2. Implement response parsing and validation
3. Add error handling for malformed responses

### Phase 4: Optimization
1. Fine-tune prompts for Apple's models
2. Optimize for performance and battery usage
3. Add proper fallback mechanisms

## Expected API Pattern (Based on Apple's Conventions)

```swift
@available(iOS 18.0, *)
import FoundationModels

class AppleIntelligenceService {
    private var model: FoundationModel?
    
    func initialize() async throws {
        guard FoundationModel.isAvailable else {
            throw AIServiceError.notConfigured
        }
        
        self.model = try await FoundationModel.textGeneration(
            configuration: .init(
                maxTokens: 4096,
                temperature: 0.7,
                structuredOutput: true
            )
        )
    }
    
    func generateDesignVariations(
        prompt: String,
        schema: JSONSchema
    ) async throws -> StructuredResponse {
        guard let model = model else {
            throw AIServiceError.notConfigured
        }
        
        let request = GenerationRequest(
            prompt: prompt,
            outputSchema: schema,
            options: .init(
                enableJSONMode: true,
                maxRetries: 3
            )
        )
        
        return try await model.generate(request)
    }
}
```

## Next Steps

1. **Research Phase**: Use Xcode's autocomplete and documentation viewer to discover the actual Foundation Models API
2. **Prototype Phase**: Create minimal working implementation
3. **Integration Phase**: Replace hardcoded variations with actual AI generation
4. **Testing Phase**: Validate on real devices with Apple Intelligence support

## Fallback Strategy

- Continue using Gemini API as primary until Foundation Models is fully implemented
- Detect device capabilities and route accordingly
- Provide user feedback about AI provider being used

## Notes

- Apple Intelligence requires specific hardware (A17 Pro chip or later)
- On-device processing means no network dependency but hardware requirements
- Structured output should be more reliable than parsing free-form text
- Privacy-focused approach aligns with Apple's values
// MARK: - Provider Configuration

public struct AIProviderConfiguration {
    public let apiKey: String?
    public let modelSettings: [String: Any]?
    public init(apiKey: String? = nil, modelSettings: [String: Any]? = nil) {
        self.apiKey = apiKey
        self.modelSettings = modelSettings
    }
}
// MARK: - Request/Response Models

/// Request structure for design variation generation
public struct DesignVariationRequest: Codable {
    public let layers: [SimpleLayerData]
    public let canvasBounds: CanvasBounds
    public let constraints: GenerationConstraints?
    public init(
        layers: [SimpleLayerData],
        canvasBounds: CanvasBounds,
        constraints: GenerationConstraints? = nil
    ) {
        self.layers = layers
        self.canvasBounds = canvasBounds
        self.constraints = constraints
    }
}

/// Response structure from AI providers
public struct DesignVariationResponse: Codable {
    public let variations: [DesignVariation]
    public let metadata: GenerationMetadata?
    public init(variations: [DesignVariation], metadata: GenerationMetadata? = nil) {
        self.variations = variations
        self.metadata = metadata
    }
}

/// Generation constraints and preferences
public struct GenerationConstraints: Codable {
    public let maxVariations: Int
    public let stylePreferences: [String]?
    public let preserveElements: [String]?
    public init(
        maxVariations: Int = 3,
        stylePreferences: [String]? = nil,
        preserveElements: [String]? = nil
    ) {
        self.maxVariations = maxVariations
        self.stylePreferences = stylePreferences
        self.preserveElements = preserveElements
    }
}

/// Metadata about the generation process
public struct GenerationMetadata: Codable {
    public let provider: String
    public let modelVersion: String?
    public let processingTime: TimeInterval?
    public let confidence: Double?
    public init(
        provider: String,
        modelVersion: String? = nil,
        processingTime: TimeInterval? = nil,
        confidence: Double? = nil
    ) {
        self.provider = provider
        self.modelVersion = modelVersion
        self.processingTime = processingTime
        self.confidence = confidence
    }
}
import Foundation
import CoreGraphics
// ...existing code...

// MARK: - Canvas Models

/// Canvas bounds information for AI analysis
public struct CanvasBounds: Codable {
    public let width: Double
    public let height: Double
    
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    
    public init(from size: CGSize) {
        self.width = Double(size.width)
        self.height = Double(size.height)
    }
    
    /// Check if a point is within canvas bounds
    public func contains(x: Double, y: Double) -> Bool {
        return x >= 0 && x <= width && y >= 0 && y <= height
    }
    
    /// Get center point of canvas
    public var center: (x: Double, y: Double) {
        return (x: width / 2.0, y: height / 2.0)
    }
}

// MARK: - Layer Models

/// Simple layer data structure for AI processing
public struct SimpleLayerData: Identifiable, Codable {
    public let id: String
    public let type: String
    public let content: String
    public let x: Double
    public let y: Double
    
    public init(id: String, type: String, content: String, x: Double, y: Double) {
        self.id = id
        self.type = type
        self.content = content
        self.x = x
        self.y = y
    }
    
    /// Check if layer is visible within given canvas bounds
    public func isVisible(within bounds: CanvasBounds) -> Bool {
        return bounds.contains(x: x, y: y)
    }
    
    /// Get visibility status description for AI
    public func visibilityDescription(within bounds: CanvasBounds) -> String {
        if isVisible(within: bounds) {
            return "visible on canvas"
        } else {
            let direction: String
            
            if x < 0 && y < 0 {
                direction = "off-canvas (top-left)"
            } else if x > bounds.width && y < 0 {
                direction = "off-canvas (top-right)"
            } else if x < 0 && y > bounds.height {
                direction = "off-canvas (bottom-left)"
            } else if x > bounds.width && y > bounds.height {
                direction = "off-canvas (bottom-right)"
            } else if x < 0 {
                direction = "off-canvas (left)"
            } else if x > bounds.width {
                direction = "off-canvas (right)"
            } else if y < 0 {
                direction = "off-canvas (top)"
            } else if y > bounds.height {
                direction = "off-canvas (bottom)"
            } else {
                direction = "partially off-canvas"
            }
            
            return direction
        }
    }
}

// MARK: - Design Variation Models

/// Represents a complete design variation with all layer modifications
public struct DesignVariation: Identifiable, Codable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let layers: [SimpleLayerData]
    
    public init(title: String, description: String, layers: [SimpleLayerData]) {
        self.title = title
        self.description = description
        self.layers = layers
    }
    
    /// Custom coding keys to handle UUID serialization
    private enum CodingKeys: String, CodingKey {
        case title, description, layers
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(layers, forKey: .layers)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        layers = try container.decode([SimpleLayerData].self, forKey: .layers)
    }
}

// MARK: - Canvas Analysis Models

/// Canvas data structure for analysis
public struct DesignCanvasData {
    public let layers: [Any]
    public let canvasSize: CGSize
    public let canvasBounds: CanvasBounds
    
    public init(layers: [Any], canvasSize: CGSize = CGSize(width: 400, height: 500)) {
        self.layers = layers
        self.canvasSize = canvasSize
        self.canvasBounds = CanvasBounds(from: canvasSize)
    }
}

/// Response structure for canvas analysis
public struct CanvasAnalysisResponse: Codable {
    public let suggestions: [AISuggestion]
    
    public init(suggestions: [AISuggestion]) {
        self.suggestions = suggestions
    }
}

/// AI suggestion structure
public struct AISuggestion: Codable, Identifiable {
    public let id: String
    public let type: String
    public let description: String
    public let confidence: Double
    
    public init(id: String, type: String, description: String, confidence: Double) {
        self.id = id
        self.type = type
        self.description = description
        self.confidence = confidence
    }
}

// MARK: - Error Handling

/// Error types for AI service operations
public enum AIServiceError: Error {
    case notConfigured
    case validationError(String)
    case networkError(String)
    case apiError(String)
    case parseError(String)
    case invalidResponse
    case providerUnavailable(String)
}
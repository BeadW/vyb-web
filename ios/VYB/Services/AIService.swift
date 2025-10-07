import Foundation
import SwiftUI

// MARK: - Error Types

public enum AIServiceError: LocalizedError, Equatable {
    case notConfigured
    case authError(String)
    case validationError(String)
    case networkError(String)
    case apiError(String)
    case parseError(String)
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI Service not configured"
        case .authError(let message):
            return "Authentication Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .apiError(let message):
            return "API Error: \(message)"
        case .parseError(let message):
            return "Parse Error: \(message)"
        case .invalidResponse:
            return "Invalid response from AI service"
        }
    }
}

// MARK: - Data Models

public struct CanvasDimensions: Codable {
    public let width: Double
    public let height: Double
    public let pixelDensity: Double
    
    public init(width: Double, height: Double, pixelDensity: Double) {
        self.width = width
        self.height = height
        self.pixelDensity = pixelDensity
    }
}

public struct CanvasMetadata: Codable {
    public let createdAt: Date
    public let modifiedAt: Date
    
    public init(createdAt: Date, modifiedAt: Date) {
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// Minimal SimpleLayer for AI service - will be extended later
public struct SimpleLayerData: Codable {
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
}

public struct DesignCanvasData: Codable {
    public let id: String
    public let deviceType: String
    public let dimensions: CanvasDimensions
    public let layers: [SimpleLayerData]
    public let metadata: CanvasMetadata
    public let state: String
    
    public init(id: String, deviceType: String, dimensions: CanvasDimensions, layers: [SimpleLayerData], metadata: CanvasMetadata, state: String) {
        self.id = id
        self.deviceType = deviceType
        self.dimensions = dimensions
        self.layers = layers
        self.metadata = metadata
        self.state = state
    }
}

public struct CanvasAnalysisResponse: Codable {
    public let suggestions: [AISuggestion]
    
    public init(suggestions: [AISuggestion]) {
        self.suggestions = suggestions
    }
}

public struct AISuggestion: Codable {
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

// MARK: - Design Variation Models

/// Represents a complete design variation with all layer modifications
/// Used for TikTok-style AI variation browsing experience
struct DesignVariation: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let layers: [Any] // In production, this should be properly typed layers
    public let type: VariationType
    
    public init(title: String, description: String, layers: [Any], type: VariationType) {
        self.title = title
        self.description = description
        self.layers = layers
        self.type = type
    }
}

/// Types of design variations that can be generated
public enum VariationType {
    case original
    case colorScheme
    case layout
    case typography
    case composition
    case mixed
}

// MARK: - AIService Class

import Foundation

/// AI Service for generating design variations using the Gemini AI API
/// Currently contains demo implementations that should be replaced with real API calls
class AIService {
    private var apiKey: String?
    
    public var isConfigured: Bool {
        return apiKey != nil
    }
    
    public init() {
        // Minimal initialization
    }
    
    public func configure(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func analyzeCanvas(_ canvasData: DesignCanvasData) async throws -> CanvasAnalysisResponse {
        guard isConfigured else {
            throw AIServiceError.notConfigured
        }
        
        // Minimal implementation to make tests pass
        return CanvasAnalysisResponse(suggestions: [
            AISuggestion(id: "test-suggestion", type: "creative", description: "Test suggestion", confidence: 0.8)
        ])
    }
    
    /// Generate design variations using Gemini AI API
    /// - Parameter layers: The current canvas layers to analyze and improve  
    /// - Returns: Array of design variations with different styling approaches
    /// - Note: Currently returns empty array; real implementation should call Gemini AI API
    /// - Note: In production, replace with actual Gemini AI API integration
    func generateDesignVariations(for layers: [Any]) async throws -> [DesignVariation] {
        // TODO: Implement actual Gemini AI API call
        // 1. Convert layers to visual description
        // 2. Send to Gemini AI with design improvement prompts  
        // 3. Parse AI response into DesignVariation objects
        // 4. Return variations for TikTok-style browsing
        return []
    }
}
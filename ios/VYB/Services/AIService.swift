/*
 * AIService - Gemini AI API integration for iOS
 * Implements T048: iOS AI Service Integration
 * Swift/SwiftUI counterpart to web AIService with API compatibility
 */

import Foundation
import Combine
import SwiftUI
import CoreData

// MARK: - Error Types

enum AIServiceError: LocalizedError, Equatable {
    case authError(String)
    case validationError(String)
    case networkError(String)
    case apiError(String)
    case parseError(String)
    
    var errorDescription: String? {
        switch self {
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
        }
    }
}

// MARK: - Request/Response Models

struct CanvasAnalysisRequest: Codable {
    let canvas: DesignCanvasData
    let deviceType: String
    let analysisType: [AnalysisType]
    let userPreferences: UserPreferences?
}

enum AnalysisType: String, Codable, CaseIterable {
    case trends = "trends"
    case creative = "creative"
    case accessibility = "accessibility"
    case performance = "performance"
}

struct AISuggestion: Codable, Identifiable {
    let id: String
    let type: SuggestionType
    let description: String
    let confidence: Double
    let preview: String?
}

enum SuggestionType: String, Codable, CaseIterable {
    case layout = "layout"
    case color = "color"
    case typography = "typography"
    case composition = "composition"
}

struct TrendItem: Codable {
    let name: String
    let popularity: Double
    let description: String
}

struct TrendData: Codable {
    let category: String
    let trends: [TrendItem]
}

struct CanvasAnalysisResponse: Codable {
    let analysisId: String
    let suggestions: [AISuggestion]
    let confidence: Double
    let trends: TrendData?
    let processingTime: Int
}

struct VariationRequest: Codable {
    let baseCanvas: DesignCanvasData
    let variationType: VariationType
    let count: Int
    let preferences: UserPreferences?
}

enum VariationType: String, Codable, CaseIterable {
    case creative = "creative"
    case trendBased = "trend-based"
    case accessibility = "accessibility"
    case brandAligned = "brand-aligned"
}

struct VariationResponse: Codable {
    let requestId: String
    let variations: [DesignCanvasData]
    let confidence: Double
    let processingTime: Int
}

struct UserPreferences: Codable {
    let style: String?
    let industry: String?
    let targetAudience: String?
    let brandColors: [String]?
}

struct CurrentTrendsResponse: Codable {
    let trendsId: String
    let categories: [TrendData]
    let lastUpdated: String
    let confidence: Double
}

// MARK: - Simple Data Transfer Objects

struct SimpleCanvasDimensions: Codable {
    let width: Double
    let height: Double
    let pixelDensity: Double
}

struct SimpleCanvasMetadata: Codable {
    let createdAt: Date
    let modifiedAt: Date
    let tags: [String]
    let description: String?
    let author: String?
}

struct DesignCanvasData: Codable {
    let id: String
    let deviceType: String
    let dimensions: SimpleCanvasDimensions
    let layers: [LayerData]
    let metadata: SimpleCanvasMetadata
    let state: String
}

struct LayerData: Codable {
    let id: String
    let type: String
    let zIndex: Int
    let content: [String: AnyCodable]
    let transform: LayerTransform
    let style: [String: AnyCodable]
    let constraints: [String: AnyCodable]
    let metadata: SimpleLayerMetadata
}

struct LayerTransform: Codable {
    let x: Double
    let y: Double
    let scaleX: Double
    let scaleY: Double
    let rotation: Double
    let opacity: Double
}

struct SimpleLayerMetadata: Codable {
    let source: String
    let createdAt: Date
}

// MARK: - Helper for Any Values

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to encode value"))
        }
    }
}

// MARK: - AI Service Class

@MainActor
class AIService: ObservableObject {
    private let baseUrl: String
    private let apiKey: String
    private let session: URLSession
    
    @Published var isLoading = false
    @Published var lastError: AIServiceError?
    
    init(apiKey: String = "", baseUrl: String = "https://ai.gemini.googleapis.com/v1") {
        self.baseUrl = baseUrl
        self.apiKey = apiKey
        self.session = URLSession.shared
    }
    
    // MARK: - Public API Methods
    
    /**
     * Analyze canvas for AI suggestions
     * Corresponds to POST /canvas/analyze
     */
    func analyzeCanvas(_ request: CanvasAnalysisRequest) async throws -> CanvasAnalysisResponse {
        let startTime = Date()
        
        guard !apiKey.isEmpty else {
            throw AIServiceError.authError("API key not configured")
        }
        
        // Validate canvas data
        try validateCanvasData(request.canvas)
        
        let url = URL(string: "\(baseUrl)/canvas/analyze")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let requestData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestData
            
            isLoading = true
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.networkError("Invalid response type")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIServiceError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            let analysisResponse = try JSONDecoder().decode(CanvasAnalysisResponse.self, from: data)
            
            let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
            var finalResponse = analysisResponse
            
            // Update processing time if not set by server
            if finalResponse.processingTime == 0 {
                finalResponse = CanvasAnalysisResponse(
                    analysisId: analysisResponse.analysisId,
                    suggestions: analysisResponse.suggestions,
                    confidence: analysisResponse.confidence,
                    trends: analysisResponse.trends,
                    processingTime: processingTime
                )
            }
            
            isLoading = false
            lastError = nil
            
            return finalResponse
            
        } catch let error as AIServiceError {
            isLoading = false
            lastError = error
            throw error
        } catch {
            let aiError = AIServiceError.networkError("Canvas analysis failed: \(error.localizedDescription)")
            isLoading = false
            lastError = aiError
            throw aiError
        }
    }
    
    /**
     * Generate design variations
     * Corresponds to POST /variations/generate
     */
    func generateVariations(_ request: VariationRequest) async throws -> VariationResponse {
        let startTime = Date()
        
        guard !apiKey.isEmpty else {
            throw AIServiceError.authError("API key not configured")
        }
        
        // Validate base canvas
        try validateCanvasData(request.baseCanvas)
        
        guard request.count > 0 && request.count <= 10 else {
            throw AIServiceError.validationError("Count must be between 1 and 10")
        }
        
        let url = URL(string: "\(baseUrl)/variations/generate")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let requestData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestData
            
            isLoading = true
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.networkError("Invalid response type")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIServiceError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            let variationResponse = try JSONDecoder().decode(VariationResponse.self, from: data)
            
            let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
            var finalResponse = variationResponse
            
            // Update processing time if not set by server
            if finalResponse.processingTime == 0 {
                finalResponse = VariationResponse(
                    requestId: variationResponse.requestId,
                    variations: variationResponse.variations,
                    confidence: variationResponse.confidence,
                    processingTime: processingTime
                )
            }
            
            isLoading = false
            lastError = nil
            
            return finalResponse
            
        } catch let error as AIServiceError {
            isLoading = false
            lastError = error
            throw error
        } catch {
            let aiError = AIServiceError.networkError("Variation generation failed: \(error.localizedDescription)")
            isLoading = false
            lastError = aiError
            throw aiError
        }
    }
    
    /**
     * Get current design trends
     * Corresponds to GET /trends/current
     */
    func getCurrentTrends() async throws -> CurrentTrendsResponse {
        guard !apiKey.isEmpty else {
            throw AIServiceError.authError("API key not configured")
        }
        
        let url = URL(string: "\(baseUrl)/trends/current")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            isLoading = true
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.networkError("Invalid response type")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIServiceError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            let trendsResponse = try JSONDecoder().decode(CurrentTrendsResponse.self, from: data)
            
            isLoading = false
            lastError = nil
            
            return trendsResponse
            
        } catch let error as AIServiceError {
            isLoading = false
            lastError = error
            throw error
        } catch {
            let aiError = AIServiceError.networkError("Trends request failed: \(error.localizedDescription)")
            isLoading = false
            lastError = aiError
            throw aiError
        }
    }
    
    // MARK: - Validation Methods
    
    private func validateCanvasData(_ canvas: DesignCanvasData) throws {
        guard !canvas.id.isEmpty else {
            throw AIServiceError.validationError("Canvas ID is required")
        }
        
        guard canvas.dimensions.width > 0 && canvas.dimensions.height > 0 else {
            throw AIServiceError.validationError("Canvas dimensions must be positive")
        }
        
        guard !canvas.layers.isEmpty else {
            throw AIServiceError.validationError("Canvas must contain at least one layer")
        }
        
        // Validate each layer
        for layer in canvas.layers {
            guard !layer.id.isEmpty else {
                throw AIServiceError.validationError("Layer ID is required")
            }
            
            guard !layer.type.isEmpty else {
                throw AIServiceError.validationError("Layer type is required")
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /**
     * Create analysis request from dictionary data
     */
    func createAnalysisRequest(
        canvasData: DesignCanvasData,
        analysisTypes: [AnalysisType] = [.creative, .trends],
        userPreferences: UserPreferences? = nil
    ) -> CanvasAnalysisRequest {
        return CanvasAnalysisRequest(
            canvas: canvasData,
            deviceType: canvasData.deviceType,
            analysisType: analysisTypes,
            userPreferences: userPreferences
        )
    }
    
    /**
     * Create variation request from dictionary data
     */
    func createVariationRequest(
        baseCanvasData: DesignCanvasData,
        variationType: VariationType = .creative,
        count: Int = 3,
        preferences: UserPreferences? = nil
    ) -> VariationRequest {
        return VariationRequest(
            baseCanvas: baseCanvasData,
            variationType: variationType,
            count: count,
            preferences: preferences
        )
    }
}

// MARK: - SwiftUI Integration Extensions

extension AIService {
    /**
     * Analyze canvas with SwiftUI state management
     */
    func analyzeCanvasAsync(
        canvasData: DesignCanvasData,
        analysisTypes: [AnalysisType] = [.creative, .trends],
        userPreferences: UserPreferences? = nil
    ) -> AsyncThrowingStream<CanvasAnalysisResponse, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = createAnalysisRequest(
                        canvasData: canvasData,
                        analysisTypes: analysisTypes,
                        userPreferences: userPreferences
                    )
                    let response = try await analyzeCanvas(request)
                    continuation.yield(response)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /**
     * Generate variations with SwiftUI state management
     */
    func generateVariationsAsync(
        baseCanvasData: DesignCanvasData,
        variationType: VariationType = .creative,
        count: Int = 3,
        preferences: UserPreferences? = nil
    ) -> AsyncThrowingStream<VariationResponse, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = createVariationRequest(
                        baseCanvasData: baseCanvasData,
                        variationType: variationType,
                        count: count,
                        preferences: preferences
                    )
                    let response = try await generateVariations(request)
                    continuation.yield(response)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Global Shared Instance

extension AIService {
    static let shared = AIService()
}
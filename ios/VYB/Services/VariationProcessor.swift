/*
 * VariationProcessor - AI response processing and variation generation for iOS
 * Implements T049: iOS Variation Processing
 * Swift counterpart to web VariationProcessor with feature parity
 */

import Foundation
import Combine
import SwiftUI
import CoreGraphics

// MARK: - Simple JSON Value Type

enum JSONValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .boolean(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - Processing Types

// Using LayerChange from AIService.swift

struct ProcessingOptions {
    let preserveOriginal: Bool
    let maxVariations: Int
    let confidenceThreshold: Double
    let enableBatching: Bool
    let autoSave: Bool
    
    static let `default` = ProcessingOptions(
        preserveOriginal: true,
        maxVariations: 5,
        confidenceThreshold: 0.5,
        enableBatching: true,
        autoSave: true
    )
}

struct ProcessingResult {
    let processedVariations: [SimpleVariationData]
    let appliedChanges: [LayerChange]
    let rejectedChanges: [LayerChange]
    let processingTime: TimeInterval
    let confidence: Double
}

struct VariationMetrics {
    var totalProcessed: Int
    var successful: Int
    var failed: Int
    var averageConfidence: Double
    var averageProcessingTime: TimeInterval
    
    static let empty = VariationMetrics(
        totalProcessed: 0,
        successful: 0,
        failed: 0,
        averageConfidence: 0.0,
        averageProcessingTime: 0.0
    )
}

struct ChangeApplication {
    let layerId: String
    let property: String
    let previousValue: JSONValue
    let newValue: JSONValue
    let success: Bool
    let error: String?
}

// MARK: - Simple Variation Data Model

struct SimpleVariationData: Codable, Identifiable {
    let id: String
    let parentId: String?
    let canvasState: SimpleCanvasData
    let source: String
    let prompt: String
    let confidence: Double
    let timestamp: Date
    let metadata: VariationMetadata
    
    struct VariationMetadata: Codable {
        let tags: [String]
        let notes: String
        let approvalStatus: ApprovalStatus
        
        enum ApprovalStatus: String, Codable, CaseIterable {
            case pending = "pending"
            case approved = "approved"
            case rejected = "rejected"
        }
    }
}

struct SimpleCanvasData: Codable {
    let id: String
    let deviceType: String
    let dimensions: SimpleDimensions
    var layers: [SimpleLayerData]
    let metadata: SimpleMetadata
    let state: String
}

struct SimpleDimensions: Codable {
    let width: Double
    let height: Double
    let pixelDensity: Double
}

struct SimpleMetadata: Codable {
    let createdAt: Date
    let modifiedAt: Date
    let tags: [String]
}

// Using SimpleLayerData from AIService.swift

struct SimpleTransform: Codable {
    let x: Double
    let y: Double
    let scaleX: Double
    let scaleY: Double
    let rotation: Double
    let opacity: Double
}

// SimpleLayerMetadata is defined in AIService.swift

// MARK: - Mock Response Types (for compatibility)

struct MockVariationResponse {
    let requestId: String
    let variations: [SimpleCanvasData]
    let confidence: Double
    let processingTime: Int
}

struct MockAISuggestion {
    let id: String
    let type: String
    let description: String
    let confidence: Double
    let preview: String?
}

// MARK: - Error Types

enum VariationProcessingError: LocalizedError {
    case invalidAIResponse(String)
    case invalidCanvas(String)
    case processingFailed(String)
    case layerNotFound(String)
    case propertyNotFound(String)
    case previewGenerationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAIResponse(let message):
            return "Invalid AI Response: \(message)"
        case .invalidCanvas(let message):
            return "Invalid Canvas: \(message)"
        case .processingFailed(let message):
            return "Processing Failed: \(message)"
        case .layerNotFound(let message):
            return "Layer Not Found: \(message)"
        case .propertyNotFound(let message):
            return "Property Not Found: \(message)"
        case .previewGenerationFailed(let message):
            return "Preview Generation Failed: \(message)"
        }
    }
}

// MARK: - Variation Processor Class

@MainActor
class VariationProcessor: ObservableObject {
    
    @Published var isProcessing = false
    @Published var lastError: VariationProcessingError?
    @Published var metrics = VariationMetrics.empty
    
    private var processingCache: [String: ProcessingResult] = [:]
    
    // MARK: - Public API
    
    /**
     * Process AI response and generate variations
     */
    func processAIResponse(
        _ aiResponse: MockVariationResponse,
        baseCanvas: SimpleCanvasData,
        options: ProcessingOptions = .default
    ) async throws -> ProcessingResult {
        let startTime = Date()
        
        isProcessing = true
        lastError = nil
        
        do {
            // Validate AI response
            try validateAIResponse(aiResponse)
            
            // Process each variation
            var processedVariations: [SimpleVariationData] = []
            var appliedChanges: [LayerChange] = []
            var rejectedChanges: [LayerChange] = []
            
            for variationCanvasData in aiResponse.variations.prefix(options.maxVariations) {
                let variation = createVariationData(
                    from: variationCanvasData,
                    baseCanvas: baseCanvas,
                    source: "ai_suggestion",
                    prompt: "AI generated variation"
                )
                
                if variation.confidence < options.confidenceThreshold {
                    print("Skipping variation \(variation.id) due to low confidence: \(variation.confidence)")
                    continue
                }
                
                do {
                    let result = try await processVariation(variation, options: options)
                    processedVariations.append(result.variation)
                    appliedChanges.append(contentsOf: result.appliedChanges)
                    rejectedChanges.append(contentsOf: result.rejectedChanges)
                } catch {
                    print("Failed to process variation \(variation.id): \(error)")
                    metrics.failed += 1
                }
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            let overallConfidence = calculateOverallConfidence(processedVariations)
            
            // Update metrics
            updateMetrics(
                processed: processedVariations.count,
                time: processingTime,
                confidence: overallConfidence
            )
            
            let result = ProcessingResult(
                processedVariations: processedVariations,
                appliedChanges: appliedChanges,
                rejectedChanges: rejectedChanges,
                processingTime: processingTime,
                confidence: overallConfidence
            )
            
            isProcessing = false
            return result
            
        } catch let error as VariationProcessingError {
            isProcessing = false
            lastError = error
            throw error
        } catch {
            let processingError = VariationProcessingError.processingFailed(error.localizedDescription)
            isProcessing = false
            lastError = processingError
            throw processingError
        }
    }
    
    /**
     * Apply AI suggestions to canvas
     */
    func applySuggestions(
        _ suggestions: [AISuggestionWithChanges],
        targetCanvas: SimpleCanvasData,
        options: ProcessingOptions = .default
    ) async throws -> (canvas: SimpleCanvasData, changes: [ChangeApplication]) {
        
        var modifiedCanvas = targetCanvas
        var changes: [ChangeApplication] = []
        
        for suggestion in suggestions {
            if suggestion.suggestion.confidence < options.confidenceThreshold {
                continue
            }
            
            for change in suggestion.changes {
                do {
                    let application = try await applyLayerChange(&modifiedCanvas, change: change)
                    changes.append(application)
                } catch {
                    let failedApplication = ChangeApplication(
                        layerId: change.layerId,
                        property: change.property,
                        previousValue: change.currentValue,
                        newValue: change.suggestedValue,
                        success: false,
                        error: error.localizedDescription
                    )
                    changes.append(failedApplication)
                }
            }
        }
        
        return (canvas: modifiedCanvas, changes: changes)
    }
    
    /**
     * Generate variation preview as base64 string (simplified without UIKit)
     */
    func generateVariationPreview(
        _ variation: SimpleVariationData,
        size: CGSize = CGSize(width: 300, height: 200)
    ) async throws -> String {
        
        // For now, return a placeholder base64 string
        // In a full implementation, this would render the canvas to an image
        let placeholder = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjZjNmNGY2Ii8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIxNCIgZmlsbD0iIzY2NjY2NiIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZHk9Ii4zZW0iPkRlc2lnbiBQcmV2aWV3PC90ZXh0Pjwvc3ZnPg=="
        
        return placeholder
    }
    
    // MARK: - Private Processing Methods
    
    private func createVariationData(
        from canvasData: SimpleCanvasData,
        baseCanvas: SimpleCanvasData,
        source: String,
        prompt: String
    ) -> SimpleVariationData {
        return SimpleVariationData(
            id: UUID().uuidString,
            parentId: baseCanvas.id,
            canvasState: canvasData,
            source: source,
            prompt: prompt,
            confidence: 0.8, // Default confidence
            timestamp: Date(),
            metadata: SimpleVariationData.VariationMetadata(
                tags: [],
                notes: "",
                approvalStatus: .pending
            )
        )
    }
    
    private func processVariation(
        _ variation: SimpleVariationData,
        options: ProcessingOptions
    ) async throws -> (
        variation: SimpleVariationData,
        appliedChanges: [LayerChange],
        rejectedChanges: [LayerChange]
    ) {
        
        // Validate variation canvas
        try validateVariationCanvas(variation.canvasState)
        
        // For now, we'll just return the variation as-is
        // In a real implementation, you might process actual changes
        return (
            variation: variation,
            appliedChanges: [],
            rejectedChanges: []
        )
    }
    
    private func applyLayerChange(
        _ canvas: inout SimpleCanvasData,
        change: LayerChange
    ) async throws -> ChangeApplication {
        
        guard let layerIndex = canvas.layers.firstIndex(where: { $0.id == change.layerId }) else {
            throw VariationProcessingError.layerNotFound(change.layerId)
        }
        
        var layer = canvas.layers[layerIndex]
        let previousValue = try getLayerProperty(layer, propertyPath: change.property)
        
        setLayerProperty(&layer, propertyPath: change.property, value: change.suggestedValue)
        canvas.layers[layerIndex] = layer
        
        return ChangeApplication(
            layerId: change.layerId,
            property: change.property,
            previousValue: previousValue,
            newValue: change.suggestedValue,
            success: true,
            error: nil
        )
    }
    
    private func getLayerProperty(_ layer: SimpleLayerData, propertyPath: String) throws -> JSONValue {
        let components = propertyPath.split(separator: ".").map(String.init)
        
        guard !components.isEmpty else {
            throw VariationProcessingError.propertyNotFound(propertyPath)
        }
        
        // Simple property access for common cases
        switch components[0] {
        case "transform":
            if components.count > 1 {
                switch components[1] {
                case "x": return .number(layer.transform.x)
                case "y": return .number(layer.transform.y)
                case "scaleX": return .number(layer.transform.scaleX)
                case "scaleY": return .number(layer.transform.scaleY)
                case "rotation": return .number(layer.transform.rotation)
                case "opacity": return .number(layer.transform.opacity)
                default: throw VariationProcessingError.propertyNotFound(propertyPath)
                }
            }
        case "content":
            if components.count > 1, let value = layer.content[components[1]] {
                return value
            }
        case "style":
            if components.count > 1, let value = layer.style[components[1]] {
                return value
            }
        default:
            break
        }
        
        throw VariationProcessingError.propertyNotFound(propertyPath)
    }
    
    private func setLayerProperty(_ layer: inout SimpleLayerData, propertyPath: String, value: JSONValue) {
        let components = propertyPath.split(separator: ".").map(String.init)
        
        guard !components.isEmpty else { return }
        
        // Simple property setting for common cases
        switch components[0] {
        case "transform":
            if components.count > 1, case .number(let doubleValue) = value {
                var transform = layer.transform
                switch components[1] {
                case "x": transform = SimpleTransform(x: doubleValue, y: transform.y, scaleX: transform.scaleX, scaleY: transform.scaleY, rotation: transform.rotation, opacity: transform.opacity)
                case "y": transform = SimpleTransform(x: transform.x, y: doubleValue, scaleX: transform.scaleX, scaleY: transform.scaleY, rotation: transform.rotation, opacity: transform.opacity)
                case "scaleX": transform = SimpleTransform(x: transform.x, y: transform.y, scaleX: doubleValue, scaleY: transform.scaleY, rotation: transform.rotation, opacity: transform.opacity)
                case "scaleY": transform = SimpleTransform(x: transform.x, y: transform.y, scaleX: transform.scaleX, scaleY: doubleValue, rotation: transform.rotation, opacity: transform.opacity)
                case "rotation": transform = SimpleTransform(x: transform.x, y: transform.y, scaleX: transform.scaleX, scaleY: transform.scaleY, rotation: doubleValue, opacity: transform.opacity)
                case "opacity": transform = SimpleTransform(x: transform.x, y: transform.y, scaleX: transform.scaleX, scaleY: transform.scaleY, rotation: transform.rotation, opacity: doubleValue)
                default: break
                }
                layer.transform = transform
            }
        case "content":
            if components.count > 1 {
                var content = layer.content
                content[components[1]] = value
                layer.content = content
            }
        case "style":
            if components.count > 1 {
                var style = layer.style
                style[components[1]] = value
                layer.style = style
            }
        default:
            break
        }
    }
    
    // MARK: - Validation Methods
    
    private func validateAIResponse(_ response: MockVariationResponse) throws {
        if response.variations.isEmpty {
            throw VariationProcessingError.invalidAIResponse("Response contains no variations")
        }
        
        for variation in response.variations {
            if variation.id.isEmpty {
                throw VariationProcessingError.invalidAIResponse("Variation missing ID")
            }
        }
    }
    
    private func validateVariationCanvas(_ canvas: SimpleCanvasData) throws {
        if canvas.layers.isEmpty {
            throw VariationProcessingError.invalidCanvas("Canvas must contain at least one layer")
        }
        
        for layer in canvas.layers {
            if layer.id.isEmpty || layer.type.isEmpty {
                throw VariationProcessingError.invalidCanvas("Layer missing ID or type")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    private func calculateOverallConfidence(_ variations: [SimpleVariationData]) -> Double {
        guard !variations.isEmpty else { return 0.0 }
        
        let totalConfidence = variations.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Double(variations.count)
    }
    
    private func updateMetrics(processed: Int, time: TimeInterval, confidence: Double) {
        metrics.totalProcessed += processed
        metrics.successful += processed
        
        // Running average calculation
        let total = metrics.successful
        if total > 0 {
            metrics.averageProcessingTime = 
                (metrics.averageProcessingTime * Double(total - processed) + time) / Double(total)
            
            metrics.averageConfidence = 
                (metrics.averageConfidence * Double(total - processed) + confidence * Double(processed)) / Double(total)
        }
    }
    
    // MARK: - Public Utility Methods
    
    func clearMetrics() {
        metrics = VariationMetrics.empty
    }
    
    func clearError() {
        lastError = nil
    }
}

// MARK: - Supporting Types

struct AISuggestionWithChanges {
    let suggestion: MockAISuggestion
    let changes: [LayerChange]
}

// MARK: - Global Shared Instance

extension VariationProcessor {
    static let shared = VariationProcessor()
}
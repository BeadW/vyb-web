import Foundation
import CoreGraphics

// Import our modular AI system - this makes the architecture explicit
// Note: In a proper Swift module system, these would be separate modules

// MARK: - Legacy AIService class for backward compatibility
// This file provides the same interface as the old AIService while using our new modular architecture

/// Legacy AIService class that delegates to AIServiceManager
class AIService {
    private let serviceManager = AIServiceManager()
    
    public var isConfigured: Bool {
        return serviceManager.isConfigured
    }
    
    public init() {
        // ServiceManager handles provider setup internally
    }
    
    public func configure(apiKey: String) {
        do {
            try serviceManager.configure(apiKey: apiKey)
            NSLog("✅ AIService (Legacy): Successfully configured")
        } catch {
            NSLog("❌ AIService (Legacy): Configuration failed: \(error)")
        }
    }
    
    func generateDesignVariations(
        for layers: [Any],
        canvasSize: CGSize = CGSize(width: 400, height: 500)
    ) async throws -> [DesignVariation] {
        return try await serviceManager.generateDesignVariations(
            for: layers,
            canvasSize: canvasSize,
            constraints: GenerationConstraints(maxVariations: 3)
        )
    }
    
    public func analyzeCanvas(_ canvasData: DesignCanvasData) async throws -> CanvasAnalysisResponse {
        return try await serviceManager.analyzeCanvas(canvasData)
    }
}

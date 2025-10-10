import Foundation
import CoreGraphics

/// Main AI Service that orchestrates different AI providers
class AIServiceManager {
    
    private let providerRegistry = AIProviderRegistry.shared
    private var currentProvider: AIProviderProtocol?
    
    public init() {
        setupProviders()
    }
    
    // MARK: - Configuration
    
    /// Configure the AI service with API keys and settings
    public func configure(apiKey: String) throws {
        let config = AIProviderConfiguration(apiKey: apiKey)
        
        // Configure all providers that need API keys
        if let geminiProvider = providerRegistry.getProvider(named: "Gemini") {
            try geminiProvider.configure(with: config)
        }
        
        // Configure Apple Intelligence (doesn't need API key)
        if let appleProvider = providerRegistry.getProvider(named: "Apple Intelligence") {
            try appleProvider.configure(with: AIProviderConfiguration())
        }
        
        // Set the best available provider as current
        currentProvider = providerRegistry.getBestProvider()
        
        if let provider = currentProvider {
            NSLog("✅ AIServiceManager: Configured with provider: \(provider.providerName)")
        } else {
            NSLog("❌ AIServiceManager: No providers available")
            throw AIServiceError.notConfigured
        }
    }
    
    /// Set a specific provider to use
    public func setProvider(named name: String) throws {
        guard let provider = providerRegistry.getProvider(named: name) else {
            throw AIServiceError.providerUnavailable("Provider '\(name)' not found")
        }
        
        guard provider.isAvailable else {
            throw AIServiceError.providerUnavailable("Provider '\(name)' is not available")
        }
        
        currentProvider = provider
        NSLog("🔄 AIServiceManager: Switched to provider: \(provider.providerName)")
    }
    
    /// Get the current provider name
    public var currentProviderName: String? {
        return currentProvider?.providerName
    }
    
    /// Get all available providers
    public var availableProviders: [String] {
        return providerRegistry.getAvailableProviders().map { $0.providerName }
    }
    
    /// Get provider selection information for UI
    public var providerSelectionInfo: (current: String, available: [String], reason: String) {
        return providerRegistry.getProviderSelectionInfo()
    }
    
    /// Check if the service is configured
    public var isConfigured: Bool {
        return currentProvider != nil
    }
    
    /// Check if device supports Apple Intelligence
    public var supportsAppleIntelligence: Bool {
        if #available(iOS 26.0, *) {
            #if canImport(FoundationModels)
            return true
            #else
            return false
            #endif
        }
        return false
    }
    
    /// Check if currently using Apple Intelligence
    public var isUsingAppleIntelligence: Bool {
        return currentProvider?.providerName == "Apple Intelligence"
    }
    
    // MARK: - Design Generation
    
    /// Generate design variations using the current AI provider
    public func generateDesignVariations(
        for layers: [Any],
        canvasSize: CGSize = CGSize(width: 400, height: 500),
        constraints: GenerationConstraints? = nil
    ) async throws -> [DesignVariation] {
        
        guard let provider = currentProvider else {
            throw AIServiceError.notConfigured
        }
        
        NSLog("🎨 AIServiceManager: Generating variations with \(provider.providerName)")
        NSLog("🎨 AIServiceManager: Canvas: \(canvasSize.width)x\(canvasSize.height), Layers: \(layers.count)")
        
        // Convert layers to SimpleLayerData
        let simpleLayers = convertToSimpleLayerData(layers)
        let canvasBounds = CanvasBounds(from: canvasSize)
        
        // Log layer visibility for debugging
        logLayerVisibility(simpleLayers, canvasBounds: canvasBounds)
        
        // Create the request
        let request = DesignVariationRequest(
            layers: simpleLayers,
            canvasBounds: canvasBounds,
            constraints: constraints
        )
        
        // Generate variations
        let response = try await provider.generateVariations(request: request)
        
        NSLog("✅ AIServiceManager: Generated \(response.variations.count) variations")
        if let metadata = response.metadata {
            NSLog("📊 AIServiceManager: Provider: \(metadata.provider), Time: \(String(format: "%.2f", metadata.processingTime ?? 0))s")
        }
        
        return response.variations
    }
    
    /// Analyze canvas for suggestions (legacy compatibility)
    public func analyzeCanvas(_ canvasData: DesignCanvasData) async throws -> CanvasAnalysisResponse {
        // Minimal implementation for backward compatibility
        return CanvasAnalysisResponse(suggestions: [
            AISuggestion(
                id: "generic-suggestion",
                type: "creative",
                description: "Consider using the AI-powered design variations feature",
                confidence: 0.8
            )
        ])
    }
    
    // MARK: - Private Methods
    
    private func setupProviders() {
        // Register Gemini provider
        let geminiProvider = GeminiAIProvider()
        providerRegistry.register(provider: geminiProvider)
        
        // Register Apple Intelligence provider (iOS 26.0+)
        if #available(iOS 26.0, *) {
            let appleProvider = AppleIntelligenceProvider()
            providerRegistry.register(provider: appleProvider)
        }
        
        NSLog("🏗️ AIServiceManager: Registered \(providerRegistry.getAvailableProviders().count) providers")
    }
    
    private func convertToSimpleLayerData(_ layers: [Any]) -> [SimpleLayerData] {
        return layers.compactMap { layer in
            if let simpleLayer = layer as? SimpleLayerData {
                return simpleLayer
            }
            
            // Convert SimpleLayer to SimpleLayerData
            if let simpleLayer = layer as? SimpleLayer {
                NSLog("🔄 AIServiceManager: Converting SimpleLayer '\(simpleLayer.content)' to SimpleLayerData")
                return SimpleLayerData(
                    id: simpleLayer.id,
                    type: simpleLayer.type,
                    content: simpleLayer.content,
                    x: simpleLayer.x,
                    y: simpleLayer.y
                )
            }
            
            NSLog("⚠️ AIServiceManager: Unknown layer type: \(type(of: layer))")
            return nil
        }
    }
    
    private func logLayerVisibility(_ layers: [SimpleLayerData], canvasBounds: CanvasBounds) {
        let visibleCount = layers.filter { $0.isVisible(within: canvasBounds) }.count
        let hiddenCount = layers.count - visibleCount
        
        NSLog("👁️ AIServiceManager: Layer visibility - \(visibleCount) visible, \(hiddenCount) hidden within \(canvasBounds.width)x\(canvasBounds.height) canvas")
        
        // Log specific hidden layers for debugging
        let hiddenLayers = layers.filter { !$0.isVisible(within: canvasBounds) }
        for layer in hiddenLayers {
            let visibility = layer.visibilityDescription(within: canvasBounds)
            NSLog("🙈 AIServiceManager: Hidden layer '\(layer.id)': \(visibility) at (\(layer.x), \(layer.y))")
        }
    }
}

// MARK: - Legacy Compatibility

/// AIService class is maintained as a separate wrapper around AIServiceManager
/// for backward compatibility with existing code.
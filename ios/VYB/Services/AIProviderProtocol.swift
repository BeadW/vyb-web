import Foundation
import CoreGraphics

// MARK: - AI Provider Protocol

/// Protocol defining the interface for AI providers that generate design variations
public protocol AIProviderProtocol {
    /// The name of the AI provider (e.g., "Gemini", "Apple Intelligence")
    var providerName: String { get }
    
    /// Whether this provider is available on the current device/configuration
    var isAvailable: Bool { get }
    
    /// Configure the provider with necessary credentials/settings
    func configure(with configuration: AIProviderConfiguration) throws
    
    /// Generate design variations based on input layers and canvas constraints
    func generateVariations(
        request: DesignVariationRequest
    ) async throws -> DesignVariationResponse
}

// MARK: - Request/Response Models
// Moved to AIDataModels.swift for type visibility
    
// Removed stray initializers and closing braces

// MARK: - Provider Registry

/// Registry for managing AI providers
class AIProviderRegistry {
    private var providers: [String: AIProviderProtocol] = [:]
    
    static let shared = AIProviderRegistry()
    
    private init() {}
    
    /// Register a new AI provider
    func register(provider: AIProviderProtocol) {
        providers[provider.providerName] = provider
    }
    
    /// Get a provider by name
    func getProvider(named name: String) -> AIProviderProtocol? {
        return providers[name]
    }
    
    /// Get all available providers
    func getAvailableProviders() -> [AIProviderProtocol] {
        return providers.values.filter { $0.isAvailable }
    }
    
    /// Get the best available provider (prioritizes Apple Intelligence, then others)
    func getBestProvider() -> AIProviderProtocol? {
        // First try Apple Intelligence if available
        if let appleProvider = providers["Apple Intelligence"], appleProvider.isAvailable {
            return appleProvider
        }
        
        // Then try other available providers
        return getAvailableProviders().first
    }
}
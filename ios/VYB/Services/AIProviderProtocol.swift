import Foundation
import CoreGraphics

#if canImport(FoundationModels)
import FoundationModels
#endif

// Import data models for protocol requirements
// Note: Types are defined in AIDataModels.swift in the same project

// MARK: - Foundation Models Availability Detection

/// Comprehensive Foundation Models availability checking using SystemLanguageModel.availability
@available(iOS 26.0, *)
func checkFoundationModelAvailability() -> (isAvailable: Bool, reason: String) {
    #if canImport(FoundationModels)
    let model = SystemLanguageModel.default
    switch model.availability {
    case .available:
        NSLog("🧠 Foundation Model is available and ready to use.")
        return (true, "Foundation Model is available and ready to use")
    case .unavailable(let reason):
        let reasonString: String
        let logMessage: String
        
        // Handle the actual available enum cases
        switch reason {
        case .deviceNotEligible:
            reasonString = "Device does not support Apple Intelligence"
            logMessage = "❌ Foundation Model unavailable: Device does not support Apple Intelligence."
        default:
            // Handle other cases that might exist
            reasonString = "Foundation Models unavailable: \(reason)"
            logMessage = "❌ Foundation Model unavailable: \(reason)"
        }
        
        NSLog(logMessage)
        return (false, reasonString)
    @unknown default:
        NSLog("❓ Foundation Model availability status is unknown.")
        return (false, "Availability status unknown")
    }
    #else
    return (false, "FoundationModels framework not available")
    #endif
}

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
    
    /// Get the best available provider based on device capabilities - NO FALLBACK MIXING
    func getBestProvider() -> AIProviderProtocol? {
        // STRICT PROTOCOL PATTERN: Either Foundation Models OR Gemini, NEVER mix
        
        // First: Check if this device actually supports Foundation Models using comprehensive detection
        if #available(iOS 26.0, *) {
            let availability = checkFoundationModelAvailability()
            if availability.isAvailable {
                if let appleProvider = providers["Apple Intelligence"], appleProvider.isAvailable {
                    NSLog("🧠 AIProviderRegistry: Foundation Models available - ONLY using Apple Intelligence")
                    return appleProvider
                }
            } else {
                NSLog("🤖 AIProviderRegistry: Foundation Models NOT available (\(availability.reason)) - ONLY using Gemini")
            }
        } else {
            NSLog("🤖 AIProviderRegistry: iOS < 26.0 - ONLY using Gemini")
        }
        
        // Second: Device doesn't support Foundation Models, use Gemini ONLY
        if let geminiProvider = providers["Gemini"], geminiProvider.isAvailable {
            NSLog("🤖 AIProviderRegistry: Selecting Gemini as ONLY provider")
            return geminiProvider
        }
        
        NSLog("❌ AIProviderRegistry: No valid providers available")
        return nil
    }
    

    
    /// Get provider selection info for UI display
    func getProviderSelectionInfo() -> (current: String, available: [String], reason: String) {
        let bestProvider = getBestProvider()
        let currentName = bestProvider?.providerName ?? "None"
        let availableNames = getAvailableProviders().map { $0.providerName }
        
        let reason: String
        if currentName == "Apple Intelligence" {
            reason = "Foundation Models available - using Apple Intelligence ONLY"
        } else if currentName == "Gemini" {
            // Get detailed reason why Foundation Models isn't available
            if #available(iOS 26.0, *) {
                let availability = checkFoundationModelAvailability()
                reason = "Foundation Models unavailable (\(availability.reason)) - using Gemini ONLY"
            } else {
                reason = "iOS < 26.0 - using Gemini ONLY"
            }
        } else {
            reason = "No AI provider available"
        }
        
        return (current: currentName, available: availableNames, reason: reason)
    }
}
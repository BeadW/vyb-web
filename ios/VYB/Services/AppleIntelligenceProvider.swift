import Foundation
import CoreGraphics

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple Intelligence provider implementation using REAL Foundation Models API calls
@available(iOS 26.0, *)
class AppleIntelligenceProvider: AIProviderProtocol {
    init() {}
    var providerName: String { "Apple Intelligence" }
    var isAvailable: Bool { true }
    func configure(with configuration: AIProviderConfiguration) throws {}
    
    // MARK: - Private Methods
    private func isFoundationModelsAvailable() -> Bool {
        #if canImport(FoundationModels)
        NSLog("🧠 AppleIntelligenceProvider: FoundationModels framework is available")
        return true
        #else
        NSLog("🚨 AppleIntelligenceProvider: FoundationModels framework not importable")
        return false
        #endif
    }

    func createDesignAnalysisPrompt(request: DesignVariationRequest) -> String {
        let maxVariations = request.constraints?.maxVariations ?? 3
        let layerInfo = request.layers.map { layer in
            let x = round(layer.x * 100) / 100 // Round to 2 decimal places
            let y = round(layer.y * 100) / 100
            let visibility = request.canvasBounds.contains(x: layer.x, y: layer.y) ? "visible" : "out of bounds"
            return "Layer \(layer.id): \(layer.type) '\(layer.content)' at (\(x), \(y)) - \(visibility)"
        }.joined(separator: "\n")
        
        // Create the exact layer IDs that must be used in the response
        let exactLayerIds = request.layers.map { $0.id }
        let layerIdList = exactLayerIds.map { "\"\($0)\"" }.joined(separator: ", ")
        
        return """
        You are an expert graphic designer helping a client with a social media post. Your job is to take their current post and use your amazing skills to change it into something engaging and following the latest and best trends for social media posts. The Canvas is the image portion of the post so you are creating an image to be viewed based on the existing context. The variations you propose should be meanifully significantly different from the original and show different styles which the user might look to adopt.
        Create \(maxVariations) COMPLETELY DIFFERENT design variations for this salon cancellation policy:

        Canvas bounds: \(request.canvasBounds.width)x\(request.canvasBounds.height)
        Current layers (you can modify, remove, or add to these):
        \(layerInfo)
        
        EXAMPLE THEME INSPIRATIONS (create your own unique content inspired by these styles):
        - Professional/Corporate: Formal language, business emojis (📋, 📞, ⏰), neutral positioning
        - Casual/Friendly: Conversational tone, fun emojis (🌈, 💜, ✨), relaxed positioning  
        - Luxury/Premium: Sophisticated language, elegant emojis (💎, 👑, 🏆), refined positioning
        
        LAYER MANAGEMENT OPTIONS:
        - MODIFY existing layers: Change content, position, or type of current layers
        - ADD new layers: Create additional text, background, or other elements with new IDs
        - REMOVE layers: Simply don't include layers you don't want in a variation
        - Layer types available: "text", "background", "image", "shape"
        
        ID NAMING GUIDELINES:
        - Keep existing IDs if modifying those layers
        - For new layers, use descriptive IDs like: "contact-info", "decorative-border", "accent-text", "phone-number", etc.
        - Use kebab-case (words-separated-by-hyphens)
        
        POSITION GUIDELINES:
        - Keep x values between 0 and \(request.canvasBounds.width)
        - Keep y values between 0 and \(request.canvasBounds.height)
        - Vary positions dramatically between variations
        - Consider visual hierarchy and readability
        
        Requirements:
        1. Each variation must be DRAMATICALLY different in content, layout, and number of elements
        2. Create unique layer compositions - don't just copy the current structure
        3. Make each variation feel like a completely different designer created it
        4. Ensure all coordinates are within canvas bounds
        5. Each variation can have different numbers of layers (add/remove as needed)

        RESPOND WITH VALID JSON ONLY (no markdown, no explanations):
        {
          "variations": [
            {
              "title": "Descriptive title for this variation",
              "description": "Brief description of the style/theme",
              "layers": [
                {
                  "id": "layer-id-here",
                  "type": "text|background|image|shape",
                  "content": "Content for this layer",
                  "x": number_between_0_and_\(Int(request.canvasBounds.width)),
                  "y": number_between_0_and_\(Int(request.canvasBounds.height))
                }
              ]
            }
          ]
        }
        """
    }

    func generateWithFoundationModels(request: DesignVariationRequest) async throws -> [DesignVariation] {
        NSLog("🧠 AppleIntelligenceProvider: Initializing Foundation Models...")
        guard isFoundationModelsAvailable() else {
            throw NSError(domain: "AppleIntelligenceProvider", code: -3, userInfo: [NSLocalizedDescriptionKey: "Foundation Models not available"])
        }
        let prompt = createDesignAnalysisPrompt(request: request)
        let jsonSchema: String = "{\"type\": \"object\", \"properties\": {\"variations\": {\"type\": \"array\", \"items\": {\"type\": \"object\", \"properties\": {\"title\": {\"type\": \"string\"}, \"description\": {\"type\": \"string\"}, \"layers\": {\"type\": \"array\", \"items\": {\"type\": \"object\", \"properties\": {\"id\": {\"type\": \"string\"}, \"type\": {\"type\": \"string\"}, \"content\": {\"type\": \"string\"}, \"x\": {\"type\": \"number\"}, \"y\": {\"type\": \"number\"}}, \"required\": [\"id\", \"type\", \"content\", \"x\", \"y\"]}}}}}, \"required\": [\"title\", \"description\", \"layers\"]}}}}, \"required\": [\"variations\"]}}"
        NSLog("🧠 AppleIntelligenceProvider: Creating LanguageModelSession...")
        
        #if canImport(FoundationModels)
        let session = LanguageModelSession(model: SystemLanguageModel())
        NSLog("🧠 AppleIntelligenceProvider: Making REAL Foundation Models API call...")
        
        do {
            // Use the ACTUAL Foundation Models API - this is the real call!
            let response = try await session.respond(to: prompt)
            
            // Extract the actual response content from Foundation Models
            let responseText = response.content
            if responseText.isEmpty {
                NSLog("🚨 AppleIntelligenceProvider: Empty response from Foundation Models")
                throw NSError(domain: "AppleIntelligenceProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty response from Foundation Models"])
            }
            
            NSLog("🧠 =====================================================")
            NSLog("🧠 REAL FOUNDATION MODELS API RESPONSE:")
            NSLog("🧠 FULL RAW RESPONSE: '\(responseText)'")
            NSLog("🧠 RESPONSE LENGTH: \(responseText.count) characters")
            NSLog("🧠 RESPONSE TYPE: \(type(of: response))")
            NSLog("🧠 =====================================================")
            
            // Parse the JSON response from Foundation Models API
            do {
                // Clean up the response - Foundation Models may wrap JSON in markdown code blocks
                var cleanedResponse = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanedResponse.hasPrefix("```json") {
                    cleanedResponse = String(cleanedResponse.dropFirst(7)) // Remove "```json"
                }
                if cleanedResponse.hasSuffix("```") {
                    cleanedResponse = String(cleanedResponse.dropLast(3)) // Remove "```"
                }
                cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                
                NSLog("🧠 AppleIntelligenceProvider: Cleaned JSON: '\(String(cleanedResponse.prefix(200)))...'")
                
                // Try parsing as JSON
                let jsonData = cleanedResponse.data(using: .utf8)!
                let jsonResponse = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
                
                if let variationsArray = jsonResponse?["variations"] as? [[String: Any]] {
                    NSLog("🧠 AppleIntelligenceProvider: Parsing \(variationsArray.count) variations from Foundation Models JSON")
                    
                    let parsedVariations = variationsArray.compactMap { variation -> DesignVariation? in
                        guard let title = variation["title"] as? String,
                              let description = variation["description"] as? String,
                              let layersArray = variation["layers"] as? [[String: Any]] else {
                            NSLog("🚨 AppleIntelligenceProvider: Invalid variation structure")
                            return nil
                        }
                        
                        let layers = layersArray.compactMap { layerData -> SimpleLayerData? in
                            guard let id = layerData["id"] as? String,
                                  let type = layerData["type"] as? String,
                                  let content = layerData["content"] as? String,
                                  let x = layerData["x"] as? Double,
                                  let y = layerData["y"] as? Double else {
                                NSLog("🚨 AppleIntelligenceProvider: Invalid layer structure")
                                return nil
                            }
                            return SimpleLayerData(id: id, type: type, content: content, x: x, y: y)
                        }
                        
                        NSLog("🧠 AppleIntelligenceProvider: Parsed variation '\(title)' with \(layers.count) layers")
                        return DesignVariation(title: title, description: description, layers: layers)
                    }
                    
                    NSLog("🧠 AppleIntelligenceProvider: Successfully parsed \(parsedVariations.count) Foundation Models variations")
                    return parsedVariations
                } else {
                    NSLog("🚨 AppleIntelligenceProvider: No variations array found in Foundation Models response")
                }
            } catch {
                NSLog("🚨 AppleIntelligenceProvider: JSON parsing failed: \(error)")
            }
            
            // Fallback: create a single variation with properly matched layer IDs
            NSLog("🧠 AppleIntelligenceProvider: Using fallback variation creation")
            let fallbackVariation = DesignVariation(
                title: "Foundation Models Generated",
                description: "Generated by real Foundation Models API: \(String(responseText.prefix(100)))",
                layers: request.layers.map { originalLayer in
                    SimpleLayerData(
                        id: originalLayer.id, // Use the original layer ID for proper matching
                        type: originalLayer.type, 
                        content: "Real AI: \(String(responseText.prefix(50)))", 
                        x: originalLayer.x + 50.0, // Slight offset to show change
                        y: originalLayer.y + 50.0
                    )
                }
            )
            
            NSLog("🧠 AppleIntelligenceProvider: Created fallback variation with \(fallbackVariation.layers.count) layers")
            return [fallbackVariation]
            
        } catch {
            NSLog("🚨 AppleIntelligenceProvider: Foundation Models generation failed: \(error)")
            throw NSError(domain: "AppleIntelligenceProvider", code: -2, userInfo: [NSLocalizedDescriptionKey: "Foundation Models API call failed: \(error.localizedDescription)"])
        }
        #else
        throw NSError(domain: "AppleIntelligenceProvider", code: -4, userInfo: [NSLocalizedDescriptionKey: "Foundation Models framework not available"])
        #endif
    }

    func generateVariations(request: DesignVariationRequest) async throws -> DesignVariationResponse {
        #if canImport(FoundationModels)
        let variations = try await generateWithFoundationModels(request: request)
        let response = DesignVariationResponse(variations: variations, metadata: GenerationMetadata(provider: "Apple Intelligence", modelVersion: "foundation-models-1.0", processingTime: Double?.none, confidence: Double?.none))
        NSLog("📦 AppleIntelligenceProvider: Final response contains \(response.variations.count) variations")
        return response
        #else
        NSLog("🚨 AppleIntelligenceProvider: Foundation Models framework not available")
        throw AIServiceError.providerUnavailable("Foundation Models framework not available")
        #endif
    }
}

// MARK: - Foundation Models Response Types
#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct FoundationModelsVariationResponse: Codable {
    let variations: [FoundationModelsVariation]
}

@available(iOS 26.0, *)
@Generable
struct FoundationModelsVariation: Codable {
    let title: String
    let description: String
    let layers: [FoundationModelsLayer]
}

@available(iOS 26.0, *)
@Generable
struct FoundationModelsLayer: Codable {
    let id: String
    let type: String
    let content: String
    let x: Double
    let y: Double
}
#endif

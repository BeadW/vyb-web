import Foundation
import CoreGraphics

// MARK: - Response Validation Utilities

/// Validates if an API response appears to be complete and well-formed
private func isValidAPIResponse(_ response: String) -> Bool {
    // Check if response appears to be valid JSON structure
    guard !response.isEmpty else { return false }
    
    // Look for expected Gemini API response structure
    let hasExpectedStructure = response.contains("\"candidates\"") && 
                              response.contains("\"content\"") && 
                              response.contains("\"parts\"")
    
    // Check if response ends properly (not truncated)
    let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
    let endsWithValidJSON = trimmed.hasSuffix("}") || trimmed.hasSuffix("]")
    
    return hasExpectedStructure && endsWithValidJSON
}

/// Validates if JSON content appears complete for design variations
private func isCompleteJSONResponse(_ content: String) -> Bool {
    let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Remove any markdown formatting
    let cleanedContent = trimmed
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Check for expected structure
    let hasVariationsArray = cleanedContent.contains("\"variations\"") && 
                            cleanedContent.contains("[")
    
    // Check if JSON appears complete - must end with } or ]
    let endsWithValidJSON = cleanedContent.hasSuffix("}") || cleanedContent.hasSuffix("]")
    
    // Basic bracket/brace matching check - allow some tolerance
    let openBraces = cleanedContent.filter { $0 == "{" }.count
    let closeBraces = cleanedContent.filter { $0 == "}" }.count
    let openBrackets = cleanedContent.filter { $0 == "[" }.count
    let closeBrackets = cleanedContent.filter { $0 == "]" }.count
    
    // More lenient check - if brackets are close to balanced and has expected structure
    let bracesDiff = abs(openBraces - closeBraces)
    let bracketsDiff = abs(openBrackets - closeBrackets)
    let reasonablyBalanced = bracesDiff <= 1 && bracketsDiff <= 1
    
    // Be more lenient - just check for basic structure and reasonable balance
    return hasVariationsArray && endsWithValidJSON && reasonablyBalanced
}

/// Gemini AI provider implementation
class GeminiAIProvider: AIProviderProtocol {
    
    // MARK: - AIProviderProtocol Implementation
    
    var providerName: String {
        return "Gemini"
    }
    
    var isAvailable: Bool {
        return true // Gemini is always available via API
    }
    
    private var apiKey: String?
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    func configure(with configuration: AIProviderConfiguration) throws {
        guard let apiKey = configuration.apiKey, !apiKey.isEmpty else {
            throw AIServiceError.notConfigured
        }
        self.apiKey = apiKey
        NSLog("✅ GeminiAIProvider: Configured with API key")
    }
    
    func generateVariations(request: DesignVariationRequest) async throws -> DesignVariationResponse {
        // Retry logic for handling truncated responses
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let result = try await performGenerationRequest(request: request, attempt: attempt)
                if attempt > 1 {
                    NSLog("✅ GeminiAIProvider: Request succeeded on attempt \(attempt)/\(maxRetries)")
                }
                return result
            } catch let error as NSError where error.domain == "GeminiAIProvider" && (error.code == -2 || error.code == -3 || error.code == -4) {
                NSLog("⚠️ GeminiAIProvider: Attempt \(attempt)/\(maxRetries) failed: \(error.localizedDescription)")
                lastError = error
                
                // Only retry for truncation errors (-2, -3), not parsing errors (-4)
                if (error.code == -2 || error.code == -3) && attempt < maxRetries {
                    // Wait briefly before retrying
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    NSLog("🔄 GeminiAIProvider: Retrying request (attempt \(attempt + 1)/\(maxRetries))")
                    continue
                } else {
                    if error.code == -4 {
                        NSLog("❌ GeminiAIProvider: JSON parsing error - not retrying")
                    } else {
                        NSLog("❌ GeminiAIProvider: All \(maxRetries) attempts failed due to truncated responses")
                    }
                    throw error
                }
            } catch {
                // For non-truncation errors, don't retry
                throw error
            }
        }
        
        // This should never be reached, but just in case
        throw lastError ?? NSError(domain: "GeminiAIProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected error in retry logic"])
    }
    
    private func performGenerationRequest(request: DesignVariationRequest, attempt: Int) async throws -> DesignVariationResponse {
        let startTime = Date()
        
        guard let apiKey = self.apiKey else {
            throw NSError(domain: "GeminiAIProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "API key not configured"])
        }
        
        NSLog("🤖 GeminiAIProvider: Generating variations for \(request.layers.count) layers")
        
        // Create the prompt
        let prompt = createDesignAnalysisPrompt(
            layers: request.layers,
            canvasBounds: request.canvasBounds,
            constraints: request.constraints
        )
        
        // Prepare the API request
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw AIServiceError.networkError("Invalid URL")
        }
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(parts: [GeminiPart(text: prompt)])
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                maxOutputTokens: 4096,
                responseMimeType: "application/json"
            )
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(requestBody)
            
            NSLog("📝 GeminiAIProvider: Sending request to Gemini API")
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.networkError("Invalid response type")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                NSLog("❌ GeminiAIProvider: HTTP \(httpResponse.statusCode): \(errorMessage)")
                throw AIServiceError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            // Log the raw response for debugging
            let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            NSLog("📡 GeminiAIProvider: Raw API Response: \(rawResponse)")
            
            // Check if API response appears truncated
            if !isValidAPIResponse(rawResponse) {
                NSLog("⚠️ GeminiAIProvider: API response appears truncated or malformed")
                throw NSError(domain: "GeminiAIProvider", code: -2, userInfo: [NSLocalizedDescriptionKey: "API response appears truncated"])
            }
            
            // Parse the response
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            
            guard let content = geminiResponse.candidates.first?.content.parts.first?.text else {
                throw AIServiceError.parseError("No content in Gemini response")
            }
            
            NSLog("📄 GeminiAIProvider: Received response length: \(content.count) characters")
            NSLog("📄 GeminiAIProvider: Full response content: \(content)")
            
            // Validate JSON completeness before parsing - but let's be more lenient and see the actual error
            if !isCompleteJSONResponse(content) {
                NSLog("⚠️ GeminiAIProvider: JSON validation failed - attempting to parse anyway to see real error")
                NSLog("🔍 GeminiAIProvider: Last 200 characters: \(String(content.suffix(200)))")
                // Don't throw here - let the JSON parser give us the real error
            }
            
            // Parse the JSON content to extract variations
            let variations = try parseVariationsFromJSON(content)
            
            let processingTime = Date().timeIntervalSince(startTime)
            let metadata = GenerationMetadata(
                provider: providerName,
                modelVersion: "gemini-1.5-flash",
                processingTime: processingTime,
                confidence: 0.8
            )
            
            NSLog("✅ GeminiAIProvider: Successfully generated \(variations.count) variations in \(String(format: "%.2f", processingTime))s")
            
            return DesignVariationResponse(variations: variations, metadata: metadata)
            
        } catch let error as AIServiceError {
            throw error
        } catch {
            NSLog("❌ GeminiAIProvider: Unexpected error: \(error)")
            throw AIServiceError.networkError("Request failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    private func createDesignAnalysisPrompt(
        layers: [SimpleLayerData],
        canvasBounds: CanvasBounds,
        constraints: GenerationConstraints?
    ) -> String {
        let maxVariations = constraints?.maxVariations ?? 3
        
        // Separate visible and non-visible layers for clearer AI understanding
        let visibleLayers = layers.filter { $0.isVisible(within: canvasBounds) }
        let hiddenLayers = layers.filter { !$0.isVisible(within: canvasBounds) }
        
        let visibleLayerInfo = visibleLayers.map { layer in
            let x = round(layer.x * 100) / 100 // Round to 2 decimal places
            let y = round(layer.y * 100) / 100
            return "  • \(layer.id): \(layer.type) '\(layer.content)' at (\(x), \(y))"
        }.joined(separator: "\n")
        
        let hiddenLayerInfo = hiddenLayers.map { layer in
            let x = round(layer.x * 100) / 100
            let y = round(layer.y * 100) / 100
            let visibilityDesc = layer.visibilityDescription(within: canvasBounds)
            return "  • \(layer.id): \(layer.type) '\(layer.content)' at (\(x), \(y)) - \(visibilityDesc)"
        }.joined(separator: "\n")
        
        // Create the exact layer IDs that must be used in the response
        let exactLayerIds = layers.map { $0.id }
        let layerIdList = exactLayerIds.map { "\"\($0)\"" }.joined(separator: ", ")
        
        return """
        You are an expert graphic designer helping a client with a social media post. Your job is to take their current post and use your amazing skills to change it into something engaging and following the latest and best trends for social media posts. The Canvas is the image portion of the post so you are creating an image to be viewed based on the existing context. The variations you propose should be meanifully significantly different from the original and show different styles which the user might look to adopt.
        Create \(maxVariations) COMPLETELY DIFFERENT design variations for this salon cancellation policy:

        Canvas bounds: \(canvasBounds.width)x\(canvasBounds.height)
        
        VISIBLE LAYERS (currently on canvas):
        \(visibleLayerInfo.isEmpty ? "  • No layers currently visible" : visibleLayerInfo)
        
        \(hiddenLayers.isEmpty ? "" : """
        HIDDEN LAYERS (outside canvas view - consider moving these into view or replacing):
        \(hiddenLayerInfo)
        
        """)
        
        EXAMPLE THEME INSPIRATIONS (create your own unique content inspired by these styles):
        - Professional/Corporate: Formal language, business emojis (📋, 📞, ⏰), neutral positioning
        - Casual/Friendly: Conversational tone, fun emojis (🌈, 💜, ✨), relaxed positioning  
        - Luxury/Premium: Sophisticated language, elegant emojis (💎, 👑, 🏆), refined positioning
        
        LAYER MANAGEMENT OPTIONS:
        - MODIFY existing layers: Change content and position, but KEEP the same layer type
        - ADD new layers: Create additional elements with new IDs and appropriate types
        - REMOVE layers: Simply don't include layers you don't want in a variation
        - REPLACE layers: Remove old layer + Add new layer with same ID but different type
        
        VALIDATION RULES:
        ✅ VALID: {"type": "text", "content": "Welcome to Bella Salon"}
        ❌ INVALID: {"type": "text", "content": "gradient:blue,white"}
        ❌ INVALID: {"type": "text", "content": "icon:star"}
        
        ✅ VALID: {"type": "background", "content": "gradient:blue,white"}
        ✅ VALID: {"type": "background", "content": "solid:purple"}
        ❌ INVALID: {"type": "background", "content": "Welcome to Bella Salon"}
        
        ✅ VALID: {"type": "image", "content": "icon:star"}
        ❌ INVALID: {"type": "image", "content": "gradient:blue,white"}
        
        ✅ VALID: {"type": "shape", "content": "circle:red:50"}
        ❌ INVALID: {"type": "shape", "content": "Welcome to Bella Salon"}
        
        LAYER TYPE DEFINITIONS AND VALID CONTENT:
        
        1. TEXT LAYER (type: "text"):
           - Content: Plain text only
           - Examples: "Welcome to Bella Salon", "Call (555) 123-4567", "⚠️ Cancellation Policy"
           - Invalid: gradient:blue,white, icon:star, shape:circle:red
        
        2. BACKGROUND LAYER (type: "background"):
           - Content Format: "gradient:color1,color2" OR "solid:color"
           - Valid Colors: red, blue, green, yellow, orange, purple, pink, white, black, gray, brown, cyan, mint, teal, indigo, #FF0000
           - Examples: "gradient:blue,white", "gradient:#FF0000,#00FF00", "solid:purple"
           - Invalid: Plain text, icon:star, shape:circle:red
        
        3. IMAGE LAYER (type: "image"):
           - Content Format: "icon:systemIconName"
           - Valid Icons: star, star.fill, person.circle, phone.fill, photo, heart, crown, diamond, sparkles
           - Examples: "icon:star", "icon:person.circle", "icon:phone.fill"
           - Invalid: Plain text, gradient:blue,white, shape:circle:red
        
        4. SHAPE LAYER (type: "shape"):
           - Content Format: "shape:type:color" OR "type:color:size"
           - Valid Shapes: circle, rectangle, rect, square, star
           - Valid Colors: Same as background colors
           - Examples: "shape:circle:blue", "circle:red:50", "star:gold:30"
           - Invalid: Plain text, gradient:blue,white, icon:star
        
        LAYER TYPE CHANGES:
        If you want to change a text layer to a shape, REMOVE the original text layer and ADD a new shape layer with a different ID.
        
        CONTENT FORMAT SPECIFICATIONS:
        For BACKGROUND layers, use these content formats:
        - Gradient: "gradient:color1,color2" (e.g., "gradient:blue,green", "gradient:#FF0000,#00FF00")
        - Solid color: "solid:color" (e.g., "solid:red", "solid:#3498db")
        
        For SHAPE layers, use these content formats:
        - Circle: "circle:color:size" (e.g., "circle:blue:50", "circle:#FF5733:80")
        - Rectangle: "rectangle:color:size" (e.g., "rectangle:green:60", "rectangle:#2ECC71:100")
        - Star: "star:color:size" (e.g., "star:yellow:40", "star:#F1C40F:70")
        - Heart: "heart:color:size" (e.g., "heart:red:45", "heart:#E74C3C:65")
        
        For IMAGE layers, use these content formats:
        - System icon: "icon:name:color:size" (e.g., "icon:star:yellow:40", "icon:heart:red:50", "icon:phone:blue:35")
        - Available icons: star, heart, phone, envelope, house, person, camera, calendar, clock, car, airplane, globe, etc.
        
        For TEXT layers, use regular text content as usual.
        
        ID NAMING GUIDELINES:
        - MUST use these EXACT layer IDs for modifications: [\(layerIdList)]
        - You can omit layers you don't want in a variation (layer removal)
        - You can add new layers with descriptive IDs like: "contact-info", "decorative-border", "accent-text", "phone-number", etc.
        - Use kebab-case (words-separated-by-hyphens) for new layers only
        
        POSITION GUIDELINES:
        - Keep x values between 0 and \(canvasBounds.width)
        - Keep y values between 0 and \(canvasBounds.height)
        - Vary positions dramatically between variations
        - Consider visual hierarchy and readability
        
        VISIBILITY AWARENESS:
        - ONLY use coordinates that place content WITHIN the canvas bounds
        - Any layers currently off-canvas (hidden) should be repositioned to be visible OR replaced with appropriate content
        - Ensure critical information (policy text, contact info) is always positioned to be fully visible
        - Use the full canvas space effectively - don't cluster everything in one corner
        
        Requirements:
        1. Each variation must be DRAMATICALLY different in content, layout, and number of elements
        2. Create unique layer compositions - don't just copy the current structure
        3. Make each variation feel like a completely different designer created it
        4. Ensure all coordinates are within canvas bounds
        5. Each variation can have different numbers of layers (add/remove as needed)
        6. MATCH content type to layer type - text content for text layers, shape content for shape layers
        
        COMPLETE EXAMPLE:
        {
          "variations": [
            {
              "title": "Professional Design",
              "description": "Clean corporate style with proper type matching",
              "layers": [
                {"id": "background-gradient", "type": "background", "content": "gradient:blue,white", "x": 185, "y": 115},
                {"id": "title-text", "type": "text", "content": "Bella Salon", "x": 200, "y": 50},
                {"id": "main-policy-text", "type": "text", "content": "Cancellation policy applies", "x": 200, "y": 150},
                {"id": "phone-icon", "type": "image", "content": "icon:phone.fill", "x": 50, "y": 200},
                {"id": "decorative-star", "type": "shape", "content": "star:gold:25", "x": 300, "y": 180}
              ]
            }
          ]
        }
        
        WRONG EXAMPLE (DO NOT DO THIS):
        {"id": "title-text", "type": "text", "content": "gradient:blue,white"}  ❌ Type mismatch!
        {"id": "background-gradient", "type": "background", "content": "Welcome Text"}  ❌ Type mismatch!

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
                  "x": number_between_0_and_\(Int(canvasBounds.width)),
                  "y": number_between_0_and_\(Int(canvasBounds.height))
                }
              ]
            }
          ]
        }
        """
    }
    
    private func parseVariationsFromJSON(_ jsonString: String) throws -> [DesignVariation] {
        // Clean up any potential markdown formatting
        let cleanedJSON = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw AIServiceError.parseError("Could not convert response to data")
        }
        
        do {
            let decoder = JSONDecoder()
            let variationsWrapper = try decoder.decode(VariationsWrapper.self, from: jsonData)
            
            // Convert to DesignVariation objects
            let variations = variationsWrapper.variations.map { variation in
                DesignVariation(
                    title: variation.title,
                    description: variation.description,
                    layers: variation.layers
                )
            }
            
            return variations
            
        } catch {
            NSLog("❌ GeminiAIProvider: JSON parsing failed with error: \(error)")
            NSLog("📄 GeminiAIProvider: Error type: \(type(of: error))")
            if let decodingError = error as? DecodingError {
                NSLog("🔍 GeminiAIProvider: Decoding error details: \(decodingError)")
            }
            NSLog("📄 GeminiAIProvider: Cleaned JSON length: \(cleanedJSON.count)")
            NSLog("📄 GeminiAIProvider: First 500 chars: \(String(cleanedJSON.prefix(500)))")
            NSLog("📄 GeminiAIProvider: Last 500 chars: \(String(cleanedJSON.suffix(500)))")
            throw NSError(domain: "GeminiAIProvider", code: -4, userInfo: [NSLocalizedDescriptionKey: "JSON parsing failed: \(error.localizedDescription)"])
        }
    }
}

// MARK: - Gemini API Models

private struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

private struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
    let responseMimeType: String
}

private struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Codable {
    let content: GeminiContent
}

// MARK: - JSON Parsing Models

private struct VariationsWrapper: Codable {
    let variations: [VariationJSON]
}

private struct VariationJSON: Codable {
    let title: String
    let description: String
    let layers: [SimpleLayerData]
}
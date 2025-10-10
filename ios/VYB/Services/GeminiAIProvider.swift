import Foundation
import CoreGraphics

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
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    func configure(with configuration: AIProviderConfiguration) throws {
        guard let apiKey = configuration.apiKey, !apiKey.isEmpty else {
            throw AIServiceError.notConfigured
        }
        self.apiKey = apiKey
        NSLog("✅ GeminiAIProvider: Configured with API key")
    }
    
    func generateVariations(request: DesignVariationRequest) async throws -> DesignVariationResponse {
        let startTime = Date()
        
        guard let apiKey = apiKey else {
            throw AIServiceError.notConfigured
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
            
            // Parse the response
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            
            guard let content = geminiResponse.candidates.first?.content.parts.first?.text else {
                throw AIServiceError.parseError("No content in Gemini response")
            }
            
            NSLog("📄 GeminiAIProvider: Received response: \(content.prefix(200))...")
            
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
        
        // Round coordinates to prevent floating point precision issues and include visibility info
        let layerInfo = layers.map { layer in
            let x = round(layer.x * 100) / 100 // Round to 2 decimal places
            let y = round(layer.y * 100) / 100
            let visibility = layer.visibilityDescription(within: canvasBounds)
            return "Layer \(layer.id): \(layer.type) '\(layer.content)' at (\(x), \(y)) - \(visibility)"
        }.joined(separator: "\n")
        
        return """
        Analyze this design and create exactly \(maxVariations) distinct variations with comprehensive changes:

        CANVAS BOUNDS: width: \(canvasBounds.width), height: \(canvasBounds.height)
        - Visible area: (0, 0) to (\(canvasBounds.width), \(canvasBounds.height))

        CURRENT LAYERS:
        \(layerInfo)

        INSTRUCTIONS:
        1. Create exactly \(maxVariations) unique variations
        2. Each variation should modify multiple elements for visual impact
        3. Keep all layers within canvas bounds: (0, 0) to (\(canvasBounds.width), \(canvasBounds.height))
        4. Preserve layer IDs but can modify type, content, and position
        5. Each variation should have a distinct visual theme
        
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

        RESPOND WITH VALID JSON ONLY (no markdown, no explanations):
        {
            "variations": [
                {
                    "title": "Variation name",
                    "description": "Brief description of changes",
                    "layers": [
                        {
                            "id": "layer_id",
                            "type": "text|shape|image",
                            "content": "updated content",
                            "x": number_within_canvas,
                            "y": number_within_canvas
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
            NSLog("❌ GeminiAIProvider: JSON parsing failed: \(error)")
            NSLog("📄 GeminiAIProvider: Raw JSON: \(cleanedJSON)")
            throw AIServiceError.parseError("JSON parsing failed: \(error.localizedDescription)")
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
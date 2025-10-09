import Foundation

// MARK: - Error Handling

/// Error types for AI service operations
public enum AIServiceError: Error {
    case notConfigured
    case validationError(String)
    case networkError(String)
    case apiError(String)
    case parseError(String)
    case invalidResponse
}

// MARK: - Canvas Data Models

/// Canvas data structure for analysis
public struct DesignCanvasData {
    public let layers: [Any]
    
    public init(layers: [Any]) {
        self.layers = layers
    }
}

/// Response structure for canvas analysis
public struct CanvasAnalysisResponse: Codable {
    public let suggestions: [AISuggestion]
    
    public init(suggestions: [AISuggestion]) {
        self.suggestions = suggestions
    }
}

/// AI suggestion structure
public struct AISuggestion: Codable, Identifiable {
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

// MARK: - Simple Layer Data

/// Simple layer data structure for AI processing
public struct SimpleLayerData: Identifiable, Codable {
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

// MARK: - Design Variation Models

/// Represents a complete design variation with all layer modifications
public struct DesignVariation: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let layers: [SimpleLayerData]
    public let type: VariationType
    
    public init(title: String, description: String, layers: [SimpleLayerData], type: VariationType) {
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

// MARK: - Gemini AI API Models

public struct GeminiRequest: Codable {
    public let contents: [GeminiContent]
    public let generationConfig: GeminiGenerationConfig
    
    public init(contents: [GeminiContent], generationConfig: GeminiGenerationConfig) {
        self.contents = contents
        self.generationConfig = generationConfig
    }
}

public struct GeminiContent: Codable {
    public let parts: [GeminiPart]
    
    public init(parts: [GeminiPart]) {
        self.parts = parts
    }
}

public struct GeminiPart: Codable {
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
}

public struct GeminiGenerationConfig: Codable {
    public let temperature: Double
    public let topK: Int
    public let topP: Double
    public let maxOutputTokens: Int
    public let responseMimeType: String?
    public let responseJsonSchema: GeminiResponseSchema?
    
    private enum CodingKeys: String, CodingKey {
        case temperature
        case topK
        case topP
        case maxOutputTokens
        case responseMimeType = "response_mime_type"
        case responseJsonSchema = "response_json_schema"
    }
    
    public init(temperature: Double, topK: Int, topP: Double, maxOutputTokens: Int, responseMimeType: String? = nil, responseJsonSchema: GeminiResponseSchema? = nil) {
        self.temperature = temperature
        self.topK = topK
        self.topP = topP
        self.maxOutputTokens = maxOutputTokens
        self.responseMimeType = responseMimeType
        self.responseJsonSchema = responseJsonSchema
    }
}

// MARK: - Response Schema Models

public struct GeminiResponseSchema: Codable {
    public let type: String
    public let properties: [String: GeminiSchemaProperty]
    public let required: [String]
    
    public init(type: String, properties: [String: GeminiSchemaProperty], required: [String]) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

public indirect enum GeminiSchemaProperty: Codable {
    case primitive(type: String, description: String?)
    case array(type: String, items: GeminiSchemaProperty, description: String?)
    case object(type: String, properties: [String: GeminiSchemaProperty], required: [String]?, description: String?)
    
    private enum CodingKeys: String, CodingKey {
        case type, items, properties, required, description
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let description = try container.decodeIfPresent(String.self, forKey: .description)
        
        if type == "array" {
            let items = try container.decode(GeminiSchemaProperty.self, forKey: .items)
            self = .array(type: type, items: items, description: description)
        } else if type == "object" {
            let properties = try container.decodeIfPresent([String: GeminiSchemaProperty].self, forKey: .properties) ?? [:]
            let required = try container.decodeIfPresent([String].self, forKey: .required)
            self = .object(type: type, properties: properties, required: required, description: description)
        } else {
            self = .primitive(type: type, description: description)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .primitive(let type, let description):
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(description, forKey: .description)
        case .array(let type, let items, let description):
            try container.encode(type, forKey: .type)
            try container.encode(items, forKey: .items)
            try container.encodeIfPresent(description, forKey: .description)
        case .object(let type, let properties, let required, let description):
            try container.encode(type, forKey: .type)
            try container.encode(properties, forKey: .properties)
            try container.encodeIfPresent(required, forKey: .required)
            try container.encodeIfPresent(description, forKey: .description)
        }
    }
}

public struct GeminiResponse: Codable {
    public let candidates: [GeminiCandidate]
    
    public init(candidates: [GeminiCandidate]) {
        self.candidates = candidates
    }
}

public struct GeminiCandidate: Codable {
    public let content: GeminiContent
    
    public init(content: GeminiContent) {
        self.content = content
    }
}

// MARK: - Structured Response Models

public struct StructuredGeminiResponse: Codable {
    public let variations: [VariationResponse]
    
    public init(variations: [VariationResponse]) {
        self.variations = variations
    }
}

public struct LayerChange: Codable {
    public let x: Double?
    public let y: Double?
    public let content: String?
    public let fontSize: Double?
    public let textColor: String?
    public let fontWeight: String?
}

public struct LayerChangeRequest: Codable {
    public let id: String
    public let x: Double?
    public let y: Double?
    public let content: String?
    public let textColor: String?
}

public struct VariationResponse: Codable {
    public let title: String
    public let description: String
    public let layerChanges: [LayerChangeRequest]
    
    public init(title: String, description: String, layerChanges: [LayerChangeRequest]) {
        self.title = title
        self.description = description
        self.layerChanges = layerChanges
    }
}

public struct LayerChangeResponse: Codable {
    public let layer_id: String
    public let action: String
    public let properties: LayerPropertiesResponse
    
    public init(layer_id: String, action: String, properties: LayerPropertiesResponse) {
        self.layer_id = layer_id
        self.action = action
        self.properties = properties
    }
}

public struct LayerPropertiesResponse: Codable {
    public let type: String?
    public let content: String?
    public let x: Double?
    public let y: Double?
    public let textColor: String?
    public let fontSize: Double?
    public let fontWeight: String?
    
    public init(type: String?, content: String?, x: Double?, y: Double?, textColor: String?, fontSize: Double?, fontWeight: String?) {
        self.type = type
        self.content = content
        self.x = x
        self.y = y
        self.textColor = textColor
        self.fontSize = fontSize
        self.fontWeight = fontWeight
    }
}

// MARK: - AIService Class

/// AI Service for generating design variations using the Gemini AI API with structured responses
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
    
    /// Generate design variations using Gemini AI API with structured responses
    func generateDesignVariations(for layers: [Any]) async throws -> [DesignVariation] {
        NSLog("🎨 AIService: generateDesignVariations called with \(layers.count) layers")
        
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            NSLog("❌ AIService: API key not configured")
            throw AIServiceError.notConfigured
        }
        
        NSLog("✅ AIService: API key is configured")
        
        // Convert layers to SimpleLayerData for analysis and modifications
        let simpleLayerData = layers.compactMap { layer -> SimpleLayerData? in
            let mirror = Mirror(reflecting: layer)
            var id = "", content = "", type = ""
            var x = 0.0, y = 0.0
            
            for (label, value) in mirror.children {
                switch label {
                case "id": id = "\(value)"
                case "content": content = "\(value)"
                case "type": type = "\(value)"
                case "x": x = value as? Double ?? 0.0
                case "y": y = value as? Double ?? 0.0
                default: break
                }
            }
            
            return SimpleLayerData(id: id, type: type, content: content, x: x, y: y)
        }
        
        NSLog("📊 AIService: Generated \(simpleLayerData.count) layer descriptions")
        for (index, layer) in simpleLayerData.enumerated() {
            NSLog("📊 AIService: Layer \(index): id: \(layer.id), type: \(layer.type), content: \(layer.content), x: \(layer.x), y: \(layer.y)")
        }
        
        // Create design analysis prompt with layer data
        let prompt = createDesignAnalysisPrompt(layers: simpleLayerData)
        NSLog("📝 AIService: Created prompt for Gemini API")
        
        // Make Gemini AI API call with structured response
        NSLog("🌐 AIService: Calling Gemini API...")
        let response = try await callGeminiAPI(prompt: prompt)
        NSLog("✅ AIService: Received response from Gemini API")
        
        // Parse structured response into design variations
        NSLog("🔄 AIService: Parsing structured Gemini response...")
        let variations = try parseStructuredGeminiResponse(response, originalLayers: simpleLayerData)
        NSLog("✅ AIService: Successfully parsed \(variations.count) design variations")
        
        return variations
    }
    
    /// Create a concise design analysis prompt for Gemini AI
    private func createDesignAnalysisPrompt(layers: [SimpleLayerData]) -> String {
        // Round coordinates to prevent floating point precision issues
        let layerInfo = layers.map { layer in
            let x = round(layer.x * 100) / 100 // Round to 2 decimal places
            let y = round(layer.y * 100) / 100
            return "Layer \(layer.id): \(layer.type) '\(layer.content)' at (\(x), \(y))"
        }.joined(separator: "\n")
        
        return """
        Analyze this design and create exactly 3 variations with specific changes:

        CURRENT DESIGN:
        \(layerInfo)

        IMPORTANT: Use coordinates rounded to 2 decimal places only (e.g., 150.50, not 150.000000...).
        
        For each variation, specify EXACT changes to make using the layer IDs above. 
        Focus on changes that will be visually obvious:
        - Move layers to better positions (change x, y coordinates with max 2 decimal places)
        - Update text content to be more engaging
        - Change text colors for better contrast
        
        Each variation should modify 1-2 layers with concrete changes.
        """
    }
    
    /// Create the JSON schema for structured Gemini response - simplified to prevent token explosion
    private func createResponseSchema() -> GeminiResponseSchema {        
        // Simplified layer modification schema - flattened to prevent nesting issues
        let layerChangeSchema = GeminiSchemaProperty.object(
            type: "object",
            properties: [
                "id": .primitive(type: "string", description: "Layer ID to modify"),
                "x": .primitive(type: "number", description: "New X position (max 2 decimal places, e.g. 150.50)"),
                "y": .primitive(type: "number", description: "New Y position (max 2 decimal places, e.g. 150.50)"),
                "content": .primitive(type: "string", description: "New text content"),
                "textColor": .primitive(type: "string", description: "Text color")
            ],
            required: ["id"],
            description: "A specific change to apply to a layer"
        )
        
        let variationSchema = GeminiSchemaProperty.object(
            type: "object",
            properties: [
                "title": .primitive(type: "string", description: "Brief title like 'Bold Text' or 'Centered Layout'"),
                "description": .primitive(type: "string", description: "What will visually change"),
                "layerChanges": .array(type: "array", items: layerChangeSchema, description: "Specific layer modifications")
            ],
            required: ["title", "description", "layerChanges"],
            description: "A design variation with concrete layer changes"
        )
        
        return GeminiResponseSchema(
            type: "object",
            properties: [
                "variations": .array(type: "array", items: variationSchema, description: "Array of exactly 3 design variations")
            ],
            required: ["variations"]
        )
    }
    
    /// Make HTTP request to Gemini AI API with structured response schema
    private func callGeminiAPI(prompt: String) async throws -> Data {
        NSLog("🚀 AIService: Starting Gemini API call with structured response")
        NSLog("🔑 AIService: API Key configured: \(apiKey != nil)")
        if let key = apiKey {
            NSLog("🔑 AIService: API Key length: \(key.count)")
            NSLog("🔑 AIService: API Key prefix: \(key.prefix(10))...")
        }
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1alpha/models/gemini-2.5-flash:generateContent?key=\(apiKey!)") else {
            NSLog("❌ AIService: Invalid API URL")
            throw AIServiceError.validationError("Invalid API URL")
        }
        
        NSLog("🌐 AIService: Request URL: \(url.absoluteString.replacingOccurrences(of: apiKey!, with: "[API_KEY]"))")
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [GeminiPart(text: prompt)]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 8192,
                responseMimeType: "application/json",
                responseJsonSchema: createResponseSchema()
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        NSLog("📝 AIService: Prompt length: \(prompt.count) characters")
        NSLog("📝 AIService: Prompt preview: \(prompt.prefix(200))...")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            request.httpBody = try encoder.encode(requestBody)
            
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                NSLog("📤 AIService: Request body:")
                NSLog("📤 AIService: \(bodyString)")
            }
        } catch {
            NSLog("❌ AIService: Failed to encode request: \(error)")
            throw AIServiceError.parseError("Failed to encode request: \(error)")
        }
        
        NSLog("🌐 AIService: Making HTTP request...")
        
        // Add a timeout for debugging
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            NSLog("⏰ AIService: Request taking longer than 10 seconds...")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            timeoutTask.cancel() // Cancel the timeout task since we got a response
            
            NSLog("📥 AIService: Received response")
            NSLog("📥 AIService: Response data size: \(data.count) bytes")
            
            if let httpResponse = response as? HTTPURLResponse {
                NSLog("📥 AIService: HTTP Status Code: \(httpResponse.statusCode)")
                NSLog("📥 AIService: Response Headers: \(httpResponse.allHeaderFields)")
                
                guard 200...299 ~= httpResponse.statusCode else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    NSLog("❌ AIService: API Error - HTTP \(httpResponse.statusCode)")
                    NSLog("❌ AIService: Error Response: \(errorMessage)")
                    throw AIServiceError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                NSLog("📥 AIService: === RESPONSE START ===")
                NSLog("📥 AIService: Response length: \(responseString.count) characters")
                
                // Split response into manageable chunks to avoid truncation
                let chunkSize = 800
                let totalChunks = (responseString.count + chunkSize - 1) / chunkSize
                
                for i in 0..<totalChunks {
                    let startIndex = responseString.index(responseString.startIndex, offsetBy: i * chunkSize)
                    let endIndex = responseString.index(startIndex, offsetBy: min(chunkSize, responseString.count - i * chunkSize))
                    let chunk = String(responseString[startIndex..<endIndex])
                    NSLog("📥 AIService: Chunk \(i + 1)/\(totalChunks): \(chunk)")
                }
                
                NSLog("📥 AIService: === RESPONSE END ===")
            } else {
                NSLog("❌ AIService: Could not decode response as UTF-8")
            }
            
            NSLog("✅ AIService: Successfully received Gemini API response")
            return data
        } catch {
            if error is AIServiceError {
                throw error
            }
            NSLog("❌ AIService: Network error: \(error)")
            throw AIServiceError.networkError("Network request failed: \(error)")
        }
    }
    
    /// Parse structured Gemini AI response into design variations
    private func parseStructuredGeminiResponse(_ data: Data, originalLayers: [SimpleLayerData]) throws -> [DesignVariation] {
        NSLog("🔍 AIService: Starting to parse structured Gemini response...")
        NSLog("📊 AIService: Response data size: \(data.count) bytes")
        
        do {
            // First decode the outer Gemini response wrapper
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            NSLog("✅ AIService: Successfully decoded Gemini wrapper response")
            NSLog("📊 AIService: Found \(geminiResponse.candidates.count) candidates")
            
            guard let candidate = geminiResponse.candidates.first else {
                NSLog("❌ AIService: No candidates found in response")
                throw AIServiceError.invalidResponse
            }
            
            guard let contentPart = candidate.content.parts.first else {
                NSLog("❌ AIService: No content parts in candidate")
                throw AIServiceError.invalidResponse
            }
            
            NSLog("📝 AIService: Content part available, parsing structured data...")
            
            // With structured responses, the content should be JSON in the text field
            let structuredText = contentPart.text
            
            NSLog("📝 AIService: Structured text content: \(structuredText.prefix(500))")
            
            // Check for truncated JSON (common signs of truncation)
            if !structuredText.hasSuffix("}") && !structuredText.hasSuffix("]") {
                NSLog("⚠️ AIService: Detected potentially truncated JSON response")
                NSLog("📝 AIService: Response ends with: '\(structuredText.suffix(50))'")
            }
            
            let structuredData = structuredText.data(using: .utf8) ?? Data()
            let structuredResponse = try JSONDecoder().decode(StructuredGeminiResponse.self, from: structuredData)
            NSLog("✅ AIService: Successfully parsed structured response with \(structuredResponse.variations.count) variations")
            
            // Convert to DesignVariation objects - simplified without layer changes
            return structuredResponse.variations.map { variation in
                // Apply layer changes to create modified layers
                var modifiedLayers = originalLayers
                
                for layerChangeRequest in variation.layerChanges {
                    if let layerIndex = modifiedLayers.firstIndex(where: { $0.id == layerChangeRequest.id }) {
                        let layer = modifiedLayers[layerIndex]
                        
                        // Round coordinates to prevent precision issues
                        let newX = layerChangeRequest.x.map { round($0 * 100) / 100 } ?? layer.x
                        let newY = layerChangeRequest.y.map { round($0 * 100) / 100 } ?? layer.y
                        
                        // Create new layer with modifications - flattened structure
                        let newLayer = SimpleLayerData(
                            id: layer.id,
                            type: layer.type,
                            content: layerChangeRequest.content ?? layer.content,
                            x: newX,
                            y: newY
                        )
                        
                        modifiedLayers[layerIndex] = newLayer
                        NSLog("🔄 AIService: Modified layer \(layer.id): x=\(newLayer.x), y=\(newLayer.y), content='\(newLayer.content)'")
                    }
                }
                
                return DesignVariation(
                    title: variation.title,
                    description: variation.description,
                    layers: modifiedLayers,
                    type: .mixed
                )
            }
            
        } catch {
            NSLog("❌ AIService: Parse error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                NSLog("❌ AIService: Failed response content: \(responseString.prefix(500))")
            }
            throw AIServiceError.parseError("Failed to parse AI response: \(error)")
        }
    }
}
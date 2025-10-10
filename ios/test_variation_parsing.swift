#!/usr/bin/env swift

import Foundation
import FoundationModels

if #available(iOS 26.0, *) {
    let session = LanguageModelSession(model: SystemLanguageModel())
    
    // Use a prompt similar to what the app uses
    let prompt = """
    Analyze this design and create exactly 3 distinct variations with comprehensive changes:

    Canvas bounds: 400.0x250.0
    Current layers:
    Layer background-gradient: background 'Salon Background' at (200.0, 250.0) - visible
    Layer title-text: text '🚫 Cancellation Policy ⚠️' at (200.0, 60.0) - visible
    Layer main-policy-text: text 'A 50% fee will apply for no-shows or cancellations made within 3 hours of your appointment.' at (200.0, 180.0) - visible
    Layer subtitle-text: text 'Thank you for understanding — this helps us manage our time and continue providing the best service. ❤️' at (200.0, 320.0) - out of bounds
    Layer bella-salon-logo: text '✨ Bella Salon ✨' at (200.0, 420.0) - out of bounds

    CRITICAL: You MUST use these EXACT layer IDs in your response: "background-gradient", "title-text", "main-policy-text", "subtitle-text", "bella-salon-logo"
    
    Requirements:
    1. Keep all layers within canvas bounds (0,0) to (400.0,250.0)
    2. MUST use the exact layer IDs provided above - do not create new IDs
    3. Create visually distinct variations with different themes
    4. Each variation should modify content and positions of existing layers
    5. Each variation should have a distinct visual theme

    RESPOND WITH VALID JSON ONLY (no markdown, no explanations):
    {
      "variations": [
        {
          "title": "variation name",
          "description": "brief description",
          "layers": [
            {
              "id": "background-gradient",
              "type": "background",
              "content": "modified content",
              "x": number,
              "y": number
            },
            {
              "id": "title-text", 
              "type": "text",
              "content": "modified content",
              "x": number,
              "y": number
            },
            {
              "id": "main-policy-text",
              "type": "text", 
              "content": "modified content",
              "x": number,
              "y": number
            },
            {
              "id": "subtitle-text",
              "type": "text",
              "content": "modified content", 
              "x": number,
              "y": number
            },
            {
              "id": "bella-salon-logo",
              "type": "text",
              "content": "modified content",
              "x": number,
              "y": number
            }
          ]
        }
      ]
    }
    """
    
    print("🧠 Testing Foundation Models with explicit layer ID instructions...")
    print("🧠 Sending prompt...")
    
    Task {
        do {
            let response = try await session.respond(to: prompt)
            let responseText = response.content
            
            print("🧠 ===============================================")
            print("🧠 FOUNDATION MODELS RESPONSE:")
            print("🧠 LENGTH: \(responseText.count) characters")
            print("🧠 ===============================================")
            print(responseText)
            print("🧠 ===============================================")
            
            // Try to parse and see structure
            var cleanedResponse = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanedResponse.hasPrefix("```json") {
                cleanedResponse = String(cleanedResponse.dropFirst(7))
            }
            if cleanedResponse.hasSuffix("```") {
                cleanedResponse = String(cleanedResponse.dropLast(3))
            }
            cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let jsonData = cleanedResponse.data(using: .utf8),
               let jsonResponse = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let variationsArray = jsonResponse["variations"] as? [[String: Any]] {
                
                print("🧠 PARSED \(variationsArray.count) VARIATIONS:")
                for (index, variation) in variationsArray.enumerated() {
                    if let title = variation["title"] as? String,
                       let description = variation["description"] as? String,
                       let layers = variation["layers"] as? [[String: Any]] {
                        print("🧠 Variation \(index + 1): '\(title)' - \(description)")
                        print("🧠   Layers: \(layers.count)")
                        for layer in layers {
                            if let id = layer["id"] as? String,
                               let content = layer["content"] as? String {
                                print("🧠     \(id): '\(content)'")
                            }
                        }
                    }
                }
            } else {
                print("🚨 FAILED TO PARSE JSON")
            }
            
        } catch {
            print("🚨 Error: \(error)")
        }
    }
    
    // Keep the script running
    RunLoop.main.run()
} else {
    print("🚨 Foundation Models not available")
}
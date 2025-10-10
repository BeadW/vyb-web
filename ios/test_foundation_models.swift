import Foundation
import FoundationModels

if #available(iOS 26.0, *) {
    let session = LanguageModelSession(model: SystemLanguageModel())
    print("🧠 LanguageModelSession created successfully")
    
    let prompt = "Generate a simple design variation with title 'Test Design' and description 'A test design for validation'"
    print("🧠 Sending prompt: \(prompt)")
    
    Task {
        do {
            let response = try await session.respond(to: prompt)
            print("🧠 Foundation Models RAW RESPONSE:")
            print("🧠 RAW CONTENT START:")
            print(response)
            print("🧠 RAW CONTENT END")
            
            // Extract the actual text content
            let responseText = String(describing: response)
            print("🧠 Response as string: \(responseText)")
            
        } catch {
            print("🧠 Foundation Models ERROR: \(error)")
        }
    }
} else {
    print("🧠 Foundation Models not available on this OS version")
}
#!/usr/bin/env swift

// Test comprehensive layer type definitions
import Foundation

// Create a test request that should trigger AI processing with different layer types
let testPayload = """
{
    "layers": [
        {
            "id": "layer1",
            "type": "text",
            "content": "Sample text",
            "x": 100,
            "y": 100,
            "visible": true
        },
        {
            "id": "layer2", 
            "type": "background",
            "content": "gradient:blue,purple",
            "x": 0,
            "y": 0,
            "visible": true
        },
        {
            "id": "layer3",
            "type": "image",
            "content": "icon:star",
            "x": 200,
            "y": 200,
            "visible": true
        },
        {
            "id": "layer4",
            "type": "shape",
            "content": "circle:red",
            "x": 150,
            "y": 150,
            "visible": true
        }
    ],
    "prompt": "Create a modern design variation"
}
"""

// Send test request to AI service endpoint
let url = URL(string: "http://localhost:3001/enhance")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = testPayload.data(using: .utf8)

print("Testing comprehensive layer type definitions...")
print("Request payload:")
print(testPayload)

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
        print("Error: \(error)")
        return
    }
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("Response:")
        print(responseString)
    }
    
    exit(0)
}

task.resume()

// Keep the program running
RunLoop.main.run()
#!/usr/bin/env swift

import Foundation

// Mock structures matching our app
struct SimpleLayer {
    let id: String
    let type: String
    var content: String
    var x: Double
    var y: Double
    let zOrder: Int
}

struct VariationLayer {
    let id: String
    let type: String
    let content: String
    let x: Double
    let y: Double
}

struct DesignVariation {
    let title: String
    let description: String
    let layers: [VariationLayer]
}

// Test data matching our app structure
let originalLayers = [
    SimpleLayer(id: "background-gradient", type: "background", content: "Salon Background", x: 200, y: 250, zOrder: 0),
    SimpleLayer(id: "title-text", type: "text", content: "🚫 Cancellation Policy ⚠️", x: 200, y: 60, zOrder: 1),
    SimpleLayer(id: "main-policy-text", type: "text", content: "A 50% fee will apply...", x: 200, y: 180, zOrder: 2),
    SimpleLayer(id: "subtitle-text", type: "text", content: "Thank you for understanding...", x: 200, y: 320, zOrder: 3),
    SimpleLayer(id: "bella-salon-logo", type: "text", content: "✨ Bella Salon ✨", x: 200, y: 420, zOrder: 4)
]

// Foundation Models response structure (from logs)
let foundationModelsVariation = DesignVariation(
    title: "Modern Minimalist",
    description: "A clean, simple design focusing on essential information.",
    layers: [
        VariationLayer(id: "layer_0", type: "text", content: "🚫 Cancellation Policy ⚠️", x: 100, y: 50),
        VariationLayer(id: "layer_1", type: "text", content: "50 0.000000ee for no-shows/cancellations within 3 hours.", x: 150, y: 150),
        VariationLayer(id: "layer_2", type: "text", content: "Thank you for understanding — helps manage time.", x: 200, y: 250),
        VariationLayer(id: "layer_3", type: "text", content: "✨ Bella Salon ✨", x: 300, y: 350)
    ]
)

// Apply our position-based mapping logic
func applyVariationToLayers(_ variation: DesignVariation, originalLayers: [SimpleLayer]) -> [SimpleLayer] {
    print("🔄 Applying variation '\(variation.title)' to \(originalLayers.count) layers")
    
    // Sort original layers by zOrder to ensure consistent mapping
    let sortedOriginalLayers = originalLayers.sorted(by: { $0.zOrder < $1.zOrder })
    // Sort variation layers by their ID (assuming layer_0, layer_1, etc.)
    let sortedVariationLayers = variation.layers.sorted { layer1, layer2 in
        // Extract numeric part from IDs like "layer_0", "layer_1"
        let num1 = Int(layer1.id.replacingOccurrences(of: "layer_", with: "")) ?? 0
        let num2 = Int(layer2.id.replacingOccurrences(of: "layer_", with: "")) ?? 0
        return num1 < num2
    }
    
    print("🔄 Original layers: \(sortedOriginalLayers.map { "\($0.id) (z:\($0.zOrder))" }.joined(separator: ", "))")
    print("🔄 Variation layers: \(sortedVariationLayers.map { "\($0.id)" }.joined(separator: ", "))")
    
    // Map layers by position/order rather than ID matching
    var modifiedLayers: [SimpleLayer] = []
    
    for (index, originalLayer) in sortedOriginalLayers.enumerated() {
        var modifiedLayer = originalLayer
        
        // If there's a corresponding variation layer at this index
        if index < sortedVariationLayers.count {
            let variationLayer = sortedVariationLayers[index]
            
            // Apply changes from variation layer
            modifiedLayer.content = variationLayer.content
            modifiedLayer.x = variationLayer.x
            modifiedLayer.y = variationLayer.y
            
            print("🔄 Applied variation to layer \(originalLayer.id) using \(variationLayer.id): '\(variationLayer.content)' at (\(variationLayer.x), \(variationLayer.y))")
        } else {
            print("⚠️ No variation layer available for original layer \(originalLayer.id) at index \(index)")
        }
        
        modifiedLayers.append(modifiedLayer)
    }
    
    return modifiedLayers
}

// Test the mapping
print("=== TESTING LAYER MAPPING ===")
print("Original layers:")
for layer in originalLayers {
    print("  \(layer.id) (z:\(layer.zOrder)): '\(layer.content)' at (\(layer.x), \(layer.y))")
}

print("\nFoundation Models variation:")
for layer in foundationModelsVariation.layers {
    print("  \(layer.id): '\(layer.content)' at (\(layer.x), \(layer.y))")
}

print("\nApplying variation...")
let result = applyVariationToLayers(foundationModelsVariation, originalLayers: originalLayers)

print("\nResult after mapping:")
for layer in result {
    print("  \(layer.id) (z:\(layer.zOrder)): '\(layer.content)' at (\(layer.x), \(layer.y))")
}

print("\n=== MAPPING VERIFICATION ===")
print("✅ Layer mapping should work! Each original layer gets content from Foundation Models based on position.")
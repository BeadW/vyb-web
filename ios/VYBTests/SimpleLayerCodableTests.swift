import XCTest
import SwiftUI
@testable import VYB

final class SimpleLayerCodableTests: XCTestCase {
    
    func testSimpleLayerJSONEncoding() throws {
        // Given
        let layer = SimpleLayer(
            id: "test-layer-1",
            type: "text",
            content: "Hello World",
            x: 100.0,
            y: 200.0,
            zOrder: 1
        )
        
        // When
        let jsonData = try JSONEncoder().encode(layer)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"id\":\"test-layer-1\""))
        XCTAssertTrue(jsonString!.contains("\"type\":\"text\""))
        XCTAssertTrue(jsonString!.contains("\"content\":\"Hello World\""))
        XCTAssertTrue(jsonString!.contains("\"x\":100"))
        XCTAssertTrue(jsonString!.contains("\"y\":200"))
        XCTAssertTrue(jsonString!.contains("\"zOrder\":1"))
        
        print("✅ Encoded JSON: \(jsonString!)")
    }
    
    func testSimpleLayerJSONDecoding() throws {
        // Given
        let jsonString = """
        {
            "id": "decoded-layer",
            "type": "text",
            "content": "Decoded Text",
            "x": 50.5,
            "y": 75.0,
            "zOrder": 2,
            "fontSize": 24,
            "fontWeight": "bold",
            "textColor": "Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0)",
            "isItalic": true,
            "textAlignment": "center"
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let decodedLayer = try JSONDecoder().decode(SimpleLayer.self, from: jsonData)
        
        // Then
        XCTAssertEqual(decodedLayer.id, "decoded-layer")
        XCTAssertEqual(decodedLayer.type, "text")
        XCTAssertEqual(decodedLayer.content, "Decoded Text")
        XCTAssertEqual(decodedLayer.x, 50.5)
        XCTAssertEqual(decodedLayer.y, 75.0)
        XCTAssertEqual(decodedLayer.zOrder, 2)
        XCTAssertEqual(decodedLayer.fontSize, 24)
        XCTAssertEqual(decodedLayer.fontWeight, .bold)
        XCTAssertEqual(decodedLayer.isItalic, true)
        XCTAssertEqual(decodedLayer.textAlignment, .center)
        
        print("✅ Decoded layer: \(decodedLayer.content)")
    }
    
    func testSimpleLayerRoundTripSerialization() throws {
        // Given
        let originalLayer = SimpleLayer(
            id: "roundtrip-test",
            type: "text",
            content: "Round Trip Test",
            x: 123.45,
            y: 678.90,
            zOrder: 5
        )
        
        // When - Encode then decode
        let jsonData = try JSONEncoder().encode(originalLayer)
        let decodedLayer = try JSONDecoder().decode(SimpleLayer.self, from: jsonData)
        
        // Then - Should match original
        XCTAssertEqual(originalLayer.id, decodedLayer.id)
        XCTAssertEqual(originalLayer.type, decodedLayer.type)
        XCTAssertEqual(originalLayer.content, decodedLayer.content)
        XCTAssertEqual(originalLayer.x, decodedLayer.x)
        XCTAssertEqual(originalLayer.y, decodedLayer.y)
        XCTAssertEqual(originalLayer.zOrder, decodedLayer.zOrder)
        XCTAssertEqual(originalLayer.fontSize, decodedLayer.fontSize)
        XCTAssertEqual(originalLayer.fontWeight, decodedLayer.fontWeight)
        XCTAssertEqual(originalLayer.textAlignment, decodedLayer.textAlignment)
        
        print("✅ Round trip serialization successful")
    }
    
    func testSimpleLayerArraySerialization() throws {
        // Given - Multiple layers for AI API payload
        let layers = [
            SimpleLayer(id: "layer-1", type: "text", content: "Title", x: 50, y: 100, zOrder: 1),
            SimpleLayer(id: "layer-2", type: "text", content: "Subtitle", x: 50, y: 150, zOrder: 2),
            SimpleLayer(id: "layer-3", type: "image", content: "logo.png", x: 200, y: 50, zOrder: 0)
        ]
        
        // When
        let jsonData = try JSONEncoder().encode(layers)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"id\":\"layer-1\""))
        XCTAssertTrue(jsonString!.contains("\"id\":\"layer-2\""))
        XCTAssertTrue(jsonString!.contains("\"id\":\"layer-3\""))
        XCTAssertTrue(jsonString!.contains("\"type\":\"image\""))
        
        // Decode back
        let decodedLayers = try JSONDecoder().decode([SimpleLayer].self, from: jsonData)
        XCTAssertEqual(decodedLayers.count, 3)
        XCTAssertEqual(decodedLayers[0].content, "Title")
        XCTAssertEqual(decodedLayers[1].content, "Subtitle")
        XCTAssertEqual(decodedLayers[2].type, "image")
        
        print("✅ Array serialization successful: \(decodedLayers.count) layers")
    }
}
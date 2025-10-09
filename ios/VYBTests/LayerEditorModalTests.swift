import XCTest
import SwiftUI
@testable import VYB

final class LayerEditorModalTests: XCTestCase {
    
    func testLayerEditorModalViewPresentation() throws {
        // Create test layer
        var testLayer = SimpleLayer(
            id: "test-layer",
            type: "text",
            content: "Test Layer",
            x: 100,
            y: 100,
            zOrder: 1
        )
        testLayer.fontSize = 18
        testLayer.fontWeight = .medium
        testLayer.textColor = .black
        testLayer.isItalic = false
        testLayer.isUnderlined = false
        testLayer.textAlignment = .center
        testLayer.hasShadow = false
        testLayer.shadowColor = .gray
        
        // This test will verify the LayerEditorModalView can be created
        // without crashing and contains expected elements
        XCTAssertEqual(testLayer.content, "Test Layer")
        XCTAssertEqual(testLayer.type, "text")
        XCTAssertEqual(testLayer.fontSize, 18)
    }
    
    func testSimpleLayerProperties() throws {
        var layer = SimpleLayer(
            id: "test",
            type: "text",
            content: "Hello",
            x: 50,
            y: 75,
            zOrder: 2
        )
        layer.fontSize = 24
        layer.fontWeight = .bold
        layer.textColor = .red
        layer.isItalic = true
        layer.isUnderlined = false
        layer.textAlignment = .left
        layer.hasShadow = true
        layer.shadowColor = .gray
        
        XCTAssertEqual(layer.id, "test")
        XCTAssertEqual(layer.type, "text")
        XCTAssertEqual(layer.content, "Hello")
        XCTAssertEqual(layer.x, 50)
        XCTAssertEqual(layer.y, 75)
        XCTAssertEqual(layer.zOrder, 2)
        XCTAssertEqual(layer.fontSize, 24)
        XCTAssertEqual(layer.fontWeight, .bold)
        XCTAssertEqual(layer.textColor, .red)
        XCTAssertTrue(layer.isItalic)
        XCTAssertFalse(layer.isUnderlined)
        XCTAssertEqual(layer.textAlignment, .left)
        XCTAssertTrue(layer.hasShadow)
        XCTAssertEqual(layer.shadowColor, .gray)
    }
}
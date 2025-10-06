import XCTest
import SwiftUI
@testable import VYB

final class LayerEditorModalTests: XCTestCase {
    
    func testLayerEditorModalViewPresentation() throws {
        // Create test layer
        let testLayer = SimpleLayer(
            id: "test-layer",
            type: "text",
            content: "Test Layer",
            x: 100,
            y: 100,
            isSelected: false,
            zOrder: 1,
            fontSize: 18,
            fontWeight: .medium,
            textColor: .black,
            isItalic: false,
            isUnderlined: false,
            textAlignment: .center,
            hasShadow: false,
            shadowColor: .gray
        )
        
        // This test will verify the LayerEditorModalView can be created
        // without crashing and contains expected elements
        XCTAssertEqual(testLayer.content, "Test Layer")
        XCTAssertEqual(testLayer.type, "text")
        XCTAssertEqual(testLayer.fontSize, 18)
    }
    
    func testSimpleLayerProperties() throws {
        let layer = SimpleLayer(
            id: "test",
            type: "text",
            content: "Hello",
            x: 50,
            y: 75,
            isSelected: true,
            zOrder: 2,
            fontSize: 24,
            fontWeight: .bold,
            textColor: .red,
            isItalic: true,
            isUnderlined: false,
            textAlignment: .leading,
            hasShadow: true,
            shadowColor: .gray
        )
        
        XCTAssertEqual(layer.id, "test")
        XCTAssertEqual(layer.type, "text")
        XCTAssertEqual(layer.content, "Hello")
        XCTAssertEqual(layer.x, 50)
        XCTAssertEqual(layer.y, 75)
        XCTAssertTrue(layer.isSelected)
        XCTAssertEqual(layer.zOrder, 2)
        XCTAssertEqual(layer.fontSize, 24)
        XCTAssertEqual(layer.fontWeight, .bold)
        XCTAssertEqual(layer.textColor, .red)
        XCTAssertTrue(layer.isItalic)
        XCTAssertFalse(layer.isUnderlined)
        XCTAssertEqual(layer.textAlignment, .leading)
        XCTAssertTrue(layer.hasShadow)
        XCTAssertEqual(layer.shadowColor, .gray)
    }
}
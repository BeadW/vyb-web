import XCTest
@testable import VYB

class SVGLayerModelTests: XCTestCase {
    
    func testSVGTransformStringGeneration() {
        let transform = SVGTransform(x: 100, y: 200, scaleX: 1.5, scaleY: 1.5, rotation: 45, opacity: 0.8)
        
        let svgString = transform.svgTransformString
        
        XCTAssertTrue(svgString.contains("translate(100.0, 200.0)"))
        XCTAssertTrue(svgString.contains("rotate(45.0 100.0 200.0)"))
        XCTAssertTrue(svgString.contains("scale(1.5, 1.5)"))
    }
    
    func testDropShadowFilterId() {
        let dropShadow = DropShadowStyle(offsetX: 2, offsetY: 2, blur: 4, spread: 0, color: "#000000")
        
        let filterId = dropShadow.svgFilterId
        
        XCTAssertTrue(filterId.starts(with: "drop-shadow-"))
        XCTAsserts(filterId.count > 12) // More than just the prefix
    }
    
    func testSVGLayerCreation() {
        let textLayer = SVGLayer.createTextLayer(
            text: "Hello SVG",
            x: 50,
            y: 100,
            fontSize: 18,
            color: "#FF0000"
        )
        
        XCTAssertEqual(textLayer.type, .text)
        XCTAssertEqual(textLayer.content.text, "Hello SVG")
        XCTAssertEqual(textLayer.content.fontSize, 18)
        XCTAssertEqual(textLayer.content.textColor, "#FF0000")
        XCTAssertEqual(textLayer.transform.x, 50)
        XCTAssertEqual(textLayer.transform.y, 100)
    }
    
    func testRectangleLayerCreation() {
        let rectLayer = SVGLayer.createRectangleLayer(
            x: 25,
            y: 25,
            width: 150,
            height: 75,
            fill: "#00FF00"
        )
        
        XCTAssertEqual(rectLayer.type, .shape)
        XCTAssertEqual(rectLayer.content.shapeType, .rectangle)
        XCTAssertEqual(rectLayer.content.fill, "#00FF00")
        XCTAssertEqual(rectLayer.content.width, 150)
        XCTAssertEqual(rectLayer.content.height, 75)
    }
    
    func testCircleLayerCreation() {
        let circleLayer = SVGLayer.createCircleLayer(
            x: 100,
            y: 100,
            radius: 60,
            fill: "#0000FF"
        )
        
        XCTAssertEqual(circleLayer.type, .shape)
        XCTAssertEqual(circleLayer.content.shapeType, .circle)
        XCTAssertEqual(circleLayer.content.fill, "#0000FF")
        XCTAssertEqual(circleLayer.content.width, 120) // radius * 2
        XCTAssertEqual(circleLayer.content.height, 120)
    }
    
    func testGradientStyle() {
        let gradient = GradientStyle.blueToGreen
        
        XCTAssertEqual(gradient.type, .linear)
        XCTAssertEqual(gradient.angle, 45)
        XCTAssertEqual(gradient.stops.count, 2)
        XCTAssertEqual(gradient.stops[0].color, "#007AFF")
        XCTAssertEqual(gradient.stops[1].color, "#34C759")
        
        let gradientId = gradient.svgGradientId
        XCTAssertTrue(gradientId.starts(with: "gradient-"))
    }
    
    func testLayerConstraints() {
        var constraints = SVGLayerConstraints()
        
        // Test default values
        XCTAssertFalse(constraints.locked)
        XCTAssertTrue(constraints.visible)
        XCTAssertFalse(constraints.lockPosition)
        XCTAssertFalse(constraints.lockSize)
        XCTAssertFalse(constraints.lockRotation)
        XCTAssertFalse(constraints.lockContent)
        XCTAssertFalse(constraints.lockStyle)
        
        // Test AI protection locks
        constraints.lockPosition = true
        constraints.lockContent = true
        
        XCTAssertTrue(constraints.lockPosition)
        XCTAssertTrue(constraints.lockContent)
        XCTAssertFalse(constraints.lockSize) // Should remain false
    }
    
    func testStrokeStyle() {
        let stroke = StrokeStyle(color: "#FF0000", width: 2.5, dashArray: [5, 5])
        
        let svgString = stroke.svgStrokeString
        
        XCTAssertTrue(svgString.contains("stroke=\"#FF0000\""))
        XCTAssertTrue(svgString.contains("stroke-width=\"2.5\""))
        XCTAssertTrue(svgString.contains("stroke-dasharray=\"5.0,5.0\""))
    }
    
    func testImageFilters() {
        let filters = ImageFilters(brightness: 1.2, contrast: 1.1, saturation: 0.8, blur: 2.0)
        
        let filterId = filters.svgFilterId
        
        XCTAssertNotNil(filterId)
        XCTAssertTrue(filterId!.starts(with: "image-filter-"))
        
        // Test nil case
        let noFilters = ImageFilters()
        XCTAssertNil(noFilters.svgFilterId)
    }
    
    func testGroupLayer() {
        let childIds = ["layer-1", "layer-2", "layer-3"]
        let groupLayer = SVGLayer.createGroupLayer(childLayerIds: childIds, name: "Test Group")
        
        XCTAssertEqual(groupLayer.type, .group)
        XCTAssertEqual(groupLayer.content.childLayerIds, childIds)
        XCTAssertEqual(groupLayer.content.groupName, "Test Group")
    }
}

// Fix for the typo in test
extension SVGLayerModelTests {
    func XCTAsserts(_ condition: Bool, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(condition, file: file, line: line)
    }
}
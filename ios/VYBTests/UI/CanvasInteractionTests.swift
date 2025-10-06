import XCTest
@testable import VYB

class CanvasInteractionTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Canvas Creation and Basic Interaction
    
    func testCanvasCreationWithDeviceSelection() throws {
        // Navigate to canvas creation
        let createButton = app.buttons["Create New Design"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()
        
        // Select iPhone 15 Pro device simulation
        let deviceSelector = app.buttons["Device Selector"]
        XCTAssertTrue(deviceSelector.waitForExistence(timeout: 3))
        deviceSelector.tap()
        
        let iPhone15Pro = app.buttons["iPhone 15 Pro"]
        XCTAssertTrue(iPhone15Pro.waitForExistence(timeout: 3))
        iPhone15Pro.tap()
        
        // Verify canvas appears with correct dimensions
        let canvasView = app.otherElements["Canvas View"]
        XCTAssertTrue(canvasView.waitForExistence(timeout: 5))
        
        // Check canvas bounds match iPhone 15 Pro specifications
        let canvasFrame = canvasView.frame
        XCTAssertEqual(canvasFrame.width, 393, accuracy: 1.0, "Canvas width should match iPhone 15 Pro")
        XCTAssertEqual(canvasFrame.height, 852, accuracy: 1.0, "Canvas height should match iPhone 15 Pro")
    }
    
    func testTextLayerCreationAndManipulation() throws {
        try setupCanvasWithDevice()
        
        // Add text layer
        let addTextButton = app.buttons["Add Text Layer"]
        XCTAssertTrue(addTextButton.waitForExistence(timeout: 3))
        addTextButton.tap()
        
        // Enter text
        let textField = app.textFields["Text Input"]
        XCTAssertTrue(textField.waitForExistence(timeout: 3))
        textField.tap()
        textField.typeText("Test Canvas Text")
        
        let confirmButton = app.buttons["Confirm Text"]
        confirmButton.tap()
        
        // Verify text layer appears on canvas
        let textLayer = app.staticTexts["Test Canvas Text"]
        XCTAssertTrue(textLayer.waitForExistence(timeout: 3))
        
        // Test text layer manipulation - tap and drag
        let initialFrame = textLayer.frame
        let canvasView = app.otherElements["Canvas View"]
        let targetCoordinate = canvasView.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.3))
        let startCoordinate = textLayer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        startCoordinate.press(forDuration: 0.5, thenDragTo: targetCoordinate)
        
        // Verify text moved
        let newFrame = textLayer.frame
        XCTAssertNotEqual(initialFrame.origin.x, newFrame.origin.x, accuracy: 5.0)
        XCTAssertNotEqual(initialFrame.origin.y, newFrame.origin.y, accuracy: 5.0)
    }
    
    func testImageLayerAdditionAndManipulation() throws {
        try setupCanvasWithDevice()
        
        // Add image layer
        let addImageButton = app.buttons["Add Image Layer"]
        XCTAssertTrue(addImageButton.waitForExistence(timeout: 3))
        addImageButton.tap()
        
        // Select image from photo library (mock)
        let photoLibraryButton = app.buttons["Photo Library"]
        if photoLibraryButton.waitForExistence(timeout: 3) {
            photoLibraryButton.tap()
            
            // Select first image
            let firstImage = app.images.element(boundBy: 0)
            if firstImage.waitForExistence(timeout: 5) {
                firstImage.tap()
                
                let selectButton = app.buttons["Select"]
                if selectButton.waitForExistence(timeout: 2) {
                    selectButton.tap()
                }
            }
        }
        
        // Verify image layer appears
        let imageLayer = app.images["Canvas Image Layer"]
        XCTAssertTrue(imageLayer.waitForExistence(timeout: 5))
        
        // Test image scaling with pinch gesture
        let initialFrame = imageLayer.frame
        imageLayer.pinch(withScale: 1.5, velocity: 1.0)
        
        // Verify image scaled
        let scaledFrame = imageLayer.frame
        XCTAssertGreaterThan(scaledFrame.width, initialFrame.width)
        XCTAssertGreaterThan(scaledFrame.height, initialFrame.height)
    }
    
    // MARK: - Multi-Layer Interaction
    
    func testMultiLayerCanvasInteraction() throws {
        try setupCanvasWithDevice()
        
        // Add multiple layers
        try addTextLayer(text: "Layer 1")
        try addTextLayer(text: "Layer 2")
        try addShapeLayer(shape: "Rectangle")
        
        // Verify all layers exist
        XCTAssertTrue(app.staticTexts["Layer 1"].exists)
        XCTAssertTrue(app.staticTexts["Layer 2"].exists)
        XCTAssertTrue(app.otherElements["Rectangle Shape"].exists)
        
        // Test layer selection
        let layer1 = app.staticTexts["Layer 1"]
        layer1.tap()
        
        // Verify selection indicator
        let selectionIndicator = app.otherElements["Layer Selection Indicator"]
        XCTAssertTrue(selectionIndicator.waitForExistence(timeout: 2))
        
        // Test layer reordering via layer panel
        let layerPanel = app.buttons["Layer Panel"]
        if layerPanel.waitForExistence(timeout: 2) {
            layerPanel.tap()
            
            // Drag layer to reorder
            let layer1Cell = app.cells["Layer 1 Cell"]
            let layer2Cell = app.cells["Layer 2 Cell"]
            
            if layer1Cell.exists && layer2Cell.exists {
                layer1Cell.press(forDuration: 1.0, thenDragTo: layer2Cell)
            }
        }
    }
    
    // MARK: - Performance and Responsiveness
    
    func testCanvasPerformanceDuringInteraction() throws {
        try setupCanvasWithDevice()
        
        // Add multiple layers for performance testing
        for i in 1...10 {
            try addTextLayer(text: "Performance Test \(i)")
        }
        
        // Measure performance of rapid interactions
        let textLayers = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Performance Test'"))
        let layerCount = textLayers.count
        XCTAssertEqual(layerCount, 10)
        
        // Test rapid tap interactions
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<layerCount {
            let layer = textLayers.element(boundBy: i)
            if layer.exists {
                layer.tap()
                // Small delay to allow for selection feedback
                usleep(50000) // 50ms
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // Verify interactions completed within reasonable time (< 2 seconds)
        XCTAssertLessThan(totalTime, 2.0, "Canvas interactions should be responsive")
    }
    
    func testCanvasZoomAndPanGestures() throws {
        try setupCanvasWithDevice()
        try addTextLayer(text: "Zoom Test")
        
        let canvasView = app.otherElements["Canvas View"]
        
        // Test zoom in with pinch gesture
        canvasView.pinch(withScale: 2.0, velocity: 1.0)
        
        // Verify zoom level increased (check if text appears larger)
        let textLayer = app.staticTexts["Zoom Test"]
        let zoomedFrame = textLayer.frame
        
        // Test pan gesture
        let centerCoordinate = canvasView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let targetCoordinate = canvasView.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        
        centerCoordinate.press(forDuration: 0.1, thenDragTo: targetCoordinate)
        
        // Verify pan occurred by checking if text moved
        let pannedFrame = textLayer.frame
        XCTAssertNotEqual(zoomedFrame.origin.x, pannedFrame.origin.x, accuracy: 10.0)
    }
    
    // MARK: - Error Handling and Edge Cases
    
    func testCanvasBoundaryConstraints() throws {
        try setupCanvasWithDevice()
        try addTextLayer(text: "Boundary Test")
        
        let textLayer = app.staticTexts["Boundary Test"]
        let canvasView = app.otherElements["Canvas View"]
        
        // Try to drag text outside canvas bounds
        let canvasFrame = canvasView.frame
        let outsideCoordinate = canvasView.coordinate(withNormalizedOffset: CGVector(dx: 2.0, dy: 2.0))
        
        let startCoordinate = textLayer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        startCoordinate.press(forDuration: 0.5, thenDragTo: outsideCoordinate)
        
        // Verify text stays within canvas bounds
        let finalFrame = textLayer.frame
        XCTAssertTrue(canvasFrame.contains(finalFrame), "Text should stay within canvas bounds")
    }
    
    func testUndoRedoFunctionality() throws {
        try setupCanvasWithDevice()
        
        // Perform action
        try addTextLayer(text: "Undo Test")
        XCTAssertTrue(app.staticTexts["Undo Test"].exists)
        
        // Undo action
        let undoButton = app.buttons["Undo"]
        if undoButton.waitForExistence(timeout: 2) {
            undoButton.tap()
            
            // Verify text layer removed
            XCTAssertFalse(app.staticTexts["Undo Test"].exists)
            
            // Redo action
            let redoButton = app.buttons["Redo"]
            if redoButton.waitForExistence(timeout: 2) {
                redoButton.tap()
                
                // Verify text layer restored
                XCTAssertTrue(app.staticTexts["Undo Test"].waitForExistence(timeout: 2))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupCanvasWithDevice() throws {
        let createButton = app.buttons["Create New Design"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()
        
        let deviceSelector = app.buttons["Device Selector"]
        XCTAssertTrue(deviceSelector.waitForExistence(timeout: 3))
        deviceSelector.tap()
        
        let iPhone15Pro = app.buttons["iPhone 15 Pro"]
        XCTAssertTrue(iPhone15Pro.waitForExistence(timeout: 3))
        iPhone15Pro.tap()
        
        let canvasView = app.otherElements["Canvas View"]
        XCTAssertTrue(canvasView.waitForExistence(timeout: 5))
    }
    
    private func addTextLayer(text: String) throws {
        let addTextButton = app.buttons["Add Text Layer"]
        XCTAssertTrue(addTextButton.waitForExistence(timeout: 3))
        addTextButton.tap()
        
        let textField = app.textFields["Text Input"]
        XCTAssertTrue(textField.waitForExistence(timeout: 3))
        textField.tap()
        textField.typeText(text)
        
        let confirmButton = app.buttons["Confirm Text"]
        confirmButton.tap()
        
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 3))
    }
    
    private func addShapeLayer(shape: String) throws {
        let addShapeButton = app.buttons["Add Shape Layer"]
        XCTAssertTrue(addShapeButton.waitForExistence(timeout: 3))
        addShapeButton.tap()
        
        let shapeButton = app.buttons[shape]
        XCTAssertTrue(shapeButton.waitForExistence(timeout: 3))
        shapeButton.tap()
        
        let confirmButton = app.buttons["Confirm Shape"]
        confirmButton.tap()
        
        XCTAssertTrue(app.otherElements["\(shape) Shape"].waitForExistence(timeout: 3))
    }
}
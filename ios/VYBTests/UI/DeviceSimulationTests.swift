import XCTest
@testable import VYB

class DeviceSimulationTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Device Simulation Accuracy Tests
    
    func testIPhone15ProSimulationAccuracy() throws {
        try setupCanvasWithDevice(deviceName: "iPhone 15 Pro")
        
        let canvasView = app.otherElements["Canvas View"]
        let canvasFrame = canvasView.frame
        
        // Verify iPhone 15 Pro dimensions (393x852 points)
        XCTAssertEqual(canvasFrame.width, 393, accuracy: 1.0, "iPhone 15 Pro width should be 393 points")
        XCTAssertEqual(canvasFrame.height, 852, accuracy: 1.0, "iPhone 15 Pro height should be 852 points")
        
        // Verify safe areas
        let safeAreaTop = app.otherElements["Safe Area Top"]
        let safeAreaBottom = app.otherElements["Safe Area Bottom"]
        
        if safeAreaTop.exists {
            let topFrame = safeAreaTop.frame
            XCTAssertEqual(topFrame.height, 59, accuracy: 1.0, "iPhone 15 Pro top safe area should be 59 points")
        }
        
        if safeAreaBottom.exists {
            let bottomFrame = safeAreaBottom.frame
            XCTAssertEqual(bottomFrame.height, 34, accuracy: 1.0, "iPhone 15 Pro bottom safe area should be 34 points")
        }
        
        // Verify aspect ratio
        let aspectRatio = canvasFrame.width / canvasFrame.height
        let expectedAspectRatio: CGFloat = 393.0 / 852.0
        XCTAssertEqual(aspectRatio, expectedAspectRatio, accuracy: 0.01, "iPhone 15 Pro aspect ratio should be correct")
    }
    
    func testIPadProSimulationAccuracy() throws {
        try setupCanvasWithDevice(deviceName: "iPad Pro 12.9")
        
        let canvasView = app.otherElements["Canvas View"]
        let canvasFrame = canvasView.frame
        
        // Verify iPad Pro dimensions (1024x1366 points)
        XCTAssertEqual(canvasFrame.width, 1024, accuracy: 1.0, "iPad Pro width should be 1024 points")
        XCTAssertEqual(canvasFrame.height, 1366, accuracy: 1.0, "iPad Pro height should be 1366 points")
        
        // Verify safe areas for iPad
        let safeAreaTop = app.otherElements["Safe Area Top"]
        let safeAreaBottom = app.otherElements["Safe Area Bottom"]
        
        if safeAreaTop.exists {
            let topFrame = safeAreaTop.frame
            XCTAssertEqual(topFrame.height, 24, accuracy: 1.0, "iPad Pro top safe area should be 24 points")
        }
        
        if safeAreaBottom.exists {
            let bottomFrame = safeAreaBottom.frame
            XCTAssertEqual(bottomFrame.height, 24, accuracy: 1.0, "iPad Pro bottom safe area should be 24 points")
        }
        
        // Verify aspect ratio
        let aspectRatio = canvasFrame.width / canvasFrame.height
        let expectedAspectRatio: CGFloat = 1024.0 / 1366.0
        XCTAssertEqual(aspectRatio, expectedAspectRatio, accuracy: 0.01, "iPad Pro aspect ratio should be correct")
    }
    
    func testDeviceSwitchingPreservesContent() throws {
        // Start with iPhone 15 Pro
        try setupCanvasWithDevice(deviceName: "iPhone 15 Pro")
        
        // Add content
        try addTestContent()
        
        // Verify content exists
        XCTAssertTrue(app.staticTexts["Device Switch Test"].exists)
        XCTAssertTrue(app.otherElements["Rectangle Shape"].exists)
        
        // Switch to iPad Pro
        let deviceSelector = app.buttons["Device Selector"]
        XCTAssertTrue(deviceSelector.waitForExistence(timeout: 3))
        deviceSelector.tap()
        
        let iPadPro = app.buttons["iPad Pro 12.9"]
        XCTAssertTrue(iPadPro.waitForExistence(timeout: 3))
        iPadPro.tap()
        
        // Wait for device switch animation
        usleep(500000) // 500ms
        
        // Verify content still exists after device switch
        XCTAssertTrue(app.staticTexts["Device Switch Test"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["Rectangle Shape"].waitForExistence(timeout: 3))
        
        // Verify new canvas dimensions
        let canvasView = app.otherElements["Canvas View"]
        let newCanvasFrame = canvasView.frame
        XCTAssertEqual(newCanvasFrame.width, 1024, accuracy: 1.0)
        XCTAssertEqual(newCanvasFrame.height, 1366, accuracy: 1.0)
    }
    
    func testDeviceRotationHandling() throws {
        try setupCanvasWithDevice(deviceName: "iPhone 15 Pro")
        try addTestContent()
        
        // Get initial orientation
        let initialOrientation = app.orientation
        
        // Rotate device to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Wait for rotation animation
        usleep(1000000) // 1 second
        
        // Verify canvas adapted to new orientation
        let canvasView = app.otherElements["Canvas View"]
        let rotatedFrame = canvasView.frame
        
        // In landscape, dimensions should be swapped
        XCTAssertEqual(rotatedFrame.width, 852, accuracy: 1.0, "Landscape width should be 852")
        XCTAssertEqual(rotatedFrame.height, 393, accuracy: 1.0, "Landscape height should be 393")
        
        // Verify content still exists
        XCTAssertTrue(app.staticTexts["Device Switch Test"].exists)
        
        // Rotate back to portrait
        XCUIDevice.shared.orientation = .portrait
        usleep(1000000) // 1 second
        
        // Verify return to original dimensions
        let portraitFrame = canvasView.frame
        XCTAssertEqual(portraitFrame.width, 393, accuracy: 1.0)
        XCTAssertEqual(portraitFrame.height, 852, accuracy: 1.0)
    }
    
    // MARK: - Visual Fidelity Tests
    
    func testPixelPerfectRendering() throws {
        try setupCanvasWithDevice(deviceName: "iPhone 15 Pro")
        
        // Add content with specific positioning
        try addTextLayer(text: "Pixel Perfect Test", position: CGPoint(x: 100, y: 200))
        
        let textLayer = app.staticTexts["Pixel Perfect Test"]
        let textFrame = textLayer.frame
        
        // Verify positioning accuracy (within 1 pixel)
        XCTAssertEqual(textFrame.origin.x, 100, accuracy: 1.0, "Text X position should be pixel-perfect")
        XCTAssertEqual(textFrame.origin.y, 200, accuracy: 1.0, "Text Y position should be pixel-perfect")
        
        // Test sub-pixel rendering
        try addTextLayer(text: "Sub-pixel Test", position: CGPoint(x: 100.5, y: 200.5))
        
        let subPixelText = app.staticTexts["Sub-pixel Test"]
        let subPixelFrame = subPixelText.frame
        
        // Verify sub-pixel positioning is handled correctly
        XCTAssertEqual(subPixelFrame.origin.x, 100.5, accuracy: 0.5, "Sub-pixel positioning should be preserved")
    }
    
    func testHighDPIRendering() throws {
        try setupCanvasWithDevice(deviceName: "iPhone 15 Pro")
        
        // Test rendering at different pixel densities
        // iPhone 15 Pro has 3x pixel density
        
        // Add fine details that would be affected by DPI
        try addTextLayer(text: "High DPI Test", fontSize: 12)
        
        let textLayer = app.staticTexts["High DPI Test"]
        
        // Take a snapshot for visual verification
        let screenshot = textLayer.screenshot()
        XCTAssertNotNil(screenshot, "Screenshot should be captured successfully")
        
        // Verify text is crisp and readable at small sizes
        // This is primarily a visual test - in real scenarios you'd compare with reference images
        XCTAssertGreaterThan(screenshot.image.size.width, 0)
        XCTAssertGreaterThan(screenshot.image.size.height, 0)
    }
    
    // MARK: - Performance Tests
    
    func testDeviceSwitchPerformance() throws {
        try setupCanvasWithDevice(deviceName: "iPhone 15 Pro")
        
        // Add multiple elements for performance testing
        for i in 1...20 {
            try addTextLayer(text: "Performance Test \(i)", position: CGPoint(x: 50 + (i * 10), y: 100 + (i * 20)))
        }
        
        // Measure device switch performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let deviceSelector = app.buttons["Device Selector"]
        deviceSelector.tap()
        
        let iPadPro = app.buttons["iPad Pro 12.9"]
        iPadPro.tap()
        
        // Wait for switch completion
        let canvasView = app.otherElements["Canvas View"]
        XCTAssertTrue(canvasView.waitForExistence(timeout: 5))
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let switchTime = endTime - startTime
        
        // Device switch should complete within 2 seconds
        XCTAssertLessThan(switchTime, 2.0, "Device switch should be performant")
        
        // Verify all content preserved
        for i in 1...20 {
            XCTAssertTrue(app.staticTexts["Performance Test \(i)"].exists, "Content \(i) should be preserved")
        }
    }
    
    func testMemoryUsageDuringDeviceSwitch() throws {
        // This test would typically use Instruments in a real scenario
        // For XCUITest, we can test for responsiveness as a proxy for memory efficiency
        
        try setupCanvasWithDevice(deviceName: "iPhone 15 Pro")
        
        // Perform multiple device switches rapidly
        let devices = ["iPhone 15 Pro", "iPad Pro 12.9", "iPhone 15", "iPad Air"]
        
        for device in devices {
            let deviceSelector = app.buttons["Device Selector"]
            if deviceSelector.waitForExistence(timeout: 2) {
                deviceSelector.tap()
                
                let deviceButton = app.buttons[device]
                if deviceButton.waitForExistence(timeout: 2) {
                    deviceButton.tap()
                    
                    // Verify switch completed
                    let canvasView = app.otherElements["Canvas View"]
                    XCTAssertTrue(canvasView.waitForExistence(timeout: 3), "Device switch to \(device) should succeed")
                }
            }
        }
        
        // Verify app is still responsive after multiple switches
        try addTextLayer(text: "Memory Test Passed", position: CGPoint(x: 100, y: 100))
        XCTAssertTrue(app.staticTexts["Memory Test Passed"].exists)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testUnsupportedDeviceHandling() throws {
        let createButton = app.buttons["Create New Design"]
        createButton.tap()
        
        let deviceSelector = app.buttons["Device Selector"]
        deviceSelector.tap()
        
        // Try to select a hypothetically unsupported device
        // This would test error handling in device selection
        let customDeviceButton = app.buttons["Custom Device"]
        if customDeviceButton.exists {
            customDeviceButton.tap()
            
            // Should show error or fallback to default device
            let errorAlert = app.alerts.element
            if errorAlert.waitForExistence(timeout: 2) {
                let okButton = errorAlert.buttons["OK"]
                okButton.tap()
            }
            
            // Should fallback to a default device
            let canvasView = app.otherElements["Canvas View"]
            XCTAssertTrue(canvasView.waitForExistence(timeout: 5), "Should fallback to default device")
        }
    }
    
    func testExtremeAspectRatioHandling() throws {
        // Test with very wide or tall aspect ratios if supported
        try setupCanvasWithDevice(deviceName: "iPhone 15 Pro")
        
        // Simulate extreme zoom that might cause aspect ratio issues
        let canvasView = app.otherElements["Canvas View"]
        canvasView.pinch(withScale: 10.0, velocity: 2.0)
        
        // Verify canvas remains functional
        try addTextLayer(text: "Extreme Zoom Test", position: CGPoint(x: 200, y: 400))
        XCTAssertTrue(app.staticTexts["Extreme Zoom Test"].waitForExistence(timeout: 3))
        
        // Zoom back out
        canvasView.pinch(withScale: 0.1, velocity: 2.0)
        
        // Verify content still visible
        XCTAssertTrue(app.staticTexts["Extreme Zoom Test"].exists)
    }
    
    // MARK: - Helper Methods
    
    private func setupCanvasWithDevice(deviceName: String) throws {
        let createButton = app.buttons["Create New Design"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()
        
        let deviceSelector = app.buttons["Device Selector"]
        XCTAssertTrue(deviceSelector.waitForExistence(timeout: 3))
        deviceSelector.tap()
        
        let deviceButton = app.buttons[deviceName]
        XCTAssertTrue(deviceButton.waitForExistence(timeout: 3))
        deviceButton.tap()
        
        let canvasView = app.otherElements["Canvas View"]
        XCTAssertTrue(canvasView.waitForExistence(timeout: 5))
    }
    
    private func addTestContent() throws {
        try addTextLayer(text: "Device Switch Test", position: CGPoint(x: 100, y: 200))
        
        let addShapeButton = app.buttons["Add Shape Layer"]
        addShapeButton.tap()
        
        let rectangleButton = app.buttons["Rectangle"]
        rectangleButton.tap()
        
        let confirmButton = app.buttons["Confirm Shape"]
        confirmButton.tap()
    }
    
    private func addTextLayer(text: String, position: CGPoint = CGPoint(x: 100, y: 100), fontSize: CGFloat = 16) throws {
        let addTextButton = app.buttons["Add Text Layer"]
        XCTAssertTrue(addTextButton.waitForExistence(timeout: 3))
        addTextButton.tap()
        
        let textField = app.textFields["Text Input"]
        XCTAssertTrue(textField.waitForExistence(timeout: 3))
        textField.tap()
        textField.typeText(text)
        
        // Set font size if different from default
        if fontSize != 16 {
            let fontSizeSlider = app.sliders["Font Size Slider"]
            if fontSizeSlider.exists {
                fontSizeSlider.adjust(toNormalizedSliderPosition: fontSize / 72.0) // Normalize to 0-1 range
            }
        }
        
        let confirmButton = app.buttons["Confirm Text"]
        confirmButton.tap()
        
        // Position the text if specified
        if position.x != 100 || position.y != 100 {
            let textLayer = app.staticTexts[text]
            if textLayer.waitForExistence(timeout: 2) {
                let canvasView = app.otherElements["Canvas View"]
                let targetCoordinate = canvasView.coordinate(withNormalizedOffset: CGVector(
                    dx: position.x / canvasView.frame.width,
                    dy: position.y / canvasView.frame.height
                ))
                textLayer.press(forDuration: 0.5, thenDragTo: targetCoordinate)
            }
        }
        
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 3))
    }
}
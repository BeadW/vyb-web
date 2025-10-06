import XCTest

final class ActualUITests: XCTestCase {
    
    func testVYBAppLaunchAndBasicUI() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch")
        
        // Take screenshot of initial state
        let initialScreenshot = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: initialScreenshot)
        attachment1.name = "VYB_Initial_Launch"
        attachment1.lifetime = .keepAlways
        add(attachment1)
        
        // Verify Facebook post structure elements exist
        XCTAssertTrue(app.staticTexts["Your Name"].exists, "Profile name should be visible")
        XCTAssertTrue(app.staticTexts["Just now"].exists, "Timestamp should be visible")
        XCTAssertTrue(app.staticTexts["What's on your mind?"].exists, "Post text should be visible")
        
        // Verify layer management elements
        XCTAssertTrue(app.buttons["Add Layer"].exists, "Add Layer button should be visible")
        XCTAssertTrue(app.buttons["Clear All"].exists, "Clear All button should be visible")
        XCTAssertTrue(app.staticTexts["Layers: 0"].exists, "Layer count should show 0 initially")
        
        // Verify Facebook action buttons
        XCTAssertTrue(app.buttons["Like"].exists, "Like button should be visible")
        XCTAssertTrue(app.buttons["Comment"].exists, "Comment button should be visible")
        XCTAssertTrue(app.buttons["Share"].exists, "Share button should be visible")
    }
    
    func testAddTextLayer() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch")
        
        // Tap "Add Layer" button to open menu
        let addLayerButton = app.buttons["Add Layer"]
        XCTAssertTrue(addLayerButton.waitForExistence(timeout: 5), "Add Layer button should exist")
        addLayerButton.tap()
        
        // Wait for menu to appear and tap "Text"
        let textMenuItem = app.menuItems["Text"]
        XCTAssertTrue(textMenuItem.waitForExistence(timeout: 3), "Text menu item should appear")
        textMenuItem.tap()
        
        // Verify layer count increased
        XCTAssertTrue(app.staticTexts["Layers: 1"].waitForExistence(timeout: 3), "Layer count should show 1")
        
        // Verify text layer appears on canvas
        XCTAssertTrue(app.staticTexts["New Text"].exists, "New text layer should be visible")
        
        // Verify layer management panel appears
        XCTAssertTrue(app.staticTexts["Layer Manager"].waitForExistence(timeout: 3), "Layer Manager should appear")
        XCTAssertTrue(app.staticTexts["Text"].exists, "Layer type should be shown in panel")
        
        // Take screenshot showing text layer added with management panel
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "VYB_Text_Layer_Added_With_Management"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testAddMultipleLayers() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch")
        
        // Add text layer
        app.buttons["Add Layer"].tap()
        app.menuItems["Text"].waitForExistence(timeout: 3)
        app.menuItems["Text"].tap()
        
        // Add image layer
        app.buttons["Add Layer"].tap()
        app.menuItems["Image"].waitForExistence(timeout: 3)
        app.menuItems["Image"].tap()
        
        // Add shape layer
        app.buttons["Add Layer"].tap()
        app.menuItems["Shape"].waitForExistence(timeout: 3)
        app.menuItems["Shape"].tap()
        
        // Verify layer count is 3
        XCTAssertTrue(app.staticTexts["Layers: 3"].waitForExistence(timeout: 3), "Layer count should show 3")
        
        // Take screenshot showing multiple layers
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "VYB_Multiple_Layers"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testClearAllLayers() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch")
        
        // Add a few layers first
        app.buttons["Add Layer"].tap()
        app.menuItems["Text"].waitForExistence(timeout: 3)
        app.menuItems["Text"].tap()
        
        app.buttons["Add Layer"].tap()
        app.menuItems["Shape"].waitForExistence(timeout: 3)
        app.menuItems["Shape"].tap()
        
        // Verify layers were added
        XCTAssertTrue(app.staticTexts["Layers: 2"].waitForExistence(timeout: 3), "Should have 2 layers")
        
        // Clear all layers
        app.buttons["Clear All"].tap()
        
        // Verify layers were cleared
        XCTAssertTrue(app.staticTexts["Layers: 0"].waitForExistence(timeout: 3), "Layer count should be 0")
        
        // Take screenshot showing cleared canvas
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "VYB_Cleared_Canvas"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testPostTextEditing() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch")
        
        // Tap on the post text to start editing
        let postText = app.staticTexts["What's on your mind?"]
        XCTAssertTrue(postText.exists, "Post text should exist")
        postText.tap()
        
        // Verify editing mode is active (Save/Cancel buttons appear)
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 3), "Save button should appear")
        XCTAssertTrue(app.buttons["Cancel"].exists, "Cancel button should exist")
        
        // Take screenshot showing edit mode
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "VYB_Text_Edit_Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Cancel editing
        app.buttons["Cancel"].tap()
        
        // Verify edit mode is dismissed
        XCTAssertFalse(app.buttons["Save"].exists, "Save button should be gone")
        XCTAssertFalse(app.buttons["Cancel"].exists, "Cancel button should be gone")
    }
    
    func testLayerDragAndSelection() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch")
        
        // Add a text layer
        app.buttons["Add Layer"].tap()
        app.menuItems["Text"].waitForExistence(timeout: 3)
        app.menuItems["Text"].tap()
        
        // Wait for layer to appear
        let textLayer = app.staticTexts["New Text"]
        XCTAssertTrue(textLayer.waitForExistence(timeout: 3), "Text layer should appear")
        
        // Test layer selection by tapping
        textLayer.tap()
        
        // Take screenshot showing layer interaction
        let screenshot1 = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "VYB_Layer_Selection"
        attachment1.lifetime = .keepAlways
        add(attachment1)
        
        // Test drag gesture on layer
        let startCoordinate = textLayer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endCoordinate = startCoordinate.withOffset(CGVector(dx: 50, dy: 50))
        
        startCoordinate.press(forDuration: 0.5, thenDragTo: endCoordinate)
        
        // Take screenshot after drag
        let screenshot2 = app.screenshot()
        let attachment2 = XCTAttachment(screenshot: screenshot2)
        attachment2.name = "VYB_Layer_After_Drag"
        attachment2.lifetime = .keepAlways
        add(attachment2)
    }
    
    func testLayerManagementPanel() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch")
        
        // Add multiple layers
        ["Text", "Shape", "Image"].forEach { layerType in
            app.buttons["Add Layer"].tap()
            app.menuItems[layerType].waitForExistence(timeout: 3)
            app.menuItems[layerType].tap()
        }
        
        // Verify layer count
        XCTAssertTrue(app.staticTexts["Layers: 3"].waitForExistence(timeout: 3), "Should have 3 layers")
        
        // Verify layer management panel is visible
        XCTAssertTrue(app.staticTexts["Layer Manager"].exists, "Layer Manager should be visible")
        
        // Test deselect all functionality
        let deselectButton = app.buttons["Deselect All"]
        XCTAssertTrue(deselectButton.exists, "Deselect All button should exist")
        deselectButton.tap()
        
        // Take screenshot showing layer management panel
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "VYB_Layer_Management_Panel"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
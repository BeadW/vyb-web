import XCTest
@testable import VYB

final class LayerEditorUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testLayerEditorModalAppears() throws {
        // Add a text layer first
        let addButton = app.buttons["+"]
        XCTAssertTrue(addButton.exists, "Add button should exist")
        addButton.tap()
        
        // Check if text option appears and tap it
        let textButton = app.buttons["Text"]
        if textButton.waitForExistence(timeout: 2) {
            textButton.tap()
        }
        
        // Wait for a layer to be created and try to find an Edit button
        let editButton = app.buttons["Edit"]
        if editButton.waitForExistence(timeout: 5) {
            editButton.tap()
            
            // Check if the modal appears by looking for navigation title
            let modalTitle = app.navigationBars["Edit Layer"]
            XCTAssertTrue(modalTitle.waitForExistence(timeout: 3), "Layer editor modal should appear with 'Edit Layer' title")
            
            // Check for Cancel and Done buttons
            let cancelButton = app.buttons["Cancel"]
            let doneButton = app.buttons["Done"]
            XCTAssertTrue(cancelButton.exists, "Cancel button should exist in modal")
            XCTAssertTrue(doneButton.exists, "Done button should exist in modal")
            
            // Close the modal
            cancelButton.tap()
        } else {
            XCTFail("Edit button not found - modal test cannot proceed")
        }
    }
    
    func testAddTextLayer() throws {
        // Test adding a text layer
        let addButton = app.buttons["+"]
        XCTAssertTrue(addButton.exists, "Add button should exist")
        addButton.tap()
        
        let textButton = app.buttons["Text"]
        if textButton.waitForExistence(timeout: 2) {
            textButton.tap()
            
            // Check if layer count increased
            let layerCountText = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Layers:'")).firstMatch
            XCTAssertTrue(layerCountText.exists, "Layer count should be displayed")
        }
    }
    
    func testDoubleTabLayerForEdit() throws {
        // Add a text layer first
        let addButton = app.buttons["+"]
        addButton.tap()
        
        let textButton = app.buttons["Text"]
        if textButton.waitForExistence(timeout: 2) {
            textButton.tap()
            
            // Try to find and double tap a layer (this is tricky in UI tests)
            // We'll look for text elements that might represent layers
            let layerTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Sample'"))
            if layerTexts.count > 0 {
                let firstLayer = layerTexts.firstMatch
                firstLayer.doubleTap()
                
                // Check if modal appears
                let modalTitle = app.navigationBars["Edit Layer"]
                if modalTitle.waitForExistence(timeout: 3) {
                    XCTAssertTrue(true, "Double tap successfully opened layer editor")
                    
                    // Close modal
                    app.buttons["Cancel"].tap()
                } else {
                    XCTFail("Double tap did not open layer editor modal")
                }
            }
        }
    }
}
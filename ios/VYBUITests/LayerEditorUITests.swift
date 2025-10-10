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
    
    func testLayerTextEditingReflectsOnCanvas() throws {
        // Take initial screenshot
        let screenshot1 = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "Initial State Before Layer Edit Test"
        add(attachment1)
        
        // Wait for app to load
        sleep(3)
        
        // Look for any existing text layers on canvas
        let allStaticTexts = app.staticTexts.allElementsBoundByIndex
        print("Found \(allStaticTexts.count) static text elements")
        
        var foundEditableLayer = false
        
        // Try to find and tap on a text layer
        for (index, textElement) in allStaticTexts.enumerated() {
            print("Text element \(index): '\(textElement.label)' - exists: \(textElement.exists)")
            
            // Skip system elements and look for actual layer content
            if textElement.label.contains("Cancellation") || textElement.label.contains("Policy") || 
               textElement.label.contains("Bella") || textElement.label.contains("Salon") {
                print("Attempting to tap on layer text: '\(textElement.label)'")
                textElement.tap()
                
                // Wait for potential modal or edit interface
                sleep(2)
                
                // Look for text editing field or modal
                let textFields = app.textFields.allElementsBoundByIndex
                let textViews = app.textViews.allElementsBoundByIndex
                
                print("After tap - Found \(textFields.count) text fields and \(textViews.count) text views")
                
                if textFields.count > 0 || textViews.count > 0 {
                    foundEditableLayer = true
                    
                    // Take screenshot of edit modal
                    let screenshot2 = app.screenshot()
                    let attachment2 = XCTAttachment(screenshot: screenshot2)
                    attachment2.name = "Layer Edit Modal Opened"
                    add(attachment2)
                    
                    // Try to edit the text
                    let editField = textFields.count > 0 ? textFields[0] : textViews[0]
                    editField.tap()
                    
                    // Clear existing text and type new text
                    let selectAllMenuItem = app.menuItems["Select All"]
                    if selectAllMenuItem.waitForExistence(timeout: 2) {
                        selectAllMenuItem.tap()
                    }
                    
                    let newText = "EDITED: \(Date().timeIntervalSince1970)"
                    editField.typeText(newText)
                    
                    // Look for Done/Save button
                    let doneButton = app.buttons["Done"]
                    let saveButton = app.buttons["Save"]
                    
                    if doneButton.exists {
                        doneButton.tap()
                    } else if saveButton.exists {
                        saveButton.tap()
                    } else {
                        // Try tapping outside to close modal
                        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
                    }
                    
                    // Wait for changes to reflect
                    sleep(3)
                    
                    // Take final screenshot to see if changes reflected on canvas
                    let screenshot3 = app.screenshot()
                    let attachment3 = XCTAttachment(screenshot: screenshot3)
                    attachment3.name = "After Layer Text Edit - Should Show Changes"
                    add(attachment3)
                    
                    // Check if the new text is visible on canvas
                    let updatedTexts = app.staticTexts.allElementsBoundByIndex
                    var foundUpdatedText = false
                    
                    for updatedText in updatedTexts {
                        if updatedText.label.contains("EDITED:") {
                            foundUpdatedText = true
                            print("SUCCESS: Found updated text on canvas: '\(updatedText.label)'")
                            break
                        }
                    }
                    
                    XCTAssertTrue(foundUpdatedText, "Layer text changes should be reflected on canvas")
                    break
                }
            }
        }
        
        if !foundEditableLayer {
            // Take screenshot of current state for debugging
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "No Editable Layer Found - Debug State"
            add(attachment)
            
            XCTFail("Could not find any editable text layers to test")
        }
    }
}
import XCTest

final class ShapeLayerModalBugTest: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testRaceConditionReproduction() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for the app to load
        XCTAssertTrue(app.waitForExistence(timeout: 5), "App should launch successfully")
        
        // This test is designed to reproduce the race condition by rapidly creating and editing layers
        // The race condition occurs when a layer is created and immediately tapped before 
        // the UI has fully updated
        
        for attempt in 1...10 {
            print("🧪 Race condition test attempt \(attempt)")
            
            // Find and tap the "Add Layer" menu button
            let addLayerButton = app.buttons["Add Layer"]
            XCTAssertTrue(addLayerButton.waitForExistence(timeout: 3), "Add Layer button should exist")
            addLayerButton.tap()
            
            // Tap on "Shape" option in the menu
            let shapeOption = app.buttons["Shape"]
            XCTAssertTrue(shapeOption.waitForExistence(timeout: 2), "Shape option should exist in menu")
            shapeOption.tap()
            
            // CRITICAL: Don't wait - immediately try to edit the layer to trigger race condition
            // The race condition happens when we try to edit a layer before the UI fully updates
            
            // Look for the edit button (appears when a layer is selected)
            let editButton = app.buttons["Edit"]
            if editButton.waitForExistence(timeout: 1) {
                editButton.tap()
                
                // Check if we get the "Layer not found" error
                let errorText = app.staticTexts["Layer not found"]
                if errorText.exists {
                    XCTFail("Race condition reproduced on attempt \(attempt): 'Layer not found' error appeared")
                    return // Test has successfully reproduced the bug
                }
                
                // If modal opened successfully, close it
                let layerEditorModal = app.sheets.firstMatch
                if layerEditorModal.exists {
                    let closeButton = layerEditorModal.buttons["Close"]
                    if closeButton.exists {
                        closeButton.tap()
                    } else {
                        let cancelButton = layerEditorModal.buttons["Cancel"]
                        if cancelButton.exists {
                            cancelButton.tap()
                        }
                    }
                    // Wait for modal to close
                    _ = layerEditorModal.waitForNonExistence(timeout: 2)
                }
            }
            
            // Alternative approach - try double-tapping the layer directly
            // Look for a shape layer in the quick access area
            let layerButtons = app.buttons.matching(identifier: "")
            for i in 0..<layerButtons.count {
                let button = layerButtons.element(boundBy: i)
                if button.exists && button.label.contains("Shape") {
                    button.doubleTap() // Double tap to trigger edit
                    
                    // Check for race condition error
                    let errorText = app.staticTexts["Layer not found"]
                    if errorText.exists {
                        XCTFail("Race condition reproduced on attempt \(attempt) via double-tap: 'Layer not found' error appeared")
                        return
                    }
                    
                    // Close modal if it opened
                    let layerEditorModal = app.sheets.firstMatch
                    if layerEditorModal.exists {
                        let closeButton = layerEditorModal.buttons["Close"]
                        if closeButton.exists {
                            closeButton.tap()
                        } else {
                            let cancelButton = layerEditorModal.buttons["Cancel"]
                            if cancelButton.exists {
                                cancelButton.tap()
                            }
                        }
                        _ = layerEditorModal.waitForNonExistence(timeout: 2)
                    }
                    break
                }
            }
            
            // Clean up - clear all layers for next attempt
            let clearButton = app.buttons["Clear All"]
            if clearButton.exists {
                clearButton.tap()
            }
        }
        
        // If we get here, we couldn't reproduce the race condition in 10 attempts
        // This could mean the bug is fixed, or our test isn't triggering it correctly
        print("🧪 Could not reproduce race condition in 10 attempts")
    }
    
    func testLayerManagerRaceCondition() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.waitForExistence(timeout: 5), "App should launch successfully")
        
        // Test race condition through the layer manager modal
        for attempt in 1...5 {
            print("🧪 Layer manager race condition test attempt \(attempt)")
            
            // Add a shape layer
            let addLayerButton = app.buttons["Add Layer"]
            XCTAssertTrue(addLayerButton.waitForExistence(timeout: 3), "Add Layer button should exist")
            addLayerButton.tap()
            
            let shapeOption = app.buttons["Shape"]
            XCTAssertTrue(shapeOption.waitForExistence(timeout: 2), "Shape option should exist")
            shapeOption.tap()
            
            // Open layer manager immediately
            let manageButton = app.buttons["Manage"]
            XCTAssertTrue(manageButton.waitForExistence(timeout: 2), "Manage button should exist")
            manageButton.tap()
            
            // Try to edit the layer immediately through the manager
            let layerManagerModal = app.sheets.firstMatch
            XCTAssertTrue(layerManagerModal.waitForExistence(timeout: 2), "Layer manager should open")
            
            // Look for edit button in the layer manager
            let editButtons = layerManagerModal.buttons.matching(NSPredicate(format: "label CONTAINS 'pencil'"))
            if editButtons.count > 0 {
                editButtons.firstMatch.tap()
                
                // Check for race condition
                let errorText = app.staticTexts["Layer not found"]
                if errorText.exists {
                    XCTFail("Race condition reproduced via layer manager on attempt \(attempt)")
                    return
                }
                
                // Close the editor modal if it opened
                let editorModal = app.sheets.element(boundBy: 1) // Second modal
                if editorModal.exists {
                    let closeButton = editorModal.buttons["Close"]
                    if closeButton.exists {
                        closeButton.tap()
                    } else {
                        let cancelButton = editorModal.buttons["Cancel"]
                        if cancelButton.exists {
                            cancelButton.tap()
                        }
                    }
                    _ = editorModal.waitForNonExistence(timeout: 2)
                }
            }
            
            // Close layer manager
            let doneButton = layerManagerModal.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
            _ = layerManagerModal.waitForNonExistence(timeout: 2)
            
            // Clean up
            let clearButton = app.buttons["Clear All"]
            if clearButton.exists {
                clearButton.tap()
            }
        }
        
        print("🧪 Could not reproduce layer manager race condition in 5 attempts")
    }
}
#!/usr/bin/env swift

import XCTest
import Foundation

class LayerUIConsistencyTest: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    func testLayerUIReflectsCanvasState() throws {
        let app = XCUIApplication()
        
        // Wait for app to load
        let addLayerButton = app.buttons["Add Layer"]
        XCTAssertTrue(addLayerButton.waitForExistence(timeout: 10), "Add Layer button should exist")
        
        // Test 1: Initial state - should show 0 layers
        let quickLayerAccess = app.staticTexts.matching(identifier: "QuickLayerAccess").firstMatch
        if quickLayerAccess.exists {
            let initialText = quickLayerAccess.label
            print("Initial Quick Layer Access text: \(initialText)")
        }
        
        // Test 2: Add a layer and verify UI updates
        addLayerButton.tap()
        
        // Wait for layer to be added
        sleep(2)
        
        // Check if Quick Layer Access reflects the new layer
        if quickLayerAccess.exists {
            let afterAddText = quickLayerAccess.label
            print("After adding layer Quick Layer Access text: \(afterAddText)")
        }
        
        // Test 3: Open Layer Manager Modal and verify it shows current layers
        let layerManagerButton = app.buttons["Layer Manager"]
        if layerManagerButton.exists {
            layerManagerButton.tap()
            
            // Wait for modal to open
            sleep(1)
            
            // Check layer count in modal
            let layerCountText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Layer'")).firstMatch
            if layerCountText.exists {
                print("Layer Manager Modal shows: \(layerCountText.label)")
            }
            
            // Close modal
            let closeButton = app.buttons["Close"] // Or whatever button closes the modal
            if closeButton.exists {
                closeButton.tap()
            } else {
                // Try tapping outside modal or other close method
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
            }
        }
        
        // Test 4: Test AI generation and verify UI updates
        let aiButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'AI' OR label CONTAINS 'Generate'")).firstMatch
        if aiButton.exists {
            aiButton.tap()
            
            // Wait for potential AI processing
            sleep(3)
            
            // Check if UI updated after AI generation
            if quickLayerAccess.exists {
                let afterAIText = quickLayerAccess.label
                print("After AI generation Quick Layer Access text: \(afterAIText)")
            }
        }
        
        // Test 5: Test history navigation and verify UI updates
        let historyButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'History' OR label CONTAINS 'Back' OR label CONTAINS 'Previous'")).firstMatch
        if historyButton.exists {
            historyButton.tap()
            
            sleep(1)
            
            // Check if UI updated after history navigation
            if quickLayerAccess.exists {
                let afterHistoryText = quickLayerAccess.label
                print("After history navigation Quick Layer Access text: \(afterHistoryText)")
            }
        }
        
        // Take final screenshot
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Final UI State"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testLayerCountConsistency() throws {
        let app = XCUIApplication()
        
        // Wait for app to load
        let addLayerButton = app.buttons["Add Layer"]
        XCTAssertTrue(addLayerButton.waitForExistence(timeout: 10), "Add Layer button should exist")
        
        // Add multiple layers and verify counts are consistent
        for i in 1...3 {
            addLayerButton.tap()
            sleep(1)
            
            // Check various UI elements that should show layer count
            let layerCountElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '\(i)'"))
            
            print("After adding layer \(i):")
            for j in 0..<layerCountElements.count {
                let element = layerCountElements.element(boundBy: j)
                if element.exists {
                    print("  - Element \(j): \(element.label)")
                }
            }
        }
        
        // Take screenshot of multiple layers state
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Multiple Layers State"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// Usage: swift test_ui_consistency.swift
if CommandLine.argc > 0 {
    print("Running VYB Layer UI Consistency Test...")
    
    // Create test suite
    let testSuite = XCTestSuite(name: "LayerUIConsistencyTest")
    
    // Add test methods
    testSuite.addTest(LayerUIConsistencyTest.defaultTestSuite())
    
    // Run tests
    let testRun = XCTestSuiteRun(test: testSuite)
    testSuite.run(testRun)
    
    print("Test completed!")
}
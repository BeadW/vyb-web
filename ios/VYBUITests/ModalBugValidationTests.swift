import XCTest
@testable import VYB

final class ModalBugValidationTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Wait for app to fully load
        let timeout: TimeInterval = 10
        let vybCanvasText = app.staticTexts["VYB Canvas"]
        XCTAssertTrue(vybCanvasText.waitForExistence(timeout: timeout), "App should load and show VYB Canvas")
    }
    
    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }
    
    // MARK: - Core Modal Bug Tests
    
    func testShapeLayerModalBugReproduction() throws {
        print("🧪 Testing: Shape Layer Modal Bug - Should work immediately without text layer dependency")
        
        // Step 1: Add ONLY a shape layer (the problematic scenario)
        print("  📱 Adding shape layer...")
        addLayer(type: "Shape")
        
        // Step 2: Verify layer was created
        let shapeLayers = app.staticTexts.matching(identifier: "Shape")
        XCTAssertTrue(shapeLayers.count > 0, "Shape layer should be created")
        print("  ✅ Shape layer created")
        
        // Step 3: Find and tap edit button for shape layer
        print("  📱 Opening shape layer modal...")
        let editButton = app.buttons["Edit"].firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 5), "Edit button should exist for shape layer")
        editButton.tap()
        
        // Step 4: Verify modal appears with content (critical test)
        print("  🔍 Validating modal content...")
        let modal = app.navigationBars["Edit Layer"]
        XCTAssertTrue(modal.waitForExistence(timeout: 5), "Shape layer modal should appear")
        
        // Step 5: Verify modal is NOT empty (the main bug symptom)
        let layerInfoSection = app.staticTexts["Layer Information"]
        XCTAssertTrue(layerInfoSection.waitForExistence(timeout: 3), 
                     "CRITICAL: Layer Information section should be visible immediately - modal should not be empty")
        
        let shapeSettingsSection = app.staticTexts["Shape Settings"]
        XCTAssertTrue(shapeSettingsSection.waitForExistence(timeout: 2), 
                     "Shape Settings section should be visible")
        
        // Step 6: Verify specific content exists
        let contentTextField = app.textFields["Layer content"]
        XCTAssertTrue(contentTextField.exists, "Content text field should exist and be accessible")
        
        let layerTypeDisplay = app.staticTexts["Shape"]
        XCTAssertTrue(layerTypeDisplay.exists, "Layer type should be displayed correctly")
        
        print("  ✅ Modal contains expected content - bug is FIXED")
        
        // Step 7: Close modal
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should exist")
        doneButton.tap()
        
        // Verify modal closes properly
        XCTAssertFalse(modal.waitForExistence(timeout: 2), "Modal should close")
        print("  ✅ Modal closes properly")
    }
    
    func testTextLayerCreationDoesNotAffectOtherModals() throws {
        print("🧪 Testing: Text layer creation should not be required for other modals to work")
        
        // Step 1: Create shape layer and verify its modal works
        print("  📱 Testing shape layer modal BEFORE text layer...")
        addLayer(type: "Shape")
        
        let firstEditButton = app.buttons["Edit"].firstMatch
        firstEditButton.tap()
        
        let shapeModal = app.navigationBars["Edit Layer"]
        XCTAssertTrue(shapeModal.waitForExistence(timeout: 5), "Shape modal should work before text layer")
        
        let shapeContent = app.staticTexts["Layer Information"]
        let shapeModalHasContent = shapeContent.waitForExistence(timeout: 3)
        app.buttons["Done"].tap()
        
        // Step 2: Create text layer
        print("  📱 Adding text layer...")
        addLayer(type: "Text")
        
        // Step 3: Verify shape layer modal still works the same way
        print("  📱 Testing shape layer modal AFTER text layer...")
        let editButtons = app.buttons.matching(identifier: "Edit")
        XCTAssertTrue(editButtons.count >= 2, "Should have edit buttons for both layers")
        
        editButtons.element(boundBy: 0).tap() // First edit button (shape layer)
        
        let shapeModalAfter = app.navigationBars["Edit Layer"]
        XCTAssertTrue(shapeModalAfter.waitForExistence(timeout: 5), "Shape modal should still work after text layer")
        
        let shapeContentAfter = app.staticTexts["Layer Information"]
        let shapeModalHasContentAfter = shapeContentAfter.waitForExistence(timeout: 3)
        app.buttons["Done"].tap()
        
        // Critical assertion: Both should work independently
        XCTAssertTrue(shapeModalHasContent, "Shape modal should work BEFORE text layer creation")
        XCTAssertTrue(shapeModalHasContentAfter, "Shape modal should work AFTER text layer creation")
        
        print("  ✅ Shape layer modal works independently of text layer")
    }
    
    func testAllLayerTypesModalsFunctionIndependently() throws {
        print("🧪 Testing: All layer types should have working modals independently")
        
        let layerTypes = ["Shape", "Text", "Image", "Background"]
        var modalResults: [String: Bool] = [:]
        
        for layerType in layerTypes {
            print("  📱 Testing \(layerType) layer modal...")
            
            // Add layer
            addLayer(type: layerType)
            
            // Get the most recent edit button
            let editButtons = app.buttons.matching(identifier: "Edit")
            let latestEditButton = editButtons.element(boundBy: editButtons.count - 1)
            latestEditButton.tap()
            
            // Verify modal appears
            let modal = app.navigationBars["Edit Layer"]
            let modalAppears = modal.waitForExistence(timeout: 5)
            XCTAssertTrue(modalAppears, "\(layerType) modal should appear")
            
            // Verify modal has content
            let layerInfo = app.staticTexts["Layer Information"]
            let hasContent = layerInfo.waitForExistence(timeout: 3)
            modalResults[layerType] = hasContent
            
            // Verify correct layer type is shown
            let layerTypeText = app.staticTexts[layerType]
            XCTAssertTrue(layerTypeText.exists, "\(layerType) modal should show correct layer type")
            
            // Close modal
            app.buttons["Done"].tap()
            XCTAssertFalse(modal.waitForExistence(timeout: 2), "\(layerType) modal should close")
            
            print("  ✅ \(layerType) layer modal: \(hasContent ? "WORKING" : "BROKEN")")
        }
        
        // Verify all modals worked
        for (layerType, worked) in modalResults {
            XCTAssertTrue(worked, "\(layerType) layer modal should have content and work properly")
        }
        
        print("  🎉 All layer type modals work independently!")
    }
    
    func testPositionControlsRemovedFromModal() throws {
        print("🧪 Testing: Position controls should be removed from modal")
        
        addLayer(type: "Text")
        
        let editButton = app.buttons["Edit"].firstMatch
        editButton.tap()
        
        let modal = app.navigationBars["Edit Layer"]
        XCTAssertTrue(modal.waitForExistence(timeout: 5), "Modal should appear")
        
        // Verify position controls are NOT present
        let xPositionLabel = app.staticTexts["X Position"]
        let yPositionLabel = app.staticTexts["Y Position"]
        let positionLayoutSection = app.staticTexts["Position & Layout"]
        
        XCTAssertFalse(xPositionLabel.exists, "X Position control should be removed")
        XCTAssertFalse(yPositionLabel.exists, "Y Position control should be removed")
        XCTAssertFalse(positionLayoutSection.exists, "Position & Layout section should be removed")
        
        print("  ✅ Position controls successfully removed from modal")
        
        app.buttons["Done"].tap()
    }
    
    // MARK: - Stress Tests
    
    func testModalPerformanceWithMultipleLayers() throws {
        print("🧪 Testing: Modal performance with multiple layers")
        
        let layerCount = 10
        
        // Create multiple layers
        for i in 0..<layerCount {
            addLayer(type: i % 2 == 0 ? "Shape" : "Text")
        }
        
        let editButtons = app.buttons.matching(identifier: "Edit")
        XCTAssertEqual(editButtons.count, layerCount, "Should have \(layerCount) edit buttons")
        
        // Test opening modals - they should all work quickly
        for i in 0..<min(5, editButtons.count) { // Test first 5 to keep test time reasonable
            let startTime = Date()
            
            editButtons.element(boundBy: i).tap()
            
            let modal = app.navigationBars["Edit Layer"]
            XCTAssertTrue(modal.waitForExistence(timeout: 5), "Modal \(i) should open")
            
            let layerInfo = app.staticTexts["Layer Information"]
            XCTAssertTrue(layerInfo.waitForExistence(timeout: 3), "Modal \(i) should have content")
            
            app.buttons["Done"].tap()
            
            let timeElapsed = Date().timeIntervalSince(startTime)
            XCTAssertLessThan(timeElapsed, 3.0, "Modal \(i) should open quickly (under 3 seconds)")
        }
        
        print("  ✅ All modals perform well with multiple layers")
    }
    
    func testSequentialModalOpenClose() throws {
        print("🧪 Testing: Sequential modal open/close operations")
        
        addLayer(type: "Shape")
        
        let editButton = app.buttons["Edit"].firstMatch
        
        // Open and close modal multiple times
        for i in 0..<5 {
            print("  📱 Modal open/close cycle \(i + 1)")
            
            editButton.tap()
            
            let modal = app.navigationBars["Edit Layer"]
            XCTAssertTrue(modal.waitForExistence(timeout: 5), "Modal should open on attempt \(i + 1)")
            
            let layerInfo = app.staticTexts["Layer Information"]
            XCTAssertTrue(layerInfo.waitForExistence(timeout: 3), "Modal should have content on attempt \(i + 1)")
            
            app.buttons["Done"].tap()
            XCTAssertFalse(modal.waitForExistence(timeout: 2), "Modal should close on attempt \(i + 1)")
        }
        
        print("  ✅ Sequential modal operations work consistently")
    }
    
    // MARK: - Helper Methods
    
    private func addLayer(type: String) {
        let addButton = app.buttons["+"]
        XCTAssertTrue(addButton.exists, "Add button should exist")
        addButton.tap()
        
        let layerButton = app.buttons[type]
        XCTAssertTrue(layerButton.waitForExistence(timeout: 3), "\(type) button should appear in menu")
        layerButton.tap()
        
        // Wait for layer to be created
        sleep(1)
    }
    
    private func printTestSeparator(_ testName: String) {
        print("\n" + String(repeating: "=", count: 60))
        print("🧪 \(testName)")
        print(String(repeating: "=", count: 60))
    }
}
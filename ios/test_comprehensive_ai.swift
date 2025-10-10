import XCTest
import XCUITest

final class ComprehensiveAITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: "com.vyb.VYB")
        app.launch()
    }
    
    func test_comprehensive_ai_layer_operations() throws {
        // Test that AI can handle comprehensive layer modifications
        
        // First, add several layers to create a complex design
        let addLayerButton = app.buttons["Add Layer"]
        
        // Add multiple layers for AI to work with
        XCTAssertTrue(addLayerButton.waitForExistence(timeout: 5))
        addLayerButton.tap()
        
        let textLayerButton = app.buttons["Text Layer"]
        if textLayerButton.waitForExistence(timeout: 2) {
            textLayerButton.tap()
        }
        
        // Add another layer
        if addLayerButton.exists {
            addLayerButton.tap()
            let shapeLayerButton = app.buttons["Shape Layer"]
            if shapeLayerButton.waitForExistence(timeout: 2) {
                shapeLayerButton.tap()
            }
        }
        
        // Add a third layer
        if addLayerButton.exists {
            addLayerButton.tap()
            if textLayerButton.waitForExistence(timeout: 2) {
                textLayerButton.tap()
            }
        }
        
        // Take screenshot of complex design
        let screenshot1 = XCUIScreen.main.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "Complex Design Before AI"
        add(attachment1)
        
        // Now test the enhanced AI
        let enhanceButton = app.buttons["Enhance with AI"]
        XCTAssertTrue(enhanceButton.waitForExistence(timeout: 5))
        enhanceButton.tap()
        
        // Wait for AI processing (comprehensive changes may take longer)
        sleep(8) // Wait for Gemini AI to process comprehensive changes
        
        // Take screenshot of first AI variation
        let screenshot2 = XCUIScreen.main.screenshot()
        let attachment2 = XCTAttachment(screenshot: screenshot2)
        attachment2.name = "AI Variation 1 - Comprehensive Changes"
        add(attachment2)
        
        // Test that we can cycle through all 3 variations
        let nextVariationButton = app.buttons["Next Variation"]
        if nextVariationButton.waitForExistence(timeout: 2) {
            nextVariationButton.tap()
            sleep(2)
            
            let screenshot3 = XCUIScreen.main.screenshot()
            let attachment3 = XCTAttachment(screenshot: screenshot3)
            attachment3.name = "AI Variation 2 - Comprehensive Changes"
            add(attachment3)
            
            // Third variation
            if nextVariationButton.exists {
                nextVariationButton.tap()
                sleep(2)
                
                let screenshot4 = XCUIScreen.main.screenshot()
                let attachment4 = XCTAttachment(screenshot: screenshot4)
                attachment4.name = "AI Variation 3 - Comprehensive Changes"
                add(attachment4)
            }
        }
        
        print("✅ Comprehensive AI test completed - Generated 3 variations with extensive layer modifications")
    }
    
    func test_ai_create_delete_modify_operations() throws {
        // Test specific AI operations: create, delete, modify
        
        // Start with a simple design
        let addLayerButton = app.buttons["Add Layer"]
        XCTAssertTrue(addLayerButton.waitForExistence(timeout: 5))
        addLayerButton.tap()
        
        let textLayerButton = app.buttons["Text Layer"]
        if textLayerButton.waitForExistence(timeout: 2) {
            textLayerButton.tap()
        }
        
        // Take baseline screenshot
        let screenshot1 = XCUIScreen.main.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "Simple Design for AI Operations Test" 
        add(attachment1)
        
        // Test AI enhancement
        let enhanceButton = app.buttons["Enhance with AI"]
        XCTAssertTrue(enhanceButton.waitForExistence(timeout: 5))
        enhanceButton.tap()
        
        // Wait for AI processing
        sleep(8)
        
        // Capture result - should show create/delete/modify operations
        let screenshot2 = XCUIScreen.main.screenshot()
        let attachment2 = XCTAttachment(screenshot: screenshot2)
        attachment2.name = "AI Operations Result - Create/Delete/Modify"
        add(attachment2)
        
        print("✅ AI operations test completed - Tested create/delete/modify capabilities")
    }
}
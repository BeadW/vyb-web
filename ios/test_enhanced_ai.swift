import XCTest
import XCUITest

class TestEnhancedAI: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["testing"]
        app.launch()
    }
    
    func testEnhancedAICapabilities() {
        let app = XCUIApplication()
        
        // Navigate to salon design (assuming it's available)
        if app.staticTexts["Salon Design"].exists {
            app.staticTexts["Salon Design"].tap()
        } else {
            // Look for any navigation elements
            sleep(2)
        }
        
        // Add some initial layers to test AI on
        if app.buttons["Add Layer"].exists {
            app.buttons["Add Layer"].tap()
            sleep(1)
            
            // Add a text layer
            if app.buttons["Text"].exists {
                app.buttons["Text"].tap()
                sleep(1)
            }
        }
        
        // Look for AI analysis button
        if app.buttons["AI Analysis"].exists || app.buttons["Analyze Design"].exists {
            if app.buttons["AI Analysis"].exists {
                app.buttons["AI Analysis"].tap()
            } else {
                app.buttons["Analyze Design"].tap()
            }
            
            // Wait for AI processing
            sleep(5)
            
            // Take screenshot of AI results
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Enhanced AI Results"
            add(attachment)
        }
        
        // Test if variations are shown (should be up to 5 now)
        let variationButtons = app.buttons.matching(identifier: "variation")
        XCTAssertTrue(variationButtons.count > 0, "Should show AI variations")
        
        // If we have variations, test applying one
        if variationButtons.count > 0 {
            variationButtons.element(boundBy: 0).tap()
            sleep(2)
            
            // Take screenshot after applying variation
            let afterScreenshot = XCUIScreen.main.screenshot()
            let afterAttachment = XCTAttachment(screenshot: afterScreenshot)
            afterAttachment.name = "After Applying AI Variation"
            add(afterAttachment)
        }
    }
    
    func testCanvasBoundsAwareness() {
        let app = XCUIApplication()
        
        // Navigate to design area
        if app.staticTexts["Salon Design"].exists {
            app.staticTexts["Salon Design"].tap()
            sleep(2)
        }
        
        // Try to add a layer and move it off-canvas
        if app.buttons["Add Layer"].exists {
            app.buttons["Add Layer"].tap()
            sleep(1)
            
            if app.buttons["Text"].exists {
                app.buttons["Text"].tap()
                sleep(1)
                
                // Try to drag the layer off-canvas (drag to edge)
                let canvas = app.otherElements["canvas"]
                if canvas.exists {
                    let startPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    let endPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 1.2, dy: 0.5))
                    startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
                    sleep(1)
                }
            }
        }
        
        // Now test AI analysis on off-canvas content
        if app.buttons["AI Analysis"].exists {
            app.buttons["AI Analysis"].tap()
            sleep(5)
            
            // AI should now recognize off-canvas positioning
            let aiResponse = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'canvas' OR label CONTAINS[c] 'visible' OR label CONTAINS[c] 'position'"))
            XCTAssertTrue(aiResponse.count > 0, "AI should recognize canvas positioning")
            
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Canvas Bounds AI Analysis"
            add(attachment)
        }
    }
}
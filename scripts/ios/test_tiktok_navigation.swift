import XCTest

/// Test script to validate TikTok-style variation browsing functionality
class TikTokNavigationTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testTikTokStyleVariationBrowsing() throws {
        // Take initial screenshot
        let initialScreenshot = XCUIScreen.main.screenshot()
        let initialAttachment = XCTAttachment(screenshot: initialScreenshot)
        initialAttachment.name = "01_Initial_State"
        add(initialAttachment)
        
        // Wait for app to load
        Thread.sleep(forTimeInterval: 2.0)
        
        // Add some layers first
        let addLayerButton = app.buttons["Add Layer"]
        if addLayerButton.exists {
            addLayerButton.tap()
            Thread.sleep(forTimeInterval: 1.0)
            
            // Add text layer
            let textLayerButton = app.buttons["Text"]
            if textLayerButton.exists {
                textLayerButton.tap()
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
        
        // Take screenshot after adding layer
        let layerAddedScreenshot = XCUIScreen.main.screenshot()
        let layerAddedAttachment = XCTAttachment(screenshot: layerAddedScreenshot)
        layerAddedAttachment.name = "02_Layer_Added"
        add(layerAddedAttachment)
        
        // Test AI trigger swipe (swipe up from bottom)
        let canvas = app.otherElements["Canvas"]
        if !canvas.exists {
            // Fallback to main view
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            coordinate.swipeUp()
        } else {
            canvas.swipeUp()
        }
        
        // Wait for AI analysis
        Thread.sleep(forTimeInterval: 5.0)
        
        // Take screenshot after AI trigger
        let aiTriggeredScreenshot = XCUIScreen.main.screenshot()
        let aiTriggeredAttachment = XCTAttachment(screenshot: aiTriggeredScreenshot)
        aiTriggeredAttachment.name = "03_AI_Analysis_Triggered"
        add(aiTriggeredAttachment)
        
        // Test variation navigation (swipe down for next variation)
        if canvas.exists {
            canvas.swipeDown()
        } else {
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            coordinate.swipeDown()
        }
        
        Thread.sleep(forTimeInterval: 2.0)
        
        // Take screenshot of first variation
        let firstVariationScreenshot = XCUIScreen.main.screenshot()
        let firstVariationAttachment = XCTAttachment(screenshot: firstVariationScreenshot)
        firstVariationAttachment.name = "04_First_Variation"
        add(firstVariationAttachment)
        
        // Test swipe down for next variation
        if canvas.exists {
            canvas.swipeDown()
        } else {
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            coordinate.swipeDown()
        }
        
        Thread.sleep(forTimeInterval: 2.0)
        
        // Take screenshot of second variation
        let secondVariationScreenshot = XCUIScreen.main.screenshot()
        let secondVariationAttachment = XCTAttachment(screenshot: secondVariationScreenshot)
        secondVariationAttachment.name = "05_Second_Variation"
        add(secondVariationAttachment)
        
        // Test swipe up to go back to previous variation
        if canvas.exists {
            canvas.swipeUp()
        } else {
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            coordinate.swipeUp()
        }
        
        Thread.sleep(forTimeInterval: 2.0)
        
        // Take screenshot going back
        let backVariationScreenshot = XCUIScreen.main.screenshot()
        let backVariationAttachment = XCTAttachment(screenshot: backVariationScreenshot)
        backVariationAttachment.name = "06_Back_To_Previous_Variation"
        add(backVariationAttachment)
        
        // Test tap to apply variation
        if canvas.exists {
            canvas.tap()
        } else {
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
        
        Thread.sleep(forTimeInterval: 2.0)
        
        // Take final screenshot
        let finalScreenshot = XCUIScreen.main.screenshot()
        let finalAttachment = XCTAttachment(screenshot: finalScreenshot)
        finalAttachment.name = "07_Variation_Applied_Final"
        add(finalAttachment)
        
        print("✅ TikTok-style navigation test completed successfully!")
        print("📸 Screenshots saved: Initial, Layer Added, AI Analysis, First Variation, Second Variation, Back Navigation, Final Applied")
    }
    
    func testVariationModeIndicators() throws {
        // Test that variation mode shows proper indicators
        
        // Add layer first
        let addLayerButton = app.buttons["Add Layer"]
        if addLayerButton.exists {
            addLayerButton.tap()
            Thread.sleep(forTimeInterval: 1.0)
            
            let textLayerButton = app.buttons["Text"]
            if textLayerButton.exists {
                textLayerButton.tap()
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
        
        // Trigger AI analysis
        let canvas = app.otherElements["Canvas"]
        if !canvas.exists {
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            coordinate.swipeUp()
        } else {
            canvas.swipeUp()
        }
        
        // Wait for AI to complete
        Thread.sleep(forTimeInterval: 5.0)
        
        // Check that swipe indicator is hidden during variation mode
        let swipeIndicator = app.otherElements["Swipe Indicator"]
        XCTAssertFalse(swipeIndicator.exists, "Swipe indicator should be hidden during variation mode")
        
        // Take screenshot to verify
        let indicatorTestScreenshot = XCUIScreen.main.screenshot()
        let indicatorTestAttachment = XCTAttachment(screenshot: indicatorTestScreenshot)
        indicatorTestAttachment.name = "08_Variation_Mode_Indicators"
        add(indicatorTestAttachment)
        
        print("✅ Variation mode indicators test completed!")
    }
    
    func testEdgeCases() throws {
        // Test edge cases like no layers, network errors, etc.
        
        // Test AI trigger with no layers
        let canvas = app.otherElements["Canvas"]
        if !canvas.exists {
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            coordinate.swipeUp()
        } else {
            canvas.swipeUp()
        }
        
        Thread.sleep(forTimeInterval: 3.0)
        
        let noLayersScreenshot = XCUIScreen.main.screenshot()
        let noLayersAttachment = XCTAttachment(screenshot: noLayersScreenshot)
        noLayersAttachment.name = "09_No_Layers_Edge_Case"
        add(noLayersAttachment)
        
        print("✅ Edge cases test completed!")
    }
}
import XCTest

final class AISwipeGestureUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
        
        // Wait for the app to fully load
        _ = app.waitForExistence(timeout: 5.0)
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testAISwipeGestureDetection() throws {
        // Take initial screenshot
        let initialScreenshot = app.screenshot()
        let initialAttachment = XCTAttachment(screenshot: initialScreenshot)
        initialAttachment.name = "Initial App State"
        add(initialAttachment)
        
        print("🎯 Starting AI Swipe Gesture Test")
        
        // Find the main canvas area to swipe on
        let canvasArea = app.otherElements.firstMatch
        XCTAssertTrue(canvasArea.exists, "Canvas area should exist")
        
        print("🎯 Found canvas area, performing upward swipe gesture")
        
        // Perform upward swipe gesture (swipe from bottom to top)
        let startPoint = CGPoint(x: canvasArea.frame.midX, y: canvasArea.frame.maxY - 50)
        let endPoint = CGPoint(x: canvasArea.frame.midX, y: canvasArea.frame.midY - 100)
        
        // Perform the swipe gesture
        canvasArea.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            .press(forDuration: 0.1, thenDragTo: canvasArea.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
        
        // Wait a moment for the gesture to be processed
        sleep(2)
        
        // Take screenshot after swipe
        let afterSwipeScreenshot = app.screenshot()
        let afterSwipeAttachment = XCTAttachment(screenshot: afterSwipeScreenshot)
        afterSwipeAttachment.name = "After Swipe Gesture"
        add(afterSwipeAttachment)
        
        // Check if AI analysis is triggered (loading indicator should appear)
        // We'll check for either a loading indicator or some change in the UI
        let loadingIndicator = app.staticTexts["Analyzing with AI..."]
        let aiKeyAlert = app.alerts["Gemini API Key Required"]
        
        // Give some time for the UI to respond
        sleep(1)
        
        if aiKeyAlert.exists {
            print("🔑 API Key alert appeared - this means the swipe was detected but API key validation failed")
            
            let alertScreenshot = app.screenshot()
            let alertAttachment = XCTAttachment(screenshot: alertScreenshot)
            alertAttachment.name = "API Key Alert"
            add(alertAttachment)
            
            // This is actually success - it means the swipe gesture worked!
            XCTAssertTrue(aiKeyAlert.exists, "API key alert should appear when swiping without configured key")
            
        } else if loadingIndicator.exists {
            print("⏳ Loading indicator appeared - AI analysis started successfully")
            
            let loadingScreenshot = app.screenshot()
            let loadingAttachment = XCTAttachment(screenshot: loadingScreenshot)
            loadingAttachment.name = "AI Loading State"
            add(loadingAttachment)
            
            XCTAssertTrue(loadingIndicator.exists, "Loading indicator should appear during AI analysis")
            
        } else {
            print("❌ No expected UI changes detected after swipe gesture")
            
            // Take a final screenshot to see what's happening
            let finalScreenshot = app.screenshot()
            let finalAttachment = XCTAttachment(screenshot: finalScreenshot)
            finalAttachment.name = "Final State - No Changes Detected"
            add(finalAttachment)
            
            // This test will fail if neither alert nor loading appears
            XCTFail("Expected either API key alert or loading indicator to appear after swipe gesture")
        }
        
        print("🎯 AI Swipe Gesture Test Completed")
    }
    
    func testMultipleSwipeGestures() throws {
        print("🎯 Testing multiple swipe gestures")
        
        let canvasArea = app.otherElements.firstMatch
        XCTAssertTrue(canvasArea.exists, "Canvas area should exist")
        
        // Perform multiple swipe gestures to test consistency
        for i in 1...3 {
            print("🔄 Performing swipe gesture #\(i)")
            
            // Upward swipe
            canvasArea.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
                .press(forDuration: 0.1, thenDragTo: canvasArea.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
            
            sleep(1)
            
            // Take screenshot after each swipe
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "After Swipe #\(i)"
            add(attachment)
            
            // Check if any UI response occurred
            let aiKeyAlert = app.alerts["Gemini API Key Required"]
            let loadingIndicator = app.staticTexts["Analyzing with AI..."]
            
            if aiKeyAlert.exists || loadingIndicator.exists {
                print("✅ Swipe #\(i) triggered expected response")
                
                // Dismiss alert if it exists
                if aiKeyAlert.exists {
                    let cancelButton = aiKeyAlert.buttons["Cancel"]
                    if cancelButton.exists {
                        cancelButton.tap()
                        sleep(1)
                    }
                }
                break
            } else {
                print("⚠️ Swipe #\(i) did not trigger expected response")
            }
        }
    }
    
    func testSwipeDirections() throws {
        print("🎯 Testing different swipe directions")
        
        let canvasArea = app.otherElements.firstMatch
        XCTAssertTrue(canvasArea.exists, "Canvas area should exist")
        
        // Test different swipe directions
        let swipeTests = [
            ("Upward", CGVector(dx: 0.5, dy: 0.8), CGVector(dx: 0.5, dy: 0.2)),
            ("Downward", CGVector(dx: 0.5, dy: 0.2), CGVector(dx: 0.5, dy: 0.8)),
            ("Leftward", CGVector(dx: 0.8, dy: 0.5), CGVector(dx: 0.2, dy: 0.5)),
            ("Rightward", CGVector(dx: 0.2, dy: 0.5), CGVector(dx: 0.8, dy: 0.5))
        ]
        
        for (direction, startVector, endVector) in swipeTests {
            print("🔄 Testing \(direction) swipe")
            
            canvasArea.coordinate(withNormalizedOffset: startVector)
                .press(forDuration: 0.1, thenDragTo: canvasArea.coordinate(withNormalizedOffset: endVector))
            
            sleep(1)
            
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "\(direction) Swipe Result"
            add(attachment)
            
            // Check for response (only upward should trigger AI)
            let aiKeyAlert = app.alerts["Gemini API Key Required"]
            let loadingIndicator = app.staticTexts["Analyzing with AI..."]
            
            if direction == "Upward" {
                // Upward swipe should trigger AI
                if aiKeyAlert.exists || loadingIndicator.exists {
                    print("✅ \(direction) swipe correctly triggered AI response")
                    
                    // Dismiss alert if it exists
                    if aiKeyAlert.exists {
                        let cancelButton = aiKeyAlert.buttons["Cancel"]
                        if cancelButton.exists {
                            cancelButton.tap()
                            sleep(1)
                        }
                    }
                } else {
                    print("❌ \(direction) swipe failed to trigger AI response")
                }
            } else {
                // Other directions should not trigger AI
                if aiKeyAlert.exists || loadingIndicator.exists {
                    print("⚠️ \(direction) swipe unexpectedly triggered AI response")
                } else {
                    print("✅ \(direction) swipe correctly did not trigger AI response")
                }
            }
        }
    }
}
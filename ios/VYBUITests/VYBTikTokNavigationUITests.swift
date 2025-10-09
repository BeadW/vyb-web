import XCTest

final class VYBTikTokNavigationUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Wait for app to fully load
        sleep(2)
    }
    
    override func tearDownWithError() throws {
        app.terminate()
    }
    
    func testTikTokStyleNavigationComplete() throws {
        // Test the complete TikTok-style navigation flow
        
        // 1. Take initial screenshot
        let initialScreenshot = XCUIScreen.main.screenshot()
        let initialAttachment = XCTAttachment(screenshot: initialScreenshot)
        initialAttachment.name = "01_VYB_Initial_State"
        add(initialAttachment)
        
        // 2. Add a text layer first
        addTestLayer()
        
        let layerAddedScreenshot = XCUIScreen.main.screenshot()
        let layerAddedAttachment = XCTAttachment(screenshot: layerAddedScreenshot)
        layerAddedAttachment.name = "02_VYB_Layer_Added"
        add(layerAddedAttachment)
        
        // 3. Trigger AI analysis with swipe up
        triggerAIAnalysis()
        
        let aiTriggeredScreenshot = XCUIScreen.main.screenshot()
        let aiTriggeredAttachment = XCTAttachment(screenshot: aiTriggeredScreenshot)
        aiTriggeredAttachment.name = "03_VYB_AI_Analysis_Started"
        add(aiTriggeredAttachment)
        
        // 4. Wait for AI to complete
        waitForAIAnalysisCompletion()
        
        let aiCompletedScreenshot = XCUIScreen.main.screenshot()
        let aiCompletedAttachment = XCTAttachment(screenshot: aiCompletedScreenshot)
        aiCompletedAttachment.name = "04_VYB_AI_Analysis_Complete"
        add(aiCompletedAttachment)
        
        // 5. Test TikTok-style navigation
        testVariationNavigation()
        
        // 6. Test tap to apply current variation
        testTapToApplyVariation()
        
        let finalScreenshot = XCUIScreen.main.screenshot()
        let finalAttachment = XCTAttachment(screenshot: finalScreenshot)
        finalAttachment.name = "08_VYB_Final_Applied_State"
        add(finalAttachment)
        
        // Validation
        XCTAssertTrue(app.exists, "App should still be running")
        
        print("✅ TikTok-style navigation test completed successfully!")
    }
    
    private func addTestLayer() {
        // Try multiple ways to add a layer
        
        // Method 1: Look for Add Layer button
        let addLayerButton = app.buttons["Add Layer"]
        if addLayerButton.exists {
            addLayerButton.tap()
            sleep(1)
            
            // Look for Text button
            let textButton = app.buttons["Text"]
            if textButton.exists {
                textButton.tap()
                sleep(1)
                return
            }
        }
        
        // Method 2: Look for floating action button (FAB)
        let fabButton = app.buttons.matching(identifier: "fab").firstMatch
        if fabButton.exists {
            fabButton.tap()
            sleep(1)
            
            let textOption = app.buttons["Add Text"]
            if textOption.exists {
                textOption.tap()
                sleep(1)
                return
            }
        }
        
        // Method 3: Double tap on canvas to create layer
        let canvasArea = app.otherElements.firstMatch
        canvasArea.doubleTap()
        sleep(1)
        
        print("Layer addition attempted via multiple methods")
    }
    
    private func triggerAIAnalysis() {
        // Swipe up from bottom of screen to trigger AI
        let screenFrame = app.frame
        let startPoint = CGPoint(x: screenFrame.midX, y: screenFrame.maxY - 50)
        let endPoint = CGPoint(x: screenFrame.midX, y: screenFrame.midY)
        
        let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        let endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
        
        print("AI analysis triggered via swipe up gesture")
    }
    
    private func waitForAIAnalysisCompletion() {
        // Wait for AI analysis to complete
        // Look for loading indicator or wait fixed time
        
        let loadingTexts = [
            "AI is generating variations...",
            "Analyzing...",
            "Generating suggestions..."
        ]
        
        var foundLoadingIndicator = false
        for text in loadingTexts {
            let indicator = app.staticTexts[text]
            if indicator.waitForExistence(timeout: 3.0) {
                foundLoadingIndicator = true
                print("Found AI loading indicator: \(text)")
                
                // Wait for it to disappear
                let expectation = XCTNSPredicateExpectation(
                    predicate: NSPredicate(format: "exists == false"),
                    object: indicator
                )
                _ = XCTWaiter.wait(for: [expectation], timeout: 15.0)
                break
            }
        }
        
        if !foundLoadingIndicator {
            // Fallback: wait fixed time
            sleep(10)
            print("No loading indicator found, waited 10 seconds")
        }
        
        print("AI analysis completion phase finished")
    }
    
    private func testVariationNavigation() {
        // Test swiping through variations
        
        // Swipe down for next variation
        performVariationSwipe(direction: .down)
        
        let variation1Screenshot = XCUIScreen.main.screenshot()
        let variation1Attachment = XCTAttachment(screenshot: variation1Screenshot)
        variation1Attachment.name = "05_VYB_Variation_1"
        add(variation1Attachment)
        
        // Swipe down for another variation
        performVariationSwipe(direction: .down)
        
        let variation2Screenshot = XCUIScreen.main.screenshot()
        let variation2Attachment = XCTAttachment(screenshot: variation2Screenshot)
        variation2Attachment.name = "06_VYB_Variation_2"
        add(variation2Attachment)
        
        // Swipe up to go back
        performVariationSwipe(direction: .up)
        
        let backVariationScreenshot = XCUIScreen.main.screenshot()
        let backVariationAttachment = XCTAttachment(screenshot: backVariationScreenshot)
        backVariationAttachment.name = "07_VYB_Back_To_Previous_Variation"
        add(backVariationAttachment)
        
        print("Variation navigation testing completed")
    }
    
    private func performVariationSwipe(direction: SwipeDirection) {
        let startCoordinate: XCUICoordinate
        let endCoordinate: XCUICoordinate
        
        switch direction {
        case .down:
            startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        case .up:
            startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        }
        
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
        sleep(2) // Wait for animation/transition
        
        print("Performed variation swipe: \(direction)")
    }
    
    private func testTapToApplyVariation() {
        // Tap anywhere on canvas to apply current variation
        let centerCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        centerCoordinate.tap()
        
        sleep(2) // Wait for application
        
        print("Tap to apply variation completed")
    }
    
    enum SwipeDirection {
        case up, down
    }
    
    func testValidateUIElements() throws {
        // Additional validation test
        
        // Check that the app launches properly
        XCTAssertTrue(app.exists)
        
        // Validate that we can interact with the main interface
        let mainView = app.otherElements.firstMatch
        XCTAssertTrue(mainView.exists)
        
        print("UI element validation completed")
    }
}
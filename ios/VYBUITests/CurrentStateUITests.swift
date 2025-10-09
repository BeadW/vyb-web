import XCTest

final class CurrentStateUITests: XCTestCase {
    
    func testCaptureCurrentAppState() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch")
        
        // Give the app a moment to fully render
        sleep(2)
        
        // Take screenshot of current state
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Current_VYB_App_State"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Basic test - just verify app launched successfully
        // We won't test specific UI elements since we want to see what's actually there
        XCTAssertTrue(true, "App launched and screenshot captured")
    }
    
    func testAddLayerFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch")
        sleep(1)
        
        // Take initial screenshot
        let initialScreenshot = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: initialScreenshot)
        attachment1.name = "01_Initial_State"
        attachment1.lifetime = .keepAlways
        add(attachment1)
        
        // Try to find and tap Add Layer button (menu)
        let addLayerButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Layer'")).firstMatch
        if addLayerButton.exists {
            addLayerButton.tap()
            sleep(1)
            
            // Take screenshot after opening menu
            let menuScreenshot = app.screenshot()
            let attachment2 = XCTAttachment(screenshot: menuScreenshot)
            attachment2.name = "02_Add_Layer_Menu_Open"
            attachment2.lifetime = .keepAlways
            add(attachment2)
            
            // Try to tap text option if it exists
            let textOption = app.menuItems["Text"]
            if textOption.exists {
                textOption.tap()
                sleep(1)
                
                // Take screenshot after adding text layer
                let afterTextScreenshot = app.screenshot()
                let attachment3 = XCTAttachment(screenshot: afterTextScreenshot)
                attachment3.name = "03_After_Adding_Text_Layer"
                attachment3.lifetime = .keepAlways
                add(attachment3)
            }
        }
        
        // Always pass - we just want to capture the flow
        XCTAssertTrue(true, "Layer flow captured")
    }
}
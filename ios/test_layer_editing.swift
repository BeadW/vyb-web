import XCTest

class LayerEditingUITest: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testLayerEditingFunctionality() throws {
        // Wait for the app to load
        sleep(3)
        
        // Take initial screenshot
        let screenshot1 = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "Initial State"
        add(attachment1)
        
        // Look for any text layer on the canvas
        let textElements = app.staticTexts.allElementsBoundByIndex
        print("Found \(textElements.count) text elements")
        
        for (index, element) in textElements.enumerated() {
            print("Text element \(index): '\(element.label)' exists: \(element.exists)")
        }
        
        // Try to tap on the first text layer
        if textElements.count > 0 {
            let firstTextElement = textElements[0]
            print("Attempting to tap on first text element: '\(firstTextElement.label)'")
            firstTextElement.tap()
            
            // Wait for modal to appear
            sleep(2)
            
            // Take screenshot after tap
            let screenshot2 = app.screenshot()
            let attachment2 = XCTAttachment(screenshot: screenshot2)
            attachment2.name = "After Tapping Text Layer"
            add(attachment2)
            
            // Look for text field in the modal
            let textFields = app.textFields.allElementsBoundByIndex
            print("Found \(textFields.count) text fields after tap")
            
            if textFields.count > 0 {
                let textField = textFields[0]
                textField.tap()
                textField.typeText("EDITED TEXT")
                
                // Look for save/done button
                let buttons = app.buttons.allElementsBoundByIndex
                for button in buttons {
                    print("Button: '\(button.label)'")
                    if button.label.contains("Done") || button.label.contains("Save") {
                        button.tap()
                        break
                    }
                }
                
                // Wait for changes to reflect
                sleep(2)
                
                // Take final screenshot
                let screenshot3 = app.screenshot()
                let attachment3 = XCTAttachment(screenshot: screenshot3)
                attachment3.name = "After Editing Text"
                add(attachment3)
            }
        }
    }
}
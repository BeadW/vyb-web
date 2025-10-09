import XCTest
@testable import VYB

import XCTest
@testable import VYB

class AIServiceTests: XCTestCase {
    
    var aiService: AIService!
    
    override func setUp() {
        super.setUp()
        // This will fail because AIService doesn't exist yet
        aiService = AIService()
    }
    
    override func tearDown() {
        aiService = nil
        super.tearDown()
    }
    
    func testAIServiceInitialization() {
        // This test will fail because AIService class doesn't exist
        XCTAssertNotNil(aiService)
        XCTAssertEqual(aiService.isConfigured, false)
    }
    
    func testConfigureAIService() {
        // This test will fail because configure method doesn't exist
        let apiKey = "test-api-key"
        aiService.configure(apiKey: apiKey)
        XCTAssertEqual(aiService.isConfigured, true)
    }
    
    func testAnalyzeCanvasFailsWithoutConfiguration() async {
        // This test will fail because analyzeCanvas method doesn't exist
        let canvasData = createMockCanvasData()
        
        do {
            let _ = try await aiService.analyzeCanvas(canvasData)
            XCTFail("Should throw error when not configured")
        } catch AIServiceError.notConfigured {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testAnalyzeCanvasSuccess() async {
        // This test will fail because methods don't exist
        aiService.configure(apiKey: "test-key")
        let canvasData = createMockCanvasData()
        
        do {
            let response = try await aiService.analyzeCanvas(canvasData)
            XCTAssertNotNil(response)
            XCTAssertFalse(response.suggestions.isEmpty)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    // Helper method to create mock canvas data
    private func createMockCanvasData() -> DesignCanvasData {
        return DesignCanvasData(
            id: "test-canvas",
            deviceType: "iphone-15-pro",
            dimensions: CanvasDimensions(width: 393, height: 852, pixelDensity: 3),
            layers: [],
            metadata: CanvasMetadata(createdAt: Date(), modifiedAt: Date()),
            state: "editing"
        )
    }
}

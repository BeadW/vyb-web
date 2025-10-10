# Technical Specification: Enhanced Layers & Visual AI

**Document Version**: 1.0  
**Date**: October 9, 2025  
**Branch**: `enhanced-layers-visual-ai`  
**Implementation**: iOS-first, TDD approach  

## 1. Overview

This specification details the implementation of an enhanced SVG-based layer system with visual AI integration for VYB. The system will enable creation of complex, valuable social media designs while maintaining brand consistency through AI-powered suggestions.

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    VYB Enhanced Layer System                 │
├─────────────────────────────────────────────────────────────┤
│  UI Layer (SwiftUI)                                         │
│  ├── ContentView (TikTok Navigation)                        │
│  ├── LayerManagementView                                    │
│  ├── VisualCanvasView (SVG Rendering)                       │
│  └── LayerEditorView (Properties Panel)                     │
├─────────────────────────────────────────────────────────────┤
│  Business Logic                                             │
│  ├── SVGLayerManager                                        │
│  ├── VisualAIService (Enhanced)                             │
│  ├── BrandManager                                           │
│  └── CanvasCaptureService                                   │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                 │
│  ├── SVGLayer Models                                        │
│  ├── BrandProfile                                           │
│  └── HistoryState (Enhanced)                                │
├─────────────────────────────────────────────────────────────┤
│  External Services                                          │
│  ├── Gemini AI API (with visual input)                      │
│  └── SVG Rendering Engine                                   │
└─────────────────────────────────────────────────────────────┘
```

## 3. Data Models

### 3.1 Enhanced Layer Model

```swift
// MARK: - SVG Layer Types
enum SVGLayerType: String, CaseIterable, Codable {
    case text = "text"
    case shape = "shape"
    case image = "image"
    case background = "background"
    case group = "group"
}

// MARK: - Enhanced Transform
struct SVGTransform: Codable, Equatable {
    var x: Double
    var y: Double
    var scaleX: Double
    var scaleY: Double
    var rotation: Double // degrees
    var opacity: Double // 0-1
    
    // SVG transform string generation
    var svgTransformString: String {
        var transforms: [String] = []
        
        if x != 0 || y != 0 {
            transforms.append("translate(\(x), \(y))")
        }
        
        if rotation != 0 {
            let centerX = x
            let centerY = y
            transforms.append("rotate(\(rotation) \(centerX) \(centerY))")
        }
        
        if scaleX != 1 || scaleY != 1 {
            transforms.append("scale(\(scaleX), \(scaleY))")
        }
        
        return transforms.joined(separator: " ")
    }
}

// MARK: - Layer Style (Enhanced)
struct SVGLayerStyle: Codable, Equatable {
    // Drop Shadow
    var dropShadow: DropShadowStyle?
    
    // Inner Shadow
    var innerShadow: InnerShadowStyle?
    
    // Border
    var border: BorderStyle?
    
    // Border Radius
    var borderRadius: Double?
    
    // Blend Mode (future)
    var blendMode: BlendMode?
}

struct DropShadowStyle: Codable, Equatable {
    var offsetX: Double
    var offsetY: Double
    var blur: Double
    var spread: Double
    var color: String
    
    var svgFilterId: String {
        return "drop-shadow-\(abs(hashValue))"
    }
}

struct InnerShadowStyle: Codable, Equatable {
    var offsetX: Double
    var offsetY: Double
    var blur: Double
    var spread: Double
    var color: String
    
    var svgFilterId: String {
        return "inner-shadow-\(abs(hashValue))"
    }
}

struct BorderStyle: Codable, Equatable {
    var width: Double
    var color: String
    var style: BorderStyleType
}

enum BorderStyleType: String, Codable {
    case solid = "solid"
    case dashed = "dashed"
    case dotted = "dotted"
}

enum BlendMode: String, Codable {
    case normal = "normal"
    case multiply = "multiply"
    case screen = "screen"
    case overlay = "overlay"
    case darken = "darken"
    case lighten = "lighten"
}

// MARK: - Layer Constraints (Enhanced)
struct SVGLayerConstraints: Codable, Equatable {
    var locked: Bool
    var visible: Bool
    
    // AI Protection Locks
    var lockPosition: Bool
    var lockSize: Bool
    var lockRotation: Bool
    var lockContent: Bool
    var lockStyle: Bool
    
    // Auto-layout constraints
    var maintainAspectRatio: Bool?
    var minWidth: Double?
    var minHeight: Double?
    var maxWidth: Double?
    var maxHeight: Double?
}

// MARK: - Main SVG Layer
struct SVGLayer: Codable, Equatable, Identifiable {
    let id: String
    var type: SVGLayerType
    var content: SVGLayerContent
    var transform: SVGTransform
    var style: SVGLayerStyle
    var constraints: SVGLayerConstraints
    var metadata: LayerMetadata
    
    // SVG generation
    func toSVGElement() -> String {
        switch type {
        case .text:
            return generateTextSVG()
        case .shape:
            return generateShapeSVG()
        case .image:
            return generateImageSVG()
        case .background:
            return generateBackgroundSVG()
        case .group:
            return generateGroupSVG()
        }
    }
}
```

### 3.2 Layer Content Types

```swift
// MARK: - Layer Content
struct SVGLayerContent: Codable {
    // Text Layer
    var text: String?
    var fontSize: Double?
    var fontFamily: String?
    var fontWeight: FontWeight?
    var textColor: String?
    var textAlign: TextAlignment?
    var lineHeight: Double?
    var letterSpacing: Double?
    
    // Shape Layer
    var shapeType: ShapeType?
    var fill: String?
    var stroke: StrokeStyle?
    var cornerRadius: Double?
    var sides: Int? // for polygons
    
    // Image Layer
    var imageURL: String?
    var imageData: String? // base64
    var crop: CropRegion?
    var filters: ImageFilters?
    
    // Background Layer
    var backgroundColor: String?
    var backgroundGradient: GradientStyle?
    
    // Group Layer
    var childLayerIds: [String]?
    var groupName: String?
}

enum FontWeight: String, Codable {
    case normal = "normal"
    case bold = "bold"
    case w100 = "100"
    case w200 = "200"
    case w300 = "300"
    case w400 = "400"
    case w500 = "500"
    case w600 = "600"
    case w700 = "700"
    case w800 = "800"
    case w900 = "900"
}

enum TextAlignment: String, Codable {
    case left = "left"
    case center = "center"
    case right = "right"
    case justify = "justify"
}

enum ShapeType: String, Codable {
    case rectangle = "rectangle"
    case circle = "circle"
    case triangle = "triangle"
    case polygon = "polygon"
    case line = "line"
    case arrow = "arrow"
}

struct StrokeStyle: Codable, Equatable {
    var color: String
    var width: Double
    var dashArray: [Double]?
}

struct CropRegion: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

struct ImageFilters: Codable, Equatable {
    var brightness: Double? // 0-2, default 1
    var contrast: Double?   // 0-2, default 1
    var saturation: Double? // 0-2, default 1
    var blur: Double?       // 0-10, default 0
}

struct GradientStyle: Codable, Equatable {
    var type: GradientType
    var angle: Double? // for linear
    var stops: [GradientStop]
}

enum GradientType: String, Codable {
    case linear = "linear"
    case radial = "radial"
}

struct GradientStop: Codable, Equatable {
    var color: String
    var position: Double // 0-1
}
```

### 3.3 Brand Management

```swift
// MARK: - Brand Profile
struct BrandProfile: Codable, Identifiable {
    let id: String
    var name: String
    var colors: BrandColors
    var fonts: BrandFonts
    var guidelines: BrandGuidelines
}

struct BrandColors: Codable {
    var primary: [String]     // Array of hex colors
    var secondary: [String]
    var accent: [String]
    var neutral: [String]
}

struct BrandFonts: Codable {
    var primary: String       // Font family name
    var secondary: String?
    var allowedWeights: [FontWeight]
}

struct BrandGuidelines: Codable {
    var minFontSize: Double
    var maxFontSize: Double
    var preferredSpacing: Double
    var logoPlacement: LogoPlacement?
}

enum LogoPlacement: String, Codable {
    case topLeft = "top-left"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomRight = "bottom-right"
    case center = "center"
}
```

## 4. Core Services

### 4.1 SVGLayerManager

```swift
class SVGLayerManager: ObservableObject {
    @Published var layers: [SVGLayer] = []
    @Published var selectedLayerIds: Set<String> = []
    
    private let brandManager: BrandManager
    
    init(brandManager: BrandManager) {
        self.brandManager = brandManager
    }
    
    // MARK: - Layer Management
    func addLayer(_ layer: SVGLayer) throws {
        validateLayer(layer)
        layers.append(layer)
        updateCanvas()
    }
    
    func removeLayer(id: String) {
        layers.removeAll { $0.id == id }
        selectedLayerIds.remove(id)
        updateCanvas()
    }
    
    func moveLayer(from: Int, to: Int) {
        guard from < layers.count && to < layers.count else { return }
        let layer = layers.remove(at: from)
        layers.insert(layer, at: to)
        updateCanvas()
    }
    
    func updateLayer(id: String, update: (inout SVGLayer) -> Void) {
        guard let index = layers.firstIndex(where: { $0.id == id }) else { return }
        update(&layers[index])
        validateLayer(layers[index])
        updateCanvas()
    }
    
    // MARK: - Group Operations
    func groupLayers(ids: [String], name: String) -> String {
        let groupId = UUID().uuidString
        let childLayers = layers.filter { ids.contains($0.id) }
        
        // Create group layer
        let groupLayer = SVGLayer(
            id: groupId,
            type: .group,
            content: SVGLayerContent(
                childLayerIds: ids,
                groupName: name
            ),
            transform: calculateGroupBounds(childLayers),
            style: SVGLayerStyle(),
            constraints: SVGLayerConstraints(
                locked: false,
                visible: true,
                lockPosition: false,
                lockSize: false,
                lockRotation: false,
                lockContent: false,
                lockStyle: false
            ),
            metadata: LayerMetadata(
                source: .user,
                createdAt: Date()
            )
        )
        
        // Remove child layers from root
        layers.removeAll { ids.contains($0.id) }
        
        // Add group layer
        layers.append(groupLayer)
        
        updateCanvas()
        return groupId
    }
    
    func ungroupLayer(id: String) {
        guard let groupIndex = layers.firstIndex(where: { $0.id == id && $0.type == .group }),
              let childIds = layers[groupIndex].content.childLayerIds else { return }
        
        // Add child layers back to root
        // Note: In real implementation, we'd need to store child layers
        
        // Remove group layer
        layers.remove(at: groupIndex)
        updateCanvas()
    }
    
    // MARK: - Brand Validation
    private func validateLayer(_ layer: SVGLayer) {
        guard let brandProfile = brandManager.currentBrand else { return }
        
        // Validate brand colors
        if let textColor = layer.content.textColor {
            validateBrandColor(textColor, brand: brandProfile)
        }
        
        // Validate brand fonts
        if let fontFamily = layer.content.fontFamily {
            validateBrandFont(fontFamily, brand: brandProfile)
        }
        
        // Validate font size
        if let fontSize = layer.content.fontSize {
            validateFontSize(fontSize, brand: brandProfile)
        }
    }
    
    // MARK: - SVG Generation
    func generateFullSVG(canvasSize: CGSize) -> String {
        let defs = generateSVGDefs()
        let layerElements = layers.map { $0.toSVGElement() }.joined(separator: "\n")
        
        return """
        <svg width="\(canvasSize.width)" height="\(canvasSize.height)" 
             viewBox="0 0 \(canvasSize.width) \(canvasSize.height)"
             xmlns="http://www.w3.org/2000/svg">
        \(defs)
        \(layerElements)
        </svg>
        """
    }
    
    private func generateSVGDefs() -> String {
        var defs: [String] = []
        
        // Generate filter definitions for shadows
        for layer in layers {
            if let dropShadow = layer.style.dropShadow {
                defs.append(generateDropShadowFilter(dropShadow))
            }
            if let innerShadow = layer.style.innerShadow {
                defs.append(generateInnerShadowFilter(innerShadow))
            }
        }
        
        if defs.isEmpty {
            return ""
        }
        
        return """
        <defs>
        \(defs.joined(separator: "\n"))
        </defs>
        """
    }
}
```

### 4.2 Enhanced AIService with Visual Input

```swift
extension AIService {
    
    // MARK: - Visual AI Integration
    func analyzeDesignWithVisual(
        layers: [SVGLayer],
        canvasImage: UIImage,
        brandProfile: BrandProfile?,
        userPrompt: String? = nil
    ) async throws -> [DesignVariation] {
        
        // Convert image to base64
        guard let imageData = canvasImage.jpegData(compressionQuality: 0.8) else {
            throw AIServiceError.invalidInput("Cannot convert canvas image")
        }
        let base64Image = imageData.base64EncodedString()
        
        // Create enhanced prompt with visual context
        let prompt = createVisualAnalysisPrompt(
            layers: layers,
            brandProfile: brandProfile,
            userPrompt: userPrompt
        )
        
        // Create Gemini request with image
        let requestBody = createGeminiVisualRequest(
            prompt: prompt,
            base64Image: base64Image
        )
        
        // Make API call
        let response = try await callGeminiVisualAPI(requestBody: requestBody)
        
        // Parse response into variations
        return try parseVisualGeminiResponse(response, originalLayers: layers)
    }
    
    private func createVisualAnalysisPrompt(
        layers: [SVGLayer],
        brandProfile: BrandProfile?,
        userPrompt: String?
    ) -> String {
        
        var promptParts: [String] = []
        
        // Visual analysis instruction
        promptParts.append("""
        Analyze the provided canvas image and layer data to suggest design improvements.
        Focus on visual composition, hierarchy, spacing, and social media best practices.
        """)
        
        // Brand guidelines
        if let brand = brandProfile {
            promptParts.append("""
            BRAND GUIDELINES:
            Brand Name: \(brand.name)
            Primary Colors: \(brand.colors.primary.joined(separator: ", "))
            Secondary Colors: \(brand.colors.secondary.joined(separator: ", "))
            Primary Font: \(brand.fonts.primary)
            Secondary Font: \(brand.fonts.secondary ?? "None")
            """)
        }
        
        // Layer information
        let layerInfo = layers.enumerated().map { index, layer in
            "Layer \(index + 1): \(layer.type.rawValue) '\(layer.content.text ?? layer.content.groupName ?? "element")' at (\(layer.transform.x), \(layer.transform.y))"
        }.joined(separator: "\n")
        
        promptParts.append("""
        CURRENT LAYERS:
        \(layerInfo)
        """)
        
        // User prompt if provided
        if let userPrompt = userPrompt {
            promptParts.append("""
            USER REQUEST:
            \(userPrompt)
            """)
        }
        
        // Response format instruction
        promptParts.append("""
        Based on the visual analysis and layer data, create exactly 3 design variations.
        Each variation should make specific, visually obvious improvements.
        
        Respect any locked properties (lockPosition, lockSize, lockRotation, lockContent, lockStyle).
        Stay within brand guidelines if provided.
        Focus on social media optimization.
        """)
        
        return promptParts.joined(separator: "\n\n")
    }
    
    private func createGeminiVisualRequest(prompt: String, base64Image: String) -> GeminiVisualRequest {
        return GeminiVisualRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: prompt),
                        GeminiImagePart(
                            inlineData: GeminiInlineData(
                                mimeType: "image/jpeg",
                                data: base64Image
                            )
                        )
                    ]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 8192,
                responseMimeType: "application/json",
                responseJsonSchema: createVisualResponseSchema()
            )
        )
    }
}

// MARK: - Visual API Models
struct GeminiVisualRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiImagePart: Codable {
    let inlineData: GeminiInlineData
}

struct GeminiInlineData: Codable {
    let mimeType: String
    let data: String
}
```

### 4.3 Canvas Capture Service

```swift
class CanvasCaptureService {
    
    func captureCanvas(
        layers: [SVGLayer],
        canvasSize: CGSize,
        format: CaptureFormat = .jpeg
    ) async throws -> CaptureResult {
        
        // Generate SVG
        let svgManager = SVGLayerManager(brandManager: BrandManager.shared)
        svgManager.layers = layers
        let svgString = svgManager.generateFullSVG(canvasSize: canvasSize)
        
        // Render SVG to image
        let image = try await renderSVGToImage(svgString: svgString, size: canvasSize)
        
        switch format {
        case .svg:
            return .svg(svgString)
        case .png:
            guard let pngData = image.pngData() else {
                throw CaptureError.renderingFailed
            }
            return .png(pngData)
        case .jpeg:
            guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
                throw CaptureError.renderingFailed
            }
            return .jpeg(jpegData)
        }
    }
    
    private func renderSVGToImage(svgString: String, size: CGSize) async throws -> UIImage {
        // Use SVGKit or similar library to render SVG to UIImage
        // This is a placeholder - actual implementation would use SVGKit
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                // SVG rendering implementation
                // For now, create a placeholder image
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                let context = UIGraphicsGetCurrentContext()
                context?.setFillColor(UIColor.white.cgColor)
                context?.fill(CGRect(origin: .zero, size: size))
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: CaptureError.renderingFailed)
                }
            }
        }
    }
}

enum CaptureFormat {
    case svg
    case png
    case jpeg
}

enum CaptureResult {
    case svg(String)
    case png(Data)
    case jpeg(Data)
}

enum CaptureError: Error {
    case renderingFailed
    case invalidFormat
}
```

## 5. Testing Strategy

### 5.1 Unit Tests
```swift
class SVGLayerManagerTests: XCTestCase {
    
    func testLayerCreation() {
        let manager = SVGLayerManager(brandManager: MockBrandManager())
        
        let textLayer = SVGLayer(
            id: "test-1",
            type: .text,
            content: SVGLayerContent(
                text: "Hello World",
                fontSize: 16,
                fontFamily: "Arial"
            ),
            transform: SVGTransform(x: 100, y: 100, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1),
            style: SVGLayerStyle(),
            constraints: SVGLayerConstraints(
                locked: false,
                visible: true,
                lockPosition: false,
                lockSize: false,
                lockRotation: false,
                lockContent: false,
                lockStyle: false
            ),
            metadata: LayerMetadata(source: .user, createdAt: Date())
        )
        
        XCTAssertNoThrow(try manager.addLayer(textLayer))
        XCTAssertEqual(manager.layers.count, 1)
        XCTAssertEqual(manager.layers.first?.id, "test-1")
    }
    
    func testSVGGeneration() {
        let manager = SVGLayerManager(brandManager: MockBrandManager())
        
        // Add test layers
        let textLayer = createTestTextLayer()
        let shapeLayer = createTestShapeLayer()
        
        try! manager.addLayer(textLayer)
        try! manager.addLayer(shapeLayer)
        
        let svg = manager.generateFullSVG(canvasSize: CGSize(width: 400, height: 400))
        
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("<text"))
        XCTAssertTrue(svg.contains("<rect"))
        XCTAssertTrue(svg.contains("</svg>"))
    }
    
    func testBrandValidation() {
        let brandProfile = BrandProfile(
            id: "test-brand",
            name: "Test Brand",
            colors: BrandColors(
                primary: ["#FF0000", "#00FF00"],
                secondary: ["#0000FF"],
                accent: ["#FFFF00"],
                neutral: ["#000000", "#FFFFFF", "#CCCCCC"]
            ),
            fonts: BrandFonts(
                primary: "Arial",
                secondary: "Helvetica",
                allowedWeights: [.normal, .bold]
            ),
            guidelines: BrandGuidelines(
                minFontSize: 12,
                maxFontSize: 72,
                preferredSpacing: 16
            )
        )
        
        let brandManager = MockBrandManager()
        brandManager.currentBrand = brandProfile
        
        let manager = SVGLayerManager(brandManager: brandManager)
        
        // Test valid layer
        let validLayer = createTestTextLayer(color: "#FF0000", fontSize: 16)
        XCTAssertNoThrow(try manager.addLayer(validLayer))
        
        // Test invalid color
        let invalidColorLayer = createTestTextLayer(color: "#PURPLE", fontSize: 16)
        // Should validate against brand colors in real implementation
    }
}
```

### 5.2 UI Tests
```swift
class EnhancedLayersUITests: XCTestCase {
    
    func testTextLayerCreationAndEditing() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 10))
        
        // Add text layer
        let addTextButton = app.buttons["Add Text Layer"]
        XCTAssertTrue(addTextButton.waitForExistence(timeout: 5))
        addTextButton.tap()
        
        // Verify text layer appears
        let textLayer = app.staticTexts["New Text Layer"]
        XCTAssertTrue(textLayer.waitForExistence(timeout: 5))
        
        // Edit text content
        try editTextLayerContent(app: app, newText: "Hello SVG World")
        
        // Verify text updated
        let updatedText = app.staticTexts["Hello SVG World"]
        XCTAssertTrue(updatedText.waitForExistence(timeout: 3))
        
        // Test text styling
        try applyTextStyling(app: app, fontSize: 24, color: "red")
        
        // Take screenshot for verification
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Text_Layer_Styled"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testShapeLayerCreationAndTransform() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Add rectangle shape
        let addShapeButton = app.buttons["Add Shape Layer"]
        addShapeButton.tap()
        
        let rectangleOption = app.buttons["Rectangle"]
        rectangleOption.tap()
        
        // Verify shape appears
        let shapeLayer = app.otherElements["Rectangle Layer"]
        XCTAssertTrue(shapeLayer.waitForExistence(timeout: 5))
        
        // Test transformation
        try transformLayer(app: app, scale: 1.5, rotation: 45)
        
        // Screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Shape_Layer_Transformed"
        add(attachment)
    }
    
    func testVisualAIIntegration() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Create a complex design
        try createTestDesign(app: app)
        
        // Trigger AI analysis with visual input
        let canvas = app.otherElements["Canvas"]
        canvas.press(forDuration: 2.0) // Long press to trigger AI
        
        // Wait for AI analysis
        let aiIndicator = app.staticTexts["Analyzing with AI..."]
        XCTAssertTrue(aiIndicator.waitForExistence(timeout: 5))
        
        // Wait for suggestions
        let suggestionsView = app.otherElements["AI Suggestions"]
        XCTAssertTrue(suggestionsView.waitForExistence(timeout: 30))
        
        // Test variation navigation
        try testVariationNavigation(app: app)
        
        // Apply a variation
        canvas.tap() // Apply current variation
        
        // Verify changes applied
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "AI_Variation_Applied"
        add(attachment)
    }
    
    func testGroupOperations() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Create multiple layers
        try createMultipleLayers(app: app)
        
        // Select multiple layers
        try selectMultipleLayers(app: app, layerIds: ["layer-1", "layer-2"])
        
        // Group layers
        let groupButton = app.buttons["Group Layers"]
        groupButton.tap()
        
        // Verify group created
        let groupLayer = app.otherElements["Group Layer"]
        XCTAssertTrue(groupLayer.waitForExistence(timeout: 3))
        
        // Test group transformation
        try transformLayer(app: app, scale: 0.8, rotation: 30)
        
        // Screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Group_Operations"
        add(attachment)
    }
    
    func testBrandConsistency() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Set up brand profile
        try setupBrandProfile(app: app)
        
        // Create text with brand colors
        try createBrandedText(app: app)
        
        // Trigger AI analysis
        try triggerAIAnalysis(app: app)
        
        // Verify AI suggestions maintain brand consistency
        try verifyBrandConsistency(app: app)
        
        // Screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Brand_Consistency"
        add(attachment)
    }
    
    // MARK: - Helper Methods
    private func editTextLayerContent(app: XCUIApplication, newText: String) throws {
        // Implementation for editing text content
    }
    
    private func applyTextStyling(app: XCUIApplication, fontSize: Int, color: String) throws {
        // Implementation for applying text styling
    }
    
    private func transformLayer(app: XCUIApplication, scale: Double, rotation: Double) throws {
        // Implementation for layer transformation
    }
    
    private func createTestDesign(app: XCUIApplication) throws {
        // Create a complex test design with multiple layers
    }
    
    private func testVariationNavigation(app: XCUIApplication) throws {
        // Test TikTok-style navigation through AI variations
    }
}
```

## 6. Implementation Phases

### Phase 1: Core SVG Layer System (Week 1-2)
- ✅ Implement SVG data models
- ✅ Create SVGLayerManager
- ✅ Basic layer operations (add, remove, edit)
- ✅ Text and Rectangle layers only
- ✅ Unit tests for core functionality

### Phase 2: Enhanced Layer Types (Week 3)
- ✅ Circle, Triangle, and Image layers
- ✅ Background layers with gradients
- ✅ Group operations
- ✅ Layer styling (shadows, borders)

### Phase 3: Visual AI Integration (Week 4)
- ✅ Canvas capture service
- ✅ Enhanced AIService with visual input
- ✅ Brand profile management
- ✅ Visual analysis prompts

### Phase 4: UI Enhancement (Week 5)
- ✅ Enhanced layer editor UI
- ✅ Visual property panels
- ✅ Transformation controls
- ✅ Brand consistency indicators

### Phase 5: Testing & Polish (Week 6)
- ✅ Comprehensive UI test suite
- ✅ Performance optimization
- ✅ Bug fixes and polish
- ✅ Documentation updates

## 7. Success Metrics

1. **Layer System Performance**
   - Canvas rendering < 16ms (60fps)
   - Layer operations < 100ms
   - SVG generation < 500ms

2. **AI Integration Quality**
   - AI response time < 10 seconds
   - Brand consistency accuracy > 95%
   - User satisfaction with suggestions > 80%

3. **User Experience**
   - Layer creation flow < 3 taps
   - Transformation operations < 2 gestures
   - Zero crashes in critical paths

4. **Test Coverage**
   - Unit test coverage > 90%
   - UI test coverage for all core flows
   - Performance test benchmarks

This technical specification provides a comprehensive roadmap for implementing the enhanced layer system with visual AI integration, following TDD principles and maintaining the existing TikTok-style navigation experience.
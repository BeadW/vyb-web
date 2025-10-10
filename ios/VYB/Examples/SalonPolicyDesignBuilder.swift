import SwiftUI

// MARK: - Salon Policy Design Implementation
// This demonstrates our enhanced SVG layer system by recreating the salon policy design

@MainActor
class SalonPolicyDesignBuilder: ObservableObject {
    
    private let layerManager: SVGLayerManager
    private let canvasCaptureService: CanvasCaptureService
    
    init() {
        self.layerManager = SVGLayerManager()
        self.canvasCaptureService = CanvasCaptureService(layerManager: layerManager)
    }
    
    // MARK: - Design Creation
    func buildSalonPolicyDesign() -> [String] {
        var layerIds: [String] = []
        
        // 1. Create gradient background layer
        let backgroundLayer = createGradientBackground()
        layerManager.addLayer(backgroundLayer)
        layerIds.append(backgroundLayer.id)
        
        // 2. Create title with emojis
        let titleLayer = createTitleLayer()
        layerManager.addLayer(titleLayer)
        layerIds.append(titleLayer.id)
        
        // 3. Create main policy text
        let mainTextLayer = createMainPolicyText()
        layerManager.addLayer(mainTextLayer)
        layerIds.append(mainTextLayer.id)
        
        // 4. Create subtitle
        let subtitleLayer = createSubtitleText()
        layerManager.addLayer(subtitleLayer)
        layerIds.append(subtitleLayer.id)
        
        // 5. Create logo
        let logoLayer = createLogoLayer()
        layerManager.addLayer(logoLayer)
        layerIds.append(logoLayer.id)
        
        return layerIds
    }
    
    // MARK: - Layer Creation Methods
    
    private func createGradientBackground() -> SVGLayer {
        let gradientStops = [
            GradientStop(color: "#1E3A5F", position: 0.0), // Darker blue
            GradientStop(color: "#2E5A7F", position: 1.0)  // Lighter blue
        ]
        
        let gradient = GradientStyle(
            type: .linear,
            angle: 45, // Diagonal gradient
            stops: gradientStops
        )
        
        return SVGLayer(
            id: "background-gradient",
            type: .background,
            content: SVGLayerContent(
                backgroundGradient: gradient
            ),
            transform: SVGTransform(
                x: 0, y: 0,
                scaleX: 1, scaleY: 1,
                rotation: 0, opacity: 1
            ),
            style: SVGLayerStyle(),
            constraints: SVGLayerConstraints(
                locked: false, visible: true,
                lockPosition: true, lockSize: true,
                lockRotation: true, lockContent: false,
                lockStyle: false,
                maintainAspectRatio: false
            ),
            metadata: LayerMetadata(
                name: "Background Gradient",
                createdAt: Date(),
                lastModified: Date(),
                tags: ["background", "gradient"]
            )
        )
    }
    
    private func createTitleLayer() -> SVGLayer {
        return SVGLayer(
            id: "title-text",
            type: .text,
            content: SVGLayerContent(
                text: "👩‍💼 Cancellation & No-Show Policy 👩‍💼",
                fontSize: 32,
                fontFamily: "Times New Roman",
                fontWeight: .w400,
                textColor: "#FFFFFF",
                textAlign: .center,
                lineHeight: 1.2,
                letterSpacing: 0.5
            ),
            transform: SVGTransform(
                x: 50, y: 80, // Centered horizontally, top positioned
                scaleX: 1, scaleY: 1,
                rotation: 0, opacity: 1
            ),
            style: SVGLayerStyle(
                dropShadow: DropShadowStyle(
                    offsetX: 0, offsetY: 2,
                    blur: 4, spread: 0,
                    color: "rgba(0,0,0,0.3)"
                )
            ),
            constraints: SVGLayerConstraints(
                locked: false, visible: true,
                lockPosition: false, lockSize: false,
                lockRotation: true, lockContent: false,
                lockStyle: false,
                maintainAspectRatio: true
            ),
            metadata: LayerMetadata(
                name: "Policy Title",
                createdAt: Date(),
                lastModified: Date(),
                tags: ["title", "text", "emoji"]
            )
        )
    }
    
    private func createMainPolicyText() -> SVGLayer {
        let policyText = """
        A 50% fee will apply for no-
        shows or cancellations made
        within 3 hours of your
        appointment.
        """
        
        return SVGLayer(
            id: "main-policy-text",
            type: .text,
            content: SVGLayerContent(
                text: policyText,
                fontSize: 48,
                fontFamily: "Times New Roman",
                fontWeight: .w300, // Thin weight
                textColor: "#FFFFFF",
                textAlign: .center,
                lineHeight: 1.3,
                letterSpacing: 0.2
            ),
            transform: SVGTransform(
                x: 50, y: 200, // Centered horizontally, middle positioned
                scaleX: 1, scaleY: 1,
                rotation: 0, opacity: 1
            ),
            style: SVGLayerStyle(
                dropShadow: DropShadowStyle(
                    offsetX: 0, offsetY: 1,
                    blur: 2, spread: 0,
                    color: "rgba(0,0,0,0.2)"
                )
            ),
            constraints: SVGLayerConstraints(
                locked: false, visible: true,
                lockPosition: false, lockSize: false,
                lockRotation: true, lockContent: false,
                lockStyle: false,
                maintainAspectRatio: true
            ),
            metadata: LayerMetadata(
                name: "Main Policy Text",
                createdAt: Date(),
                lastModified: Date(),
                tags: ["policy", "main-text", "large"]
            )
        )
    }
    
    private func createSubtitleText() -> SVGLayer {
        let subtitleText = """
        THANK YOU FOR UNDERSTANDING — THIS HELPS US MANAGE OUR
        TIME AND CONTINUE PROVIDING THE BEST SERVICE FOR ALL CLIENTS.
        ❤️
        """
        
        return SVGLayer(
            id: "subtitle-text",
            type: .text,
            content: SVGLayerContent(
                text: subtitleText,
                fontSize: 14,
                fontFamily: "Helvetica Neue",
                fontWeight: .w400,
                textColor: "#E8F4F8", // Slightly off-white
                textAlign: .center,
                lineHeight: 1.4,
                letterSpacing: 0.3
            ),
            transform: SVGTransform(
                x: 50, y: 420, // Centered horizontally, bottom positioned
                scaleX: 1, scaleY: 1,
                rotation: 0, opacity: 0.9
            ),
            style: SVGLayerStyle(),
            constraints: SVGLayerConstraints(
                locked: false, visible: true,
                lockPosition: false, lockSize: false,
                lockRotation: true, lockContent: false,
                lockStyle: false,
                maintainAspectRatio: true
            ),
            metadata: LayerMetadata(
                name: "Subtitle Text",
                createdAt: Date(),
                lastModified: Date(),
                tags: ["subtitle", "small-text", "footer"]
            )
        )
    }
    
    private func createLogoLayer() -> SVGLayer {
        return SVGLayer(
            id: "mystique-logo",
            type: .image,
            content: SVGLayerContent(
                // For demonstration, we'll create a circular placeholder
                // In real implementation, this would be the actual logo image
                text: "Mystique Hair Co.", // Placeholder text
                fontSize: 12,
                fontFamily: "Helvetica Neue",
                fontWeight: .w500,
                textColor: "#FFFFFF"
            ),
            transform: SVGTransform(
                x: 320, y: 420, // Bottom-right positioned
                scaleX: 1, scaleY: 1,
                rotation: 0, opacity: 0.8
            ),
            style: SVGLayerStyle(
                border: BorderStyle(
                    width: 2,
                    color: "#FFFFFF",
                    style: .solid
                ),
                borderRadius: 30 // Circular appearance
            ),
            constraints: SVGLayerConstraints(
                locked: false, visible: true,
                lockPosition: false, lockSize: false,
                lockRotation: true, lockContent: true,
                lockStyle: false,
                maintainAspectRatio: true,
                minWidth: 60, minHeight: 60,
                maxWidth: 80, maxHeight: 80
            ),
            metadata: LayerMetadata(
                name: "Mystique Logo",
                createdAt: Date(),
                lastModified: Date(),
                tags: ["logo", "brand", "circular"]
            )
        )
    }
    
    // MARK: - Canvas Operations
    
    func captureDesignForAI() async throws -> (svgData: String, description: String) {
        let canvasSize = CGSize(width: 400, height: 500) // Instagram post dimensions
        return try await canvasCaptureService.captureForAI(canvasSize: canvasSize)
    }
    
    func generateDesignSVG() -> String {
        let canvasSize = CGSize(width: 400, height: 500)
        return layerManager.generateFullSVG(canvasSize: canvasSize)
    }
    
    // MARK: - Design Variations
    
    func createColorVariation() {
        // Example: Change to purple gradient
        if let backgroundLayer = layerManager.layers.first(where: { $0.id == "background-gradient" }) {
            layerManager.updateLayer(id: backgroundLayer.id) { layer in
                let purpleStops = [
                    GradientStop(color: "#4A1A4A", position: 0.0), // Dark purple
                    GradientStop(color: "#6A2A6A", position: 1.0)  // Light purple
                ]
                layer.content.backgroundGradient = GradientStyle(
                    type: .linear,
                    angle: 45,
                    stops: purpleStops
                )
            }
        }
    }
    
    func createFontVariation() {
        // Example: Change main text to different font
        if let textLayer = layerManager.layers.first(where: { $0.id == "main-policy-text" }) {
            layerManager.updateLayer(id: textLayer.id) { layer in
                layer.content.fontFamily = "Georgia"
                layer.content.fontSize = 44
            }
        }
    }
}

// MARK: - Supporting Data Structures

struct LayerMetadata: Codable, Equatable {
    let name: String
    let createdAt: Date
    let lastModified: Date
    let tags: [String]
}

// MARK: - Temporary SVGLayerManager Implementation
// This provides the interface needed for our demonstration
class SVGLayerManager: ObservableObject {
    @Published var layers: [SVGLayer] = []
    
    func addLayer(_ layer: SVGLayer) {
        layers.append(layer)
    }
    
    func updateLayer(id: String, update: (inout SVGLayer) -> Void) {
        guard let index = layers.firstIndex(where: { $0.id == id }) else { return }
        update(&layers[index])
    }
    
    func generateFullSVG(canvasSize: CGSize) -> String {
        let layerElements = layers.compactMap { layer in
            return layer.toSVGElement()
        }.joined(separator: "\n  ")
        
        return """
        <svg width="\(Int(canvasSize.width))" height="\(Int(canvasSize.height))" 
             viewBox="0 0 \(Int(canvasSize.width)) \(Int(canvasSize.height))"
             xmlns="http://www.w3.org/2000/svg"
             xmlns:xlink="http://www.w3.org/1999/xlink">
          <defs>
            <!-- Gradients and filters would be defined here -->
          </defs>
          \(layerElements)
        </svg>
        """
    }
}

// MARK: - Usage Example
extension SalonPolicyDesignBuilder {
    
    func demonstrateCapabilities() {
        print("🎨 Building Salon Policy Design using Enhanced SVG Layer System")
        
        // Create the design
        let layerIds = buildSalonPolicyDesign()
        print("✅ Created \(layerIds.count) layers:")
        
        for layer in layerManager.layers {
            print("  - \(layer.metadata.name) (\(layer.type.rawValue))")
        }
        
        // Generate SVG
        let svg = generateDesignSVG()
        print("📄 Generated SVG (\(svg.count) characters)")
        
        // Demonstrate variations
        print("🎨 Creating color variation...")
        createColorVariation()
        
        print("🔤 Creating font variation...")
        createFontVariation()
        
        print("🎯 Design demonstration complete!")
    }
}
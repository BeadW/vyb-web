import SwiftUI

// MARK: - Salon Policy Design Creator
// This extension creates the salon cancellation policy design using existing SimpleLayer system

extension ContentView {
    
    // MARK: - Create Salon Policy Design
    func createSalonPolicyDesign() {
        print("🎨 Creating Salon Policy Design with current layer system...")
        
        // Clear existing layers
        layers.removeAll()
        
        // Canvas setup for Instagram post (1:1 ratio)
        let canvasWidth: Double = 400
        let canvasHeight: Double = 500
        canvasSize = CGSize(width: canvasWidth, height: canvasHeight)
        
        // Create layers in order (bottom to top)
        createBackgroundLayer(canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        createTitleLayer(canvasWidth: canvasWidth)
        createMainTextLayer(canvasWidth: canvasWidth)
        createSubtitleLayer(canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        createLogoLayer(canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        
        // Save to history
        saveCurrentStateToHistory(source: .userEdit, title: "Created Salon Policy Design")
        
        print("✅ Salon Policy Design created with \(layers.count) layers")
    }
    
    // MARK: - Background Layer (Shape as gradient substitute)
    private func createBackgroundLayer(canvasWidth: Double, canvasHeight: Double) {
        let backgroundLayer = SimpleLayer(
            id: "background-gradient",
            type: "shape", // Using shape type for background
            content: "Background",
            x: 0,
            y: 0,
            zOrder: 0
        )
        
        layers.append(backgroundLayer)
        print("  ✓ Background layer created")
    }
    
    // MARK: - Title Layer with Emojis
    private func createTitleLayer(canvasWidth: Double) {
        var titleLayer = SimpleLayer(
            id: "title-text",
            type: "text",
            content: "👩‍💼 Cancellation & No-Show Policy 👩‍💼",
            x: canvasWidth / 2, // Center horizontally
            y: 80, // Top positioned
            zOrder: 1
        )
        
        // Style the title
        titleLayer.fontSize = 28
        titleLayer.fontWeight = .semibold
        titleLayer.textColor = .white
        titleLayer.textAlignment = .center
        titleLayer.hasShadow = true
        titleLayer.shadowColor = .black.opacity(0.3)
        
        layers.append(titleLayer)
        print("  ✓ Title layer created: '\(titleLayer.content)'")
    }
    
    // MARK: - Main Policy Text Layer
    private func createMainTextLayer(canvasWidth: Double) {
        let policyText = """
        A 50% fee will apply for no-
        shows or cancellations made
        within 3 hours of your
        appointment.
        """
        
        var mainTextLayer = SimpleLayer(
            id: "main-policy-text",
            type: "text",
            content: policyText,
            x: canvasWidth / 2, // Center horizontally
            y: 250, // Center positioned
            zOrder: 2
        )
        
        // Style the main text
        mainTextLayer.fontSize = 36
        mainTextLayer.fontWeight = .light
        mainTextLayer.textColor = .white
        mainTextLayer.textAlignment = .center
        mainTextLayer.hasShadow = true
        mainTextLayer.shadowColor = .black.opacity(0.2)
        
        layers.append(mainTextLayer)
        print("  ✓ Main policy text layer created")
    }
    
    // MARK: - Subtitle Layer
    private func createSubtitleLayer(canvasWidth: Double, canvasHeight: Double) {
        let subtitleText = """
        THANK YOU FOR UNDERSTANDING — THIS HELPS US MANAGE OUR
        TIME AND CONTINUE PROVIDING THE BEST SERVICE FOR ALL CLIENTS. ❤️
        """
        
        var subtitleLayer = SimpleLayer(
            id: "subtitle-text",
            type: "text",
            content: subtitleText,
            x: canvasWidth / 2, // Center horizontally
            y: canvasHeight - 80, // Bottom positioned
            zOrder: 3
        )
        
        // Style the subtitle
        subtitleLayer.fontSize = 12
        subtitleLayer.fontWeight = .medium
        subtitleLayer.textColor = .white.opacity(0.9)
        subtitleLayer.textAlignment = .center
        
        layers.append(subtitleLayer)
        print("  ✓ Subtitle layer created")
    }
    
    // MARK: - Logo Layer (Text placeholder)
    private func createLogoLayer(canvasWidth: Double, canvasHeight: Double) {
        var logoLayer = SimpleLayer(
            id: "mystique-logo",
            type: "text", // Using text as logo placeholder
            content: "Mystique\nHair Co.",
            x: canvasWidth - 60, // Bottom-right positioned
            y: canvasHeight - 60,
            zOrder: 4
        )
        
        // Style the logo
        logoLayer.fontSize = 10
        logoLayer.fontWeight = .medium
        logoLayer.textColor = .white.opacity(0.8)
        logoLayer.textAlignment = .center
        logoLayer.hasStroke = true
        logoLayer.strokeColor = .white
        logoLayer.strokeWidth = 1.0
        
        layers.append(logoLayer)
        print("  ✓ Logo placeholder layer created")
    }
    
    // MARK: - Design Variations
    
    func createSalonPolicyColorVariation() {
        print("🎨 Creating purple color variation...")
        
        // Update text colors for purple theme
        for i in layers.indices {
            if layers[i].type == "text" {
                // Adjust text colors for purple background
                layers[i].textColor = .white
            }
        }
        
        saveCurrentStateToHistory(source: .userEdit, title: "Purple Color Variation")
        print("  ✓ Purple color variation applied")
    }
    
    func createSalonPolicyFontVariation() {
        print("🔤 Creating font variation...")
        
        // Update fonts for all text layers
        for i in layers.indices {
            if layers[i].type == "text" {
                switch layers[i].id {
                case "title-text":
                    layers[i].fontSize = 30
                    layers[i].fontWeight = .bold
                case "main-policy-text":
                    layers[i].fontSize = 34
                    layers[i].fontWeight = .medium
                case "subtitle-text":
                    layers[i].fontSize = 11
                    layers[i].fontWeight = .regular
                default:
                    break
                }
            }
        }
        
        saveCurrentStateToHistory(source: .userEdit, title: "Font Variation")
        print("  ✓ Font variation applied")
    }
    
    func createSalonPolicyLayoutVariation() {
        print("📐 Creating layout variation...")
        
        // Adjust positioning for tighter layout
        for i in layers.indices {
            switch layers[i].id {
            case "title-text":
                layers[i].y = 60 // Move title higher
            case "main-policy-text":
                layers[i].y = 220 // Move main text up
            case "subtitle-text":
                layers[i].y = canvasSize.height - 60 // Adjust subtitle
            default:
                break
            }
        }
        
        saveCurrentStateToHistory(source: .userEdit, title: "Layout Variation")
        print("  ✓ Layout variation applied")
    }
    
    // MARK: - Preview and Export Functions
    
    func previewSalonDesign() -> String {
        var preview = "Salon Policy Design Preview:\n"
        preview += "Canvas Size: \(Int(canvasSize.width))×\(Int(canvasSize.height))px\n"
        preview += "Layers: \(layers.count)\n\n"
        
        for layer in layers.sorted(by: { $0.zOrder < $1.zOrder }) {
            preview += "• \(layer.type.capitalized): "
            if layer.type == "text" {
                let shortContent = String(layer.content.prefix(30))
                preview += "'\(shortContent)...'\n"
            } else {
                preview += "\(layer.content)\n"
            }
        }
        
        return preview
    }
    
    func exportDesignMetadata() -> SalonDesignExport {
        return SalonDesignExport(
            title: "Salon Cancellation Policy",
            canvasSize: canvasSize,
            layers: layers.map { layer in
                LayerExportInfo(
                    id: layer.id,
                    type: layer.type,
                    content: layer.content,
                    position: CGPoint(x: layer.x, y: layer.y),
                    styling: LayerStyling(
                        fontSize: layer.fontSize,
                        fontWeight: layer.fontWeight,
                        textColor: layer.textColor,
                        alignment: layer.textAlignment
                    )
                )
            }
        )
    }
}

// MARK: - Supporting Data Structures

struct SalonDesignExport {
    let title: String
    let canvasSize: CGSize
    let layers: [LayerExportInfo]
}

struct LayerExportInfo {
    let id: String
    let type: String
    let content: String
    let position: CGPoint
    let styling: LayerStyling
}

struct LayerStyling {
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let textColor: Color
    let alignment: CustomTextAlignment
}

// MARK: - Usage Instructions
/*
To create the salon policy design in the app:

1. Call createSalonPolicyDesign() to build the base design
2. Use createSalonPolicyColorVariation() for color themes
3. Use createSalonPolicyFontVariation() for font changes
4. Use createSalonPolicyLayoutVariation() for spacing adjustments
5. Use previewSalonDesign() to see layer information
6. Use exportDesignMetadata() to get structured data

Example:
createSalonPolicyDesign()
print(previewSalonDesign())
*/
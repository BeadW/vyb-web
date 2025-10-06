import SwiftUI
import CoreData

enum LayerTool: CaseIterable {
    case select, text, image, shape, background
    
    var displayName: String {
        switch self {
        case .select: return "Select"
        case .text: return "Text"
        case .image: return "Image"
        case .shape: return "Shape"
        case .background: return "Background"
        }
    }
    
    var iconName: String {
        switch self {
        case .select: return "cursorarrow.click.2"
        case .text: return "textformat"
        case .image: return "photo"
        case .shape: return "circle.square"
        case .background: return "rectangle.fill"
        }
    }
}

@MainActor
class LayerManager: ObservableObject {
    @Published var layers: [Layer] = []
    @Published var selectedLayer: Layer?
    @Published var currentTool: LayerTool = .select
    @Published var canUndo = false
    @Published var canRedo = false
    @Published var canPaste = false
    
    private var clipboard: Layer?
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadLayers()
    }
    
    // MARK: - Layer Management
    
    func loadLayers() {
        // Load layers from Core Data
        // This would fetch from your DesignCanvas or similar
        // For now, we'll create some sample layers
        createSampleLayers()
    }
    
    private func createSampleLayers() {
        // Create sample layers for testing
        // This would be replaced with actual Core Data fetching
    }
    
    func selectLayer(_ layer: Layer) {
        selectedLayer = layer
    }
    
    func addTextLayer() {
        let layer = Layer(context: context)
        layer.id = UUID().uuidString
        layer.type = .text
        layer.transform = Transform(x: 100, y: 100, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1)
        layer.content = LayerContent(text: "New Text", fontSize: 16, fontFamily: "System")
        layer.style = LayerStyle()
        layer.constraints = LayerConstraints(locked: false, visible: true)
        layer.zIndex = Int32(layers.count)
        
        layers.append(layer)
        selectedLayer = layer
        saveContext()
    }
    
    func addImageLayer() {
        let layer = Layer(context: context)
        layer.id = UUID().uuidString
        layer.type = .image
        layer.transform = Transform(x: 100, y: 100, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1)
        layer.content = LayerContent(imageUrl: "placeholder.jpg")
        layer.style = LayerStyle()
        layer.constraints = LayerConstraints(locked: false, visible: true)
        layer.zIndex = Int32(layers.count)
        
        layers.append(layer)
        selectedLayer = layer
        saveContext()
    }
    
    func addShapeLayer(_ shapeType: ShapeType) {
        let layer = Layer(context: context)
        layer.id = UUID().uuidString
        layer.type = .shape
        layer.transform = Transform(x: 100, y: 100, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1)
        layer.content = LayerContent(
            shapeType: shapeType.rawValue,
            fill: "#007AFF",
            stroke: "#000000",
            strokeWidth: 2
        )
        layer.style = LayerStyle()
        layer.constraints = LayerConstraints(locked: false, visible: true)
        layer.zIndex = Int32(layers.count)
        
        layers.append(layer)
        selectedLayer = layer
        saveContext()
    }
    
    func addCameraImage() {
        // Implement camera functionality
        print("Camera functionality not yet implemented")
    }
    
    func addWebImage() {
        // Implement web image functionality
        print("Web image functionality not yet implemented")
    }
    
    func duplicateLayer(_ layer: Layer) {
        let newLayer = Layer(context: context)
        newLayer.id = UUID().uuidString
        newLayer.type = layer.type
        
        // Copy transform with slight offset
        var newTransform = layer.transform
        newTransform.x += 20
        newTransform.y += 20
        newLayer.transform = newTransform
        
        newLayer.content = layer.content
        newLayer.style = layer.style
        newLayer.constraints = layer.constraints
        newLayer.zIndex = Int32(layers.count)
        
        layers.append(newLayer)
        selectedLayer = newLayer
        saveContext()
    }
    
    func deleteLayer(_ layer: Layer) {
        if let index = layers.firstIndex(where: { $0.id == layer.id }) {
            layers.remove(at: index)
            context.delete(layer)
            
            if selectedLayer?.id == layer.id {
                selectedLayer = layers.first
            }
            
            saveContext()
        }
    }
    
    func toggleLayerVisibility(_ layer: Layer) {
        var constraints = layer.constraints
        constraints.visible.toggle()
        layer.constraints = constraints
        saveContext()
    }
    
    func toggleLayerLock(_ layer: Layer) {
        var constraints = layer.constraints
        constraints.locked.toggle()
        layer.constraints = constraints
        saveContext()
    }
    
    // MARK: - Text Editing
    
    func updateTextSize(_ layer: Layer, size: Double) {
        var content = layer.content
        content.fontSize = size
        layer.content = content
        saveContext()
    }
    
    func updateFontFamily(_ layer: Layer, fontFamily: String) {
        var content = layer.content
        content.fontFamily = fontFamily
        layer.content = content
        saveContext()
    }
    
    func toggleFontStyle(_ layer: Layer, style: FontStyleButton.Style) {
        var layerStyle = layer.style ?? LayerStyle()
        
        switch style {
        case .bold:
            // Toggle bold - this would need to be implemented in LayerStyle
            break
        case .italic:
            // Toggle italic
            break
        case .underline:
            // Toggle underline
            break
        }
        
        layer.style = layerStyle
        saveContext()
    }
    
    func updateTextAlignment(_ layer: Layer, alignment: TextAlignment) {
        var style = layer.style ?? LayerStyle()
        // Update text alignment in style
        layer.style = style
        saveContext()
    }
    
    func updateLineHeight(_ layer: Layer, height: Double) {
        var style = layer.style ?? LayerStyle()
        // Update line height in style
        layer.style = style
        saveContext()
    }
    
    // MARK: - Image Editing
    
    func replaceImage(_ layer: Layer) {
        // Implement image replacement functionality
        print("Image replacement not yet implemented")
    }
    
    func updateOpacity(_ layer: Layer, opacity: Double) {
        var transform = layer.transform
        transform.opacity = opacity
        layer.transform = transform
        saveContext()
    }
    
    func updateBrightness(_ layer: Layer, brightness: Double) {
        var style = layer.style ?? LayerStyle()
        // Update brightness in style
        layer.style = style
        saveContext()
    }
    
    func updateContrast(_ layer: Layer, contrast: Double) {
        var style = layer.style ?? LayerStyle()
        // Update contrast in style
        layer.style = style
        saveContext()
    }
    
    // MARK: - Shape Editing
    
    func updateShapeFill(_ layer: Layer, color: String) {
        var content = layer.content
        content.fill = color
        layer.content = content
        saveContext()
    }
    
    func updateShapeStroke(_ layer: Layer, color: String) {
        var content = layer.content
        content.stroke = color
        layer.content = content
        saveContext()
    }
    
    func updateStrokeWidth(_ layer: Layer, width: Double) {
        var content = layer.content
        content.strokeWidth = width
        layer.content = content
        saveContext()
    }
    
    // MARK: - General Styling
    
    func updateColor(_ layer: Layer, color: String) {
        var content = layer.content
        content.color = color
        layer.content = content
        saveContext()
    }
    
    func addShadow(_ layer: Layer) {
        var style = layer.style ?? LayerStyle()
        style.boxShadow = ShadowData(x: 0, y: 2, blur: 4, spread: 0, color: "#000000")
        layer.style = style
        saveContext()
    }
    
    func removeShadow(_ layer: Layer) {
        var style = layer.style ?? LayerStyle()
        style.boxShadow = nil
        layer.style = style
        saveContext()
    }
    
    func updateShadowBlur(_ layer: Layer, blur: Double) {
        var style = layer.style ?? LayerStyle()
        if var shadow = style.boxShadow {
            shadow.blur = blur
            style.boxShadow = shadow
            layer.style = style
            saveContext()
        }
    }
    
    func updateShadowOffsetX(_ layer: Layer, x: Double) {
        var style = layer.style ?? LayerStyle()
        if var shadow = style.boxShadow {
            shadow.x = x
            style.boxShadow = shadow
            layer.style = style
            saveContext()
        }
    }
    
    func updateShadowOffsetY(_ layer: Layer, y: Double) {
        var style = layer.style ?? LayerStyle()
        if var shadow = style.boxShadow {
            shadow.y = y
            style.boxShadow = shadow
            layer.style = style
            saveContext()
        }
    }
    
    // MARK: - History Management
    
    func undo() {
        // Implement undo functionality
        print("Undo not yet implemented")
    }
    
    func redo() {
        // Implement redo functionality
        print("Redo not yet implemented")
    }
    
    // MARK: - Clipboard Operations
    
    func copyLayer(_ layer: Layer) {
        clipboard = layer
        canPaste = true
    }
    
    func paste() {
        guard let clipboardLayer = clipboard else { return }
        duplicateLayer(clipboardLayer)
    }
    
    func editLayer(_ layer: Layer) {
        // Enter edit mode for the layer
        selectedLayer = layer
        // Trigger appropriate editing interface based on layer type
    }
    
    // MARK: - Core Data
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
        
        objectWillChange.send()
    }
}

// MARK: - Temporary PersistenceController
// This should be moved to its own file or use your existing one
struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "VYB") // Your Core Data model name
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
    }
}
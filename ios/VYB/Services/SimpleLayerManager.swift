import SwiftUI
import CoreData

// MARK: - Simple Layer Types for UI Components

import SwiftUI
import CoreData

// LayerTool is defined in LayerManager.swift

enum FontStyle {
    case bold, italic, underline
}

// MARK: - Simplified Layer Manager for UI Components

@MainActor
class SimpleLayerManager: ObservableObject {
    @Published var selectedLayerCount: Int = 0
    @Published var currentTool: SimpleLayerType = .text
    @Published var canUndo = false
    @Published var canRedo = false
    
    // Font properties for selected layer
    @Published var selectedFontSize: Double = 16
    @Published var selectedFontFamily: String = "System"
    @Published var selectedTextAlignment: String = "left"
    @Published var isBold: Bool = false
    @Published var isItalic: Bool = false
    @Published var isUnderlined: Bool = false
    
    // Color properties
    @Published var selectedColor: Color = .black
    @Published var selectedOpacity: Double = 1.0
    
    // Image properties
    @Published var brightness: Double = 0
    @Published var contrast: Double = 0
    @Published var saturation: Double = 0
    
    // Shape properties  
    @Published var shapeFillColor: Color = .blue
    @Published var shapeStrokeColor: Color = .black
    @Published var strokeWidth: Double = 2
    
    // Layer list for UI
    @Published var layerItems: [SimpleLayerItem] = []
    
    init() {
        // Create some sample layers for demo
        layerItems = [
            SimpleLayerItem(id: "1", name: "Background", type: .background, isVisible: true, isLocked: false),
            SimpleLayerItem(id: "2", name: "Main Text", type: .text, isVisible: true, isLocked: false),
            SimpleLayerItem(id: "3", name: "Profile Image", type: .image, isVisible: true, isLocked: false)
        ]
    }
    
    func selectTool(_ tool: SimpleLayerType) {
        currentTool = tool
    }
    
    func toggleFontStyle(_ style: FontStyle) {
        switch style {
        case .bold:
            isBold.toggle()
        case .italic:
            isItalic.toggle()
        case .underline:
            isUnderlined.toggle()
        }
    }
    
    func updateFontSize(_ size: Double) {
        selectedFontSize = size
    }
    
    func updateOpacity(_ opacity: Double) {
        selectedOpacity = opacity
    }
    
    func updateBrightness(_ brightness: Double) {
        self.brightness = brightness
    }
    
    func updateContrast(_ contrast: Double) {
        self.contrast = contrast
    }
    
    func addTextLayer() {
        let newLayer = SimpleLayerItem(
            id: UUID().uuidString,
            name: "Text Layer \(layerItems.count + 1)",
            type: .text,
            isVisible: true,
            isLocked: false
        )
        layerItems.append(newLayer)
    }
    
    func addImageLayer() {
        let newLayer = SimpleLayerItem(
            id: UUID().uuidString,
            name: "Image Layer \(layerItems.count + 1)",
            type: .image,
            isVisible: true,
            isLocked: false
        )
        layerItems.append(newLayer)
    }
    
    func deleteLayer(_ layer: SimpleLayerItem) {
        layerItems.removeAll { $0.id == layer.id }
    }
    
    func toggleLayerVisibility(_ layer: SimpleLayerItem) {
        if let index = layerItems.firstIndex(where: { $0.id == layer.id }) {
            layerItems[index].isVisible.toggle()
        }
    }
    
    func toggleLayerLock(_ layer: SimpleLayerItem) {
        if let index = layerItems.firstIndex(where: { $0.id == layer.id }) {
            layerItems[index].isLocked.toggle()
        }
    }
}

// MARK: - Simple Layer Types

enum SimpleLayerType: String, CaseIterable, Hashable {
    case background, text, image, shape
    
    var displayName: String {
        switch self {
        case .background: return "Background"
        case .text: return "Text"
        case .image: return "Image"
        case .shape: return "Shape"
        }
    }
}

// MARK: - Layer Item for UI

struct SimpleLayerItem: Identifiable, Hashable {
    let id: String
    var name: String
    let type: SimpleLayerType
    var isVisible: Bool
    var isLocked: Bool
}
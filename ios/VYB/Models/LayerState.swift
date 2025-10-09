import Foundation
import SwiftUI

// MARK: - Layer Management State
class LayerState: ObservableObject {
    @Published var layers: [LayerItem] = []
    @Published var selectedLayerIds: Set<String> = []
    @Published var isLayerListExpanded: Bool = false
    @Published var showAddLayerModal: Bool = false
    @Published var showPropertiesPanel: Bool = false
    
    var selectedLayers: [LayerItem] {
        layers.filter { selectedLayerIds.contains($0.id) }
    }
    
    var hasSelection: Bool {
        !selectedLayerIds.isEmpty
    }
    
    var primarySelectedLayer: LayerItem? {
        selectedLayers.first
    }
    
    init() {
        // Initialize with default post text layer
        addDefaultPostTextLayer()
    }
    
    // MARK: - Layer Management
    func addLayer(_ layer: LayerItem) {
        layers.append(layer)
        selectLayer(layer.id)
    }
    
    func removeLayer(_ id: String) {
        layers.removeAll { $0.id == id }
        selectedLayerIds.remove(id)
    }
    
    func selectLayer(_ id: String, addToSelection: Bool = false) {
        if addToSelection {
            selectedLayerIds.insert(id)
        } else {
            selectedLayerIds = [id]
        }
    }
    
    func deselectLayer(_ id: String) {
        selectedLayerIds.remove(id)
    }
    
    func clearSelection() {
        selectedLayerIds.removeAll()
    }
    
    func moveLayer(from source: IndexSet, to destination: Int) {
        layers.move(fromOffsets: source, toOffset: destination)
    }
    
    func toggleLayerVisibility(_ id: String) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index].isVisible.toggle()
        }
    }
    
    func updateLayerProperty<T>(_ id: String, keyPath: WritableKeyPath<LayerItem, T>, value: T) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index][keyPath: keyPath] = value
        }
    }
    
    private func addDefaultPostTextLayer() {
        let postTextLayer = LayerItem(
            id: UUID().uuidString,
            name: "Post Text",
            type: .postText,
            content: LayerItemContent(text: "What's on your mind?"),
            transform: LayerTransform(x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1),
            isVisible: true,
            isLocked: false
        )
        layers.append(postTextLayer)
    }
}

// MARK: - Simplified Layer Models for UI
struct LayerItem: Identifiable, Hashable {
    let id: String
    var name: String
    var type: LayerItemType
    var content: LayerItemContent
    var transform: LayerTransform
    var style: LayerItemStyle
    var isVisible: Bool
    var isLocked: Bool
    var zIndex: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LayerItem, rhs: LayerItem) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: String, name: String, type: LayerItemType, content: LayerItemContent, 
         transform: LayerTransform, isVisible: Bool = true, isLocked: Bool = false, 
         style: LayerItemStyle = LayerItemStyle(), zIndex: Int = 0) {
        self.id = id
        self.name = name
        self.type = type
        self.content = content
        self.transform = transform
        self.style = style
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.zIndex = zIndex
    }
}

enum LayerItemType: String, CaseIterable {
    case postText = "post_text"
    case text = "text"
    case image = "image"
    case shape = "shape"
    case background = "background"
    case group = "group"
    
    var displayName: String {
        switch self {
        case .postText: return "Post Text"
        case .text: return "Text"
        case .image: return "Image"
        case .shape: return "Shape"
        case .background: return "Background"
        case .group: return "Group"
        }
    }
    
    var icon: String {
        switch self {
        case .postText: return "text.quote"
        case .text: return "textformat"
        case .image: return "photo"
        case .shape: return "circle"
        case .background: return "rectangle"
        case .group: return "folder"
        }
    }
}

struct LayerItemContent {
    var text: String?
    var fontSize: Double?
    var fontFamily: String?
    var imageUrl: String?
    var color: String?
    var shapeType: String?
    var childLayerIds: [String]?
    
    init(text: String? = nil, fontSize: Double? = 16, fontFamily: String? = nil,
         imageUrl: String? = nil, color: String? = nil, shapeType: String? = nil,
         childLayerIds: [String]? = nil) {
        self.text = text
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.imageUrl = imageUrl
        self.color = color
        self.shapeType = shapeType
        self.childLayerIds = childLayerIds
    }
}

struct LayerTransform: Codable {
    var x: Double = 0
    var y: Double = 0
    var scaleX: Double = 1
    var scaleY: Double = 1
    var rotation: Double = 0
    var opacity: Double = 1
}

struct LayerItemStyle {
    var fontSize: Double?
    var fontFamily: String?
    var color: String?
    var backgroundColor: String?
    var borderRadius: Double?
    var borderWidth: Double?
    var borderColor: String?
    
    init(fontSize: Double? = nil, fontFamily: String? = nil, color: String? = nil,
         backgroundColor: String? = nil, borderRadius: Double? = nil,
         borderWidth: Double? = nil, borderColor: String? = nil) {
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.color = color
        self.backgroundColor = backgroundColor
        self.borderRadius = borderRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
    }
}
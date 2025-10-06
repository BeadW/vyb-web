import Foundation
import CoreData
import SwiftUI

// MARK: - Layer Type Enum
public enum LayerType: String, CaseIterable, Codable {
    case text = "text"
    case image = "image"
    case background = "background"
    case shape = "shape"
    case group = "group"
    case postText = "post_text"
}

// MARK: - Transform Properties
public struct Transform: Codable, Equatable {
    var x: Double
    var y: Double
    var scaleX: Double
    var scaleY: Double
    var rotation: Double // in degrees
    var opacity: Double // 0-1
}

// MARK: - Layer Content (type-specific)
public struct LayerContent: Codable {
    // Text layer
    var text: String?
    var fontSize: Double?
    var fontFamily: String?
    
    // Image layer
    var imageUrl: String?
    var imageData: String?
    
    // Background layer
    var color: String?
    var gradient: GradientData?
    
    // Shape layer
    var shapeType: String?
    var fill: String?
    var stroke: String?
    var strokeWidth: Double?
    
    // Group layer
    var childLayerIds: [String]?
}

public struct GradientData: Codable {
    let type: String // 'linear' or 'radial'
    let stops: [GradientStop]
}

public struct GradientStop: Codable {
    let color: String
    let position: Double
}

// MARK: - Layer Style Properties
public struct LayerStyle: Codable {
    var fontSize: Double?
    var fontFamily: String?
    var color: String?
    var backgroundColor: String?
    var borderRadius: Double?
    var borderWidth: Double?
    var borderColor: String?
    var boxShadow: ShadowData?
    var filter: FilterData?
}

public struct ShadowData: Codable {
    let x: Double
    let y: Double
    let blur: Double
    let spread: Double
    let color: String
}

public struct FilterData: Codable {
    var blur: Double?
    var brightness: Double?
    var contrast: Double?
    var saturate: Double?
}

// MARK: - Layer Constraints
public struct LayerConstraints: Codable {
    var locked: Bool
    var visible: Bool
    var maintainAspectRatio: Bool?
    var minWidth: Double?
    var minHeight: Double?
    var maxWidth: Double?
    var maxHeight: Double?
    var pinTop: Bool?
    var pinBottom: Bool?
    var pinLeft: Bool?
    var pinRight: Bool?
    var centerX: Bool?
    var centerY: Bool?
}

// MARK: - Layer Metadata
public struct LayerMetadata: Codable {
    var source: String // 'user' or 'ai'
    var createdAt: Date
    var modifiedAt: Date?
    var version: Int?
    var tags: [String]?
    var notes: String?
}

// MARK: - Core Data Entity
@objc(Layer)
public class Layer: NSManagedObject, Identifiable {
    
    // MARK: - Core Data Properties
    @NSManaged public var id: String
    @NSManaged public var typeRaw: String
    @NSManaged public var contentData: Data
    @NSManaged public var transformData: Data
    @NSManaged public var styleData: Data
    @NSManaged public var constraintsData: Data
    @NSManaged public var metadataData: Data
    @NSManaged public var zIndex: Int32
    @NSManaged public var designCanvas: NSManagedObject? // Using NSManagedObject to avoid circular import
    
    // MARK: - Computed Properties
    public var type: LayerType {
        get {
            return LayerType(rawValue: typeRaw) ?? .text
        }
        set {
            typeRaw = newValue.rawValue
        }
    }
    
    public var content: LayerContent {
        get {
            do {
                return try JSONDecoder().decode(LayerContent.self, from: contentData)
            } catch {
                return LayerContent()
            }
        }
        set {
            do {
                contentData = try JSONEncoder().encode(newValue)
            } catch {
                print("Failed to encode content: \(error)")
            }
        }
    }
    
    public var transform: Transform {
        get {
            do {
                return try JSONDecoder().decode(Transform.self, from: transformData)
            } catch {
                return Transform(x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1)
            }
        }
        set {
            do {
                transformData = try JSONEncoder().encode(newValue)
            } catch {
                print("Failed to encode transform: \(error)")
            }
        }
    }
    
    public var style: LayerStyle {
        get {
            do {
                return try JSONDecoder().decode(LayerStyle.self, from: styleData)
            } catch {
                return LayerStyle()
            }
        }
        set {
            do {
                styleData = try JSONEncoder().encode(newValue)
            } catch {
                print("Failed to encode style: \(error)")
            }
        }
    }
    
    public var constraints: LayerConstraints {
        get {
            do {
                return try JSONDecoder().decode(LayerConstraints.self, from: constraintsData)
            } catch {
                return LayerConstraints(locked: false, visible: true)
            }
        }
        set {
            do {
                constraintsData = try JSONEncoder().encode(newValue)
            } catch {
                print("Failed to encode constraints: \(error)")
            }
        }
    }
    
    public var metadata: LayerMetadata {
        get {
            do {
                return try JSONDecoder().decode(LayerMetadata.self, from: metadataData)
            } catch {
                return LayerMetadata(source: "user", createdAt: Date())
            }
        }
        set {
            do {
                metadataData = try JSONEncoder().encode(newValue)
            } catch {
                print("Failed to encode metadata: \(error)")
            }
        }
    }
}

// MARK: - Validation Methods
extension Layer {
    
    public func validateLayerData() throws {
        // Validate Layer ID
        guard !id.isEmpty else {
            throw LayerValidationError.invalidLayerID("Layer ID must be a valid non-empty string")
        }
        
        // Validate Layer Type
        guard LayerType(rawValue: typeRaw) != nil else {
            throw LayerValidationError.invalidLayerType("Layer type must be a supported layer type")
        }
        
        // Validate content matches layer type
        try validateLayerContent()
        
        // Validate transform values
        try validateTransform()
        
        // Validate constraints
        try validateConstraints()
    }
    
    private func validateLayerContent() throws {
        switch type {
        case .text:
            try validateTextContent()
        case .image:
            try validateImageContent()
        case .background:
            try validateBackgroundContent()
        case .shape:
            try validateShapeContent()
        case .group:
            try validateGroupContent()
        case .postText:
            try validateTextContent() // Post text uses same validation as regular text
        }
    }
    
    private func validateTextContent() throws {
        let content = self.content
        guard let text = content.text, !text.isEmpty else {
            throw LayerValidationError.invalidContent("Text layer must have text content")
        }
    }
    
    private func validateImageContent() throws {
        let content = self.content
        guard content.imageUrl != nil || content.imageData != nil else {
            throw LayerValidationError.invalidContent("Image layer must have imageUrl or imageData")
        }
        
        if let imageUrl = content.imageUrl, imageUrl.isEmpty {
            throw LayerValidationError.invalidContent("Image layer imageUrl must not be empty")
        }
    }
    
    private func validateBackgroundContent() throws {
        let content = self.content
        
        // Background layers can have empty content (will use defaults)
        if content.color == nil && content.gradient == nil {
            // Allow empty content for background layers - will use defaults
            return
        }
    }
    
    private func validateShapeContent() throws {
        // Shape layers can have various properties, minimal validation
        // Just ensure content exists
        _ = self.content
    }
    
    private func validateGroupContent() throws {
        let content = self.content
        guard let childIds = content.childLayerIds else {
            throw LayerValidationError.invalidContent("Group layer must have childLayerIds array")
        }
        
        guard !childIds.isEmpty else {
            throw LayerValidationError.invalidContent("Group layer must contain at least one child layer")
        }
    }
    
    private func validateTransform() throws {
        let transform = self.transform
        
        // Validate opacity range (0-1)
        guard transform.opacity >= 0 && transform.opacity <= 1 else {
            throw LayerValidationError.invalidTransform("Transform opacity must be between 0 and 1")
        }
        
        // Validate rotation range (0-360)
        guard transform.rotation >= 0 && transform.rotation <= 360 else {
            throw LayerValidationError.invalidTransform("Transform rotation must be between 0 and 360 degrees")
        }
        
        // Validate scale values
        guard transform.scaleX > 0 && transform.scaleY > 0 else {
            throw LayerValidationError.invalidTransform("Transform scale values must be positive")
        }
    }
    
    private func validateConstraints() throws {
        let constraints = self.constraints
        
        // Validate dimension constraints
        if let minWidth = constraints.minWidth, let maxWidth = constraints.maxWidth {
            guard minWidth <= maxWidth else {
                throw LayerValidationError.invalidConstraints("minWidth must be less than or equal to maxWidth")
            }
        }
        
        if let minHeight = constraints.minHeight, let maxHeight = constraints.maxHeight {
            guard minHeight <= maxHeight else {
                throw LayerValidationError.invalidConstraints("minHeight must be less than or equal to maxHeight")
            }
        }
    }
    
    public func validateTransformBounds(canvasWidth: Double, canvasHeight: Double) throws {
        let bounds = getBoundingBox()
        
        // Check if layer is completely outside canvas bounds (with some tolerance)
        let tolerance = max(canvasWidth, canvasHeight) * 0.5
        let minBounds = -tolerance
        let maxBoundsX = canvasWidth + tolerance
        let maxBoundsY = canvasHeight + tolerance
        
        if bounds.minX > maxBoundsX || bounds.maxX < minBounds ||
           bounds.minY > maxBoundsY || bounds.maxY < minBounds {
            throw LayerValidationError.invalidTransform("Transform values must be within canvas boundaries")
        }
    }
}

// MARK: - Convenience Methods
extension Layer {
    
    @discardableResult
    public func updateTransform(_ updates: Transform) throws -> Layer {
        // Validate the new transform
        let oldTransform = transform
        transform = updates
        
        do {
            try validateTransform()
        } catch {
            // Restore old transform if validation fails
            transform = oldTransform
            throw error
        }
        
        // Update metadata
        var currentMetadata = metadata
        currentMetadata.modifiedAt = Date()
        metadata = currentMetadata
        
        return self
    }
    
    @discardableResult
    public func updateContent(_ updates: LayerContent) throws -> Layer {
        let oldContent = content
        content = updates
        
        do {
            try validateLayerContent()
        } catch {
            // Restore old content if validation fails
            content = oldContent
            throw error
        }
        
        // Update metadata
        var currentMetadata = metadata
        currentMetadata.modifiedAt = Date()
        metadata = currentMetadata
        
        return self
    }
    
    @discardableResult
    public func updateStyle(_ updates: LayerStyle) throws -> Layer {
        var currentStyle = style
        
        // Merge style properties
        if let fontSize = updates.fontSize { currentStyle.fontSize = fontSize }
        if let fontFamily = updates.fontFamily { currentStyle.fontFamily = fontFamily }
        if let color = updates.color { currentStyle.color = color }
        if let backgroundColor = updates.backgroundColor { currentStyle.backgroundColor = backgroundColor }
        if let borderRadius = updates.borderRadius { currentStyle.borderRadius = borderRadius }
        if let borderWidth = updates.borderWidth { currentStyle.borderWidth = borderWidth }
        if let borderColor = updates.borderColor { currentStyle.borderColor = borderColor }
        if let boxShadow = updates.boxShadow { currentStyle.boxShadow = boxShadow }
        if let filter = updates.filter { currentStyle.filter = filter }
        
        style = currentStyle
        
        // Update metadata
        var currentMetadata = metadata
        currentMetadata.modifiedAt = Date()
        metadata = currentMetadata
        
        return self
    }
    
    public func isVisible() -> Bool {
        return constraints.visible && transform.opacity > 0
    }
    
    public func getBoundingBox() -> CGRect {
        let currentTransform = self.transform
        
        // This is a simplified bounding box calculation
        // In a real implementation, this would consider the layer's actual content dimensions
        let width = 100.0 * currentTransform.scaleX // Default width scaled
        let height = 100.0 * currentTransform.scaleY // Default height scaled
        
        return CGRect(
            x: currentTransform.x,
            y: currentTransform.y,
            width: width,
            height: height
        )
    }
}

// MARK: - Factory Methods
extension Layer {
    
    public static func createDefault(type: LayerType, id: String, in context: NSManagedObjectContext) -> Layer {
        let layer = Layer(context: context)
        layer.id = id
        layer.type = type
        layer.zIndex = 0
        layer.transform = Transform(x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1)
        layer.constraints = LayerConstraints(locked: false, visible: true, maintainAspectRatio: true)
        layer.metadata = LayerMetadata(source: "user", createdAt: Date())
        
        var defaultContent = LayerContent()
        var defaultStyle = LayerStyle()
        
        switch type {
        case .text:
            defaultContent.text = "New Text Layer"
            defaultStyle.fontSize = 16
            defaultStyle.color = "#000000"
        case .image:
            defaultContent.imageUrl = ""
        case .background:
            defaultContent.color = "#ffffff"
        case .shape:
            defaultContent.shapeType = "rectangle"
            defaultStyle.color = "#000000"
        case .group:
            defaultContent.childLayerIds = []
        case .postText:
            defaultContent.text = "What's on your mind?"
            defaultStyle.fontSize = 16
            defaultStyle.color = "#1c1e21"
        }
        
        layer.content = defaultContent
        layer.style = defaultStyle
        
        return layer
    }
}

// MARK: - JSON Serialization
extension Layer {
    
    public func toJSON() -> [String: Any] {
        return [
            "id": id,
            "type": type.rawValue,
            "content": encodeContent(),
            "transform": encodeTransform(),
            "style": encodeStyle(),
            "constraints": encodeConstraints(),
            "metadata": encodeMetadata(),
            "zIndex": zIndex
        ]
    }
    
    private func encodeContent() -> [String: Any] {
        let content = self.content
        var dict: [String: Any] = [:]
        
        if let text = content.text { dict["text"] = text }
        if let fontSize = content.fontSize { dict["fontSize"] = fontSize }
        if let fontFamily = content.fontFamily { dict["fontFamily"] = fontFamily }
        if let imageUrl = content.imageUrl { dict["imageUrl"] = imageUrl }
        if let imageData = content.imageData { dict["imageData"] = imageData }
        if let color = content.color { dict["color"] = color }
        if let gradient = content.gradient { 
            dict["gradient"] = [
                "type": gradient.type,
                "stops": gradient.stops.map { ["color": $0.color, "position": $0.position] }
            ]
        }
        if let shapeType = content.shapeType { dict["shapeType"] = shapeType }
        if let fill = content.fill { dict["fill"] = fill }
        if let stroke = content.stroke { dict["stroke"] = stroke }
        if let strokeWidth = content.strokeWidth { dict["strokeWidth"] = strokeWidth }
        if let childLayerIds = content.childLayerIds { dict["childLayerIds"] = childLayerIds }
        
        return dict
    }
    
    private func encodeTransform() -> [String: Any] {
        let transform = self.transform
        return [
            "x": transform.x,
            "y": transform.y,
            "scaleX": transform.scaleX,
            "scaleY": transform.scaleY,
            "rotation": transform.rotation,
            "opacity": transform.opacity
        ]
    }
    
    private func encodeStyle() -> [String: Any] {
        let style = self.style
        var dict: [String: Any] = [:]
        
        if let fontSize = style.fontSize { dict["fontSize"] = fontSize }
        if let fontFamily = style.fontFamily { dict["fontFamily"] = fontFamily }
        if let color = style.color { dict["color"] = color }
        if let backgroundColor = style.backgroundColor { dict["backgroundColor"] = backgroundColor }
        if let borderRadius = style.borderRadius { dict["borderRadius"] = borderRadius }
        if let borderWidth = style.borderWidth { dict["borderWidth"] = borderWidth }
        if let borderColor = style.borderColor { dict["borderColor"] = borderColor }
        if let boxShadow = style.boxShadow {
            dict["boxShadow"] = [
                "x": boxShadow.x,
                "y": boxShadow.y,
                "blur": boxShadow.blur,
                "spread": boxShadow.spread,
                "color": boxShadow.color
            ]
        }
        
        return dict
    }
    
    private func encodeConstraints() -> [String: Any] {
        let constraints = self.constraints
        var dict: [String: Any] = [
            "locked": constraints.locked,
            "visible": constraints.visible
        ]
        
        if let maintainAspectRatio = constraints.maintainAspectRatio { dict["maintainAspectRatio"] = maintainAspectRatio }
        if let minWidth = constraints.minWidth { dict["minWidth"] = minWidth }
        if let minHeight = constraints.minHeight { dict["minHeight"] = minHeight }
        if let maxWidth = constraints.maxWidth { dict["maxWidth"] = maxWidth }
        if let maxHeight = constraints.maxHeight { dict["maxHeight"] = maxHeight }
        if let pinTop = constraints.pinTop { dict["pinTop"] = pinTop }
        if let pinBottom = constraints.pinBottom { dict["pinBottom"] = pinBottom }
        if let pinLeft = constraints.pinLeft { dict["pinLeft"] = pinLeft }
        if let pinRight = constraints.pinRight { dict["pinRight"] = pinRight }
        if let centerX = constraints.centerX { dict["centerX"] = centerX }
        if let centerY = constraints.centerY { dict["centerY"] = centerY }
        
        return dict
    }
    
    private func encodeMetadata() -> [String: Any] {
        let metadata = self.metadata
        var dict: [String: Any] = [
            "source": metadata.source,
            "createdAt": ISO8601DateFormatter().string(from: metadata.createdAt)
        ]
        
        if let modifiedAt = metadata.modifiedAt {
            dict["modifiedAt"] = ISO8601DateFormatter().string(from: modifiedAt)
        }
        if let version = metadata.version { dict["version"] = version }
        if let tags = metadata.tags { dict["tags"] = tags }
        if let notes = metadata.notes { dict["notes"] = notes }
        
        return dict
    }
}

// MARK: - Validation Errors
public enum LayerValidationError: LocalizedError {
    case invalidLayerID(String)
    case invalidLayerType(String)
    case invalidContent(String)
    case invalidTransform(String)
    case invalidConstraints(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidLayerID(let message),
             .invalidLayerType(let message),
             .invalidContent(let message),
             .invalidTransform(let message),
             .invalidConstraints(let message):
            return message
        }
    }
}
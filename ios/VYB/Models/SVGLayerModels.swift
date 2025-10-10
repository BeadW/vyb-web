import Foundation
import SwiftUI

// MARK: - SVG Layer Types
enum SVGLayerType: String, CaseIterable, Codable {
    case text = "text"
    case shape = "shape"
    case image = "image"
    case background = "background"
    case group = "group"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .shape: return "Shape"
        case .image: return "Image"
        case .background: return "Background"
        case .group: return "Group"
        }
    }
}

// MARK: - Enhanced Transform
struct SVGTransform: Codable, Equatable {
    var x: Double
    var y: Double
    var scaleX: Double
    var scaleY: Double
    var rotation: Double // degrees
    var opacity: Double // 0-1
    
    init(x: Double = 0, y: Double = 0, scaleX: Double = 1, scaleY: Double = 1, rotation: Double = 0, opacity: Double = 1) {
        self.x = x
        self.y = y
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.rotation = rotation
        self.opacity = opacity
    }
    
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
    
    init() {
        self.dropShadow = nil
        self.innerShadow = nil
        self.border = nil
        self.borderRadius = nil
        self.blendMode = .normal
    }
}

struct DropShadowStyle: Codable, Equatable {
    var offsetX: Double
    var offsetY: Double
    var blur: Double
    var spread: Double
    var color: String
    
    init(offsetX: Double = 2, offsetY: Double = 2, blur: Double = 4, spread: Double = 0, color: String = "#000000") {
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.blur = blur
        self.spread = spread
        self.color = color
    }
    
    var svgFilterId: String {
        let hashValue = "\(offsetX)-\(offsetY)-\(blur)-\(spread)-\(color)".hashValue
        return "drop-shadow-\(abs(hashValue))"
    }
}

struct InnerShadowStyle: Codable, Equatable {
    var offsetX: Double
    var offsetY: Double
    var blur: Double
    var spread: Double
    var color: String
    
    init(offsetX: Double = 1, offsetY: Double = 1, blur: Double = 2, spread: Double = 0, color: String = "#00000080") {
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.blur = blur
        self.spread = spread
        self.color = color
    }
    
    var svgFilterId: String {
        let hashValue = "\(offsetX)-\(offsetY)-\(blur)-\(spread)-\(color)".hashValue
        return "inner-shadow-\(abs(hashValue))"
    }
}

struct BorderStyle: Codable, Equatable {
    var width: Double
    var color: String
    var style: BorderStyleType
    
    init(width: Double = 1, color: String = "#000000", style: BorderStyleType = .solid) {
        self.width = width
        self.color = color
        self.style = style
    }
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
    
    init(
        locked: Bool = false,
        visible: Bool = true,
        lockPosition: Bool = false,
        lockSize: Bool = false,
        lockRotation: Bool = false,
        lockContent: Bool = false,
        lockStyle: Bool = false,
        maintainAspectRatio: Bool? = nil,
        minWidth: Double? = nil,
        minHeight: Double? = nil,
        maxWidth: Double? = nil,
        maxHeight: Double? = nil
    ) {
        self.locked = locked
        self.visible = visible
        self.lockPosition = lockPosition
        self.lockSize = lockSize
        self.lockRotation = lockRotation
        self.lockContent = lockContent
        self.lockStyle = lockStyle
        self.maintainAspectRatio = maintainAspectRatio
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
}

// MARK: - Layer Metadata
struct LayerMetadata: Codable, Equatable {
    var source: LayerSource
    var createdAt: Date
    var modifiedAt: Date?
    var tags: [String]?
    var notes: String?
    
    init(source: LayerSource, createdAt: Date, modifiedAt: Date? = nil, tags: [String]? = nil, notes: String? = nil) {
        self.source = source
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.tags = tags
        self.notes = notes
    }
}

enum LayerSource: String, Codable {
    case user = "user"
    case ai = "ai"
    case template = "template"
    case imported = "imported"
}
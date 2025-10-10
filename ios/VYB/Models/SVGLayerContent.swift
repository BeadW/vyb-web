import Foundation
import SwiftUI

// MARK: - Layer Content
struct SVGLayerContent: Codable, Equatable {
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
    var width: Double?
    var height: Double?
    
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
    
    init() {
        // Initialize with nil values - will be set based on layer type
    }
    
    // Convenience initializers for each layer type
    static func textContent(
        text: String = "New Text",
        fontSize: Double = 16,
        fontFamily: String = "Arial",
        fontWeight: FontWeight = .normal,
        textColor: String = "#000000",
        textAlign: TextAlignment = .left,
        lineHeight: Double = 1.2,
        letterSpacing: Double = 0
    ) -> SVGLayerContent {
        var content = SVGLayerContent()
        content.text = text
        content.fontSize = fontSize
        content.fontFamily = fontFamily
        content.fontWeight = fontWeight
        content.textColor = textColor
        content.textAlign = textAlign
        content.lineHeight = lineHeight
        content.letterSpacing = letterSpacing
        return content
    }
    
    static func shapeContent(
        shapeType: ShapeType,
        fill: String = "#000000",
        stroke: StrokeStyle? = nil,
        cornerRadius: Double = 0,
        sides: Int = 3,
        width: Double = 100,
        height: Double = 100
    ) -> SVGLayerContent {
        var content = SVGLayerContent()
        content.shapeType = shapeType
        content.fill = fill
        content.stroke = stroke
        content.cornerRadius = cornerRadius
        content.sides = sides
        content.width = width
        content.height = height
        return content
    }
    
    static func imageContent(
        imageURL: String? = nil,
        imageData: String? = nil,
        crop: CropRegion? = nil,
        filters: ImageFilters? = nil
    ) -> SVGLayerContent {
        var content = SVGLayerContent()
        content.imageURL = imageURL
        content.imageData = imageData
        content.crop = crop
        content.filters = filters
        return content
    }
    
    static func backgroundContent(
        backgroundColor: String? = nil,
        backgroundGradient: GradientStyle? = nil
    ) -> SVGLayerContent {
        var content = SVGLayerContent()
        content.backgroundColor = backgroundColor
        content.backgroundGradient = backgroundGradient
        return content
    }
    
    static func groupContent(
        childLayerIds: [String],
        groupName: String = "Group"
    ) -> SVGLayerContent {
        var content = SVGLayerContent()
        content.childLayerIds = childLayerIds
        content.groupName = groupName
        return content
    }
}

// MARK: - Font Types
enum FontWeight: String, Codable, CaseIterable {
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
    
    var displayName: String {
        switch self {
        case .normal, .w400: return "Normal"
        case .bold, .w700: return "Bold"
        case .w100: return "Thin"
        case .w200: return "Extra Light"
        case .w300: return "Light"
        case .w500: return "Medium"
        case .w600: return "Semi Bold"
        case .w800: return "Extra Bold"
        case .w900: return "Black"
        }
    }
}

enum TextAlignment: String, Codable, CaseIterable {
    case left = "left"
    case center = "center"
    case right = "right"
    case justify = "justify"
    
    var displayName: String {
        switch self {
        case .left: return "Left"
        case .center: return "Center"
        case .right: return "Right"
        case .justify: return "Justify"
        }
    }
}

// MARK: - Shape Types
enum ShapeType: String, Codable, CaseIterable {
    case rectangle = "rectangle"
    case circle = "circle"
    case triangle = "triangle"
    case polygon = "polygon"
    case line = "line"
    case arrow = "arrow"
    
    var displayName: String {
        switch self {
        case .rectangle: return "Rectangle"
        case .circle: return "Circle"
        case .triangle: return "Triangle"
        case .polygon: return "Polygon"
        case .line: return "Line"
        case .arrow: return "Arrow"
        }
    }
    
    var defaultSides: Int {
        switch self {
        case .triangle: return 3
        case .polygon: return 6
        default: return 0
        }
    }
}

struct StrokeStyle: Codable, Equatable {
    var color: String
    var width: Double
    var dashArray: [Double]?
    
    init(color: String = "#000000", width: Double = 1, dashArray: [Double]? = nil) {
        self.color = color
        self.width = width
        self.dashArray = dashArray
    }
    
    var svgStrokeString: String {
        var attributes: [String] = []
        attributes.append("stroke=\"\(color)\"")
        attributes.append("stroke-width=\"\(width)\"")
        
        if let dashArray = dashArray, !dashArray.isEmpty {
            let dashString = dashArray.map { String($0) }.joined(separator: ",")
            attributes.append("stroke-dasharray=\"\(dashString)\"")
        }
        
        return attributes.joined(separator: " ")
    }
}

// MARK: - Image Types
struct CropRegion: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    
    init(x: Double = 0, y: Double = 0, width: Double = 100, height: Double = 100) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

struct ImageFilters: Codable, Equatable {
    var brightness: Double? // 0-2, default 1
    var contrast: Double?   // 0-2, default 1
    var saturation: Double? // 0-2, default 1
    var blur: Double?       // 0-10, default 0
    
    init(brightness: Double? = nil, contrast: Double? = nil, saturation: Double? = nil, blur: Double? = nil) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.blur = blur
    }
    
    var svgFilterId: String? {
        guard brightness != nil || contrast != nil || saturation != nil || blur != nil else {
            return nil
        }
        
        let filterString = "\(brightness ?? 1)-\(contrast ?? 1)-\(saturation ?? 1)-\(blur ?? 0)"
        return "image-filter-\(abs(filterString.hashValue))"
    }
}

// MARK: - Gradient Types
struct GradientStyle: Codable, Equatable {
    var type: GradientType
    var angle: Double? // for linear gradients (0-360 degrees)
    var stops: [GradientStop]
    
    init(type: GradientType, angle: Double? = nil, stops: [GradientStop]) {
        self.type = type
        self.angle = angle
        self.stops = stops
    }
    
    var svgGradientId: String {
        let stopsString = stops.map { "\($0.color)-\($0.position)" }.joined(separator: "-")
        let typeString = type.rawValue
        let angleString = angle.map { String($0) } ?? "0"
        return "gradient-\(abs("\(typeString)-\(angleString)-\(stopsString)".hashValue))"
    }
    
    // Common gradient presets
    static let blueToGreen = GradientStyle(
        type: .linear,
        angle: 45,
        stops: [
            GradientStop(color: "#007AFF", position: 0),
            GradientStop(color: "#34C759", position: 1)
        ]
    )
    
    static let redToOrange = GradientStyle(
        type: .linear,
        angle: 90,
        stops: [
            GradientStop(color: "#FF3B30", position: 0),
            GradientStop(color: "#FF9500", position: 1)
        ]
    )
    
    static let purpleToBlue = GradientStyle(
        type: .radial,
        stops: [
            GradientStop(color: "#AF52DE", position: 0),
            GradientStop(color: "#007AFF", position: 1)
        ]
    )
}

enum GradientType: String, Codable {
    case linear = "linear"
    case radial = "radial"
    
    var displayName: String {
        switch self {
        case .linear: return "Linear"
        case .radial: return "Radial"
        }
    }
}

struct GradientStop: Codable, Equatable {
    var color: String
    var position: Double // 0-1
    
    init(color: String, position: Double) {
        self.color = color
        self.position = max(0, min(1, position)) // Clamp to 0-1
    }
}
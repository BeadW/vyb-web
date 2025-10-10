import Foundation
import SwiftUI

// Note: This file depends on SVGLayerModels.swift and SVGLayerContent.swift
// In a real Xcode project, these would be imported automatically

// MARK: - Main SVG Layer
struct SVGLayer: Codable, Equatable, Identifiable {
    let id: String
    var type: SVGLayerType
    var content: SVGLayerContent
    var transform: SVGTransform
    var style: SVGLayerStyle
    var constraints: SVGLayerConstraints
    var metadata: LayerMetadata
    
    init(
        id: String = UUID().uuidString,
        type: SVGLayerType,
        content: SVGLayerContent,
        transform: SVGTransform = SVGTransform(),
        style: SVGLayerStyle = SVGLayerStyle(),
        constraints: SVGLayerConstraints = SVGLayerConstraints(),
        metadata: LayerMetadata? = nil
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.transform = transform
        self.style = style
        self.constraints = constraints
        self.metadata = metadata ?? LayerMetadata(source: .user, createdAt: Date())
    }
    
    // MARK: - Factory Methods
    static func createTextLayer(
        text: String = "New Text",
        x: Double = 50,
        y: Double = 50,
        fontSize: Double = 16,
        color: String = "#000000"
    ) -> SVGLayer {
        return SVGLayer(
            type: .text,
            content: .textContent(
                text: text,
                fontSize: fontSize,
                textColor: color
            ),
            transform: SVGTransform(x: x, y: y)
        )
    }
    
    static func createRectangleLayer(
        x: Double = 50,
        y: Double = 50,
        width: Double = 100,
        height: Double = 100,
        fill: String = "#007AFF"
    ) -> SVGLayer {
        return SVGLayer(
            type: .shape,
            content: .shapeContent(
                shapeType: .rectangle,
                fill: fill,
                width: width,
                height: height
            ),
            transform: SVGTransform(x: x, y: y)
        )
    }
    
    static func createCircleLayer(
        x: Double = 50,
        y: Double = 50,
        radius: Double = 50,
        fill: String = "#34C759"
    ) -> SVGLayer {
        return SVGLayer(
            type: .shape,
            content: .shapeContent(
                shapeType: .circle,
                fill: fill,
                width: radius * 2,
                height: radius * 2
            ),
            transform: SVGTransform(x: x, y: y)
        )
    }
    
    static func createImageLayer(
        x: Double = 50,
        y: Double = 50,
        width: Double = 200,
        height: Double = 200,
        imageURL: String? = nil,
        imageData: String? = nil
    ) -> SVGLayer {
        return SVGLayer(
            type: .image,
            content: .imageContent(
                imageURL: imageURL,
                imageData: imageData
            ),
            transform: SVGTransform(x: x, y: y)
        )
    }
    
    static func createBackgroundLayer(
        color: String? = nil,
        gradient: GradientStyle? = nil
    ) -> SVGLayer {
        return SVGLayer(
            type: .background,
            content: .backgroundContent(
                backgroundColor: color,
                backgroundGradient: gradient
            ),
            transform: SVGTransform()
        )
    }
    
    static func createGroupLayer(
        childLayerIds: [String],
        name: String = "Group"
    ) -> SVGLayer {
        return SVGLayer(
            type: .group,
            content: .groupContent(
                childLayerIds: childLayerIds,
                groupName: name
            ),
            transform: SVGTransform()
        )
    }
    
    // MARK: - SVG Generation
    func toSVGElement() -> String {
        guard constraints.visible else { return "" }
        
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
    
    private func generateTextSVG() -> String {
        guard let text = content.text else { return "" }
        
        let fontSize = content.fontSize ?? 16
        let fontFamily = content.fontFamily ?? "Arial"
        let fontWeight = content.fontWeight?.rawValue ?? "normal"
        let textColor = content.textColor ?? "#000000"
        let textAlign = content.textAlign?.rawValue ?? "left"
        let letterSpacing = content.letterSpacing ?? 0
        
        var attributes: [String] = []
        attributes.append("x=\"\(transform.x)\"")
        attributes.append("y=\"\(transform.y + fontSize)\"") // SVG text baseline adjustment
        attributes.append("font-family=\"\(fontFamily)\"")
        attributes.append("font-size=\"\(fontSize)\"")
        attributes.append("font-weight=\"\(fontWeight)\"")
        attributes.append("fill=\"\(textColor)\"")
        attributes.append("text-anchor=\"\(svgTextAnchor(from: textAlign))\"")
        
        if letterSpacing != 0 {
            attributes.append("letter-spacing=\"\(letterSpacing)\"")
        }
        
        if transform.opacity != 1 {
            attributes.append("opacity=\"\(transform.opacity)\"")
        }
        
        if !transform.svgTransformString.isEmpty {
            attributes.append("transform=\"\(transform.svgTransformString)\"")
        }
        
        // Add style effects
        if let filter = generateFilterAttribute() {
            attributes.append("filter=\"\(filter)\"")
        }
        
        let attributeString = attributes.joined(separator: " ")
        let escapedText = text.replacingOccurrences(of: "&", with: "&amp;")
                              .replacingOccurrences(of: "<", with: "&lt;")
                              .replacingOccurrences(of: ">", with: "&gt;")
        
        return "<text \(attributeString)>\(escapedText)</text>"
    }
    
    private func generateShapeSVG() -> String {
        guard let shapeType = content.shapeType else { return "" }
        
        switch shapeType {
        case .rectangle:
            return generateRectangleSVG()
        case .circle:
            return generateCircleSVG()
        case .triangle:
            return generateTriangleSVG()
        case .polygon:
            return generatePolygonSVG()
        case .line:
            return generateLineSVG()
        case .arrow:
            return generateArrowSVG()
        }
    }
    
    private func generateRectangleSVG() -> String {
        let width = content.width ?? 100
        let height = content.height ?? 100
        let fill = content.fill ?? "#000000"
        let cornerRadius = content.cornerRadius ?? 0
        
        var attributes: [String] = []
        attributes.append("x=\"\(transform.x)\"")
        attributes.append("y=\"\(transform.y)\"")
        attributes.append("width=\"\(width)\"")
        attributes.append("height=\"\(height)\"")
        attributes.append("fill=\"\(fill)\"")
        
        if cornerRadius > 0 {
            attributes.append("rx=\"\(cornerRadius)\"")
            attributes.append("ry=\"\(cornerRadius)\"")
        }
        
        if let stroke = content.stroke {
            attributes.append(stroke.svgStrokeString)
        }
        
        if transform.opacity != 1 {
            attributes.append("opacity=\"\(transform.opacity)\"")
        }
        
        if !transform.svgTransformString.isEmpty {
            attributes.append("transform=\"\(transform.svgTransformString)\"")
        }
        
        if let filter = generateFilterAttribute() {
            attributes.append("filter=\"\(filter)\"")
        }
        
        let attributeString = attributes.joined(separator: " ")
        return "<rect \(attributeString)/>"
    }
    
    private func generateCircleSVG() -> String {
        let width = content.width ?? 100
        let radius = width / 2
        let centerX = transform.x + radius
        let centerY = transform.y + radius
        let fill = content.fill ?? "#000000"
        
        var attributes: [String] = []
        attributes.append("cx=\"\(centerX)\"")
        attributes.append("cy=\"\(centerY)\"")
        attributes.append("r=\"\(radius)\"")
        attributes.append("fill=\"\(fill)\"")
        
        if let stroke = content.stroke {
            attributes.append(stroke.svgStrokeString)
        }
        
        if transform.opacity != 1 {
            attributes.append("opacity=\"\(transform.opacity)\"")
        }
        
        if transform.rotation != 0 || transform.scaleX != 1 || transform.scaleY != 1 {
            let transformString = "rotate(\(transform.rotation) \(centerX) \(centerY)) scale(\(transform.scaleX) \(transform.scaleY))"
            attributes.append("transform=\"\(transformString)\"")
        }
        
        if let filter = generateFilterAttribute() {
            attributes.append("filter=\"\(filter)\"")
        }
        
        let attributeString = attributes.joined(separator: " ")
        return "<circle \(attributeString)/>"
    }
    
    private func generateTriangleSVG() -> String {
        let width = content.width ?? 100
        let height = content.height ?? 100
        let fill = content.fill ?? "#000000"
        
        // Create triangle points
        let x1 = transform.x + width / 2 // Top point
        let y1 = transform.y
        let x2 = transform.x // Bottom left
        let y2 = transform.y + height
        let x3 = transform.x + width // Bottom right
        let y3 = transform.y + height
        
        let points = "\(x1),\(y1) \(x2),\(y2) \(x3),\(y3)"
        
        var attributes: [String] = []
        attributes.append("points=\"\(points)\"")
        attributes.append("fill=\"\(fill)\"")
        
        if let stroke = content.stroke {
            attributes.append(stroke.svgStrokeString)
        }
        
        if transform.opacity != 1 {
            attributes.append("opacity=\"\(transform.opacity)\"")
        }
        
        if let filter = generateFilterAttribute() {
            attributes.append("filter=\"\(filter)\"")
        }
        
        let attributeString = attributes.joined(separator: " ")
        return "<polygon \(attributeString)/>"
    }
    
    private func generatePolygonSVG() -> String {
        let width = content.width ?? 100
        let height = content.height ?? 100
        let fill = content.fill ?? "#000000"
        let sides = content.sides ?? 6
        
        // Generate polygon points
        let centerX = transform.x + width / 2
        let centerY = transform.y + height / 2
        let radiusX = width / 2
        let radiusY = height / 2
        
        var points: [String] = []
        for i in 0..<sides {
            let angle = (Double(i) * 2 * Double.pi) / Double(sides) - Double.pi / 2
            let x = centerX + radiusX * cos(angle)
            let y = centerY + radiusY * sin(angle)
            points.append("\(x),\(y)")
        }
        
        var attributes: [String] = []
        attributes.append("points=\"\(points.joined(separator: " "))\"")
        attributes.append("fill=\"\(fill)\"")
        
        if let stroke = content.stroke {
            attributes.append(stroke.svgStrokeString)
        }
        
        if transform.opacity != 1 {
            attributes.append("opacity=\"\(transform.opacity)\"")
        }
        
        if let filter = generateFilterAttribute() {
            attributes.append("filter=\"\(filter)\"")
        }
        
        let attributeString = attributes.joined(separator: " ")
        return "<polygon \(attributeString)/>"
    }
    
    private func generateLineSVG() -> String {
        let width = content.width ?? 100
        let strokeColor = content.stroke?.color ?? "#000000"
        let strokeWidth = content.stroke?.width ?? 1
        
        var attributes: [String] = []
        attributes.append("x1=\"\(transform.x)\"")
        attributes.append("y1=\"\(transform.y)\"")
        attributes.append("x2=\"\(transform.x + width)\"")
        attributes.append("y2=\"\(transform.y)\"")
        attributes.append("stroke=\"\(strokeColor)\"")
        attributes.append("stroke-width=\"\(strokeWidth)\"")
        
        if transform.opacity != 1 {
            attributes.append("opacity=\"\(transform.opacity)\"")
        }
        
        if !transform.svgTransformString.isEmpty {
            attributes.append("transform=\"\(transform.svgTransformString)\"")
        }
        
        let attributeString = attributes.joined(separator: " ")
        return "<line \(attributeString)/>"
    }
    
    private func generateArrowSVG() -> String {
        // Simplified arrow as a path
        let width = content.width ?? 100
        let height = content.height ?? 20
        let fill = content.fill ?? "#000000"
        
        let arrowBody = width * 0.7
        let arrowHead = width * 0.3
        let arrowBodyHeight = height * 0.4
        
        let pathData = """
        M \(transform.x) \(transform.y + height/2 - arrowBodyHeight/2)
        L \(transform.x + arrowBody) \(transform.y + height/2 - arrowBodyHeight/2)
        L \(transform.x + arrowBody) \(transform.y)
        L \(transform.x + width) \(transform.y + height/2)
        L \(transform.x + arrowBody) \(transform.y + height)
        L \(transform.x + arrowBody) \(transform.y + height/2 + arrowBodyHeight/2)
        L \(transform.x) \(transform.y + height/2 + arrowBodyHeight/2)
        Z
        """
        
        var attributes: [String] = []
        attributes.append("d=\"\(pathData)\"")
        attributes.append("fill=\"\(fill)\"")
        
        if let stroke = content.stroke {
            attributes.append(stroke.svgStrokeString)
        }
        
        if transform.opacity != 1 {
            attributes.append("opacity=\"\(transform.opacity)\"")
        }
        
        if let filter = generateFilterAttribute() {
            attributes.append("filter=\"\(filter)\"")
        }
        
        let attributeString = attributes.joined(separator: " ")
        return "<path \(attributeString)/>"
    }
    
    private func generateImageSVG() -> String {
        let width = content.width ?? 200
        let height = content.height ?? 200
        
        var href: String
        if let imageData = content.imageData {
            href = "data:image/jpeg;base64,\(imageData)"
        } else if let imageURL = content.imageURL {
            href = imageURL
        } else {
            return "" // No image source
        }
        
        var attributes: [String] = []
        attributes.append("x=\"\(transform.x)\"")
        attributes.append("y=\"\(transform.y)\"")
        attributes.append("width=\"\(width)\"")
        attributes.append("height=\"\(height)\"")
        attributes.append("href=\"\(href)\"")
        
        if transform.opacity != 1 {
            attributes.append("opacity=\"\(transform.opacity)\"")
        }
        
        if !transform.svgTransformString.isEmpty {
            attributes.append("transform=\"\(transform.svgTransformString)\"")
        }
        
        if let filter = generateFilterAttribute() {
            attributes.append("filter=\"\(filter)\"")
        }
        
        let attributeString = attributes.joined(separator: " ")
        return "<image \(attributeString)/>"
    }
    
    private func generateBackgroundSVG() -> String {
        // Background layer should be handled at canvas level
        // This method is for completeness but won't be used in normal rendering
        return ""
    }
    
    private func generateGroupSVG() -> String {
        // Group SVG generation needs child layers
        // This would be handled by the SVGLayerManager
        let groupName = content.groupName ?? "Group"
        return "<g id=\"\(id)\" data-name=\"\(groupName)\"></g>"
    }
    
    // MARK: - Helper Methods
    private func svgTextAnchor(from alignment: String) -> String {
        switch alignment {
        case "left": return "start"
        case "center": return "middle"
        case "right": return "end"
        default: return "start"
        }
    }
    
    private func generateFilterAttribute() -> String? {
        var filters: [String] = []
        
        if let dropShadow = style.dropShadow {
            filters.append("url(#\(dropShadow.svgFilterId))")
        }
        
        if let innerShadow = style.innerShadow {
            filters.append("url(#\(innerShadow.svgFilterId))")
        }
        
        if let imageFilters = content.filters, let filterId = imageFilters.svgFilterId {
            filters.append("url(#\(filterId))")
        }
        
        return filters.isEmpty ? nil : filters.joined(separator: " ")
    }
}
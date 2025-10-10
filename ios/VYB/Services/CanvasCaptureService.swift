import Foundation
import SwiftUI
import CoreData

// MARK: - Canvas Capture Service
@MainActor
class CanvasCaptureService: ObservableObject {
    
    // MARK: - Capture Formats
    enum CaptureFormat {
        case svg
        case png(quality: Double = 1.0)
        case jpeg(compressionQuality: Double = 0.8)
    }
    
    enum CaptureResult {
        case svg(String)
        case png(Data)
        case jpeg(Data)
        
        var data: Data? {
            switch self {
            case .svg(let string):
                return string.data(using: .utf8)
            case .png(let data), .jpeg(let data):
                return data
            }
        }
        
        var mimeType: String {
            switch self {
            case .svg: return "image/svg+xml"
            case .png: return "image/png"
            case .jpeg: return "image/jpeg"
            }
        }
    }
    
    enum CaptureError: Error, LocalizedError {
        case renderingFailed
        case invalidFormat
        case noLayersProvided
        case canvasSizeInvalid
        
        var errorDescription: String? {
            switch self {
            case .renderingFailed:
                return "Failed to render canvas to image"
            case .invalidFormat:
                return "Invalid capture format specified"
            case .noLayersProvided:
                return "No layers provided for capture"
            case .canvasSizeInvalid:
                return "Canvas size is invalid"
            }
        }
    }
    
    // MARK: - Dependencies
    private let layerManager: LayerManager
    
    init(layerManager: LayerManager) {
        self.layerManager = layerManager
    }
    
    // MARK: - Primary Capture Method
    func captureCanvas(
        canvasSize: CGSize,
        format: CaptureFormat = .jpeg(compressionQuality: 0.8),
        backgroundColor: String = "#FFFFFF"
    ) async throws -> CaptureResult {
        
        guard canvasSize.width > 0 && canvasSize.height > 0 else {
            throw CaptureError.canvasSizeInvalid
        }
        
        guard !layerManager.layers.isEmpty else {
            throw CaptureError.noLayersProvided
        }
        
        switch format {
        case .svg:
            return try await captureSVG(canvasSize: canvasSize, backgroundColor: backgroundColor)
        case .png, .jpeg:
            // For now, return SVG format until we implement proper raster rendering
            return try await captureSVG(canvasSize: canvasSize, backgroundColor: backgroundColor)
        }
    }
    
    // MARK: - SVG Capture
    private func captureSVG(canvasSize: CGSize, backgroundColor: String) async throws -> CaptureResult {
        let svgString = try generateFullSVG(canvasSize: canvasSize, backgroundColor: backgroundColor)
        return .svg(svgString)
    }
    
    // MARK: - SVG Generation
    private func generateFullSVG(canvasSize: CGSize, backgroundColor: String) throws -> String {
        // Generate background
        let background = generateBackgroundSVG(canvasSize: canvasSize, backgroundColor: backgroundColor)
        
        // Generate layer elements (only visible layers)
        let visibleLayers = layerManager.layers.filter { layer in
            return layer.constraints.visible
        }
        
        let layerElements = visibleLayers.enumerated().map { index, layer in
            return generateLayerSVG(layer: layer, index: index)
        }.joined(separator: "\n  ")
        
        let svgContent = """
        <svg width="\(Int(canvasSize.width))" height="\(Int(canvasSize.height))" 
             viewBox="0 0 \(Int(canvasSize.width)) \(Int(canvasSize.height))"
             xmlns="http://www.w3.org/2000/svg">
        \(background.isEmpty ? "" : "  \(background)")
        \(layerElements.isEmpty ? "" : "  \(layerElements)")
        </svg>
        """
        
        return svgContent
    }
    
    private func generateBackgroundSVG(canvasSize: CGSize, backgroundColor: String) -> String {
        return """
        <rect x="0" y="0" width="\(Int(canvasSize.width))" height="\(Int(canvasSize.height))" fill="\(backgroundColor)"/>
        """
    }
    
    private func generateLayerSVG(layer: Layer, index: Int) -> String {
        switch layer.type {
        case .text:
            return generateTextLayerSVG(layer: layer, index: index)
        case .shape:
            return generateShapeLayerSVG(layer: layer, index: index)
        case .image:
            return generateImageLayerSVG(layer: layer, index: index)
        case .background:
            return generateBackgroundLayerSVG(layer: layer, index: index)
        }
    }
    
    private func generateTextLayerSVG(layer: Layer, index: Int) -> String {
        let text = layer.content.text ?? "Text"
        let x = layer.transform.x
        let y = layer.transform.y + (layer.transform.height / 2) // Center vertically
        let fontSize = layer.content.fontSize ?? 16
        let color = layer.content.color ?? "#000000"
        let opacity = layer.transform.opacity
        
        return """
        <text x="\(x)" y="\(y)" font-size="\(fontSize)" fill="\(color)" opacity="\(opacity)" text-anchor="start" dominant-baseline="middle">\(text)</text>
        """
    }
    
    private func generateShapeLayerSVG(layer: Layer, index: Int) -> String {
        let x = layer.transform.x
        let y = layer.transform.y
        let width = layer.transform.width
        let height = layer.transform.height
        let fill = layer.content.fill ?? "#0066CC"
        let stroke = layer.content.stroke ?? "none"
        let strokeWidth = layer.content.strokeWidth ?? 0
        let opacity = layer.transform.opacity
        
        return """
        <rect x="\(x)" y="\(y)" width="\(width)" height="\(height)" fill="\(fill)" stroke="\(stroke)" stroke-width="\(strokeWidth)" opacity="\(opacity)"/>
        """
    }
    
    private func generateBackgroundLayerSVG(layer: Layer, index: Int) -> String {
        let fill = layer.content.fill ?? layer.content.color ?? "#FFFFFF"
        let opacity = layer.transform.opacity
        
        return """
        <rect x="0" y="0" width="100%" height="100%" fill="\(fill)" opacity="\(opacity)"/>
        """
    }
    
    private func generateImageLayerSVG(layer: Layer, index: Int) -> String {
        let x = layer.transform.x
        let y = layer.transform.y
        let width = layer.transform.width
        let height = layer.transform.height
        let opacity = layer.transform.opacity
        
        // Placeholder for image layers
        return """
        <rect x="\(x)" y="\(y)" width="\(width)" height="\(height)" fill="#f0f0f0" stroke="#ccc" stroke-width="2" opacity="\(opacity)"/>
        <text x="\(x + width/2)" y="\(y + height/2)" text-anchor="middle" dominant-baseline="middle" font-size="12" fill="#666">Image</text>
        """
    }
    
    // MARK: - Integration with Existing AI Service
    func captureForAI(canvasSize: CGSize) async throws -> (svgData: String, description: String) {
        // Capture SVG
        let svgResult = try await captureCanvas(
            canvasSize: canvasSize,
            format: .svg
        )
        
        guard case .svg(let svgString) = svgResult else {
            throw CaptureError.renderingFailed
        }
        
        // Generate description of current canvas state
        let description = generateCanvasDescription()
        
        return (svgData: svgString, description: description)
    }
    
    private func generateCanvasDescription() -> String {
        let layerCount = layerManager.layers.count
        let textLayers = layerManager.layers.filter { $0.type == LayerType.text }.count
        let shapeLayers = layerManager.layers.filter { $0.type == LayerType.shape }.count
        let imageLayers = layerManager.layers.filter { $0.type == LayerType.image }.count
        
        var description = "Canvas with \(layerCount) layers: "
        var components: [String] = []
        
        if textLayers > 0 {
            components.append("\(textLayers) text layer\(textLayers == 1 ? "" : "s")")
        }
        if shapeLayers > 0 {
            components.append("\(shapeLayers) shape layer\(shapeLayers == 1 ? "" : "s")")
        }
        if imageLayers > 0 {
            components.append("\(imageLayers) image layer\(imageLayers == 1 ? "" : "s")")
        }
        
        description += components.joined(separator: ", ")
        
        return description
    }
}
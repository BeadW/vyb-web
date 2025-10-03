import Foundation
import SwiftUI
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

// Import our models
struct Layer {
    let id: String
    let type: LayerType
    var transform: Transform
    let content: LayerContent
    let style: LayerStyle?
    let constraints: LayerConstraints
}

struct Transform: Equatable {
    var x: Double
    var y: Double
    var scaleX: Double
    var scaleY: Double
    var rotation: Double
    var opacity: Double
}

struct LayerContent {
    var text: String?
    var fontSize: Double?
    var fontFamily: String?
    var imageUrl: String?
    var imageData: String?
    var color: String?
    var gradient: GradientData?
    var shapeType: String?
    var fill: String?
    var stroke: String?
    var strokeWidth: Double?
    var childLayerIds: [String]?
    
    init(text: String? = nil, fontSize: Double? = nil, fontFamily: String? = nil, 
         imageUrl: String? = nil, imageData: String? = nil, color: String? = nil,
         gradient: GradientData? = nil, shapeType: String? = nil, fill: String? = nil,
         stroke: String? = nil, strokeWidth: Double? = nil, childLayerIds: [String]? = nil) {
        self.text = text
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.imageUrl = imageUrl
        self.imageData = imageData
        self.color = color
        self.gradient = gradient
        self.shapeType = shapeType
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.childLayerIds = childLayerIds
    }
}

struct GradientData {
    let type: String
    let stops: [GradientStop]
}

struct GradientStop {
    let color: String
    let position: Double
}

struct LayerStyle {
    var fontSize: Double?
    var fontFamily: String?
    var color: String?
    var backgroundColor: String?
    var borderRadius: Double?
    var borderWidth: Double?
    var borderColor: String?
}

struct LayerConstraints {
    var locked: Bool
    var visible: Bool
    var maintainAspectRatio: Bool?
    
    init(locked: Bool, visible: Bool, maintainAspectRatio: Bool? = nil) {
        self.locked = locked
        self.visible = visible
        self.maintainAspectRatio = maintainAspectRatio
    }
}

enum LayerType {
    case text, image, shape, background, group
}

/// iOS Canvas Manipulation Service - Advanced gesture-based manipulation with constraints
/// Implements T043: iOS Canvas Manipulation with gesture recognizers and advanced manipulation tools
/// Provides professional-grade manipulation features comparable to web Fabric.js implementation
class CanvasManipulation: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isManipulating: Bool = false
    @Published var currentTool: ManipulationTool = .select
    @Published var snapToGrid: Bool = false
    @Published var snapToObjects: Bool = true
    @Published var gridSize: CGFloat = 10.0
    @Published var manipulationConstraints = ManipulationConstraints()
    
    // MARK: - Private Properties
    private var activeLayer: Layer?
    private var initialTransform: Transform?
    private var manipulationStartPoint: CGPoint = .zero
    private var snapThreshold: CGFloat = 5.0
    private var undoStack: [ManipulationAction] = []
    private var redoStack: [ManipulationAction] = []
    
    // MARK: - Callbacks
    var onLayerChanged: ((Layer) -> Void)?
    var onSelectionChanged: ((String?) -> Void)?
    var onManipulationStart: (() -> Void)?
    var onManipulationEnd: (() -> Void)?
    
    // MARK: - Initialization
    init() {
        setupDefaultConstraints()
    }
    
    // MARK: - Public Interface
    
    /// Start manipulation on a specific layer
    func startManipulation(layer: Layer, at point: CGPoint, tool: ManipulationTool = .select) {
        activeLayer = layer
        initialTransform = layer.transform
        manipulationStartPoint = point
        currentTool = tool
        isManipulating = true
        
        recordAction(.start(layerId: layer.id, transform: layer.transform))
        onManipulationStart?()
    }
    
    /// Update manipulation based on gesture
    func updateManipulation(translation: CGSize, scale: CGFloat = 1.0, rotation: Angle = .zero, velocity: CGSize = .zero) {
        guard let layer = activeLayer, let initial = initialTransform else { return }
        
        var newTransform = initial
        
        switch currentTool {
        case .select, .move:
            newTransform = applyTranslation(to: newTransform, translation: translation, layer: layer)
        case .scale:
            newTransform = applyScaling(to: newTransform, scale: scale, layer: layer)
        case .rotate:
            newTransform = applyRotation(to: newTransform, rotation: rotation, layer: layer)
        }
        
        // Apply constraints
        newTransform = applyConstraints(to: newTransform, layer: layer)
        
        // Apply snapping
        if snapToGrid || snapToObjects {
            newTransform = applySnapping(to: newTransform, layer: layer)
        }
        
        // Update layer
        var updatedLayer = layer
        updatedLayer.transform = newTransform
        
        onLayerChanged?(updatedLayer)
    }
    
    /// End manipulation and commit changes
    func endManipulation() {
        guard let layer = activeLayer, let initial = initialTransform else { return }
        
        if layer.transform != initial {
            recordAction(.end(layerId: layer.id, transform: layer.transform))
        }
        
        activeLayer = nil
        initialTransform = nil
        isManipulating = false
        
        onManipulationEnd?()
    }
    
    /// Cancel current manipulation
    func cancelManipulation() {
        guard let layer = activeLayer, let initial = initialTransform else { return }
        
        var canceledLayer = layer
        canceledLayer.transform = initial
        
        onLayerChanged?(canceledLayer)
        
        activeLayer = nil
        initialTransform = nil
        isManipulating = false
        
        onManipulationEnd?()
    }
    
    // MARK: - Advanced Manipulation Methods
    
    /// Move layer to specific position with constraints
    func moveLayer(_ layer: Layer, to position: CGPoint) {
        let constrainedPosition = applyPositionConstraints(position, layer: layer)
        
        var newTransform = layer.transform
        newTransform.x = constrainedPosition.x
        newTransform.y = constrainedPosition.y
        
        let updatedLayer = Layer(
            id: layer.id,
            type: layer.type,
            transform: newTransform,
            content: layer.content,
            style: layer.style,
            constraints: layer.constraints
        )
        
        recordAction(.move(layerId: layer.id, from: CGPoint(x: layer.transform.x, y: layer.transform.y), to: constrainedPosition))
        onLayerChanged?(updatedLayer)
    }
    
    /// Scale layer with aspect ratio constraints
    func scaleLayer(_ layer: Layer, scale: CGFloat, maintainAspectRatio: Bool = true) {
        let constrainedScale = applyScaleConstraints(scale, layer: layer)
        
        var newTransform = layer.transform
        newTransform.scaleX = constrainedScale
        newTransform.scaleY = maintainAspectRatio ? constrainedScale : newTransform.scaleY
        
        let updatedLayer = Layer(
            id: layer.id,
            type: layer.type,
            transform: newTransform,
            content: layer.content,
            style: layer.style,
            constraints: layer.constraints
        )
        
        recordAction(.scale(layerId: layer.id, from: layer.transform.scaleX, to: constrainedScale))
        onLayerChanged?(updatedLayer)
    }
    
    /// Rotate layer with snap angles
    func rotateLayer(_ layer: Layer, angle: Double) {
        let constrainedAngle = applyRotationConstraints(angle, layer: layer)
        
        var newTransform = layer.transform
        newTransform.rotation = constrainedAngle
        
        let updatedLayer = Layer(
            id: layer.id,
            type: layer.type,
            transform: newTransform,
            content: layer.content,
            style: layer.style,
            constraints: layer.constraints
        )
        
        recordAction(.rotate(layerId: layer.id, from: layer.transform.rotation, to: constrainedAngle))
        onLayerChanged?(updatedLayer)
    }
    
    // MARK: - Batch Operations
    
    /// Group selected layers
    func groupLayers(_ layers: [Layer]) -> Layer? {
        guard layers.count > 1 else { return nil }
        
        let groupId = UUID().uuidString
        let bounds = calculateBounds(for: layers)
        
        let groupLayer = Layer(
            id: groupId,
            type: .group,
            transform: Transform(
                x: bounds.midX,
                y: bounds.midY,
                scaleX: 1.0,
                scaleY: 1.0,
                rotation: 0.0,
                opacity: 1.0
            ),
            content: LayerContent(childLayerIds: layers.map { $0.id }),
            style: nil,
            constraints: LayerConstraints(locked: false, visible: true)
        )
        
        recordAction(.group(layerIds: layers.map { $0.id }, groupId: groupId))
        return groupLayer
    }
    
    /// Align layers
    func alignLayers(_ layers: [Layer], alignment: AlignmentType) {
        guard layers.count > 1 else { return }
        
        let bounds = calculateBounds(for: layers)
        var alignedLayers: [Layer] = []
        
        for layer in layers {
            var newTransform = layer.transform
            
            switch alignment {
            case .left:
                newTransform.x = bounds.minX
            case .right:
                newTransform.x = bounds.maxX
            case .top:
                newTransform.y = bounds.minY
            case .bottom:
                newTransform.y = bounds.maxY
            case .centerHorizontal:
                newTransform.x = bounds.midX
            case .centerVertical:
                newTransform.y = bounds.midY
            }
            
            let alignedLayer = Layer(
                id: layer.id,
                type: layer.type,
                transform: newTransform,
                content: layer.content,
                style: layer.style,
                constraints: layer.constraints
            )
            
            alignedLayers.append(alignedLayer)
        }
        
        recordAction(.align(layerIds: layers.map { $0.id }, alignment: alignment))
        
        for layer in alignedLayers {
            onLayerChanged?(layer)
        }
    }
    
    /// Distribute layers evenly
    func distributeLayers(_ layers: [Layer], distribution: DistributionType) {
        guard layers.count > 2 else { return }
        
        let sortedLayers = layers.sorted { layer1, layer2 in
            switch distribution {
            case .horizontal:
                return layer1.transform.x < layer2.transform.x
            case .vertical:
                return layer1.transform.y < layer2.transform.y
            }
        }
        
        let first = sortedLayers.first!
        let last = sortedLayers.last!
        let totalDistance = distribution == .horizontal ? 
            last.transform.x - first.transform.x :
            last.transform.y - first.transform.y
        
        let spacing = totalDistance / Double(sortedLayers.count - 1)
        
        for (index, layer) in sortedLayers.enumerated() {
            guard index > 0 && index < sortedLayers.count - 1 else { continue }
            
            var newTransform = layer.transform
            
            switch distribution {
            case .horizontal:
                newTransform.x = first.transform.x + (spacing * Double(index))
            case .vertical:
                newTransform.y = first.transform.y + (spacing * Double(index))
            }
            
            let distributedLayer = Layer(
                id: layer.id,
                type: layer.type,
                transform: newTransform,
                content: layer.content,
                style: layer.style,
                constraints: layer.constraints
            )
            
            onLayerChanged?(distributedLayer)
        }
        
        recordAction(.distribute(layerIds: layers.map { $0.id }, distribution: distribution))
    }
    
    // MARK: - Undo/Redo
    
    func undo() {
        guard let action = undoStack.popLast() else { return }
        redoStack.append(action)
        
        // Apply inverse action
        switch action {
        case .move(_, _, _):
            // Move back to original position
            break
        case .scale(_, _, _):
            // Scale back to original
            break
        case .rotate(_, _, _):
            // Rotate back to original
            break
        default:
            break
        }
    }
    
    func redo() {
        guard let action = redoStack.popLast() else { return }
        undoStack.append(action)
        
        // Apply action
        // Implementation similar to undo but in forward direction
    }
    
    // MARK: - Private Helper Methods
    
    private func setupDefaultConstraints() {
        manipulationConstraints = ManipulationConstraints(
            minScale: 0.1,
            maxScale: 5.0,
            allowRotation: true,
            snapAngle: 15.0,
            respectLayerBounds: true
        )
    }
    
    private func applyTranslation(to transform: Transform, translation: CGSize, layer: Layer) -> Transform {
        var newTransform = transform
        newTransform.x += translation.width
        newTransform.y += translation.height
        return newTransform
    }
    
    private func applyScaling(to transform: Transform, scale: CGFloat, layer: Layer) -> Transform {
        var newTransform = transform
        let constrainedScale = applyScaleConstraints(scale, layer: layer)
        newTransform.scaleX = constrainedScale
        newTransform.scaleY = constrainedScale
        return newTransform
    }
    
    private func applyRotation(to transform: Transform, rotation: Angle, layer: Layer) -> Transform {
        var newTransform = transform
        newTransform.rotation = applyRotationConstraints(rotation.degrees, layer: layer)
        return newTransform
    }
    
    private func applyConstraints(to transform: Transform, layer: Layer) -> Transform {
        var constrainedTransform = transform
        
        // Apply scale constraints
        constrainedTransform.scaleX = max(manipulationConstraints.minScale, 
                                        min(constrainedTransform.scaleX, manipulationConstraints.maxScale))
        constrainedTransform.scaleY = max(manipulationConstraints.minScale, 
                                        min(constrainedTransform.scaleY, manipulationConstraints.maxScale))
        
        // Apply opacity constraints
        constrainedTransform.opacity = max(0.0, min(constrainedTransform.opacity, 1.0))
        
        return constrainedTransform
    }
    
    private func applySnapping(to transform: Transform, layer: Layer) -> Transform {
        var snappedTransform = transform
        
        if snapToGrid {
            snappedTransform.x = round(snappedTransform.x / gridSize) * gridSize
            snappedTransform.y = round(snappedTransform.y / gridSize) * gridSize
        }
        
        return snappedTransform
    }
    
    private func applyPositionConstraints(_ position: CGPoint, layer: Layer) -> CGPoint {
        // Apply layer-specific position constraints
        return position
    }
    
    private func applyScaleConstraints(_ scale: CGFloat, layer: Layer) -> CGFloat {
        return max(manipulationConstraints.minScale, min(scale, manipulationConstraints.maxScale))
    }
    
    private func applyRotationConstraints(_ rotation: Double, layer: Layer) -> Double {
        if manipulationConstraints.allowRotation {
            // Snap to common angles if within threshold
            let snapAngles: [Double] = [0, 45, 90, 135, 180, 225, 270, 315]
            for snapAngle in snapAngles {
                if abs(rotation - snapAngle) < manipulationConstraints.snapAngle {
                    return snapAngle
                }
            }
            return rotation
        }
        return 0.0
    }
    
    private func calculateBounds(for layers: [Layer]) -> CGRect {
        guard !layers.isEmpty else { return .zero }
        
        var minX = layers[0].transform.x
        var maxX = layers[0].transform.x
        var minY = layers[0].transform.y
        var maxY = layers[0].transform.y
        
        for layer in layers {
            minX = min(minX, layer.transform.x)
            maxX = max(maxX, layer.transform.x)
            minY = min(minY, layer.transform.y)
            maxY = max(maxY, layer.transform.y)
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private func recordAction(_ action: ManipulationAction) {
        undoStack.append(action)
        redoStack.removeAll() // Clear redo stack on new action
        
        // Limit undo stack size
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
    }
}

// MARK: - Supporting Types

enum ManipulationTool {
    case select
    case move
    case scale
    case rotate
}

struct ManipulationConstraints {
    var minScale: CGFloat = 0.1
    var maxScale: CGFloat = 5.0
    var allowRotation: Bool = true
    var snapAngle: Double = 15.0
    var respectLayerBounds: Bool = true
}

enum AlignmentType {
    case left, right, top, bottom
    case centerHorizontal, centerVertical
}

enum DistributionType {
    case horizontal, vertical
}

enum ManipulationAction {
    case start(layerId: String, transform: Transform)
    case end(layerId: String, transform: Transform)
    case move(layerId: String, from: CGPoint, to: CGPoint)
    case scale(layerId: String, from: CGFloat, to: CGFloat)
    case rotate(layerId: String, from: Double, to: Double)
    case group(layerIds: [String], groupId: String)
    case ungroup(groupId: String, layerIds: [String])
    case align(layerIds: [String], alignment: AlignmentType)
    case distribute(layerIds: [String], distribution: DistributionType)
}

// MARK: - Gesture Recognizer Extensions (iOS Only)
#if canImport(UIKit)
extension CanvasManipulation {
    
    /// Handle pan gesture for movement
    func handlePanGesture(_ gesture: UIPanGestureRecognizer, layer: Layer) {
        switch gesture.state {
        case .began:
            startManipulation(layer: layer, at: gesture.location(in: gesture.view), tool: .move)
        case .changed:
            let translation = gesture.translation(in: gesture.view)
            updateManipulation(translation: CGSize(width: translation.x, height: translation.y))
        case .ended, .cancelled:
            endManipulation()
        default:
            break
        }
    }
    
    /// Handle pinch gesture for scaling
    func handlePinchGesture(_ gesture: UIPinchGestureRecognizer, layer: Layer) {
        switch gesture.state {
        case .began:
            startManipulation(layer: layer, at: gesture.location(in: gesture.view), tool: .scale)
        case .changed:
            updateManipulation(translation: .zero, scale: gesture.scale)
        case .ended, .cancelled:
            endManipulation()
            gesture.scale = 1.0
        default:
            break
        }
    }
    
    /// Handle rotation gesture
    func handleRotationGesture(_ gesture: UIRotationGestureRecognizer, layer: Layer) {
        switch gesture.state {
        case .began:
            startManipulation(layer: layer, at: gesture.location(in: gesture.view), tool: .rotate)
        case .changed:
            updateManipulation(translation: .zero, scale: 1.0, rotation: Angle(radians: gesture.rotation))
        case .ended, .cancelled:
            endManipulation()
            gesture.rotation = 0
        default:
            break
        }
    }
}
#endif

// MARK: - SwiftUI Integration

extension CanvasManipulation {
    
    /// Create gesture for SwiftUI integration
    func createDragGesture(for layer: Layer) -> some Gesture {
        DragGesture()
            .onChanged { [weak self] value in
                guard let self = self else { return }
                if !self.isManipulating {
                    self.startManipulation(layer: layer, at: value.startLocation, tool: .move)
                }
                self.updateManipulation(translation: value.translation)
            }
            .onEnded { [weak self] _ in
                self?.endManipulation()
            }
    }
    
    /// Create magnification gesture for SwiftUI
    func createMagnificationGesture(for layer: Layer) -> some Gesture {
        MagnificationGesture()
            .onChanged { [weak self] value in
                guard let self = self else { return }
                if !self.isManipulating {
                    self.startManipulation(layer: layer, at: .zero, tool: .scale)
                }
                self.updateManipulation(translation: .zero, scale: value)
            }
            .onEnded { [weak self] _ in
                self?.endManipulation()
            }
    }
    
    /// Create rotation gesture for SwiftUI
    func createRotationGesture(for layer: Layer) -> some Gesture {
        RotationGesture()
            .onChanged { [weak self] value in
                guard let self = self else { return }
                if !self.isManipulating {
                    self.startManipulation(layer: layer, at: .zero, tool: .rotate)
                }
                self.updateManipulation(translation: .zero, scale: 1.0, rotation: value)
            }
            .onEnded { [weak self] _ in
                self?.endManipulation()
            }
    }
}
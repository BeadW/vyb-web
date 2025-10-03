import SwiftUI
import CoreGraphics
import Foundation

/// iOS Canvas View - Core Graphics canvas with touch handling for design manipulation
/// Implements T042: iOS Canvas View with SwiftUI and Core Graphics integration
/// Compatible with Layer and DesignCanvas models for cross-platform consistency
struct CanvasView: View {
    // MARK: - State Management
    @StateObject private var canvasState = CanvasViewModel()
    @State private var selectedLayerId: String?
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragValue: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScaleValue: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    @State private var lastRotationValue: Angle = .zero
    
    // MARK: - Canvas Properties
    let canvas: DesignCanvas
    let deviceType: DeviceType
    
    // MARK: - View Initialization
    init(canvas: DesignCanvas, deviceType: DeviceType = .mobile) {
        self.canvas = canvas
        self.deviceType = deviceType
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas Background
                Rectangle()
                    .fill(Color.white)
                    .frame(width: canvasState.canvasSize.width, height: canvasState.canvasSize.height)
                    .border(Color.gray.opacity(0.3), width: 1)
                
                // Render all layers
                ForEach(canvasState.layers) { layer in
                    LayerView(
                        layer: layer,
                        isSelected: selectedLayerId == layer.id,
                        onTap: { handleLayerTap(layer) },
                        onDrag: { gesture in handleLayerDrag(layer, gesture) },
                        onScale: { gesture in handleLayerScale(layer, gesture) },
                        onRotate: { gesture in handleLayerRotate(layer, gesture) }
                    )
                }
                
                // Selection overlay for active layer
                if let selectedId = selectedLayerId,
                   let selectedLayer = canvasState.layers.first(where: { $0.id == selectedId }) {
                    SelectionOverlay(layer: selectedLayer)
                }
            }
            .frame(width: canvasState.canvasSize.width, height: canvasState.canvasSize.height)
            .scaleEffect(canvasState.zoom)
            .offset(canvasState.panOffset)
            .clipped()
            .onAppear {
                setupCanvas(geometry: geometry)
            }
            .gesture(
                // Canvas pan gesture (when no layer is selected)
                DragGesture()
                    .onChanged { value in
                        if selectedLayerId == nil {
                            canvasState.panOffset = CGSize(
                                width: lastDragValue.width + value.translation.x,
                                height: lastDragValue.height + value.translation.y
                            )
                        }
                    }
                    .onEnded { _ in
                        lastDragValue = canvasState.panOffset
                    }
                    .simultaneously(with:
                        // Canvas zoom gesture
                        MagnificationGesture()
                            .onChanged { value in
                                let newZoom = lastScaleValue * value
                                canvasState.zoom = max(0.1, min(newZoom, 5.0))
                            }
                            .onEnded { _ in
                                lastScaleValue = canvasState.zoom
                            }
                    )
            )
        }
    }
    
    // MARK: - Canvas Setup
    private func setupCanvas(geometry: GeometryProxy) {
        // Initialize canvas based on device type and specifications
        let deviceSpec = DeviceSpecifications.DEVICE_SPECS[deviceType]
        let aspectRatio = deviceSpec?.aspectRatios.first
        
        canvasState.canvasSize = CGSize(
            width: aspectRatio?.width ?? geometry.size.width,
            height: aspectRatio?.height ?? geometry.size.height
        )
        
        // Load layers from canvas model
        canvasState.loadLayers(from: canvas)
    }
    
    // MARK: - Touch Handling
    private func handleLayerTap(_ layer: Layer) {
        selectedLayerId = layer.id
        canvasState.selectLayer(layer.id)
    }
    
    private func handleLayerDrag(_ layer: Layer, _ gesture: DragGesture.Value) {
        guard selectedLayerId == layer.id else { return }
        
        canvasState.updateLayerTransform(
            layerId: layer.id,
            transform: Transform(
                x: layer.transform.x + gesture.translation.x / canvasState.zoom,
                y: layer.transform.y + gesture.translation.y / canvasState.zoom,
                scaleX: layer.transform.scaleX,
                scaleY: layer.transform.scaleY,
                rotation: layer.transform.rotation,
                opacity: layer.transform.opacity
            )
        )
    }
    
    private func handleLayerScale(_ layer: Layer, _ gesture: MagnificationGesture.Value) {
        guard selectedLayerId == layer.id else { return }
        
        let newScale = max(0.1, min(gesture * layer.transform.scaleX, 5.0))
        canvasState.updateLayerTransform(
            layerId: layer.id,
            transform: Transform(
                x: layer.transform.x,
                y: layer.transform.y,
                scaleX: newScale,
                scaleY: newScale,
                rotation: layer.transform.rotation,
                opacity: layer.transform.opacity
            )
        )
    }
    
    private func handleLayerRotate(_ layer: Layer, _ gesture: RotationGesture.Value) {
        guard selectedLayerId == layer.id else { return }
        
        let newRotation = layer.transform.rotation + gesture.degrees
        canvasState.updateLayerTransform(
            layerId: layer.id,
            transform: Transform(
                x: layer.transform.x,
                y: layer.transform.y,
                scaleX: layer.transform.scaleX,
                scaleY: layer.transform.scaleY,
                rotation: newRotation,
                opacity: layer.transform.opacity
            )
        )
    }
}

// MARK: - Layer View Component
struct LayerView: View {
    let layer: Layer
    let isSelected: Bool
    let onTap: () -> Void
    let onDrag: (DragGesture.Value) -> Void
    let onScale: (MagnificationGesture.Value) -> Void
    let onRotate: (RotationGesture.Value) -> Void
    
    var body: some View {
        Group {
            switch layer.type {
            case .text:
                TextLayerView(layer: layer)
            case .image:
                ImageLayerView(layer: layer)
            case .shape:
                ShapeLayerView(layer: layer)
            case .background:
                BackgroundLayerView(layer: layer)
            case .group:
                GroupLayerView(layer: layer)
            }
        }
        .scaleEffect(CGSize(width: layer.transform.scaleX, height: layer.transform.scaleY))
        .rotationEffect(.degrees(layer.transform.rotation))
        .opacity(layer.transform.opacity)
        .offset(x: layer.transform.x, y: layer.transform.y)
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture()
                .onChanged(onDrag)
                .simultaneously(with:
                    MagnificationGesture()
                        .onChanged(onScale)
                        .simultaneously(with:
                            RotationGesture()
                                .onChanged(onRotate)
                        )
                )
        )
    }
}

// MARK: - Layer Type Views
struct TextLayerView: View {
    let layer: Layer
    
    var body: some View {
        if let text = layer.content.text {
            Text(text)
                .font(.system(size: layer.content.fontSize ?? 16))
                .foregroundColor(Color(hex: layer.style?.color ?? "#000000"))
                .multilineTextAlignment(.center)
        }
    }
}

struct ImageLayerView: View {
    let layer: Layer
    
    var body: some View {
        if let imageUrl = layer.content.imageUrl {
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}

struct ShapeLayerView: View {
    let layer: Layer
    
    var body: some View {
        Rectangle()
            .fill(Color(hex: layer.content.fill ?? "#3B82F6"))
            .stroke(
                Color(hex: layer.content.stroke ?? "#000000"),
                lineWidth: layer.content.strokeWidth ?? 0
            )
            .frame(width: 100, height: 100) // Default shape size
    }
}

struct BackgroundLayerView: View {
    let layer: Layer
    
    var body: some View {
        Rectangle()
            .fill(Color(hex: layer.content.color ?? "#FFFFFF"))
    }
}

struct GroupLayerView: View {
    let layer: Layer
    
    var body: some View {
        // Group layers are containers - rendered by their children
        Rectangle()
            .fill(Color.clear)
            .overlay(
                Text("Group")
                    .font(.caption)
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Selection Overlay
struct SelectionOverlay: View {
    let layer: Layer
    
    var body: some View {
        Rectangle()
            .stroke(Color.blue, lineWidth: 2)
            .fill(Color.clear)
            .frame(width: 100, height: 100) // Approximate layer bounds
            .offset(x: layer.transform.x, y: layer.transform.y)
            .scaleEffect(CGSize(width: layer.transform.scaleX, height: layer.transform.scaleY))
            .rotationEffect(.degrees(layer.transform.rotation))
    }
}

// MARK: - Canvas View Model
class CanvasViewModel: ObservableObject {
    @Published var layers: [Layer] = []
    @Published var canvasSize: CGSize = .zero
    @Published var zoom: CGFloat = 1.0
    @Published var panOffset: CGSize = .zero
    @Published var selectedLayerId: String?
    
    func loadLayers(from canvas: DesignCanvas) {
        // Load layers from Core Data model
        layers = canvas.layersArray
    }
    
    func selectLayer(_ layerId: String) {
        selectedLayerId = layerId
    }
    
    func updateLayerTransform(layerId: String, transform: Transform) {
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            layers[index].transform = transform
        }
    }
    
    func addLayer(_ layer: Layer) {
        layers.append(layer)
    }
    
    func removeLayer(layerId: String) {
        layers.removeAll { $0.id == layerId }
    }
    
    func reorderLayers(from source: IndexSet, to destination: Int) {
        layers.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct CanvasView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample canvas for preview
        let context = PersistenceController.preview.container.viewContext
        let sampleCanvas = DesignCanvas(context: context)
        sampleCanvas.id = UUID().uuidString
        
        CanvasView(canvas: sampleCanvas, deviceType: .mobile)
            .previewLayout(.sizeThatFits)
    }
}
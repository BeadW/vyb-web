import SwiftUI

/// LayerCanvas - A canvas view that renders layers from LayerState
/// This bridges our layer management UI with the visual canvas rendering
struct LayerCanvas: View {
    @ObservedObject var layerState: LayerState
    @State private var dragOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas Background
                Rectangle()
                    .fill(Color.white)
                    .border(Color.gray.opacity(0.3), width: 1)
                
                // Render all visible layers
                ForEach(layerState.layers.filter { $0.isVisible }.sorted { $0.zIndex < $1.zIndex }) { layer in
                    LayerRenderer(
                        layer: layer,
                        isSelected: layerState.selectedLayerIds.contains(layer.id),
                        canvasSize: geometry.size
                    )
                    .onTapGesture {
                        layerState.selectLayer(layer.id)
                    }
                }
            }
            .clipped()
        }
    }
}

/// LayerRenderer - Renders individual layers based on their type and properties
struct LayerRenderer: View {
    let layer: LayerItem
    let isSelected: Bool
    let canvasSize: CGSize
    
    var body: some View {
        Group {
            switch layer.type {
            case .text, .postText:
                TextLayerView(layer: layer)
            case .image:
                ImageLayerView(layer: layer)
            case .shape:
                ShapeLayerView(layer: layer)
            case .background:
                BackgroundLayerView(layer: layer)
            }
        }
        .position(
            x: canvasSize.width * 0.5 + CGFloat(layer.transform.x),
            y: canvasSize.height * 0.5 + CGFloat(layer.transform.y)
        )
        .scaleEffect(
            x: CGFloat(layer.transform.scaleX),
            y: CGFloat(layer.transform.scaleY)
        )
        .rotationEffect(.degrees(layer.transform.rotation))
        .opacity(layer.transform.opacity)
        .overlay(
            // Selection indicator
            isSelected ? 
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.blue, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.1))
                )
            : nil
        )
    }
}

// MARK: - Layer Type Views

struct TextLayerView: View {
    let layer: LayerItem
    
    var body: some View {
        Text(layer.content.text ?? "Text")
            .font(.system(size: CGFloat(layer.content.fontSize ?? 16)))
            .foregroundColor(Color(hex: layer.style.color ?? "#000000"))
            .multilineTextAlignment(.center)
            .padding(8)
    }
}

struct ImageLayerView: View {
    let layer: LayerItem
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            )
    }
}

struct ShapeLayerView: View {
    let layer: LayerItem
    
    var body: some View {
        Group {
            switch layer.content.shapeType {
            case "circle":
                Circle()
                    .fill(Color(hex: layer.style.color ?? "#FF0000"))
                    .frame(width: 60, height: 60)
            case "rectangle":
                Rectangle()
                    .fill(Color(hex: layer.style.color ?? "#00FF00"))
                    .frame(width: 80, height: 60)
            case "triangle":
                Triangle()
                    .fill(Color(hex: layer.style.color ?? "#0000FF"))
                    .frame(width: 70, height: 70)
            default:
                Circle()
                    .fill(Color(hex: layer.style.color ?? "#FF0000"))
                    .frame(width: 60, height: 60)
            }
        }
    }
}

struct BackgroundLayerView: View {
    let layer: LayerItem
    
    var body: some View {
        Rectangle()
            .fill(Color(hex: layer.style.color ?? "#F0F0F0"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Helper Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
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
#if DEBUG
struct LayerCanvas_Previews: PreviewProvider {
    static var previews: some View {
        LayerCanvas(layerState: LayerState())
            .frame(height: 400)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
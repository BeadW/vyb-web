import SwiftUI

struct ContentView: View {
    @State private var isEditing = false
    @State private var editingText = "What's on your mind?"
    @State private var layers: [SimpleLayer] = []
    @State private var canvasSize: CGSize = .zero
    @State private var isEditingLayer: String? = nil
    @State private var showTextStylePanel = false
    @State private var showTextStyleModal = false
    @State private var showLayerManagerModal = false
    @State private var showLayerEditorModal = false
    @State private var selectedLayerForStyling: SimpleLayer?
    @State private var selectedLayerForEditing: SimpleLayer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Facebook Header
            HStack(spacing: 12) {
                // Profile Picture
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Name")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text("Just now")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "globe")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Post Text Section
            VStack(alignment: .leading, spacing: 8) {
                if isEditing {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $editingText)
                            .frame(minHeight: 60)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        HStack {
                            Button("Cancel") {
                                isEditing = false
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Save") {
                                isEditing = false
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        }
                    }
                } else {
                    Button(action: {
                        isEditing = true
                    }) {
                        HStack {
                            Text(editingText)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Canvas Section with Layers
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    let canvasWidth = geometry.size.width
                    let canvasHeight = canvasWidth * (10.0/16.0) // 16:10 aspect ratio
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: canvasWidth, height: canvasHeight)
                            .cornerRadius(8)
                            .border(Color.gray.opacity(0.3), width: 1)
                        
                        // Render layers within canvas bounds, sorted by z-order
                        ForEach(layers.sorted(by: { $0.zOrder < $1.zOrder }), id: \.id) { layer in
                            if let index = layers.firstIndex(where: { $0.id == layer.id }) {
                                LayerView(
                                    layer: Binding(
                                        get: { layers[index] },
                                        set: { layers[index] = $0 }
                                    ),
                                    canvasWidth: canvasWidth,
                                    canvasHeight: canvasHeight
                                )
                            }
                        }
                    }
                    .frame(width: canvasWidth, height: canvasHeight)
                    .onAppear {
                        canvasSize = CGSize(width: canvasWidth, height: canvasHeight)
                    }
                    .onChange(of: geometry.size) { oldValue, newValue in
                        let newCanvasWidth = newValue.width
                        let newCanvasHeight = newCanvasWidth * (10.0/16.0)
                        canvasSize = CGSize(width: newCanvasWidth, height: newCanvasHeight)
                    }
                }
                .aspectRatio(16/10, contentMode: .fit)
                .clipped()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Facebook Action Buttons - Keep authentic post structure
            HStack {
                FacebookActionButton(icon: "hand.thumbsup", label: "Like")
                Spacer()
                FacebookActionButton(icon: "bubble.left", label: "Comment")
                Spacer()
                FacebookActionButton(icon: "arrowshape.turn.up.right", label: "Share")
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 10)
            .background(Color.white)
            .overlay(Divider(), alignment: .top)
            .overlay(Divider(), alignment: .bottom)
            
            // Layer Management Controls - Now below the post structure
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Canvas Controls")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                // Layer Management Toolbar
                HStack(spacing: 12) {
                    // Add Layer Menu
                    Menu {
                        Button(action: { addLayer(type: "text") }) {
                            Label("Text", systemImage: "textformat")
                        }
                        Button(action: { addLayer(type: "image") }) {
                            Label("Image", systemImage: "photo")
                        }
                        Button(action: { addLayer(type: "shape") }) {
                            Label("Shape", systemImage: "circle")
                        }
                        Button(action: { addLayer(type: "background") }) {
                            Label("Background", systemImage: "rectangle")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                            Text("Add Layer")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    
                    Button(action: {
                        showLayerManagerModal = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.stack")
                                .font(.system(size: 16, weight: .medium))
                            Text("Manage")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    
                    if let selectedLayer = layers.first(where: { $0.isSelected && $0.type == "text" }) {
                        Button(action: {
                            selectedLayerForStyling = selectedLayer
                            showTextStyleModal = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "textformat")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Style")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                    
                    Spacer()
                    
                    Text("Layers: \(layers.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !layers.isEmpty {
                        Button("Clear All") {
                            layers.removeAll()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 16)
                
                // Quick layer overview (compact horizontal scroll)
                if !layers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Layer Access")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(layers.sorted(by: { $0.zOrder > $1.zOrder }), id: \.id) { layer in
                                    Button(action: {
                                        // Toggle selection
                                        if let index = layers.firstIndex(where: { $0.id == layer.id }) {
                                            layers[index].isSelected.toggle()
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: layer.type == "text" ? "textformat" : layer.type == "image" ? "photo" : layer.type == "shape" ? "circle.fill" : "rectangle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(layer.isSelected ? .white : .primary)
                                            
                                            Text(layer.content.isEmpty ? "Layer" : String(layer.content.prefix(6)))
                                                .font(.caption2)
                                                .lineLimit(1)
                                                .foregroundColor(layer.isSelected ? .white : .primary)
                                            
                                            Text("Z:\(layer.zOrder)")
                                                .font(.caption2)
                                                .foregroundColor(layer.isSelected ? .white : .secondary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(layer.isSelected ? Color.blue : Color.gray.opacity(0.15))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showTextStyleModal) {
            if let layer = selectedLayerForStyling {
                TextStyleModalView(layer: Binding(
                    get: { layer },
                    set: { updatedLayer in
                        if let index = layers.firstIndex(where: { $0.id == layer.id }) {
                            layers[index] = updatedLayer
                        }
                        selectedLayerForStyling = updatedLayer
                    }
                ))
            }
        }
        .sheet(isPresented: $showLayerManagerModal) {
            LayerManagerModalView(
                layers: $layers,
                onEditLayer: { layer in
                    selectedLayerForEditing = layer
                    showLayerEditorModal = true
                }
            )
        }
        .sheet(isPresented: $showLayerEditorModal) {
            if let layer = selectedLayerForEditing {
                LayerEditorModalView(layer: Binding(
                    get: { layer },
                    set: { updatedLayer in
                        if let index = layers.firstIndex(where: { $0.id == layer.id }) {
                            layers[index] = updatedLayer
                        }
                        selectedLayerForEditing = updatedLayer
                    }
                ))
            }
        }
    }
    
    private func addLayer(type: String) {
        let canvasWidth = canvasSize.width > 0 ? canvasSize.width : 300
        let canvasHeight = canvasSize.height > 0 ? canvasSize.height : 200
        
        let newLayer = SimpleLayer(
            id: UUID().uuidString,
            type: type,
            content: type == "text" ? "New Text" : type.capitalized,
            x: Double.random(in: 50...(canvasWidth - 50)),
            y: Double.random(in: 50...(canvasHeight - 50)),
            zOrder: layers.count
        )
        layers.append(newLayer)
    }
    
    private func moveLayerToFront(_ layerId: String) {
        guard let index = layers.firstIndex(where: { $0.id == layerId }) else { return }
        let maxZ = layers.map { $0.zOrder }.max() ?? 0
        layers[index].zOrder = maxZ + 1
    }
    
    private func moveLayerToBack(_ layerId: String) {
        guard let index = layers.firstIndex(where: { $0.id == layerId }) else { return }
        let minZ = layers.map { $0.zOrder }.min() ?? 0
        layers[index].zOrder = minZ - 1
    }
    
    private func moveLayerUp(_ layerId: String) {
        guard let index = layers.firstIndex(where: { $0.id == layerId }) else { return }
        let currentZ = layers[index].zOrder
        let nextHigherZ = layers.filter { $0.zOrder > currentZ }.map { $0.zOrder }.min()
        
        if let nextZ = nextHigherZ {
            layers[index].zOrder = nextZ + 1
        } else {
            layers[index].zOrder = currentZ + 1
        }
    }
    
    private func moveLayerDown(_ layerId: String) {
        guard let index = layers.firstIndex(where: { $0.id == layerId }) else { return }
        let currentZ = layers[index].zOrder
        let nextLowerZ = layers.filter { $0.zOrder < currentZ }.map { $0.zOrder }.max()
        
        if let nextZ = nextLowerZ {
            layers[index].zOrder = nextZ - 1
        } else {
            layers[index].zOrder = currentZ - 1
        }
    }
    
    private func weightName(_ weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight: return "UL"
        case .thin: return "Thin"
        case .light: return "Light"
        case .regular: return "Reg"
        case .medium: return "Med"
        case .semibold: return "Semi"
        case .bold: return "Bold"
        case .heavy: return "Heavy"
        case .black: return "Black"
        default: return "Reg"
        }
    }
    
    private func alignmentIcon(_ alignment: TextAlignment) -> String {
        switch alignment {
        case .leading: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }
}

struct FacebookActionButton: View {
    let icon: String
    let label: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(.system(size: 15, weight: .medium))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SimpleLayer: Identifiable {
    let id: String
    let type: String
    var content: String
    var x: Double
    var y: Double
    var isSelected: Bool = false
    var zOrder: Int = 0
    
    // Text styling properties
    var fontSize: CGFloat = 18
    var fontWeight: Font.Weight = .medium
    var textColor: Color = .black
    var isItalic: Bool = false
    var isUnderlined: Bool = false
    var textAlignment: TextAlignment = .leading
    var hasShadow: Bool = false
    var shadowColor: Color = .gray
    var hasStroke: Bool = false
    var strokeColor: Color = .white
    var strokeWidth: CGFloat = 1.0
}

struct LayerManagementRow: View {
    @Binding var layer: SimpleLayer
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onMoveToFront: () -> Void
    let onMoveToBack: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                // Layer type icon
                Group {
                    if layer.type == "text" {
                        Image(systemName: "textformat")
                            .foregroundColor(.black)
                    } else if layer.type == "image" {
                        Image(systemName: "photo")
                            .foregroundColor(.blue)
                    } else if layer.type == "shape" {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.red)
                    } else if layer.type == "background" {
                        Image(systemName: "rectangle.fill")
                            .foregroundColor(.yellow)
                    }
                }
                .font(.system(size: 16))
                .frame(width: 20)
                
                // Layer content/name with z-order
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(layer.content)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                        
                        // Z-order indicator
                        Text("Z:\(layer.zOrder)")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(3)
                    }
                    Text(layer.type.capitalized)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if layer.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
                
                // Edit button - only show when single layer is selected
                if layer.isSelected {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Z-order controls
            if layer.isSelected {
                HStack(spacing: 8) {
                    Button("To Back") { onMoveToBack() }
                        .font(.system(size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                    
                    Button("Down") { onMoveDown() }
                        .font(.system(size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Button("Up") { onMoveUp() }
                        .font(.system(size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Button("To Front") { onMoveToFront() }
                        .font(.system(size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(layer.isSelected ? Color.blue.opacity(0.1) : Color.white)
        .cornerRadius(6)
        .onTapGesture {
            layer.isSelected.toggle()
        }
    }
}

struct LayerView: View {
    @Binding var layer: SimpleLayer
    let canvasWidth: Double
    let canvasHeight: Double
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var isEditingText = false
    @State private var editingContent = ""
    
    var body: some View {
        Group {
            if layer.type == "text" {
                Text(layer.content)
                    .font(.system(size: layer.fontSize, weight: layer.fontWeight))
                    .italic(layer.isItalic)
                    .underline(layer.isUnderlined)
                    .foregroundColor(layer.textColor)
                    .multilineTextAlignment(layer.textAlignment)
                    .shadow(
                        color: layer.hasShadow ? layer.shadowColor : Color.clear,
                        radius: layer.hasShadow ? 2 : 0,
                        x: layer.hasShadow ? 1 : 0,
                        y: layer.hasShadow ? 1 : 0
                    )
                    .padding(8)
                    .background(layer.isSelected ? Color.blue.opacity(0.2) : Color.clear)
                    .border(layer.isSelected ? Color.blue : Color.clear, width: 2)
                    .cornerRadius(4)
            } else if layer.type == "image" {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(layer.isSelected ? Color.blue.opacity(0.2) : Color.clear)
                    .border(layer.isSelected ? Color.blue : Color.clear, width: 2)
                    .cornerRadius(4)
            } else if layer.type == "shape" {
                Circle()
                    .fill(Color.red)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(layer.isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            } else if layer.type == "background" {
                Rectangle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: 100, height: 60)
                    .cornerRadius(4)
                    .overlay(
                        Rectangle()
                            .stroke(layer.isSelected ? Color.blue : Color.clear, lineWidth: 2)
                            .cornerRadius(4)
                    )
            }
        }
        .position(x: layer.x + dragOffset.width, y: layer.y + dragOffset.height)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .opacity(isDragging ? 0.8 : 1.0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    
                    // Calculate new position within canvas bounds
                    let newX = max(25, min(canvasWidth - 25, layer.x + value.translation.width))
                    let newY = max(25, min(canvasHeight - 25, layer.y + value.translation.height))
                    
                    layer.x = newX
                    layer.y = newY
                    dragOffset = .zero
                }
        )
        .onTapGesture {
            layer.isSelected.toggle()
        }
        .onTapGesture(count: 2) {
            if layer.type == "text" {
                editingContent = layer.content
                isEditingText = true
            }
        }
        .overlay(
            // Text editing overlay
            Group {
                if isEditingText && layer.type == "text" {
                    VStack(spacing: 8) {
                        TextEditor(text: $editingContent)
                            .font(.system(size: layer.fontSize, weight: layer.fontWeight))
                            .multilineTextAlignment(layer.textAlignment)
                            .frame(minWidth: 120, minHeight: 60)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 4)
                        
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                isEditingText = false
                                editingContent = ""
                            }
                            .font(.system(size: 12))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            
                            Button("Save") {
                                layer.content = editingContent
                                isEditingText = false
                                editingContent = ""
                            }
                            .font(.system(size: 12))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                    }
                    .offset(y: -80)
                }
            }
        )
    }
}

// MARK: - Modal Views

struct TextStyleModalView: View {
    @Binding var layer: SimpleLayer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Font Size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size: \(Int(layer.fontSize))")
                        .font(.system(size: 16, weight: .medium))
                    Slider(value: $layer.fontSize, in: 12...48, step: 1)
                        .tint(.blue)
                }
                
                // Font Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Weight")
                        .font(.system(size: 16, weight: .medium))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([Font.Weight.ultraLight, .light, .regular, .medium, .semibold, .bold, .heavy, .black], id: \.self) { weight in
                                Button(weightName(weight)) {
                                    layer.fontWeight = weight
                                }
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(layer.fontWeight == weight ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(layer.fontWeight == weight ? .white : .primary)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Text Style Toggles
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Style")
                        .font(.system(size: 16, weight: .medium))
                    HStack(spacing: 12) {
                        Button(action: { layer.isItalic.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "italic")
                                Text("Italic")
                            }
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(layer.isItalic ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(layer.isItalic ? .white : .primary)
                            .cornerRadius(8)
                        }
                        
                        Button(action: { layer.isUnderlined.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "underline")
                                Text("Underline")
                            }
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(layer.isUnderlined ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(layer.isUnderlined ? .white : .primary)
                            .cornerRadius(8)
                        }
                    }
                }
                
                // Text Color
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Color")
                        .font(.system(size: 16, weight: .medium))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach([Color.black, .white, .red, .blue, .green, .orange, .purple, .pink, .yellow], id: \.self) { color in
                                Button(action: { layer.textColor = color }) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(layer.textColor == color ? Color.blue : Color.gray, lineWidth: layer.textColor == color ? 3 : 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Text Effects
                VStack(alignment: .leading, spacing: 8) {
                    Text("Effects")
                        .font(.system(size: 16, weight: .medium))
                    
                    HStack(spacing: 12) {
                        Button(action: { layer.hasShadow.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "shadow")
                                Text("Shadow")
                            }
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(layer.hasShadow ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(layer.hasShadow ? .white : .primary)
                            .cornerRadius(8)
                        }
                        
                        Button(action: { layer.hasStroke.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil.tip")
                                Text("Stroke")
                            }
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(layer.hasStroke ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(layer.hasStroke ? .white : .primary)
                            .cornerRadius(8)
                        }
                    }
                }
                
                // Text Alignment
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alignment")
                        .font(.system(size: 16, weight: .medium))
                    HStack(spacing: 12) {
                        ForEach([TextAlignment.leading, .center, .trailing], id: \.self) { alignment in
                            Button(action: { layer.textAlignment = alignment }) {
                                Image(systemName: alignmentIcon(alignment))
                                    .font(.system(size: 20))
                                    .padding(12)
                                    .background(layer.textAlignment == alignment ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(layer.textAlignment == alignment ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Text Styling")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func weightName(_ weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight: return "UltraLight"
        case .thin: return "Thin"
        case .light: return "Light"
        case .regular: return "Regular"
        case .medium: return "Medium"
        case .semibold: return "Semibold"
        case .bold: return "Bold"
        case .heavy: return "Heavy"
        case .black: return "Black"
        default: return "Regular"
        }
    }
    
    private func alignmentIcon(_ alignment: TextAlignment) -> String {
        switch alignment {
        case .leading: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }
}

struct LayerManagerModalView: View {
    @Binding var layers: [SimpleLayer]
    let onEditLayer: (SimpleLayer) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                if layers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "square.stack")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Layers Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Add layers to your canvas to manage them here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Layer Management")
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                            Button("Deselect All") {
                                for i in layers.indices {
                                    layers[i].isSelected = false
                                }
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(layers.sorted(by: { $0.zOrder > $1.zOrder }), id: \.id) { layer in
                                    if let index = layers.firstIndex(where: { $0.id == layer.id }) {
                                        LayerManagementRow(
                                            layer: Binding(
                                                get: { layers[index] },
                                                set: { layers[index] = $0 }
                                            ),
                                            onDelete: {
                                                layers.remove(at: index)
                                            },
                                            onEdit: {
                                                onEditLayer(layer)
                                            },
                                            onMoveToFront: {
                                                moveLayerToFront(layer.id)
                                            },
                                            onMoveToBack: {
                                                moveLayerToBack(layer.id)
                                            },
                                            onMoveUp: {
                                                moveLayerUp(layer.id)
                                            },
                                            onMoveDown: {
                                                moveLayerDown(layer.id)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Layer Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func moveLayerToFront(_ layerId: String) {
        guard let index = layers.firstIndex(where: { $0.id == layerId }) else { return }
        let maxZ = layers.map { $0.zOrder }.max() ?? 0
        layers[index].zOrder = maxZ + 1
    }
    
    private func moveLayerToBack(_ layerId: String) {
        guard let index = layers.firstIndex(where: { $0.id == layerId }) else { return }
        let minZ = layers.map { $0.zOrder }.min() ?? 0
        layers[index].zOrder = minZ - 1
    }
    
    private func moveLayerUp(_ layerId: String) {
        guard let index = layers.firstIndex(where: { $0.id == layerId }) else { return }
        let currentZ = layers[index].zOrder
        let nextHigherZ = layers.filter { $0.zOrder > currentZ }.map { $0.zOrder }.min()
        
        if let nextZ = nextHigherZ {
            layers[index].zOrder = nextZ + 1
        } else {
            layers[index].zOrder = currentZ + 1
        }
    }
    
    private func moveLayerDown(_ layerId: String) {
        guard let index = layers.firstIndex(where: { $0.id == layerId }) else { return }
        let currentZ = layers[index].zOrder
        let nextLowerZ = layers.filter { $0.zOrder < currentZ }.map { $0.zOrder }.max()
        
        if let nextZ = nextLowerZ {
            layers[index].zOrder = nextZ - 1
        } else {
            layers[index].zOrder = currentZ - 1
        }
    }
}

struct LayerEditorModalView: View {
    @Binding var layer: SimpleLayer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Layer Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Layer Information")
                            .font(.system(size: 18, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Layer Type")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Group {
                                    if layer.type == "text" {
                                        Image(systemName: "textformat")
                                            .foregroundColor(.black)
                                    } else if layer.type == "image" {
                                        Image(systemName: "photo")
                                            .foregroundColor(.blue)
                                    } else if layer.type == "shape" {
                                        Image(systemName: "circle.fill")
                                            .foregroundColor(.red)
                                    } else if layer.type == "background" {
                                        Image(systemName: "rectangle.fill")
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .font(.system(size: 18))
                                
                                Text(layer.type.capitalized)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Spacer()
                                
                                Text("Z: \\(layer.zOrder)")
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(6)
                            }
                        }
                        
                        // Content Editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("Layer content", text: $layer.content)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Position Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Position & Layout")
                            .font(.system(size: 18, weight: .semibold))
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("X Position")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Slider(value: $layer.x, in: 0...400)
                                    Text("\\(Int(layer.x))")
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 30)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Y Position")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Slider(value: $layer.y, in: 0...250)
                                    Text("\\(Int(layer.y))")
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 30)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Type-specific settings
                    if layer.type == "text" {
                        TextLayerSettings(layer: $layer)
                    } else if layer.type == "image" {
                        ImageLayerSettings(layer: $layer)
                    } else if layer.type == "shape" {
                        ShapeLayerSettings(layer: $layer)
                    } else if layer.type == "background" {
                        BackgroundLayerSettings(layer: $layer)
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit Layer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct TextLayerSettings: View {
    @Binding var layer: SimpleLayer
    
    private let fontWeights: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
    private let textColors: [Color] = [.black, .white, .red, .blue, .green, .orange, .purple, .pink, .yellow]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Text Styling")
                .font(.system(size: 18, weight: .semibold))
            
            // Font Size
            VStack(alignment: .leading, spacing: 8) {
                Text("Font Size: \\(Int(layer.fontSize))pt")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Slider(value: $layer.fontSize, in: 8...72)
            }
            
            // Font Weight
            VStack(alignment: .leading, spacing: 8) {
                Text("Font Weight")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(fontWeights, id: \.self) { weight in
                            Button(action: { layer.fontWeight = weight }) {
                                Text(weightName(weight))
                                    .font(.system(size: 12, weight: weight))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(layer.fontWeight == weight ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(layer.fontWeight == weight ? .white : .primary)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Text Color
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Color")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(textColors, id: \.self) { color in
                            Button(action: { layer.textColor = color }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(layer.textColor == color ? Color.blue : Color.gray, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Text Style Options
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Style")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button(action: { layer.isItalic.toggle() }) {
                        Text("Italic")
                            .font(.system(size: 14, weight: .medium))
                            .italic()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(layer.isItalic ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(layer.isItalic ? .white : .primary)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { layer.isUnderlined.toggle() }) {
                        Text("Underline")
                            .font(.system(size: 14, weight: .medium))
                            .underline()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(layer.isUnderlined ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(layer.isUnderlined ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Text Alignment
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Alignment")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    ForEach([TextAlignment.leading, .center, .trailing], id: \.self) { alignment in
                        Button(action: { layer.textAlignment = alignment }) {
                            Image(systemName: alignmentIcon(alignment))
                                .font(.system(size: 18))
                                .padding(12)
                                .background(layer.textAlignment == alignment ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(layer.textAlignment == alignment ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Text Effects
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Effects")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    // Shadow
                    HStack {
                        Button(action: { layer.hasShadow.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: layer.hasShadow ? "checkmark.square.fill" : "square")
                                    .foregroundColor(layer.hasShadow ? .blue : .gray)
                                Text("Drop Shadow")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        if layer.hasShadow {
                            HStack(spacing: 8) {
                                ForEach([Color.gray, .black, .red, .blue], id: \.self) { color in
                                    Button(action: { layer.shadowColor = color }) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Circle()
                                                    .stroke(layer.shadowColor == color ? Color.blue : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Stroke
                    HStack {
                        Button(action: { layer.hasStroke.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: layer.hasStroke ? "checkmark.square.fill" : "square")
                                    .foregroundColor(layer.hasStroke ? .blue : .gray)
                                Text("Text Stroke")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        if layer.hasStroke {
                            HStack(spacing: 8) {
                                                                ForEach([Color.white, .black, .red, .blue], id: \.self) { color in
                                    Button(action: { layer.strokeColor = color }) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Circle()
                                                    .stroke(layer.strokeColor == color ? Color.blue : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func weightName(_ weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight: return "UL"
        case .thin: return "Thin"
        case .light: return "Light"
        case .regular: return "Reg"
        case .medium: return "Med"
        case .semibold: return "Semi"
        case .bold: return "Bold"
        case .heavy: return "Heavy"
        case .black: return "Black"
        default: return "Reg"
        }
    }
    
    private func alignmentIcon(_ alignment: TextAlignment) -> String {
        switch alignment {
        case .leading: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }
}

struct ImageLayerSettings: View {
    @Binding var layer: SimpleLayer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Image Settings")
                .font(.system(size: 18, weight: .semibold))
            
            Text("Image upload and editing features coming soon!")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ShapeLayerSettings: View {
    @Binding var layer: SimpleLayer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shape Settings")
                .font(.system(size: 18, weight: .semibold))
            
            Text("Shape customization features coming soon!")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct BackgroundLayerSettings: View {
    @Binding var layer: SimpleLayer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Background Settings")
                .font(.system(size: 18, weight: .semibold))
            
            Text("Background customization features coming soon!")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
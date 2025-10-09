import SwiftUI

struct LayerPropertiesPanel: View {
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: selectedLayer?.type.icon ?? "slider.horizontal.3")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text(headerText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { layerState.showPropertiesPanel = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Properties Content
            ScrollView {
                VStack(spacing: 16) {
                    if let layer = selectedLayer {
                        // Transform Properties (always shown)
                        TransformPropertiesSection(layer: layer, layerState: layerState)
                        
                        // Type-specific properties
                        switch layer.type {
                        case .postText, .text:
                            TextPropertiesSection(layer: layer, layerState: layerState)
                        case .image:
                            ImagePropertiesSection(layer: layer, layerState: layerState)
                        case .shape:
                            ShapePropertiesSection(layer: layer, layerState: layerState)
                        case .background:
                            BackgroundPropertiesSection(layer: layer, layerState: layerState)
                        case .group:
                            GroupPropertiesSection(layer: layer, layerState: layerState)
                        }
                        
                        // Style Properties (for applicable types)
                        if layer.type == .text || layer.type == .postText || layer.type == .shape {
                            StylePropertiesSection(layer: layer, layerState: layerState)
                        }
                    } else {
                        Text("Select a layer to edit properties")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                    }
                }
                .padding(.vertical, 16)
            }
            .frame(maxHeight: 300)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var selectedLayer: LayerItem? {
        layerState.primarySelectedLayer
    }
    
    private var headerText: String {
        if layerState.selectedLayers.count > 1 {
            return "Multiple Layers (\(layerState.selectedLayers.count))"
        } else {
            return selectedLayer?.name ?? "Properties"
        }
    }
}

// MARK: - Transform Properties
struct TransformPropertiesSection: View {
    let layer: LayerItem
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        PropertySection(title: "Transform") {
            VStack(spacing: 12) {
                // Position
                HStack(spacing: 12) {
                    PropertySlider(
                        title: "X",
                        value: Binding(
                            get: { layer.transform.x },
                            set: { newValue in
                                var newTransform = layer.transform
                                newTransform.x = newValue
                                layerState.updateLayerProperty(layer.id, keyPath: \.transform, value: newTransform)
                            }
                        ),
                        range: -200...200,
                        step: 1
                    )
                    
                    PropertySlider(
                        title: "Y",
                        value: Binding(
                            get: { layer.transform.y },
                            set: { newValue in
                                var newTransform = layer.transform
                                newTransform.y = newValue
                                layerState.updateLayerProperty(layer.id, keyPath: \.transform, value: newTransform)
                            }
                        ),
                        range: -200...200,
                        step: 1
                    )
                }
                
                // Scale
                PropertySlider(
                    title: "Scale",
                    value: Binding(
                        get: { layer.transform.scaleX },
                        set: { newValue in
                            var newTransform = layer.transform
                            newTransform.scaleX = newValue
                            newTransform.scaleY = newValue // Keep aspect ratio
                            layerState.updateLayerProperty(layer.id, keyPath: \.transform, value: newTransform)
                        }
                    ),
                    range: 0.1...3.0,
                    step: 0.1
                )
                
                // Rotation
                PropertySlider(
                    title: "Rotation",
                    value: Binding(
                        get: { layer.transform.rotation },
                        set: { newValue in
                            var newTransform = layer.transform
                            newTransform.rotation = newValue
                            layerState.updateLayerProperty(layer.id, keyPath: \.transform, value: newTransform)
                        }
                    ),
                    range: -180...180,
                    step: 1,
                    unit: "°"
                )
                
                // Opacity
                PropertySlider(
                    title: "Opacity",
                    value: Binding(
                        get: { layer.transform.opacity },
                        set: { newValue in
                            var newTransform = layer.transform
                            newTransform.opacity = newValue
                            layerState.updateLayerProperty(layer.id, keyPath: \.transform, value: newTransform)
                        }
                    ),
                    range: 0...1,
                    step: 0.01,
                    unit: "%",
                    displayMultiplier: 100
                )
            }
        }
    }
}

// MARK: - Text Properties
struct TextPropertiesSection: View {
    let layer: LayerItem
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        PropertySection(title: "Text") {
            VStack(spacing: 12) {
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Content")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if layer.type == .postText {
                        TextEditor(text: Binding(
                            get: { layer.content.text ?? "" },
                            set: { newValue in
                                var newContent = layer.content
                                newContent.text = newValue
                                layerState.updateLayerProperty(layer.id, keyPath: \.content, value: newContent)
                            }
                        ))
                        .frame(height: 60)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    } else {
                        TextField("Enter text", text: Binding(
                            get: { layer.content.text ?? "" },
                            set: { newValue in
                                var newContent = layer.content
                                newContent.text = newValue
                                layerState.updateLayerProperty(layer.id, keyPath: \.content, value: newContent)
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Font Size
                PropertySlider(
                    title: "Font Size",
                    value: Binding(
                        get: { layer.content.fontSize ?? 16 },
                        set: { newValue in
                            var newContent = layer.content
                            newContent.fontSize = newValue
                            layerState.updateLayerProperty(layer.id, keyPath: \.content, value: newContent)
                        }
                    ),
                    range: 8...72,
                    step: 1,
                    unit: "pt"
                )
            }
        }
    }
}

// MARK: - Other Property Sections (simplified for now)
struct ImagePropertiesSection: View {
    let layer: LayerItem
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        PropertySection(title: "Image") {
            VStack(spacing: 12) {
                Button(action: {}) {
                    Text("Choose Image")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct ShapePropertiesSection: View {
    let layer: LayerItem
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        PropertySection(title: "Shape") {
            VStack(spacing: 12) {
                Text("Shape properties coming soon")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BackgroundPropertiesSection: View {
    let layer: LayerItem
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        PropertySection(title: "Background") {
            VStack(spacing: 12) {
                Text("Background properties coming soon")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct GroupPropertiesSection: View {
    let layer: LayerItem
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        PropertySection(title: "Group") {
            VStack(spacing: 12) {
                Text("Group properties coming soon")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StylePropertiesSection: View {
    let layer: LayerItem
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        PropertySection(title: "Style") {
            VStack(spacing: 12) {
                Text("Style properties coming soon")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Utility Components
struct PropertySection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            content
        }
        .padding(.horizontal, 16)
    }
}

struct PropertySlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let displayMultiplier: Double
    
    init(title: String, value: Binding<Double>, range: ClosedRange<Double>, 
         step: Double, unit: String = "", displayMultiplier: Double = 1) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
        self.displayMultiplier = displayMultiplier
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(value * displayMultiplier))\(unit)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(.blue)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        LayerPropertiesPanel(layerState: LayerState())
    }
    .background(Color.gray.opacity(0.1))
}
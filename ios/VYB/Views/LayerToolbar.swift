import SwiftUI

struct LayerToolbar: View {
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        VStack(spacing: 0) {
            // Main toolbar with add buttons and controls
            HStack(spacing: 12) {
                // Add Layer Menu
                Menu {
                    Button(action: { addLayer(.text) }) {
                        Label("Text", systemImage: "textformat")
                    }
                    Button(action: { addLayer(.image) }) {
                        Label("Image", systemImage: "photo")
                    }
                    Button(action: { addLayer(.shape) }) {
                        Label("Shape", systemImage: "circle")
                    }
                    Button(action: { addLayer(.background) }) {
                        Label("Background", systemImage: "rectangle")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Layer")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Layer List Toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        layerState.isLayerListExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 16))
                        Text("\(layerState.layers.count)")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: layerState.isLayerListExpanded ? "chevron.down" : "chevron.up")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Properties Toggle (only show when layer selected)
                if layerState.hasSelection {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            layerState.showPropertiesPanel.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16))
                            Text("Properties")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(layerState.showPropertiesPanel ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
            
            // Selection Info Bar (when layers are selected)
            if layerState.hasSelection {
                SelectionInfoBar(layerState: layerState)
            }
            
            // Expandable Layer List
            if layerState.isLayerListExpanded {
                LayerList(layerState: layerState)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Properties Panel
            if layerState.showPropertiesPanel && layerState.hasSelection {
                LayerPropertiesPanel(layerState: layerState)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
    }
    
    private func addLayer(_ type: LayerItemType) {
        let newLayer = LayerItem(
            id: UUID().uuidString,
            name: "\(type.displayName) \(layerState.layers.count + 1)",
            type: type,
            content: LayerItemContent(
                text: type == .text ? "New Text" : nil,
                color: type == .shape || type == .background ? "#3B82F6" : nil,
                shapeType: type == .shape ? "rectangle" : nil
            ),
            transform: LayerTransform(x: 50, y: 50, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1)
        )
        
        layerState.addLayer(newLayer)
    }
}

struct SelectionInfoBar: View {
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection count and type
            HStack(spacing: 6) {
                Image(systemName: layerState.selectedLayers.first?.type.icon ?? "checkmark.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text(selectionText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Quick Actions
            HStack(spacing: 8) {
                // Visibility toggle
                Button(action: toggleVisibility) {
                    Image(systemName: allSelectedVisible ? "eye" : "eye.slash")
                        .font(.system(size: 14))
                        .foregroundColor(allSelectedVisible ? .primary : .secondary)
                }
                
                // Lock toggle
                Button(action: toggleLock) {
                    Image(systemName: allSelectedLocked ? "lock" : "lock.open")
                        .font(.system(size: 14))
                        .foregroundColor(allSelectedLocked ? .orange : .secondary)
                }
                
                // Delete
                Button(action: deleteSelected) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
                
                // Deselect
                Button(action: { layerState.clearSelection() }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.05))
    }
    
    private var selectionText: String {
        let count = layerState.selectedLayers.count
        if count == 1 {
            return layerState.selectedLayers.first?.name ?? "1 selected"
        } else {
            return "\(count) layers selected"
        }
    }
    
    private var allSelectedVisible: Bool {
        layerState.selectedLayers.allSatisfy { $0.isVisible }
    }
    
    private var allSelectedLocked: Bool {
        layerState.selectedLayers.allSatisfy { $0.isLocked }
    }
    
    private func toggleVisibility() {
        for layer in layerState.selectedLayers {
            layerState.toggleLayerVisibility(layer.id)
        }
    }
    
    private func toggleLock() {
        for layer in layerState.selectedLayers {
            layerState.updateLayerProperty(layer.id, keyPath: \.isLocked, value: !layer.isLocked)
        }
    }
    
    private func deleteSelected() {
        for layer in layerState.selectedLayers {
            // Don't delete the default post text layer
            if layer.type != .postText {
                layerState.removeLayer(layer.id)
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        LayerToolbar(layerState: LayerState())
    }
    .background(Color.gray.opacity(0.1))
}
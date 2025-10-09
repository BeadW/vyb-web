import SwiftUI

struct LayerList: View {
    @ObservedObject var layerState: LayerState
    @State private var draggedLayer: LayerItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Layers")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(layerState.layers.count) total")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Layer Items
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(layerState.layers.reversed()) { layer in
                        LayerListItem(
                            layer: layer,
                            isSelected: layerState.selectedLayerIds.contains(layer.id),
                            layerState: layerState
                        )
                        .id(layer.id)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 200)
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct LayerListItem: View {
    let layer: LayerItem
    let isSelected: Bool
    @ObservedObject var layerState: LayerState
    @State private var isRenaming: Bool = false
    @State private var editingName: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Layer Type Icon
            ZStack {
                Circle()
                    .fill(layerTypeColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: layer.type.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(layerTypeColor)
            }
            
            // Layer Info
            VStack(alignment: .leading, spacing: 2) {
                if isRenaming {
                    TextField("Layer Name", text: $editingName, onCommit: commitRename)
                        .font(.system(size: 14, weight: .medium))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(layer.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .onTapGesture(count: 2) {
                            startRenaming()
                        }
                }
                
                HStack(spacing: 8) {
                    Text(layer.type.displayName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    if !layer.isVisible {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    if layer.isLocked {
                        Image(systemName: "lock")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Layer Controls
            HStack(spacing: 8) {
                // Visibility Toggle
                Button(action: { layerState.toggleLayerVisibility(layer.id) }) {
                    Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                        .font(.system(size: 14))
                        .foregroundColor(layer.isVisible ? .primary : .secondary)
                        .frame(width: 20, height: 20)
                }
                
                // Lock Toggle
                Button(action: { 
                    layerState.updateLayerProperty(layer.id, keyPath: \.isLocked, value: !layer.isLocked)
                }) {
                    Image(systemName: layer.isLocked ? "lock" : "lock.open")
                        .font(.system(size: 14))
                        .foregroundColor(layer.isLocked ? .orange : .secondary)
                        .frame(width: 20, height: 20)
                }
                
                // More Options
                Menu {
                    Button("Rename", action: startRenaming)
                    Button("Duplicate") {
                        duplicateLayer()
                    }
                    Divider()
                    if layer.type != .postText {
                        Button("Delete", role: .destructive) {
                            layerState.removeLayer(layer.id)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            selectLayer()
        }
        .contextMenu {
            Button("Select Only") { layerState.selectLayer(layer.id) }
            Button("Add to Selection") { layerState.selectLayer(layer.id, addToSelection: true) }
            Divider()
            Button("Rename", action: startRenaming)
            Button("Duplicate", action: duplicateLayer)
            if layer.type != .postText {
                Button("Delete", role: .destructive) {
                    layerState.removeLayer(layer.id)
                }
            }
        }
    }
    
    private var layerTypeColor: Color {
        switch layer.type {
        case .postText: return .purple
        case .text: return .blue
        case .image: return .green
        case .shape: return .orange
        case .background: return .red
        case .group: return .gray
        }
    }
    
    private func selectLayer() {
        layerState.selectLayer(layer.id)
    }
    
    private func startRenaming() {
        editingName = layer.name
        isRenaming = true
    }
    
    private func commitRename() {
        layerState.updateLayerProperty(layer.id, keyPath: \.name, value: editingName)
        isRenaming = false
    }
    
    private func duplicateLayer() {
        let newLayer = LayerItem(
            id: UUID().uuidString,
            name: "\(layer.name) Copy",
            type: layer.type,
            content: layer.content,
            transform: LayerTransform(
                x: layer.transform.x + 20,
                y: layer.transform.y + 20,
                scaleX: layer.transform.scaleX,
                scaleY: layer.transform.scaleY,
                rotation: layer.transform.rotation,
                opacity: layer.transform.opacity
            ),
            style: layer.style,
            zIndex: layer.zIndex
        )
        layerState.addLayer(newLayer)
    }
}

#Preview {
    VStack {
        Spacer()
        LayerList(layerState: LayerState())
    }
    .background(Color.gray.opacity(0.1))
}
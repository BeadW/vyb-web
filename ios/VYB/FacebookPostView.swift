import SwiftUI
import UIKit

struct FacebookPostView: View {
    @State private var isEditing = false
    @State private var editingText = "What's on your mind?"
    @StateObject private var layerState = LayerState()
    
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
            VStack(alignment: .leading, spacing: 12) {
                if isEditing {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $editingText)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(minHeight: 60)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                isEditing = false
                                editingText = getPostText()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            
                            Button("Save") {
                                updatePostText(editingText)
                                isEditing = false
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            
                            Spacer()
                        }
                    }
                } else {
                    Button(action: {
                        editingText = getPostText()
                        isEditing = true
                    }) {
                        HStack {
                            Text(getPostText())
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
            
            // Canvas Section with Layer Visualization
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .aspectRatio(16/10, contentMode: .fit)
                    .cornerRadius(8)
                    .border(Color.gray.opacity(0.3), width: 1)
                
                // Simple layer visualization
                ForEach(layerState.layers.filter { $0.isVisible }) { layer in
                    SimpleLayerView(layer: layer, isSelected: layerState.selectedLayerIds.contains(layer.id))
                        .onTapGesture {
                            layerState.selectLayer(layer.id)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Facebook Actions
            HStack(spacing: 0) {
                FacebookActionButton(icon: "hand.thumbsup", text: "Like", color: .secondary)
                FacebookActionButton(icon: "message", text: "Comment", color: .secondary)
                FacebookActionButton(icon: "square.and.arrow.up", text: "Share", color: .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Spacer()
            
            // Layer Management Interface
            LayerToolbar(layerState: layerState)
        }
        .background(Color.white)
        .onAppear {
            initializeDefaultCanvas()
        }
    }
    
    private func getPostText() -> String {
        // For now, return a simple default until we implement proper layer management
        return editingText.isEmpty ? "What's on your mind?" : editingText
    }
    
    private func updatePostText(_ newText: String) {
        // Update the post text - this will be enhanced when we integrate with the layer system
        editingText = newText
    }
    
    private func initializeDefaultCanvas() {
        // Initialize with a basic canvas setup
        // This can be enhanced later to include default post text layers
    }
}

struct FacebookActionButton: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(text)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Simple Layer Visualization
struct SimpleLayerView: View {
    let layer: LayerItem
    let isSelected: Bool
    
    var body: some View {
        Group {
            switch layer.type {
            case .text, .postText:
                Text(layer.content.text ?? "Text Layer")
                    .font(.system(size: CGFloat(layer.content.fontSize ?? 16)))
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(4)
            case .image:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 80, height: 60)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Image")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    )
            case .shape:
                Circle()
                    .fill(Color.green.opacity(0.6))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("Shape")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
            case .background:
                Rectangle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 100, height: 40)
                    .overlay(
                        Text("Background")
                            .font(.caption)
                            .foregroundColor(.purple)
                    )
            case .group:
                // Group layers are containers - just show a placeholder
                Text("Group")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .scaleEffect(CGFloat(layer.transform.scaleX))
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

#Preview {
    FacebookPostView()
}
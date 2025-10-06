import SwiftUI

// Simple layer management view that integrates with our LayerState architecture
struct LayerManagementView: View {
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        VStack(spacing: 0) {
            // Layer Toolbar with add buttons and controls
            LayerToolbar(layerState: layerState)
            
            // Layer List
            LayerList(layerState: layerState)
                .frame(maxHeight: 200)
            
            // Properties Panel
            if layerState.showPropertiesPanel {
                LayerPropertiesPanel(layerState: layerState)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#if DEBUG
struct LayerManagementView_Previews: PreviewProvider {
    static var previews: some View {
        LayerManagementView(layerState: LayerState())
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color(.systemGroupedBackground))
    }
}
#endif
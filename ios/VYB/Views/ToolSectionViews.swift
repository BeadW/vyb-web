import SwiftUI

// MARK: - Simple stub implementations for ToolSectionViews
// These provide minimal functionality as the main layer management 
// is handled by LayerToolbar, LayerList, and LayerPropertiesPanel

struct TextToolsCompactView: View {
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        HStack {
            Text("Text Tools")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct ImageToolsCompactView: View {
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        HStack {
            Text("Image Tools")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct ShapeToolsCompactView: View {
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        HStack {
            Text("Shape Tools")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct StylingToolsCompactView: View {
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        HStack {
            Text("Styling Tools")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct GeneralToolsCompactView: View {
    @ObservedObject var layerState: LayerState
    
    var body: some View {
        HStack {
            Text("General Tools")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview
#if DEBUG
struct ToolSectionViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TextToolsCompactView(layerState: LayerState())
            ImageToolsCompactView(layerState: LayerState())
            ShapeToolsCompactView(layerState: LayerState())
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif
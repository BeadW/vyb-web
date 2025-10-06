import SwiftUI

// Test view to debug the LayerEditorModalView issue
struct LayerEditorTest: View {
    @State private var testLayer = SimpleLayer(
        id: UUID(),
        type: "text",
        content: "Test Layer",
        x: 100,
        y: 100,
        zOrder: 1,
        fontSize: 18,
        fontWeight: .medium,
        textColor: .black,
        isItalic: false,
        isUnderlined: false,
        textAlignment: .center,
        hasShadow: false,
        shadowColor: .gray,
        isSelected: false
    )
    
    @State private var showModal = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Layer Editor Modal Test")
                .font(.title)
                .padding()
            
            Button("Show Layer Editor Modal") {
                showModal = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Text("Layer Info:")
            Text("Type: \(testLayer.type)")
            Text("Content: \(testLayer.content)")
            Text("Position: (\(Int(testLayer.x)), \(Int(testLayer.y)))")
            Text("Font Size: \(Int(testLayer.fontSize))")
        }
        .sheet(isPresented: $showModal) {
            LayerEditorModalView(layer: $testLayer)
        }
    }
}

// Simple test version of LayerEditorModalView to debug
struct TestLayerEditorModalView: View {
    @Binding var layer: SimpleLayer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("DEBUG: Modal is working")
                    .font(.title)
                    .foregroundColor(.red)
                
                Text("Layer Type: \(layer.type)")
                    .font(.headline)
                
                Text("Layer Content: \(layer.content)")
                    .font(.body)
                
                TextField("Edit Content", text: $layer.content)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                VStack {
                    Text("Font Size: \(Int(layer.fontSize))")
                    Slider(value: $layer.fontSize, in: 12...48)
                        .padding()
                }
                
                VStack {
                    Text("X Position: \(Int(layer.x))")
                    Slider(value: $layer.x, in: 0...300)
                        .padding()
                }
                
                VStack {
                    Text("Y Position: \(Int(layer.y))")
                    Slider(value: $layer.y, in: 0...300)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Test Editor")
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
                }
            }
        }
    }
}

#Preview {
    LayerEditorTest()
}
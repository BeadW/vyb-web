import SwiftUI

// MARK: - ALTERNATE CANVAS IMPLEMENTATION (NOT CURRENTLY USED)
// This is an alternate canvas view implementation that is not actively used
// in the main app. The primary canvas implementation is in ContentView.swift

struct CanvasView: View {
    let canvas: DesignCanvas?
    let deviceType: DeviceType?
    
    init(canvas: DesignCanvas? = nil, deviceType: DeviceType? = nil) {
        self.canvas = canvas
        self.deviceType = deviceType
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Alternative Canvas View")
                .font(.title)
                .foregroundColor(.gray)
            
            Text("This is an alternate canvas implementation")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("The main canvas is in ContentView.swift")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
}
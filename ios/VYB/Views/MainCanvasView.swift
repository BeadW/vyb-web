import SwiftUI
import CoreData

/// Main Canvas View - Integrates CanvasView and Device Simulation for iOS app
/// Implementation of T045c: iOS App Integration with canvas views and device simulation
struct MainCanvasView: View {
    // MARK: - State Management
    @StateObject private var canvasManager = CanvasManager()
    @State private var selectedDevice: DeviceType = .iPhone15Pro
    @State private var isShowingDeviceSelector = false
    @State private var currentCanvas: DesignCanvas?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with device selection
                headerView
                
                // Main canvas area with device simulation
                canvasArea
                
                // Bottom toolbar
                bottomToolbar
            }
            .navigationTitle("VYB Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupInitialCanvas()
            }
        }
        .sheet(isPresented: $isShowingDeviceSelector) {
            DeviceSelectorView(selectedDevice: $selectedDevice) {
                updateCanvasForDevice()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Device type display
            Button(action: {
                isShowingDeviceSelector = true
            }) {
                HStack {
                    Image(systemName: deviceIcon)
                    Text(selectedDevice.rawValue)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .accessibilityIdentifier("Device Selector")
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(canvasManager.isProcessing ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                Text(canvasManager.isProcessing ? "Processing" : "Ready")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Canvas Area
    private var canvasArea: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemBackground)
                
                // Device simulation container
                DeviceSimulationContainer(
                    deviceType: selectedDevice,
                    geometry: geometry
                ) {
                    // Canvas view inside device simulation
                    Group {
                        if let canvas = currentCanvas {
                            CanvasView(canvas: canvas, deviceType: selectedDevice)
                                .accessibilityIdentifier("Canvas View")
                        } else {
                            // Loading or empty state
                            VStack(spacing: 16) {
                                ProgressView()
                                Text("Initializing Canvas...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            // Layer management
            Button(action: {
                // Add text layer action
                addTextLayer()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "textformat")
                    Text("Text")
                        .font(.system(size: 10))
                }
            }
            .accessibilityIdentifier("Add Text Layer")
            
            Button(action: {
                // Add shape layer action
                addShapeLayer()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "rectangle")
                    Text("Shape")
                        .font(.system(size: 10))
                }
            }
            
            Button(action: {
                // Add image layer action
                addImageLayer()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                    Text("Image")
                        .font(.system(size: 10))
                }
            }
            
            Spacer()
            
            // Canvas actions
            Button(action: {
                canvasManager.undo()
            }) {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!canvasManager.canUndo)
            
            Button(action: {
                canvasManager.redo()
            }) {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!canvasManager.canRedo)
            
            Button(action: {
                clearCanvas()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .accessibilityIdentifier("Clear All")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Device Icon
    private var deviceIcon: String {
        switch selectedDevice {
        case .iPhone15Pro, .iPhone15Plus:
            return "iphone"
        case .iPadPro11, .iPadPro129:
            return "ipad"
        case .macBookPro14:
            return "laptopcomputer"
        case .desktop1920x1080:
            return "desktopcomputer"
        default:
            return "rectangle.on.rectangle"
        }
    }
    
    // MARK: - Setup Methods
    private func setupInitialCanvas() {
        // Create initial canvas for selected device
        let canvas = canvasManager.createCanvas(deviceType: selectedDevice)
        currentCanvas = canvas
    }
    
    private func updateCanvasForDevice() {
        // Update canvas when device type changes
        if let canvas = currentCanvas {
            canvasManager.updateCanvasDevice(canvas, deviceType: selectedDevice)
        }
    }
    
    // MARK: - Layer Actions
    private func addTextLayer() {
        guard let canvas = currentCanvas else { return }
        canvasManager.addTextLayer(to: canvas, text: "New Text")
    }
    
    private func addShapeLayer() {
        guard let canvas = currentCanvas else { return }
        canvasManager.addShapeLayer(to: canvas, type: .rectangle)
    }
    
    private func addImageLayer() {
        guard let canvas = currentCanvas else { return }
        // TODO: Implement image picker
        print("Image layer add not yet implemented")
    }
    
    private func clearCanvas() {
        guard let canvas = currentCanvas else { return }
        canvasManager.clearCanvas(canvas)
    }
}

// MARK: - Device Simulation Container
struct DeviceSimulationContainer<Content: View>: View {
    let deviceType: DeviceType
    let geometry: GeometryProxy
    let content: () -> Content
    
    var body: some View {
        VStack {
            // Device chrome/frame simulation
            ZStack {
                // Device frame
                RoundedRectangle(cornerRadius: deviceCornerRadius)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: deviceWidth, height: deviceHeight)
                
                // Device screen area
                RoundedRectangle(cornerRadius: deviceCornerRadius - 2)
                    .fill(Color.black)
                    .frame(width: deviceWidth - 4, height: deviceHeight - 4)
                
                // Content area
                RoundedRectangle(cornerRadius: deviceCornerRadius - 4)
                    .fill(Color.white)
                    .frame(width: screenWidth, height: screenHeight)
                    .overlay(
                        content()
                            .clipShape(RoundedRectangle(cornerRadius: deviceCornerRadius - 4))
                    )
            }
            
            // Device info
            Text("\(deviceType.rawValue) Simulation")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
    
    // Device-specific dimensions
    private var deviceWidth: CGFloat {
        switch deviceType {
        case .iPhone15Pro: return 200
        case .iPhone15Plus: return 220
        case .iPadPro11: return 300
        case .iPadPro129: return 350
        default: return 200
        }
    }
    
    private var deviceHeight: CGFloat {
        switch deviceType {
        case .iPhone15Pro: return 400
        case .iPhone15Plus: return 440
        case .iPadPro11: return 420
        case .iPadPro129: return 480
        default: return 400
        }
    }
    
    private var screenWidth: CGFloat { deviceWidth - 20 }
    private var screenHeight: CGFloat { deviceHeight - 40 }
    
    private var deviceCornerRadius: CGFloat {
        switch deviceType {
        case .iPhone15Pro, .iPhone15Plus: return 25
        case .iPadPro11, .iPadPro129: return 15
        default: return 10
        }
    }
}

// MARK: - Device Selector View
struct DeviceSelectorView: View {
    @Binding var selectedDevice: DeviceType
    let onDeviceSelected: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(DeviceType.allCases, id: \.self) { device in
                    Button(action: {
                        selectedDevice = device
                        onDeviceSelected()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(device.rawValue)
                            Spacer()
                            if device == selectedDevice {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .accessibilityIdentifier(device.rawValue)
                }
            }
            .navigationTitle("Select Device")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Canvas Manager
class CanvasManager: ObservableObject {
    @Published var isProcessing = false
    @Published var canUndo = false
    @Published var canRedo = false
    
    func createCanvas(deviceType: DeviceType) -> DesignCanvas {
        // Create a new canvas for the specified device type
        // This would typically use Core Data context
        let canvas = DesignCanvas(context: PersistenceController.shared.container.viewContext)
        canvas.id = UUID().uuidString
        canvas.deviceType = deviceType
        canvas.state = .editing
        
        // Set device-specific dimensions
        let dimensions = dimensionsForDevice(deviceType)
        canvas.dimensions = dimensions
        
        return canvas
    }
    
    func updateCanvasDevice(_ canvas: DesignCanvas, deviceType: DeviceType) {
        canvas.deviceType = deviceType
        canvas.dimensions = dimensionsForDevice(deviceType)
    }
    
    func addTextLayer(to canvas: DesignCanvas, text: String) {
        // Add text layer logic
        print("Adding text layer: \(text)")
    }
    
    func addShapeLayer(to canvas: DesignCanvas, type: ShapeType) {
        // Add shape layer logic
        print("Adding shape layer: \(type)")
    }
    
    func clearCanvas(_ canvas: DesignCanvas) {
        // Clear canvas logic
        print("Clearing canvas")
    }
    
    func undo() {
        // Undo logic
        print("Undo")
    }
    
    func redo() {
        // Redo logic
        print("Redo")
    }
    
    private func dimensionsForDevice(_ deviceType: DeviceType) -> LocalCanvasDimensions {
        switch deviceType {
        case .iPhone15Pro:
            return LocalCanvasDimensions(width: 393, height: 852, pixelDensity: 3.0)
        case .iPhone15Plus:
            return LocalCanvasDimensions(width: 430, height: 932, pixelDensity: 3.0)
        case .iPadPro11:
            return LocalCanvasDimensions(width: 834, height: 1194, pixelDensity: 2.0)
        case .iPadPro129:
            return LocalCanvasDimensions(width: 1024, height: 1366, pixelDensity: 2.0)
        default:
            return LocalCanvasDimensions(width: 393, height: 852, pixelDensity: 3.0)
        }
    }
}


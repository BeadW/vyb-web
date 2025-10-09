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
    @State private var selectedLayerForEditing: String?
    
    // AI Integration State - History Graph System
    @State private var isAnalyzingWithAI = false
    @State private var historyStates: [HistoryState] = []
    @State private var currentHistoryIndex = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var showingAPIKeyAlert = false
    @State private var apiKeyInput = ""
    @State private var geminiAPIKey = "AIzaSyABpqGNJGVbTVVp1p2ZdrgBSaMCovakEog"
    private let aiService = AIService()
    
    // History Navigation Configuration
    private let scrollThreshold: CGFloat = 50
    private let aiTriggerThreshold: CGFloat = 100
    
    // Computed property to get current selected layer as single source of truth
    private var currentSelectedLayer: SimpleLayer? {
        guard let selectedId = selectedLayerForEditing else { return nil }
        return currentLayers.first(where: { $0.id == selectedId })
    }
    
    // Convert SimpleLayerData to SimpleLayer
    private func convertToSimpleLayer(_ layerData: SimpleLayerData) -> SimpleLayer {
        return SimpleLayer(
            id: layerData.id,
            type: layerData.type,
            content: layerData.content,
            x: layerData.x,
            y: layerData.y
        )
    }
    
    // Get current layers from history state
    private var currentLayers: [SimpleLayer] {
        if historyStates.isEmpty {
            return layers
        }
        guard currentHistoryIndex >= 0 && currentHistoryIndex < historyStates.count else {
            return layers
        }
        return historyStates[currentHistoryIndex].layers
    }
    
    // Check if we're at the current editable state (latest in history)
    private var isAtCurrentState: Bool {
        return currentHistoryIndex == historyStates.count - 1
    }
    
    var body: some View {
        mainContent
            .gesture(combinedGesture)
            .overlay(swipeIndicatorOverlay)
    }
    
    private var mainContent: some View {
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
                        ForEach(currentLayers.sorted(by: { $0.zOrder < $1.zOrder }), id: \.id) { layer in
                            HistoryLayerView(
                                layer: layer,
                                canvasWidth: canvasWidth,
                                canvasHeight: canvasHeight,
                                selectedLayerForEditing: selectedLayerForEditing,
                                isEditable: true,
                                onEditLayer: { layer in
                                    selectedLayerForEditing = layer.id
                                    showLayerEditorModal = true
                                },
                                onToggleSelection: {
                                    if selectedLayerForEditing == layer.id {
                                        selectedLayerForEditing = nil
                                    } else {
                                        selectedLayerForEditing = layer.id
                                    }
                                },
                                onLayerModified: { modifiedLayer in
                                    updateLayerInHistory(modifiedLayer)
                                }
                            )
                        }
                    }
                    .frame(width: canvasWidth, height: canvasHeight)
                    .onAppear {
                        NSLog("🎨 ContentView appeared - Initializing history system")
                        canvasSize = CGSize(width: canvasWidth, height: canvasHeight)
                        initializeHistory()
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
                FacebookActionButton(icon: "hand.thumbsup", text: "Like", color: .secondary)
                Spacer()
                FacebookActionButton(icon: "bubble.left", text: "Comment", color: .secondary)
                Spacer()
                FacebookActionButton(icon: "arrowshape.turn.up.right", text: "Share", color: .secondary)
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
                    
                    if selectedLayerForEditing != nil {
                        Button(action: {
                            showLayerEditorModal = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Edit")
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
                                        // Toggle selection using single source of truth
                                        if selectedLayerForEditing == layer.id {
                                            selectedLayerForEditing = nil
                                        } else {
                                            selectedLayerForEditing = layer.id
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: layer.type == "text" ? "textformat" : layer.type == "image" ? "photo" : layer.type == "shape" ? "circle.fill" : "rectangle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(selectedLayerForEditing == layer.id ? .white : .primary)
                                            
                                            Text(layer.content.isEmpty ? "Layer" : String(layer.content.prefix(6)))
                                                .font(.caption2)
                                                .lineLimit(1)
                                                .foregroundColor(selectedLayerForEditing == layer.id ? .white : .primary)
                                            
                                            Text("Z:\(layer.zOrder)")
                                                .font(.caption2)
                                                .foregroundColor(selectedLayerForEditing == layer.id ? .white : .secondary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(selectedLayerForEditing == layer.id ? Color.blue : Color.gray.opacity(0.15))
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

        .sheet(isPresented: $showLayerManagerModal) {
            LayerManagerModalView(
                layers: $layers,
                selectedLayerForEditing: $selectedLayerForEditing,
                onEditLayer: { layer in
                    DispatchQueue.main.async {
                        // Re-fetch the latest layer data to ensure it exists
                        if let currentLayer = layers.first(where: { $0.id == layer.id }) {
                            selectedLayerForEditing = currentLayer.id
                            showLayerEditorModal = true
                        } else {
                            NSLog("Layer not found in manager: \(layer.id)")
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showLayerEditorModal) {
            if let layer = currentSelectedLayer {
                LayerEditorModalView(layer: Binding<SimpleLayer>(
                    get: {
                        // Always get the latest layer data from the array by ID
                        return layers.first(where: { $0.id == layer.id }) ?? layer
                    },
                    set: { newValue in
                        if let currentIndex = layers.firstIndex(where: { $0.id == newValue.id }) {
                            layers[currentIndex] = newValue
                        }
                    }
                ))
                .onDisappear {
                    selectedLayerForEditing = nil
                    showLayerEditorModal = false
                }
            } else {
                // Fallback error view - this should never happen with proper state management
                NavigationView {
                    VStack {
                        Text("No layer selected for editing")
                            .foregroundColor(.red)
                            .font(.headline)
                        
                        Text("Available layers: \(layers.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .navigationTitle("Error")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                selectedLayerForEditing = nil
                                showLayerEditorModal = false
                            }
                        }
                    }
                }
            }
        }
        .alert("Gemini API Key Required", isPresented: $showingAPIKeyAlert) {
            TextField("Enter your Gemini API key", text: $apiKeyInput)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                geminiAPIKey = apiKeyInput
                apiKeyInput = ""
            }
        } message: {
            Text("To use AI-powered design variations, please enter your Google Gemini API key. You can get one from the Google AI Studio.")
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
            zOrder: currentLayers.count
        )
        
        // Update current layers and save to history
        var updatedLayers = currentLayers
        updatedLayers.append(newLayer)
        layers = updatedLayers
        
        saveCurrentStateToHistory(source: .userEdit, title: "Added \(type.capitalized) Layer")
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
    
    private func alignmentIcon(_ alignment: CustomTextAlignment) -> String {
        switch alignment {
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        case .justify: return "text.justify"
        }
    }
    
    private var combinedGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                NSLog("� Scroll gesture: height=\(value.translation.height)")
                scrollOffset = value.translation.height
            }
            .onEnded { value in
                let scrollDistance = abs(value.translation.height)
                
                if scrollDistance > scrollThreshold {
                    if value.translation.height > 0 {
                        // Scroll down - go to previous history state
                        navigateToPreviousState()
                    } else {
                        // Scroll up - go to next history state or trigger AI
                        navigateToNextState()
                    }
                }
                scrollOffset = 0
            }
    }
    
    private var swipeIndicatorOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if isAnalyzingWithAI {
                    HistoryIndicator(
                        currentIndex: currentHistoryIndex,
                        totalStates: historyStates.count,
                        isAnalyzing: true,
                        isAtCurrentState: isAtCurrentState
                    )
                } else if !historyStates.isEmpty {
                    HistoryIndicator(
                        currentIndex: currentHistoryIndex,
                        totalStates: historyStates.count,
                        isAnalyzing: false,
                        isAtCurrentState: isAtCurrentState
                    )
                }
                Spacer()
            }
            .padding(.bottom, 50)
        }
    }
    

    
    // MARK: - AI Integration Functions
    
    private func triggerAIAnalysis() {
        NSLog("🚀 triggerAIAnalysis() called")
        
        guard !isAnalyzingWithAI else { 
            NSLog("❌ Already analyzing, returning")
            return 
        }
        
        // Check if API key is configured
        guard !geminiAPIKey.isEmpty else {
            NSLog("❌ API key is empty, showing alert")
            showingAPIKeyAlert = true
            return
        }
        
        NSLog("✅ Starting AI analysis with current layers...")
        isAnalyzingWithAI = true
        
        Task {
            do {
                // Configure AI service with user's API key
                await aiService.configure(apiKey: geminiAPIKey)
                
                // Get current layers from history state
                let baseLayers = currentLayers.isEmpty ? createSampleLayers() : currentLayers
                let variations = try await aiService.generateDesignVariations(for: baseLayers)
                
                await MainActor.run {
                    // Add each AI variation as a new history state
                    for variation in variations {
                        let modifiedLayers = self.applyVariationToLayers(variation, originalLayers: baseLayers)
                        let historyState = HistoryState(
                            layers: modifiedLayers,
                            source: .aiGenerated,
                            title: variation.title
                        )
                        self.historyStates.append(historyState)
                    }
                    
                    // Move to first new AI suggestion
                    if !variations.isEmpty {
                        self.currentHistoryIndex = self.historyStates.count - variations.count
                    }
                    
                    self.isAnalyzingWithAI = false
                    NSLog("✅ AI Analysis completed - added \(variations.count) states to history")
                }
                
            } catch {
                await MainActor.run {
                    self.isAnalyzingWithAI = false
                    NSLog("❌ AI Analysis error: \(error)")
                }
            }
        }
    }
    
    // MARK: - AI Design Variations

    
    /// Creates sample layers for demo purposes when canvas is empty
    private func createSampleLayers() -> [SimpleLayer] {
        return [
            SimpleLayer(
                id: UUID().uuidString,
                type: "background",
                content: "Background",
                x: 150,
                y: 100,
                zOrder: 0
            ),
            SimpleLayer(
                id: UUID().uuidString,
                type: "text",
                content: "Hello World",
                x: 100,
                y: 80,
                zOrder: 1
            ),
            SimpleLayer(
                id: UUID().uuidString,
                type: "image",
                content: "Photo",
                x: 200,
                y: 120,
                zOrder: 2
            ),
            SimpleLayer(
                id: UUID().uuidString,
                type: "shape",
                content: "Circle",
                x: 120,
                y: 160,
                zOrder: 3
            ),
            SimpleLayer(
                id: UUID().uuidString,
                type: "text",
                content: "Sample Text",
                x: 140,
                y: 200,
                zOrder: 4
            )
        ]
    }
    
    // MARK: - Variation Navigation Functions
    
    /// Apply a design variation to the original layers
    private func applyVariationToLayers(_ variation: DesignVariation, originalLayers: [SimpleLayer]) -> [SimpleLayer] {
        return originalLayers.map { layer in
            // Find matching layer in variation
            if let variationLayer = variation.layers.first(where: { $0.id == layer.id }) {
                // Create modified layer with variation data
                var modifiedLayer = layer
                
                // Apply changes from variation layer
                modifiedLayer.content = variationLayer.content
                modifiedLayer.x = variationLayer.x
                modifiedLayer.y = variationLayer.y
                
                return modifiedLayer
            }
            return layer
        }
    }
    
    /// Navigate to previous state in history
    private func navigateToPreviousState() {
        if currentHistoryIndex > 0 {
            currentHistoryIndex -= 1
            NSLog("📜 Navigated to history index: \(currentHistoryIndex)")
        } else {
            NSLog("� Already at first history state")
        }
    }
    
    /// Navigate to next state in history or trigger AI if at the end
    private func navigateToNextState() {
        if currentHistoryIndex < historyStates.count - 1 {
            currentHistoryIndex += 1
            NSLog("📜 Navigated to history index: \(currentHistoryIndex)")
        } else {
            // At the end of history - trigger AI for more suggestions
            NSLog("� At end of history - triggering AI for more suggestions")
            triggerAIAnalysis()
        }
    }
    
    /// Add current state to history
    private func saveCurrentStateToHistory(source: HistorySource, title: String? = nil) {
        let newState = HistoryState(layers: layers, source: source, title: title)
        
        // Remove any states after current index if user made changes
        if currentHistoryIndex < historyStates.count - 1 {
            historyStates.removeLast(historyStates.count - currentHistoryIndex - 1)
        }
        
        historyStates.append(newState)
        currentHistoryIndex = historyStates.count - 1
        
        NSLog("💾 Saved state to history: '\(newState.title)' at index \(currentHistoryIndex)")
    }
    
    /// Initialize history with current state
    private func initializeHistory() {
        if historyStates.isEmpty {
            let initialState = HistoryState(
                layers: layers.isEmpty ? createSampleLayers() : layers,
                source: .initial,
                title: "Initial Canvas"
            )
            historyStates = [initialState]
            currentHistoryIndex = 0
            layers = historyStates[0].layers
            NSLog("🎯 Initialized history with initial state")
        }
    }
    
    /// Update a specific layer and save to history
    private func updateLayerInHistory(_ modifiedLayer: SimpleLayer) {
        var updatedLayers = currentLayers
        if let index = updatedLayers.firstIndex(where: { $0.id == modifiedLayer.id }) {
            updatedLayers[index] = modifiedLayer
            layers = updatedLayers
            saveCurrentStateToHistory(source: .userEdit, title: "Modified \(modifiedLayer.type.capitalized) Layer")
        }
    }

}

// MARK: - AI UI Components

struct AISwipeIndicator: View {
    let progress: CGFloat
    let isAnalyzing: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            if isAnalyzing {
                VStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.blue)
                    Text("AI is generating variations...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    Text("This may take a few seconds")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .opacity(progress > 0.5 ? 1.0 : 0.6)
                    
                    Text("Swipe for AI suggestions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .opacity(progress > 0.3 ? 1.0 : 0.7)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .scaleEffect(0.8 + (progress * 0.2))
        .opacity(0.8 + (progress * 0.2))
    }
}

struct HistoryIndicator: View {
    let currentIndex: Int
    let totalStates: Int
    let isAnalyzing: Bool
    let isAtCurrentState: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            if isAnalyzing {
                VStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.blue)
                    Text("AI is generating suggestions...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            } else {
                VStack(spacing: 6) {
                    // History position indicator
                    HStack(spacing: 4) {
                        ForEach(0..<min(totalStates, 7), id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                        if totalStates > 7 {
                            Text("...")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Current state info
                    VStack(spacing: 2) {
                        if currentIndex < totalStates {
                            let currentState = totalStates > currentIndex ? "State \(currentIndex + 1) of \(totalStates)" : "End of History"
                            Text(currentState)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        // Current state indicator
                        if isAtCurrentState {
                            Text("📍 Current")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.blue)
                        } else {
                            Text("� History")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Navigation hints
                    HStack(spacing: 16) {
                        if currentIndex > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 10))
                                Text("Previous")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.gray)
                        }
                        
                        if currentIndex < totalStates - 1 {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 10))
                                Text("Next")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.gray)
                        } else {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 10))
                                Text("AI More")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - History-aware Layer View
struct HistoryLayerView: View {
    let layer: SimpleLayer
    let canvasWidth: Double
    let canvasHeight: Double
    let selectedLayerForEditing: String?
    let isEditable: Bool
    let onEditLayer: (SimpleLayer) -> Void
    let onToggleSelection: () -> Void
    let onLayerModified: (SimpleLayer) -> Void
    
    @State private var editableLayer: SimpleLayer
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    init(layer: SimpleLayer, canvasWidth: Double, canvasHeight: Double, selectedLayerForEditing: String?, isEditable: Bool, onEditLayer: @escaping (SimpleLayer) -> Void, onToggleSelection: @escaping () -> Void, onLayerModified: @escaping (SimpleLayer) -> Void) {
        self.layer = layer
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.selectedLayerForEditing = selectedLayerForEditing
        self.isEditable = isEditable
        self.onEditLayer = onEditLayer
        self.onToggleSelection = onToggleSelection
        self.onLayerModified = onLayerModified
        self._editableLayer = State(initialValue: layer)
    }
    
    private var layerContent: some View {
        Group {
            if layer.type == "text" {
                textLayerView
            } else if layer.type == "image" {
                imageLayerView
            } else if layer.type == "shape" {
                shapeLayerView
            } else if layer.type == "background" {
                backgroundLayerView
            }
        }
    }
    
    private func swiftUITextAlignment(_ alignment: CustomTextAlignment) -> SwiftUI.TextAlignment {
        switch alignment {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        case .justify: return .center
        }
    }
    
    private var textLayerView: some View {
        Text(layer.content)
            .font(.system(size: layer.fontSize, weight: layer.fontWeight))
            .italic(layer.isItalic)
            .underline(layer.isUnderlined)
            .foregroundColor(layer.textColor)
            .multilineTextAlignment(swiftUITextAlignment(layer.textAlignment))
            .shadow(
                color: layer.hasShadow ? layer.shadowColor : Color.clear,
                radius: layer.hasShadow ? 2 : 0,
                x: layer.hasShadow ? 1 : 0,
                y: layer.hasShadow ? 1 : 0
            )
            .padding(8)
            .background(selectedLayerForEditing == layer.id ? Color.blue.opacity(0.2) : Color.clear)
            .border(selectedLayerForEditing == layer.id ? Color.blue : Color.clear, width: 2)
            .cornerRadius(4)
    }
    
    private var imageLayerView: some View {
        Image(systemName: "photo")
            .font(.system(size: 40))
            .foregroundColor(.blue)
            .padding(8)
            .background(selectedLayerForEditing == layer.id ? Color.blue.opacity(0.2) : Color.clear)
            .border(selectedLayerForEditing == layer.id ? Color.blue : Color.clear, width: 2)
            .cornerRadius(4)
    }
    
    private var shapeLayerView: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 50, height: 50)
            .overlay(
                Circle()
                    .stroke(selectedLayerForEditing == layer.id ? Color.blue : Color.clear, lineWidth: 2)
            )
    }
    
    private var backgroundLayerView: some View {
        Rectangle()
            .fill(Color.yellow.opacity(0.3))
            .frame(width: 100, height: 60)
            .cornerRadius(4)
            .overlay(
                Rectangle()
                    .stroke(selectedLayerForEditing == layer.id ? Color.blue : Color.clear, lineWidth: 2)
                    .cornerRadius(4)
            )
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
            }
            .onEnded { value in
                isDragging = false
                
                let newX = max(25, min(canvasWidth - 25, editableLayer.x + value.translation.width))
                let newY = max(25, min(canvasHeight - 25, editableLayer.y + value.translation.height))
                
                editableLayer.x = newX
                editableLayer.y = newY
                dragOffset = .zero
                
                onLayerModified(editableLayer)
            }
    }
    
    var body: some View {
        layerContent
            .position(x: editableLayer.x + dragOffset.width, y: editableLayer.y + dragOffset.height)
            .scaleEffect(isDragging && isEditable ? 1.1 : 1.0)
            .opacity(isDragging ? 0.8 : 1.0)
            .gesture(dragGesture)
            .onTapGesture {
                onToggleSelection()
            }
            .onTapGesture(count: 2) {
                onEditLayer(layer)
            }
            .onChange(of: layer) { oldValue, newValue in
                editableLayer = newValue
            }
    }
}

// FacebookActionButton is already defined in FacebookPostView.swift

public struct SimpleLayer: Identifiable, Codable, Equatable {
    public let id: String
    let type: String
    var content: String
    var x: Double
    var y: Double
    var zOrder: Int = 0
    
    // Text styling properties
    var fontSize: CGFloat = 18
    var fontWeight: Font.Weight = .medium
    var textColor: Color = .black
    var isItalic: Bool = false
    var isUnderlined: Bool = false
    var textAlignment: CustomTextAlignment = .center
    var hasShadow: Bool = false
    var shadowColor: Color = .gray
    var hasStroke: Bool = false
    var strokeColor: Color = .white
    var strokeWidth: CGFloat = 1.0
    
    // Regular memberwise initializer for normal usage
    init(id: String, type: String, content: String, x: Double, y: Double, zOrder: Int = 0) {
        self.id = id
        self.type = type
        self.content = content
        self.x = x
        self.y = y
        self.zOrder = zOrder
        // Text styling properties use default values from declaration
    }
    
    // Custom coding keys and methods for JSON serialization
    enum CodingKeys: String, CodingKey {
        case id, type, content, x, y, zOrder
        case fontSize, fontWeight, textColor, isItalic, isUnderlined, textAlignment
        case hasShadow, shadowColor, hasStroke, strokeColor, strokeWidth
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(content, forKey: .content)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(zOrder, forKey: .zOrder)
        try container.encode(fontSize, forKey: .fontSize)
        
        // Encode font weight as string
        let fontWeightString: String
        switch fontWeight {
        case .light: fontWeightString = "light"
        case .medium: fontWeightString = "medium"
        case .bold: fontWeightString = "bold"
        case .heavy: fontWeightString = "heavy"
        default: fontWeightString = "medium"
        }
        try container.encode(fontWeightString, forKey: .fontWeight)
        
        try container.encode(textColor.description, forKey: .textColor)
        try container.encode(isItalic, forKey: .isItalic)
        try container.encode(isUnderlined, forKey: .isUnderlined)
        
        // Encode text alignment as string
        let alignmentString: String
        switch textAlignment {
        case .left: alignmentString = "left"
        case .center: alignmentString = "center"
        case .right: alignmentString = "right"
        case .justify: alignmentString = "justify"
        }
        try container.encode(alignmentString, forKey: .textAlignment)
        
        try container.encode(hasShadow, forKey: .hasShadow)
        try container.encode(shadowColor.description, forKey: .shadowColor)
        try container.encode(hasStroke, forKey: .hasStroke)
        try container.encode(strokeColor.description, forKey: .strokeColor)
        try container.encode(strokeWidth, forKey: .strokeWidth)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        content = try container.decode(String.self, forKey: .content)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        zOrder = try container.decodeIfPresent(Int.self, forKey: .zOrder) ?? 0
        fontSize = try container.decodeIfPresent(CGFloat.self, forKey: .fontSize) ?? 18
        
        // Decode font weight from string
        if let fontWeightString = try container.decodeIfPresent(String.self, forKey: .fontWeight) {
            switch fontWeightString {
            case "light": fontWeight = .light
            case "medium": fontWeight = .medium
            case "bold": fontWeight = .bold
            case "heavy": fontWeight = .heavy
            default: fontWeight = .medium
            }
        } else {
            fontWeight = .medium
        }
        
        // Decode colors - simplified for now, will enhance later
        if let colorString = try container.decodeIfPresent(String.self, forKey: .textColor) {
            // For now, map basic color names - will improve color parsing later
            textColor = colorString.contains("black") ? .black : .primary
        } else {
            textColor = .black
        }
        
        isItalic = try container.decodeIfPresent(Bool.self, forKey: .isItalic) ?? false
        isUnderlined = try container.decodeIfPresent(Bool.self, forKey: .isUnderlined) ?? false
        
        // Decode text alignment from string
        if let alignmentString = try container.decodeIfPresent(String.self, forKey: .textAlignment) {
            switch alignmentString {
            case "left", "leading": textAlignment = .left
            case "center": textAlignment = .center
            case "right", "trailing": textAlignment = .right
            case "justify": textAlignment = .justify
            default: textAlignment = .left
            }
        } else {
            textAlignment = .left
        }
        
        hasShadow = try container.decodeIfPresent(Bool.self, forKey: .hasShadow) ?? false
        
        // Decode shadow color
        if let colorString = try container.decodeIfPresent(String.self, forKey: .shadowColor) {
            shadowColor = colorString.contains("gray") ? .gray : .gray
        } else {
            shadowColor = .gray
        }
        
        hasStroke = try container.decodeIfPresent(Bool.self, forKey: .hasStroke) ?? false
        
        // Decode stroke color
        if let colorString = try container.decodeIfPresent(String.self, forKey: .strokeColor) {
            strokeColor = colorString.contains("white") ? .white : .white
        } else {
            strokeColor = .white
        }
        
        strokeWidth = try container.decodeIfPresent(CGFloat.self, forKey: .strokeWidth) ?? 1.0
    }
}

// MARK: - History State Model
struct HistoryState: Identifiable, Codable {
    let id: String
    let layers: [SimpleLayer]
    let timestamp: Date
    let source: HistorySource
    let title: String
    
    init(layers: [SimpleLayer], source: HistorySource, title: String? = nil) {
        self.id = UUID().uuidString
        self.layers = layers
        self.timestamp = Date()
        self.source = source
        self.title = title ?? source.defaultTitle
    }
}

enum HistorySource: String, Codable {
    case userEdit = "user_edit"
    case aiGenerated = "ai_generated"
    case initial = "initial"
    
    var defaultTitle: String {
        switch self {
        case .userEdit: return "User Edit"
        case .aiGenerated: return "AI Suggestion"
        case .initial: return "Initial State"
        }
    }
}

struct LayerManagementRow: View {
    @Binding var layer: SimpleLayer
    let selectedLayerForEditing: String?
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onMoveToFront: () -> Void
    let onMoveToBack: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onToggleSelection: () -> Void
    
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
                if selectedLayerForEditing == layer.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
                
                // Edit button - only show when single layer is selected
                if selectedLayerForEditing == layer.id {
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
            if selectedLayerForEditing == layer.id {
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
        .background(selectedLayerForEditing == layer.id ? Color.blue.opacity(0.1) : Color.white)
        .cornerRadius(6)
        .onTapGesture {
            onToggleSelection()
        }
    }
}

// Helper view to extract sheet content and avoid compiler complexity
struct LayerView: View {
    @Binding var layer: SimpleLayer
    let canvasWidth: Double
    let canvasHeight: Double
    let selectedLayerForEditing: String?
    let onEditLayer: (SimpleLayer) -> Void
    let onToggleSelection: () -> Void
    let onLayerModified: (SimpleLayer) -> Void
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    private var layerContent: some View {
        Group {
            if layer.type == "text" {
                textLayerView
            } else if layer.type == "image" {
                imageLayerView
            } else if layer.type == "shape" {
                shapeLayerView
            } else if layer.type == "background" {
                backgroundLayerView
            }
        }
    }
    
    private func swiftUITextAlignment(_ alignment: CustomTextAlignment) -> SwiftUI.TextAlignment {
        switch alignment {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        case .justify: return .center // SwiftUI doesn't have justify, fallback to center
        }
    }
    
    private var textLayerView: some View {
        Text(layer.content)
            .font(.system(size: layer.fontSize, weight: layer.fontWeight))
            .italic(layer.isItalic)
            .underline(layer.isUnderlined)
            .foregroundColor(layer.textColor)
            .multilineTextAlignment(swiftUITextAlignment(layer.textAlignment))
            .shadow(
                color: layer.hasShadow ? layer.shadowColor : Color.clear,
                radius: layer.hasShadow ? 2 : 0,
                x: layer.hasShadow ? 1 : 0,
                y: layer.hasShadow ? 1 : 0
            )
            .padding(8)
            .background(selectedLayerForEditing == layer.id ? Color.blue.opacity(0.2) : Color.clear)
            .border(selectedLayerForEditing == layer.id ? Color.blue : Color.clear, width: 2)
            .cornerRadius(4)
    }
    
    private var imageLayerView: some View {
        Image(systemName: "photo")
            .font(.system(size: 40))
            .foregroundColor(.blue)
            .padding(8)
            .background(selectedLayerForEditing == layer.id ? Color.blue.opacity(0.2) : Color.clear)
            .border(selectedLayerForEditing == layer.id ? Color.blue : Color.clear, width: 2)
            .cornerRadius(4)
    }
    
    private var shapeLayerView: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 50, height: 50)
            .overlay(
                Circle()
                    .stroke(selectedLayerForEditing == layer.id ? Color.blue : Color.clear, lineWidth: 2)
            )
    }
    
    private var backgroundLayerView: some View {
        Rectangle()
            .fill(Color.yellow.opacity(0.3))
            .frame(width: 100, height: 60)
            .cornerRadius(4)
            .overlay(
                Rectangle()
                    .stroke(selectedLayerForEditing == layer.id ? Color.blue : Color.clear, lineWidth: 2)
                    .cornerRadius(4)
            )
    }
    
    private var dragGesture: some Gesture {
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
                
                // Notify parent of layer modification
                onLayerModified(layer)
            }
    }
    
    var body: some View {
        layerContent
            .position(x: layer.x + dragOffset.width, y: layer.y + dragOffset.height)
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .opacity(isDragging ? 0.8 : 1.0)
            .gesture(dragGesture)
            .onTapGesture {
                onToggleSelection()
            }
            .onTapGesture(count: 2) {
                // Double tap to open layer editor
                onEditLayer(layer)
            }
    }
}



// MARK: - Modal Views

struct TextStyleModalView: View {
    @Binding var layer: SimpleLayer
    @Environment(\.dismiss) private var dismiss
    
    private var fontSizeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Font Size: \(Int(layer.fontSize))")
                .font(.system(size: 16, weight: .medium))
            Slider(value: $layer.fontSize, in: 12...48, step: 1)
                .tint(.blue)
        }
    }
    
    private var fontWeightSection: some View {
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
    }
    
    private var textStyleSection: some View {
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
    }
    
    private var textColorSection: some View {
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
    }
    
    private var textEffectsSection: some View {
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
    }
    
    private var textAlignmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Alignment")
                .font(.system(size: 16, weight: .medium))
            HStack(spacing: 12) {
                ForEach([CustomTextAlignment.left, .center, .right], id: \.self) { alignment in
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
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                fontSizeSection
                fontWeightSection
                textStyleSection
                textColorSection
                textEffectsSection
                textAlignmentSection
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
    
    private func alignmentIcon(_ alignment: CustomTextAlignment) -> String {
        switch alignment {
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        case .justify: return "text.justify"
        }
    }
}

struct LayerManagerModalView: View {
    @Binding var layers: [SimpleLayer]
    @Binding var selectedLayerForEditing: String?
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
                                selectedLayerForEditing = nil
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
                                            selectedLayerForEditing: selectedLayerForEditing,
                                            onDelete: {
                                                layers.remove(at: index)
                                                if selectedLayerForEditing == layer.id {
                                                    selectedLayerForEditing = nil
                                                }
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
                                            },
                                            onToggleSelection: {
                                                if selectedLayerForEditing == layer.id {
                                                    selectedLayerForEditing = nil
                                                } else {
                                                    selectedLayerForEditing = layer.id
                                                }
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Layer Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Layer Information")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("Layer Information")
                            
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
                                
                                Text("Z: \(layer.zOrder)")
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
                Text("Font Size: \(Int(layer.fontSize))pt")
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
                    ForEach([CustomTextAlignment.left, .center, .right], id: \.self) { alignment in
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
    
    private func alignmentIcon(_ alignment: CustomTextAlignment) -> String {
        switch alignment {
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        case .justify: return "text.justify"
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

// MARK: - AI Variation Models
#Preview {
    ContentView()
}
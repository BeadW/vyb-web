import { useState, useCallback } from 'react';
import { CanvasEditor } from './components/CanvasEditor';
import { DeviceSimulation } from './components/DeviceSimulation';
import { HistoryManager } from './services/HistoryManager';
import { GestureNavigation } from './services/GestureNavigation';
import { DeviceType } from './types';
import { DEVICE_SPECIFICATIONS } from './data/device-specs';
import './App.css';

// Initialize services
const historyManager = new HistoryManager();

interface AppState {
  currentDevice: DeviceType;
  isGeneratingAI: boolean;
  aiStatus: string;
  canvasKey: number; // For forcing re-renders
}

function App() {
  const [appState, setAppState] = useState<AppState>({
    currentDevice: DeviceType.IPHONE_15_PRO,
    isGeneratingAI: false,
    aiStatus: 'Ready',
    canvasKey: 0
  });

  // Handle device selection
  const handleDeviceChange = useCallback((device: DeviceType) => {
    setAppState(prev => ({ 
      ...prev, 
      currentDevice: device,
      canvasKey: prev.canvasKey + 1 // Force canvas re-render for new device
    }));
  }, []);

  // Handle AI generation (simplified for demo)
  const handleGenerateAI = useCallback(() => {
    setAppState(prev => ({ 
      ...prev, 
      isGeneratingAI: true, 
      aiStatus: 'Generating AI variation...' 
    }));

    // Simulate AI generation
    setTimeout(() => {
      setAppState(prev => ({ 
        ...prev, 
        isGeneratingAI: false,
        aiStatus: 'AI variation ready (simulated)',
        canvasKey: prev.canvasKey + 1
      }));
    }, 2000);
  }, []);

  // Handle history navigation
  const handleUndo = useCallback(() => {
    const result = historyManager.undo();
    if (result.success) {
      setAppState(prev => ({ 
        ...prev, 
        canvasKey: prev.canvasKey + 1,
        aiStatus: 'Undo successful'
      }));
    } else {
      setAppState(prev => ({ 
        ...prev,
        aiStatus: result.error || 'Undo failed'
      }));
    }
  }, []);

  const handleRedo = useCallback(() => {
    const result = historyManager.redo();
    if (result.success) {
      setAppState(prev => ({ 
        ...prev, 
        canvasKey: prev.canvasKey + 1,
        aiStatus: 'Redo successful'
      }));
    } else {
      setAppState(prev => ({ 
        ...prev,
        aiStatus: result.error || 'Redo failed'
      }));
    }
  }, []);

  // Get current device specs
  const deviceSpec = DEVICE_SPECIFICATIONS[appState.currentDevice];
  const historyState = historyManager.getState();

  return (
    <div className="app">
      {/* Header */}
      <header className="app-header">
        <div className="header-content">
          <h1 className="app-title">
            VYB - Visual AI Collaboration Canvas
          </h1>
          <p className="app-subtitle">
            Design with AI assistance across devices
          </p>
        </div>
      </header>

      {/* Controls Bar */}
      <div className="controls-bar">
        {/* History Controls */}
        <div className="control-group">
          <h3>History</h3>
          <div className="button-group">
            <button 
              onClick={handleUndo}
              disabled={Object.keys(historyState.nodes).length <= 1}
              className="control-button"
              title="Undo last action"
            >
              ↶ Undo
            </button>
            <button 
              onClick={handleRedo}
              disabled={historyState.currentNodeId === null}
              className="control-button"
              title="Redo last undone action"
            >
              ↷ Redo
            </button>
          </div>
        </div>

        {/* AI Controls */}
        <div className="control-group">
          <h3>AI Assistant</h3>
          <div className="button-group">
            <button 
              onClick={handleGenerateAI}
              disabled={appState.isGeneratingAI}
              className="control-button ai-button"
              title="Generate AI variation"
            >
              {appState.isGeneratingAI ? '⏳ Generating...' : '🤖 AI Variation'}
            </button>
          </div>
          <div className="ai-status">
            Status: {appState.aiStatus}
          </div>
        </div>

        {/* History Stats */}
        <div className="control-group">
          <h3>Statistics</h3>
          <div className="stats">
            <span className="stat">
              Nodes: {Object.keys(historyState.nodes).length}
            </span>
            <span className="stat">
              Branches: {Object.keys(historyState.branches).length}
            </span>
            <span className="stat">
              Device: {deviceSpec?.name || appState.currentDevice}
            </span>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="main-content">
        {/* Device Simulation Panel */}
        <div className="device-panel">
          <DeviceSimulation
            deviceType={appState.currentDevice}
            onDeviceChange={handleDeviceChange}
          >
            <CanvasEditor
              key={`canvas-${appState.canvasKey}`}
              deviceType={appState.currentDevice}
            />
          </DeviceSimulation>
        </div>

        {/* Gesture Navigation Panel */}
        <div className="gesture-panel">
          <GestureNavigation 
            historyManager={historyManager}
            className="gesture-container"
          >
            {({ variations, activeVariation, navigationState, gestureHandlers }) => (
              <div 
                className="canvas-container"
                {...gestureHandlers}
              >
                <div className="gesture-content">
                  <h3>Gesture Navigation Demo</h3>
                  <p>Drag or scroll to navigate between design variations</p>
                  
                  {/* Gesture Navigation Status */}
                  <div className="navigation-status">
                    <div className="status-item">
                      State: {navigationState.currentState}
                    </div>
                    <div className="status-item">
                      Variations: {variations.length}
                    </div>
                    {activeVariation && (
                      <div className="status-item">
                        Active: {variations.findIndex(v => v.isActive) + 1}
                      </div>
                    )}
                  </div>

                  {/* Navigation Hints */}
                  <div className="navigation-hints">
                    <div className="hint">
                      📱 <strong>Gesture Navigation:</strong>
                    </div>
                    <div className="hint">
                      Drag to browse variations
                    </div>
                    <div className="hint">
                      Scroll for momentum navigation
                    </div>
                  </div>
                </div>
              </div>
            )}
          </GestureNavigation>
        </div>
      </div>

      {/* Footer */}
      <footer className="app-footer">
        <div className="footer-content">
          <p>
            VYB Canvas - Multi-platform AI collaboration for designers
          </p>
          <div className="platform-indicators">
            <span className="platform active">Web</span>
            <span className="platform">iOS</span>
            <span className="platform">Android</span>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;
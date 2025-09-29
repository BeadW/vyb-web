import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'

// Error boundary component
class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { hasError: boolean; error?: Error }
> {
  constructor(props: { children: React.ReactNode }) {
    super(props)
    this.state = { hasError: false }
  }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('VYB Canvas Error:', error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-boundary">
          <div className="error-content">
            <h1>🎨 Something went wrong with VYB Canvas</h1>
            <p>We're sorry, but the application encountered an error.</p>
            <details className="error-details">
              <summary>Error Details</summary>
              <pre>{this.state.error?.stack}</pre>
            </details>
            <button 
              onClick={() => window.location.reload()}
              className="reload-button"
            >
              🔄 Reload Application
            </button>
          </div>
          <style>{`
            .error-boundary {
              min-height: 100vh;
              display: flex;
              align-items: center;
              justify-content: center;
              background: linear-gradient(135deg, #fee2e2, #fecaca);
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            }
            .error-content {
              max-width: 500px;
              padding: 2rem;
              background: white;
              border-radius: 10px;
              box-shadow: 0 10px 25px rgba(0,0,0,0.1);
              text-align: center;
            }
            .error-content h1 {
              color: #dc2626;
              margin-bottom: 1rem;
            }
            .error-content p {
              color: #666;
              margin-bottom: 1rem;
            }
            .error-details {
              text-align: left;
              margin: 1rem 0;
              background: #f5f5f5;
              padding: 1rem;
              border-radius: 5px;
            }
            .error-details pre {
              font-size: 12px;
              overflow-x: auto;
            }
            .reload-button {
              background: #3b82f6;
              color: white;
              border: none;
              padding: 0.75rem 1.5rem;
              border-radius: 5px;
              font-size: 16px;
              cursor: pointer;
              transition: background 0.2s;
            }
            .reload-button:hover {
              background: #2563eb;
            }
          `}</style>
        </div>
      )
    }

    return this.props.children
  }
}

// Initialize application
const initializeApp = async () => {
  try {
    // Get root element
    const rootElement = document.getElementById('root')
    if (!rootElement) {
      throw new Error('Root element not found')
    }

    // Create React root and render app
    const root = ReactDOM.createRoot(rootElement)
    root.render(
      <React.StrictMode>
        <ErrorBoundary>
          <App />
        </ErrorBoundary>
      </React.StrictMode>,
    )

    console.log('🎨 VYB Canvas initialized successfully')
    
  } catch (error) {
    console.error('Failed to initialize VYB Canvas:', error)
    
    // Show fallback error message
    const rootElement = document.getElementById('root')
    if (rootElement) {
      rootElement.innerHTML = `
        <div style="
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          background: linear-gradient(135deg, #fee2e2, #fecaca);
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        ">
          <div style="
            max-width: 500px;
            padding: 2rem;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            text-align: center;
          ">
            <h1 style="color: #dc2626; margin-bottom: 1rem;">
              🚫 VYB Canvas Initialization Failed
            </h1>
            <p style="color: #666; margin-bottom: 1rem;">
              Your browser may not support all required features for VYB Canvas.
            </p>
            <p style="color: #666; margin-bottom: 1rem; font-family: monospace; font-size: 14px;">
              Error: ${error instanceof Error ? error.message : String(error)}
            </p>
            <button 
              onclick="window.location.reload()"
              style="
                background: #3b82f6;
                color: white;
                border: none;
                padding: 0.75rem 1.5rem;
                border-radius: 5px;
                font-size: 16px;
                cursor: pointer;
              "
            >
              🔄 Try Again
            </button>
          </div>
        </div>
      `
    }
  }
}

// Start the application
initializeApp()
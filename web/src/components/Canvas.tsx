import React, { useEffect, useRef, useState, useCallback } from 'react'
import { fabric } from 'fabric'
import { DeviceType } from '../types'
import { DeviceUtils } from '../data/device-specs'

/**
 * Canvas layer management for organizing design elements
 */
export interface CanvasLayer {
  id: string
  name: string
  visible: boolean
  locked: boolean
  opacity: number
  objects: fabric.Object[]
}

/**
 * Canvas state for history and undo/redo functionality
 */
export interface CanvasState {
  timestamp: number
  json: string
  layers: CanvasLayer[]
}

/**
 * Props for the Canvas component
 */
export interface CanvasProps {
  deviceType: DeviceType
  width?: number
  height?: number
  backgroundColor?: string
  onSelectionChanged?: (objects: fabric.Object[]) => void
  onObjectModified?: (object: fabric.Object) => void
  onCanvasStateChange?: (state: CanvasState) => void
  className?: string
}

/**
 * Canvas component with Fabric.js integration for visual design
 * Provides layer management, object manipulation, and device-aware rendering
 */
export const Canvas = React.forwardRef<any, CanvasProps>(({
  deviceType,
  width,
  height,
  backgroundColor = '#ffffff',
  onSelectionChanged,
  onObjectModified,
  onCanvasStateChange,
  className = ''
}, ref) => {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const fabricCanvasRef = useRef<fabric.Canvas | null>(null)
  const [layers, setLayers] = useState<CanvasLayer[]>([
    {
      id: 'layer-1',
      name: 'Background',
      visible: true,
      locked: false,
      opacity: 1,
      objects: []
    }
  ])
  const [history, setHistory] = useState<CanvasState[]>([])
  const [historyIndex, setHistoryIndex] = useState(-1)

  // Get device specifications for canvas dimensions
  const deviceSpec = DeviceUtils.getDeviceSpec(deviceType)
  const canvasWidth = width || deviceSpec.dimensions.width
  const canvasHeight = height || deviceSpec.dimensions.height

  // Initialize Fabric.js canvas
  useEffect(() => {
    if (!canvasRef.current) return

    const canvas = new fabric.Canvas(canvasRef.current, {
      width: canvasWidth,
      height: canvasHeight,
      backgroundColor,
      selection: true,
      preserveObjectStacking: true,
      controlsAboveOverlay: true,
      allowTouchScrolling: false
    })

    fabricCanvasRef.current = canvas

    // Set up event listeners
    canvas.on('selection:created', handleSelectionChange)
    canvas.on('selection:updated', handleSelectionChange)
    canvas.on('selection:cleared', handleSelectionChange)
    canvas.on('object:modified', handleObjectModified)
    canvas.on('path:created', handleObjectAdded)
    canvas.on('object:added', handleObjectAdded)
    canvas.on('object:removed', handleObjectRemoved)

    // Initial state save
    saveCanvasState()

    return () => {
      canvas.dispose()
      fabricCanvasRef.current = null
    }
  }, [canvasWidth, canvasHeight, backgroundColor])

  // Handle selection changes
  const handleSelectionChange = useCallback((_e: fabric.IEvent) => {
    const canvas = fabricCanvasRef.current
    if (!canvas) return

    const activeObjects = canvas.getActiveObjects()
    onSelectionChanged?.(activeObjects)
  }, [onSelectionChanged])

  // Handle object modifications
  const handleObjectModified = useCallback((e: fabric.IEvent) => {
    const target = e.target
    if (!target) return

    onObjectModified?.(target)
    saveCanvasState()
  }, [onObjectModified])

  // Handle object additions
  const handleObjectAdded = useCallback((_e: fabric.IEvent) => {
    saveCanvasState()
  }, [])

  // Handle object removals
  const handleObjectRemoved = useCallback((_e: fabric.IEvent) => {
    saveCanvasState()
  }, [])

  // Save canvas state for history
  const saveCanvasState = useCallback(() => {
    const canvas = fabricCanvasRef.current
    if (!canvas) return

    const state: CanvasState = {
      timestamp: Date.now(),
      json: JSON.stringify(canvas.toJSON()),
      layers: layers.map(layer => ({
        ...layer,
        objects: canvas.getObjects().filter(obj => (obj as any).layerId === layer.id)
      }))
    }

    setHistory(prev => {
      const newHistory = prev.slice(0, historyIndex + 1)
      newHistory.push(state)
      return newHistory.slice(-50) // Keep last 50 states
    })

    setHistoryIndex(prev => prev + 1)
    onCanvasStateChange?.(state)
  }, [layers, historyIndex, onCanvasStateChange])

  // Undo operation
  const undo = useCallback(() => {
    if (historyIndex <= 0) return

    const canvas = fabricCanvasRef.current
    if (!canvas) return

    const prevState = history[historyIndex - 1]
    canvas.loadFromJSON(prevState.json, () => {
      canvas.renderAll()
      setHistoryIndex(prev => prev - 1)
      setLayers(prevState.layers)
    })
  }, [history, historyIndex])

  // Redo operation
  const redo = useCallback(() => {
    if (historyIndex >= history.length - 1) return

    const canvas = fabricCanvasRef.current
    if (!canvas) return

    const nextState = history[historyIndex + 1]
    canvas.loadFromJSON(nextState.json, () => {
      canvas.renderAll()
      setHistoryIndex(prev => prev + 1)
      setLayers(nextState.layers)
    })
  }, [history, historyIndex])

  // Add rectangle
  const addRectangle = useCallback((options?: Partial<fabric.IRectOptions>) => {
    const canvas = fabricCanvasRef.current
    if (!canvas) return

    const rect = new fabric.Rect({
      left: 50,
      top: 50,
      width: 100,
      height: 100,
      fill: '#ff6b6b',
      stroke: '#333',
      strokeWidth: 2,
      ...options
    })

    canvas.add(rect)
    canvas.setActiveObject(rect)
  }, [])

  // Add circle
  const addCircle = useCallback((options?: Partial<fabric.ICircleOptions>) => {
    const canvas = fabricCanvasRef.current
    if (!canvas) return

    const circle = new fabric.Circle({
      left: 50,
      top: 50,
      radius: 50,
      fill: '#4ecdc4',
      stroke: '#333',
      strokeWidth: 2,
      ...options
    })

    canvas.add(circle)
    canvas.setActiveObject(circle)
  }, [])

  // Add text
  const addText = useCallback((text: string = 'Text', options?: Partial<fabric.ITextOptions>) => {
    const canvas = fabricCanvasRef.current
    if (!canvas) return

    const textObj = new fabric.Text(text, {
      left: 50,
      top: 50,
      fontSize: 24,
      fill: '#333',
      fontFamily: 'Arial',
      ...options
    })

    canvas.add(textObj)
    canvas.setActiveObject(textObj)
  }, [])

  // Delete selected objects
  const deleteSelected = useCallback(() => {
    const canvas = fabricCanvasRef.current
    if (!canvas) return

    const activeObjects = canvas.getActiveObjects()
    if (activeObjects.length) {
      canvas.remove(...activeObjects)
      canvas.discardActiveObject()
    }
  }, [])

  // Clear canvas
  const clearCanvas = useCallback(() => {
    const canvas = fabricCanvasRef.current
    if (!canvas) return

    canvas.clear()
    canvas.backgroundColor = backgroundColor
    saveCanvasState()
  }, [backgroundColor, saveCanvasState])

  // Export canvas as image
  const exportAsImage = useCallback((format: 'png' | 'jpeg' = 'png', quality: number = 1) => {
    const canvas = fabricCanvasRef.current
    if (!canvas) return null

    return canvas.toDataURL({
      format: `image/${format}`,
      quality,
      multiplier: deviceSpec.pixelDensity
    })
  }, [deviceSpec.pixelDensity])

  // Layer management
  const createLayer = useCallback((name: string) => {
    const newLayer: CanvasLayer = {
      id: `layer-${Date.now()}`,
      name,
      visible: true,
      locked: false,
      opacity: 1,
      objects: []
    }

    setLayers(prev => [...prev, newLayer])
    return newLayer
  }, [])

  const toggleLayerVisibility = useCallback((layerId: string) => {
    setLayers(prev => prev.map(layer => 
      layer.id === layerId ? { ...layer, visible: !layer.visible } : layer
    ))

    // Update canvas object visibility
    const canvas = fabricCanvasRef.current
    if (!canvas) return

    canvas.getObjects().forEach(obj => {
      if ((obj as any).layerId === layerId) {
        obj.visible = !obj.visible
      }
    })
    canvas.renderAll()
  }, [])

  const setLayerOpacity = useCallback((layerId: string, opacity: number) => {
    setLayers(prev => prev.map(layer => 
      layer.id === layerId ? { ...layer, opacity } : layer
    ))

    // Update canvas object opacity
    const canvas = fabricCanvasRef.current
    if (!canvas) return

    canvas.getObjects().forEach(obj => {
      if ((obj as any).layerId === layerId) {
        obj.opacity = opacity
      }
    })
    canvas.renderAll()
  }, [])

  // Expose canvas methods via ref
  const canvasMethodsRef = useRef({
    getCanvas: () => fabricCanvasRef.current,
    addRectangle,
    addCircle,
    addText,
    deleteSelected,
    clearCanvas,
    undo,
    redo,
    exportAsImage,
    createLayer,
    toggleLayerVisibility,
    setLayerOpacity,
    saveCanvasState
  })

  // Update methods ref when dependencies change
  useEffect(() => {
    canvasMethodsRef.current = {
      getCanvas: () => fabricCanvasRef.current,
      addRectangle,
      addCircle,
      addText,
      deleteSelected,
      clearCanvas,
      undo,
      redo,
      exportAsImage,
      createLayer,
      toggleLayerVisibility,
      setLayerOpacity,
      saveCanvasState
    }
  }, [
    addRectangle,
    addCircle,
    addText,
    deleteSelected,
    clearCanvas,
    undo,
    redo,
    exportAsImage,
    createLayer,
    toggleLayerVisibility,
    setLayerOpacity,
    saveCanvasState
  ])

  // Expose canvas methods via ref
  React.useImperativeHandle(ref, () => canvasMethodsRef.current, [])

  return (
    <div className={`canvas-container ${className}`} data-testid="canvas-container">
      <canvas
        ref={canvasRef}
        className="fabric-canvas"
        data-testid="fabric-canvas"
      />
    </div>
  )
})

/**
 * Canvas toolbar for common operations
 */
export interface CanvasToolbarProps {
  canvasRef: React.RefObject<any>
  onAddRectangle?: () => void
  onAddCircle?: () => void
  onAddText?: () => void
  onDeleteSelected?: () => void
  onClear?: () => void
  onUndo?: () => void
  onRedo?: () => void
  onExport?: () => void
}

export const CanvasToolbar: React.FC<CanvasToolbarProps> = ({
  canvasRef,
  onAddRectangle,
  onAddCircle,
  onAddText,
  onDeleteSelected,
  onClear,
  onUndo,
  onRedo,
  onExport
}) => {
  const handleAddRectangle = () => {
    canvasRef.current?.addRectangle()
    onAddRectangle?.()
  }

  const handleAddCircle = () => {
    canvasRef.current?.addCircle()
    onAddCircle?.()
  }

  const handleAddText = () => {
    canvasRef.current?.addText()
    onAddText?.()
  }

  const handleDeleteSelected = () => {
    canvasRef.current?.deleteSelected()
    onDeleteSelected?.()
  }

  const handleClear = () => {
    canvasRef.current?.clearCanvas()
    onClear?.()
  }

  const handleUndo = () => {
    canvasRef.current?.undo()
    onUndo?.()
  }

  const handleRedo = () => {
    canvasRef.current?.redo()
    onRedo?.()
  }

  const handleExport = () => {
    const dataUrl = canvasRef.current?.exportAsImage()
    if (dataUrl) {
      // Create download link
      const link = document.createElement('a')
      link.download = 'canvas-export.png'
      link.href = dataUrl
      link.click()
    }
    onExport?.()
  }

  return (
    <div className="canvas-toolbar flex flex-wrap gap-2 p-4 bg-gray-100 border-b">
      {/* Shape tools */}
      <div className="tool-group flex gap-1 border-r pr-2">
        <button
          onClick={handleAddRectangle}
          className="tool-button px-3 py-2 bg-white border rounded hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
          title="Add Rectangle"
        >
          ⬜
        </button>
        <button
          onClick={handleAddCircle}
          className="tool-button px-3 py-2 bg-white border rounded hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
          title="Add Circle"
        >
          ⭕
        </button>
        <button
          onClick={handleAddText}
          className="tool-button px-3 py-2 bg-white border rounded hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
          title="Add Text"
        >
          T
        </button>
      </div>

      {/* Edit tools */}
      <div className="tool-group flex gap-1 border-r pr-2">
        <button
          onClick={handleDeleteSelected}
          className="tool-button px-3 py-2 bg-white border rounded hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
          title="Delete Selected"
        >
          🗑️
        </button>
        <button
          onClick={handleClear}
          className="tool-button px-3 py-2 bg-white border rounded hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
          title="Clear Canvas"
        >
          🧹
        </button>
      </div>

      {/* History tools */}
      <div className="tool-group flex gap-1 border-r pr-2">
        <button
          onClick={handleUndo}
          className="tool-button px-3 py-2 bg-white border rounded hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
          title="Undo"
        >
          ↶
        </button>
        <button
          onClick={handleRedo}
          className="tool-button px-3 py-2 bg-white border rounded hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
          title="Redo"
        >
          ↷
        </button>
      </div>

      {/* Export tools */}
      <div className="tool-group flex gap-1">
        <button
          onClick={handleExport}
          className="tool-button px-3 py-2 bg-white border rounded hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
          title="Export as PNG"
        >
          💾
        </button>
      </div>
    </div>
  )
}

export default Canvas
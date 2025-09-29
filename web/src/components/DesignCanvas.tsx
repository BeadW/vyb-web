import React, { useRef, useState, useCallback, useEffect } from 'react'
import { DeviceSimulation } from './DeviceSimulation'
import { Canvas, CanvasToolbar } from './Canvas'
import CanvasObjectHandler, { ManipulationMode, AlignmentType } from './CanvasObjectHandler'
import { DeviceType } from '../types'
import { DeviceUtils } from '../data/device-specs'
import { fabric } from 'fabric'

/**
 * Props for the DesignCanvas component
 */
export interface DesignCanvasProps {
  initialDeviceType?: DeviceType
  showDeviceFrame?: boolean
  showToolbar?: boolean
  onSelectionChanged?: (objects: fabric.Object[]) => void
  onCanvasStateChange?: (state: any) => void
  className?: string
}

/**
 * Integrated design canvas component combining device simulation with Fabric.js canvas
 * Provides a cohesive interface for visual design with device-aware constraints
 */
export const DesignCanvas: React.FC<DesignCanvasProps> = ({
  initialDeviceType = 'iphone-15-pro' as DeviceType,
  showDeviceFrame = true,
  showToolbar = true,
  onSelectionChanged,
  onCanvasStateChange,
  className = ''
}) => {
  const canvasRef = useRef<any>(null)
  const objectHandlerRef = useRef<CanvasObjectHandler | null>(null)
  
  const [deviceType, setDeviceType] = useState<DeviceType>(initialDeviceType)
  const [selectedObjects, setSelectedObjects] = useState<fabric.Object[]>([])
  const [manipulationMode, setManipulationMode] = useState<ManipulationMode>(ManipulationMode.SELECT)
  const [canvasScale, setCanvasScale] = useState(1)

  // Get device specifications
  const deviceSpec = DeviceUtils.getDeviceSpec(deviceType)

  // Handle device change
  const handleDeviceChange = useCallback((newDeviceType: DeviceType) => {
    setDeviceType(newDeviceType)
    
    // Update canvas dimensions
    const canvas = canvasRef.current?.getCanvas()
    if (canvas) {
      const newSpec = DeviceUtils.getDeviceSpec(newDeviceType)
      canvas.setDimensions({
        width: newSpec.dimensions.width,
        height: newSpec.dimensions.height
      })
      canvas.renderAll()
    }
  }, [])

  // Handle selection changes
  const handleSelectionChanged = useCallback((objects: fabric.Object[]) => {
    setSelectedObjects(objects)
    onSelectionChanged?.(objects)
  }, [onSelectionChanged])

  // Handle canvas state changes
  const handleCanvasStateChange = useCallback((state: any) => {
    onCanvasStateChange?.(state)
  }, [onCanvasStateChange])

  // Initialize object handler when canvas is ready
  useEffect(() => {
    const canvas = canvasRef.current?.getCanvas()
    if (canvas && !objectHandlerRef.current) {
      objectHandlerRef.current = new CanvasObjectHandler(canvas, deviceType)
    }

    return () => {
      if (objectHandlerRef.current) {
        objectHandlerRef.current.destroy()
        objectHandlerRef.current = null
      }
    }
  }, [deviceType])

  // Update manipulation mode
  const handleModeChange = useCallback((mode: ManipulationMode) => {
    setManipulationMode(mode)
    objectHandlerRef.current?.setMode(mode)
  }, [])

  // Alignment functions
  const handleAlign = useCallback((alignment: AlignmentType) => {
    objectHandlerRef.current?.alignObjects(alignment)
  }, [])

  const handleDistribute = useCallback((direction: 'horizontal' | 'vertical') => {
    objectHandlerRef.current?.distributeObjects(direction)
  }, [])

  // Calculate responsive scale
  useEffect(() => {
    const calculateScale = () => {
      const container = document.querySelector('.design-canvas-container')
      if (!container || !showDeviceFrame) {
        setCanvasScale(1)
        return
      }

      const containerWidth = container.clientWidth - 64 // Account for padding
      const containerHeight = container.clientHeight - 120 // Account for toolbar and padding
      
      const scaleX = containerWidth / deviceSpec.dimensions.width
      const scaleY = containerHeight / deviceSpec.dimensions.height
      const optimalScale = Math.min(scaleX, scaleY, 1.2) // Max scale of 1.2x
      
      setCanvasScale(Math.max(optimalScale, 0.3)) // Min scale of 0.3x
    }

    calculateScale()
    window.addEventListener('resize', calculateScale)
    return () => window.removeEventListener('resize', calculateScale)
  }, [deviceType, deviceSpec.dimensions, showDeviceFrame])

  // Toolbar handlers
  const toolbarHandlers = {
    onAddRectangle: () => canvasRef.current?.addRectangle(),
    onAddCircle: () => canvasRef.current?.addCircle(),
    onAddText: () => canvasRef.current?.addText('New Text'),
    onDeleteSelected: () => canvasRef.current?.deleteSelected(),
    onClear: () => canvasRef.current?.clearCanvas(),
    onUndo: () => canvasRef.current?.undo(),
    onRedo: () => canvasRef.current?.redo(),
    onExport: () => {
      const dataUrl = canvasRef.current?.exportAsImage()
      if (dataUrl) {
        // Create and trigger download
        const link = document.createElement('a')
        link.download = `${deviceType}-design.png`
        link.href = dataUrl
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
      }
    }
  }

  return (
    <div className={`design-canvas ${className}`}>
      {/* Device selector */}
      <div className="device-controls mb-4 p-4 bg-white border-b">
        <div className="flex items-center justify-between">
          <div className="device-selector flex items-center space-x-4">
            <label className="text-sm font-medium text-gray-700">Device:</label>
            <select
              value={deviceType}
              onChange={(e) => handleDeviceChange(e.target.value as DeviceType)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <optgroup label="Popular Devices">
                {DeviceUtils.getPopularDevices().map((type) => (
                  <option key={type} value={type}>
                    {DeviceUtils.getDeviceSpec(type).name}
                  </option>
                ))}
              </optgroup>
              <optgroup label="All Devices">
                {DeviceUtils.getAllDeviceTypes().map((type) => (
                  <option key={type} value={type}>
                    {DeviceUtils.getDeviceSpec(type).name}
                  </option>
                ))}
              </optgroup>
            </select>
          </div>

          <div className="device-info text-sm text-gray-600">
            {deviceSpec.dimensions.width}×{deviceSpec.dimensions.height} 
            ({deviceSpec.pixelDensity}x) - {deviceSpec.category}
          </div>
        </div>
      </div>

      {/* Toolbar */}
      {showToolbar && (
        <div className="canvas-toolbar-container">
          <CanvasToolbar 
            canvasRef={canvasRef}
            {...toolbarHandlers}
          />
          
          {/* Advanced tools */}
          <div className="advanced-toolbar flex flex-wrap gap-2 p-4 bg-gray-50 border-b">
            {/* Manipulation modes */}
            <div className="tool-group flex gap-1 border-r pr-4 mr-4">
              <span className="text-sm text-gray-600 self-center mr-2">Mode:</span>
              {[
                { mode: ManipulationMode.SELECT, icon: '↖️', label: 'Select' },
                { mode: ManipulationMode.DRAW_RECTANGLE, icon: '⬜', label: 'Rectangle' },
                { mode: ManipulationMode.DRAW_CIRCLE, icon: '⭕', label: 'Circle' },
                { mode: ManipulationMode.DRAW_LINE, icon: '📏', label: 'Line' },
                { mode: ManipulationMode.FREE_DRAW, icon: '✏️', label: 'Draw' },
                { mode: ManipulationMode.TEXT, icon: 'T', label: 'Text' }
              ].map(({ mode, icon, label }) => (
                <button
                  key={mode}
                  onClick={() => handleModeChange(mode)}
                  className={`px-3 py-2 text-sm rounded border ${
                    manipulationMode === mode
                      ? 'bg-blue-500 text-white border-blue-500'
                      : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                  }`}
                  title={label}
                >
                  {icon}
                </button>
              ))}
            </div>

            {/* Alignment tools */}
            {selectedObjects.length > 1 && (
              <div className="tool-group flex gap-1 border-r pr-4 mr-4">
                <span className="text-sm text-gray-600 self-center mr-2">Align:</span>
                {[
                  { alignment: AlignmentType.LEFT, icon: '⬅️', label: 'Left' },
                  { alignment: AlignmentType.CENTER_HORIZONTAL, icon: '⬌', label: 'Center H' },
                  { alignment: AlignmentType.RIGHT, icon: '➡️', label: 'Right' },
                  { alignment: AlignmentType.TOP, icon: '⬆️', label: 'Top' },
                  { alignment: AlignmentType.CENTER_VERTICAL, icon: '⬍', label: 'Center V' },
                  { alignment: AlignmentType.BOTTOM, icon: '⬇️', label: 'Bottom' }
                ].map(({ alignment, icon, label }) => (
                  <button
                    key={alignment}
                    onClick={() => handleAlign(alignment)}
                    className="px-2 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-50"
                    title={label}
                  >
                    {icon}
                  </button>
                ))}
              </div>
            )}

            {/* Distribution tools */}
            {selectedObjects.length > 2 && (
              <div className="tool-group flex gap-1">
                <span className="text-sm text-gray-600 self-center mr-2">Distribute:</span>
                <button
                  onClick={() => handleDistribute('horizontal')}
                  className="px-2 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-50"
                  title="Distribute Horizontally"
                >
                  ↔️
                </button>
                <button
                  onClick={() => handleDistribute('vertical')}
                  className="px-2 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-50"
                  title="Distribute Vertically"
                >
                  ↕️
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Main canvas area */}
      <div className="design-canvas-container flex-1 p-8 bg-gray-100 overflow-auto">
        {showDeviceFrame ? (
          <DeviceSimulation
            deviceType={deviceType}
            scale={canvasScale}
            showFrame={true}
            className="mx-auto"
          >
            <div className="w-full h-full">
              <Canvas
                ref={canvasRef}
                deviceType={deviceType}
                onSelectionChanged={handleSelectionChanged}
                onCanvasStateChange={handleCanvasStateChange}
                className="w-full h-full"
              />
            </div>
          </DeviceSimulation>
        ) : (
          <div className="canvas-wrapper mx-auto" style={{ maxWidth: 'fit-content' }}>
            <Canvas
              ref={canvasRef}
              deviceType={deviceType}
              onSelectionChanged={handleSelectionChanged}
              onCanvasStateChange={handleCanvasStateChange}
              className="border border-gray-300 shadow-lg"
            />
          </div>
        )}
      </div>

      {/* Status bar */}
      <div className="status-bar px-4 py-2 bg-gray-100 border-t text-sm text-gray-600">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <span>
              {selectedObjects.length > 0 
                ? `${selectedObjects.length} object${selectedObjects.length > 1 ? 's' : ''} selected`
                : 'No selection'
              }
            </span>
            <span>Mode: {manipulationMode}</span>
          </div>
          
          <div className="flex items-center space-x-4">
            <span>Scale: {Math.round(canvasScale * 100)}%</span>
            <span>
              Canvas: {deviceSpec.dimensions.width}×{deviceSpec.dimensions.height}
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}

/**
 * Simplified design canvas for basic use cases
 */
export interface SimpleDesignCanvasProps {
  deviceType?: DeviceType
  width?: number
  height?: number
  onExport?: (dataUrl: string) => void
  children?: React.ReactNode
}

export const SimpleDesignCanvas: React.FC<SimpleDesignCanvasProps> = ({
  deviceType = 'iphone-15-pro' as DeviceType,
  width,
  height,
  onExport,
  children
}) => {
  const canvasRef = useRef<any>(null)

  const handleExport = useCallback(() => {
    const dataUrl = canvasRef.current?.exportAsImage()
    if (dataUrl && onExport) {
      onExport(dataUrl)
    }
  }, [onExport])

  return (
    <div className="simple-design-canvas">
      {children}
      
      <div className="canvas-container p-4">
        <Canvas
          ref={canvasRef}
          deviceType={deviceType}
          width={width}
          height={height}
          className="border border-gray-300 rounded-lg shadow"
        />
      </div>

      {onExport && (
        <div className="export-controls p-4 border-t">
          <button
            onClick={handleExport}
            className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors"
          >
            Export Design
          </button>
        </div>
      )}
    </div>
  )
}

export default DesignCanvas
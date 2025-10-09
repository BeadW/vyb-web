import { fabric } from 'fabric'
import { DeviceType } from '../types'
import { DeviceUtils } from '../data/device-specs'

/**
 * Object manipulation modes for different interaction styles
 */
export enum ManipulationMode {
  SELECT = 'select',
  DRAW_RECTANGLE = 'draw-rectangle',
  DRAW_CIRCLE = 'draw-circle',
  DRAW_LINE = 'draw-line',
  FREE_DRAW = 'free-draw',
  TEXT = 'text',
  PAN = 'pan',
  ZOOM = 'zoom'
}

/**
 * Object alignment options
 */
export enum AlignmentType {
  LEFT = 'left',
  CENTER_HORIZONTAL = 'center-horizontal',
  RIGHT = 'right',
  TOP = 'top',
  CENTER_VERTICAL = 'center-vertical',
  BOTTOM = 'bottom',
  CENTER = 'center'
}

/**
 * Snap settings for object positioning
 */
export interface SnapSettings {
  enabled: boolean
  grid: boolean
  objects: boolean
  threshold: number
}

/**
 * Canvas object manipulation handler class
 * Provides advanced object manipulation, alignment, and interaction features
 */
export class CanvasObjectHandler {
  private canvas: fabric.Canvas
  private mode: ManipulationMode = ManipulationMode.SELECT
  private snapSettings: SnapSettings = {
    enabled: true,
    grid: false,
    objects: true,
    threshold: 10
  }
  private deviceType: DeviceType
  private isDrawing = false
  private drawingObject: fabric.Object | null = null

  constructor(canvas: fabric.Canvas, deviceType: DeviceType) {
    this.canvas = canvas
    this.deviceType = deviceType
    this.setupEventHandlers()
  }

  /**
   * Set up canvas event handlers for object manipulation
   */
  private setupEventHandlers(): void {
    this.canvas.on('mouse:down', this.handleMouseDown.bind(this))
    this.canvas.on('mouse:move', this.handleMouseMove.bind(this))
    this.canvas.on('mouse:up', this.handleMouseUp.bind(this))
    this.canvas.on('object:moving', this.handleObjectMoving.bind(this))
    this.canvas.on('object:scaling', this.handleObjectScaling.bind(this))
    this.canvas.on('object:rotating', this.handleObjectRotating.bind(this))
    this.canvas.on('selection:created', this.handleSelectionCreated.bind(this))
    this.canvas.on('selection:updated', this.handleSelectionUpdated.bind(this))
  }

  /**
   * Set the current manipulation mode
   */
  setMode(mode: ManipulationMode): void {
    this.mode = mode
    this.updateCanvasInteraction()
  }

  /**
   * Get the current manipulation mode
   */
  getMode(): ManipulationMode {
    return this.mode
  }

  /**
   * Update canvas interaction settings based on current mode
   */
  private updateCanvasInteraction(): void {
    switch (this.mode) {
      case ManipulationMode.SELECT:
        this.canvas.isDrawingMode = false
        this.canvas.selection = true
        this.canvas.defaultCursor = 'default'
        break

      case ManipulationMode.FREE_DRAW:
        this.canvas.isDrawingMode = true
        this.canvas.selection = false
        this.canvas.freeDrawingBrush.width = 5
        this.canvas.freeDrawingBrush.color = '#000000'
        break

      case ManipulationMode.PAN:
        this.canvas.isDrawingMode = false
        this.canvas.selection = false
        this.canvas.defaultCursor = 'grab'
        break

      default:
        this.canvas.isDrawingMode = false
        this.canvas.selection = false
        this.canvas.defaultCursor = 'crosshair'
    }
  }

  /**
   * Handle mouse down events for drawing operations
   */
  private handleMouseDown(options: fabric.IEvent<MouseEvent>): void {
    const pointer = this.canvas.getPointer(options.e)

    switch (this.mode) {
      case ManipulationMode.DRAW_RECTANGLE:
        this.startDrawingRectangle(pointer)
        break

      case ManipulationMode.DRAW_CIRCLE:
        this.startDrawingCircle(pointer)
        break

      case ManipulationMode.DRAW_LINE:
        this.startDrawingLine(pointer)
        break

      case ManipulationMode.TEXT:
        this.addTextAtPosition(pointer)
        break
    }
  }

  /**
   * Handle mouse move events for drawing operations
   */
  private handleMouseMove(options: fabric.IEvent<MouseEvent>): void {
    if (!this.isDrawing || !this.drawingObject) return

    const pointer = this.canvas.getPointer(options.e)

    switch (this.mode) {
      case ManipulationMode.DRAW_RECTANGLE:
        this.updateDrawingRectangle(pointer)
        break

      case ManipulationMode.DRAW_CIRCLE:
        this.updateDrawingCircle(pointer)
        break

      case ManipulationMode.DRAW_LINE:
        this.updateDrawingLine(pointer)
        break
    }
  }

  /**
   * Handle mouse up events to finish drawing operations
   */
  private handleMouseUp(_options: fabric.IEvent<MouseEvent>): void {
    if (this.isDrawing && this.drawingObject) {
      this.finishDrawing()
    }
  }

  /**
   * Start drawing a rectangle
   */
  private startDrawingRectangle(pointer: { x: number; y: number }): void {
    const rect = new fabric.Rect({
      left: pointer.x,
      top: pointer.y,
      width: 0,
      height: 0,
      fill: 'rgba(255, 0, 0, 0.3)',
      stroke: '#ff0000',
      strokeWidth: 2
    })

    this.canvas.add(rect)
    this.drawingObject = rect
    this.isDrawing = true
  }

  /**
   * Update rectangle dimensions while drawing
   */
  private updateDrawingRectangle(pointer: { x: number; y: number }): void {
    const rect = this.drawingObject as fabric.Rect
    const startX = rect.left!
    const startY = rect.top!

    rect.set({
      width: Math.abs(pointer.x - startX),
      height: Math.abs(pointer.y - startY),
      left: Math.min(startX, pointer.x),
      top: Math.min(startY, pointer.y)
    })

    this.canvas.renderAll()
  }

  /**
   * Start drawing a circle
   */
  private startDrawingCircle(pointer: { x: number; y: number }): void {
    const circle = new fabric.Circle({
      left: pointer.x,
      top: pointer.y,
      radius: 0,
      fill: 'rgba(0, 255, 0, 0.3)',
      stroke: '#00ff00',
      strokeWidth: 2,
      originX: 'center',
      originY: 'center'
    })

    this.canvas.add(circle)
    this.drawingObject = circle
    this.isDrawing = true
  }

  /**
   * Update circle radius while drawing
   */
  private updateDrawingCircle(pointer: { x: number; y: number }): void {
    const circle = this.drawingObject as fabric.Circle
    const centerX = circle.left!
    const centerY = circle.top!

    const radius = Math.sqrt(
      Math.pow(pointer.x - centerX, 2) + Math.pow(pointer.y - centerY, 2)
    )

    circle.set({ radius })
    this.canvas.renderAll()
  }

  /**
   * Start drawing a line
   */
  private startDrawingLine(pointer: { x: number; y: number }): void {
    const line = new fabric.Line([pointer.x, pointer.y, pointer.x, pointer.y], {
      stroke: '#0000ff',
      strokeWidth: 3,
      selectable: true
    })

    this.canvas.add(line)
    this.drawingObject = line
    this.isDrawing = true
  }

  /**
   * Update line endpoint while drawing
   */
  private updateDrawingLine(pointer: { x: number; y: number }): void {
    const line = this.drawingObject as fabric.Line
    line.set({
      x2: pointer.x,
      y2: pointer.y
    })
    this.canvas.renderAll()
  }

  /**
   * Add text at the clicked position
   */
  private addTextAtPosition(pointer: { x: number; y: number }): void {
    const text = new fabric.IText('Click to edit', {
      left: pointer.x,
      top: pointer.y,
      fontSize: 24,
      fill: '#333333',
      fontFamily: 'Arial'
    })

    this.canvas.add(text)
    this.canvas.setActiveObject(text)
    text.enterEditing()
  }

  /**
   * Finish the current drawing operation
   */
  private finishDrawing(): void {
    this.isDrawing = false
    
    if (this.drawingObject) {
      this.canvas.setActiveObject(this.drawingObject)
      this.drawingObject = null
    }

    // Return to select mode after drawing
    this.setMode(ManipulationMode.SELECT)
  }

  /**
   * Handle object moving with snapping
   */
  private handleObjectMoving(options: fabric.IEvent): void {
    if (!this.snapSettings.enabled || !options.target) return

    const object = options.target
    const deviceSpec = DeviceUtils.getDeviceSpec(this.deviceType)
    
    this.snapToObjects(object)
    this.constrainToCanvas(object, deviceSpec)
  }

  /**
   * Handle object scaling with constraints
   */
  private handleObjectScaling(options: fabric.IEvent): void {
    if (!options.target) return

    const object = options.target
    const deviceSpec = DeviceUtils.getDeviceSpec(this.deviceType)
    
    // Maintain aspect ratio for certain objects if needed
    if (object.type === 'circle') {
      object.set({
        scaleX: object.scaleY,
        scaleY: object.scaleY
      })
    }

    this.constrainToCanvas(object, deviceSpec)
  }

  /**
   * Handle object rotation
   */
  private handleObjectRotating(options: fabric.IEvent): void {
    if (!options.target) return

    const object = options.target
    
    // Snap rotation to 15-degree increments when shift is held
    if (options.e && (options.e as KeyboardEvent).shiftKey) {
      const angle = object.angle || 0
      const snappedAngle = Math.round(angle / 15) * 15
      object.set({ angle: snappedAngle })
    }
  }

  /**
   * Handle selection created
   */
  private handleSelectionCreated(options: fabric.IEvent): void {
    const selection = options.selected || []
    this.updateSelectionControls(selection)
  }

  /**
   * Handle selection updated
   */
  private handleSelectionUpdated(options: fabric.IEvent): void {
    const selection = options.selected || []
    this.updateSelectionControls(selection)
  }

  /**
   * Update selection controls based on selected objects
   */
  private updateSelectionControls(selection: fabric.Object[]): void {
    // Customize controls based on object types
    selection.forEach(obj => {
      if (obj.type === 'i-text' || obj.type === 'text') {
        obj.setControlsVisibility({
          mtr: true, // rotation
          mt: false, // middle top
          mb: false, // middle bottom
          ml: false, // middle left
          mr: false  // middle right
        })
      }
    })
  }

  /**
   * Snap object to nearby objects
   */
  private snapToObjects(movingObject: fabric.Object): void {
    if (!this.snapSettings.objects) return

    const objectCenter = movingObject.getCenterPoint()
    const objectBounds = movingObject.getBoundingRect()

    this.canvas.getObjects().forEach(obj => {
      if (obj === movingObject || !obj.visible) return

      const targetCenter = obj.getCenterPoint()
      const targetBounds = obj.getBoundingRect()

      // Horizontal alignment
      if (Math.abs(objectCenter.y - targetCenter.y) < this.snapSettings.threshold) {
        movingObject.set({ top: obj.top })
      }

      // Vertical alignment
      if (Math.abs(objectCenter.x - targetCenter.x) < this.snapSettings.threshold) {
        movingObject.set({ left: obj.left })
      }

      // Edge alignment
      if (Math.abs(objectBounds.left - targetBounds.left) < this.snapSettings.threshold) {
        movingObject.set({ left: obj.left })
      }

      if (Math.abs(objectBounds.left - (targetBounds.left + targetBounds.width)) < this.snapSettings.threshold) {
        movingObject.set({ left: obj.left! + targetBounds.width })
      }
    })
  }

  /**
   * Constrain object to canvas boundaries
   */
  private constrainToCanvas(object: fabric.Object, deviceSpec: any): void {
    const bounds = object.getBoundingRect()
    
    if (bounds.left < 0) {
      object.set({ left: object.left! - bounds.left })
    }
    
    if (bounds.top < 0) {
      object.set({ top: object.top! - bounds.top })
    }
    
    if (bounds.left + bounds.width > deviceSpec.dimensions.width) {
      object.set({ left: deviceSpec.dimensions.width - bounds.width })
    }
    
    if (bounds.top + bounds.height > deviceSpec.dimensions.height) {
      object.set({ top: deviceSpec.dimensions.height - bounds.height })
    }
  }

  /**
   * Align selected objects
   */
  alignObjects(alignment: AlignmentType): void {
    const activeObjects = this.canvas.getActiveObjects()
    if (activeObjects.length < 2) return

    // Get bounds of the active selection
    let bounds: fabric.IRectOptions | null = null
    const selection = this.canvas.getActiveObject()
    
    if (selection && selection.type === 'activeSelection') {
      bounds = selection.getBoundingRect()
    } else if (activeObjects.length > 0) {
      // Calculate bounds manually
      const left = Math.min(...activeObjects.map(obj => obj.getBoundingRect().left))
      const top = Math.min(...activeObjects.map(obj => obj.getBoundingRect().top))
      const right = Math.max(...activeObjects.map(obj => {
        const rect = obj.getBoundingRect()
        return rect.left + rect.width
      }))
      const bottom = Math.max(...activeObjects.map(obj => {
        const rect = obj.getBoundingRect()
        return rect.top + rect.height
      }))
      
      bounds = { left, top, width: right - left, height: bottom - top }
    }
    
    if (!bounds) return

    activeObjects.forEach(obj => {
      const objBounds = obj.getBoundingRect()

      switch (alignment) {
        case AlignmentType.LEFT:
          obj.set({ left: bounds!.left })
          break

        case AlignmentType.CENTER_HORIZONTAL:
          obj.set({ left: bounds!.left! + (bounds!.width! - objBounds.width) / 2 })
          break

        case AlignmentType.RIGHT:
          obj.set({ left: bounds!.left! + bounds!.width! - objBounds.width })
          break

        case AlignmentType.TOP:
          obj.set({ top: bounds!.top })
          break

        case AlignmentType.CENTER_VERTICAL:
          obj.set({ top: bounds!.top! + (bounds!.height! - objBounds.height) / 2 })
          break

        case AlignmentType.BOTTOM:
          obj.set({ top: bounds!.top! + bounds!.height! - objBounds.height })
          break

        case AlignmentType.CENTER:
          obj.set({
            left: bounds!.left! + (bounds!.width! - objBounds.width) / 2,
            top: bounds!.top! + (bounds!.height! - objBounds.height) / 2
          })
          break
      }
    })

    this.canvas.renderAll()
  }

  /**
   * Distribute objects evenly
   */
  distributeObjects(direction: 'horizontal' | 'vertical'): void {
    const activeObjects = this.canvas.getActiveObjects()
    if (activeObjects.length < 3) return

    // Sort objects by position
    const sortedObjects = [...activeObjects].sort((a, b) => {
      if (direction === 'horizontal') {
        return (a.left || 0) - (b.left || 0)
      } else {
        return (a.top || 0) - (b.top || 0)
      }
    })

    const first = sortedObjects[0]
    const last = sortedObjects[sortedObjects.length - 1]
    
    if (direction === 'horizontal') {
      const totalWidth = (last.left || 0) - (first.left || 0)
      const spacing = totalWidth / (sortedObjects.length - 1)
      
      sortedObjects.forEach((obj, index) => {
        if (index > 0 && index < sortedObjects.length - 1) {
          obj.set({ left: (first.left || 0) + spacing * index })
        }
      })
    } else {
      const totalHeight = (last.top || 0) - (first.top || 0)
      const spacing = totalHeight / (sortedObjects.length - 1)
      
      sortedObjects.forEach((obj, index) => {
        if (index > 0 && index < sortedObjects.length - 1) {
          obj.set({ top: (first.top || 0) + spacing * index })
        }
      })
    }

    this.canvas.renderAll()
  }

  /**
   * Update snap settings
   */
  setSnapSettings(settings: Partial<SnapSettings>): void {
    this.snapSettings = { ...this.snapSettings, ...settings }
  }

  /**
   * Get current snap settings
   */
  getSnapSettings(): SnapSettings {
    return { ...this.snapSettings }
  }

  /**
   * Cleanup event handlers
   */
  destroy(): void {
    // Remove event handlers if needed
    this.canvas.off('mouse:down')
    this.canvas.off('mouse:move')
    this.canvas.off('mouse:up')
    this.canvas.off('object:moving')
    this.canvas.off('object:scaling')
    this.canvas.off('object:rotating')
    this.canvas.off('selection:created')
    this.canvas.off('selection:updated')
  }
}

export default CanvasObjectHandler
import { DeviceType, CanvasState, CanvasDimensions, CanvasMetadata, ValidationError, LayerType } from '../types'
import { DEVICE_SPECIFICATIONS } from '../data/device-specs'

export interface DesignCanvasData {
  id: string
  deviceType: DeviceType
  dimensions: CanvasDimensions
  layers: LayerData[]
  metadata: CanvasMetadata
  state: CanvasState
}

export interface LayerData {
  id: string
  type: LayerType
  zIndex: number
  content: any
  transform: {
    x: number
    y: number
    scaleX: number
    scaleY: number
    rotation: number
    opacity: number
  }
  style: any
  constraints: any
  metadata: {
    source: string
    createdAt: Date
  }
}

/**
 * DesignCanvas model with comprehensive validation
 * Ensures device accuracy, layer management, and state consistency
 */
export class DesignCanvas {
  public readonly id: string
  public readonly deviceType: DeviceType
  public readonly dimensions: CanvasDimensions
  public readonly layers: LayerData[]
  public readonly metadata: CanvasMetadata
  public readonly state: CanvasState

  constructor(data: DesignCanvasData) {
    this.validateCanvasData(data)
    this.validateDeviceAspectRatio(data.deviceType, data.dimensions)
    this.validateLayerOrdering(data.layers)
    this.validateLayerRequirement(data.layers)
    
    this.id = data.id
    this.deviceType = data.deviceType
    this.dimensions = data.dimensions
    this.layers = data.layers
    this.metadata = data.metadata
    this.state = data.state
  }

  private validateCanvasData(data: DesignCanvasData): void {
    // Validate Canvas ID
    if (!data.id || typeof data.id !== 'string' || data.id.trim() === '') {
      throw new ValidationError('Canvas ID must be a valid non-empty string', 'id')
    }

    // Validate Device Type matches supported specifications
    if (!Object.values(DeviceType).includes(data.deviceType)) {
      throw new ValidationError('Device type must be a supported device specification', 'deviceType')
    }

    // Validate Dimensions
    if (!data.dimensions || 
        typeof data.dimensions.width !== 'number' || data.dimensions.width <= 0 ||
        typeof data.dimensions.height !== 'number' || data.dimensions.height <= 0 ||
        typeof data.dimensions.pixelDensity !== 'number' || data.dimensions.pixelDensity <= 0) {
      throw new ValidationError('Canvas dimensions must have positive width, height, and pixelDensity', 'dimensions')
    }
  }

  private validateDeviceAspectRatio(deviceType: DeviceType, dimensions: CanvasDimensions): void {
    const deviceSpec = DEVICE_SPECIFICATIONS[deviceType]
    if (!deviceSpec) {
      throw new ValidationError(`Device specification not found for ${deviceType}`, 'deviceType')
    }

    // Calculate aspect ratios with tolerance for floating point precision
    const canvasAspectRatio = dimensions.width / dimensions.height
    const deviceAspectRatio = deviceSpec.dimensions.width / deviceSpec.dimensions.height
    const tolerance = 0.01 // 1% tolerance

    if (Math.abs(canvasAspectRatio - deviceAspectRatio) > tolerance) {
      throw new ValidationError('Dimensions must maintain accurate aspect ratios for target device', 'dimensions')
    }
  }

  private validateLayerOrdering(layers: LayerData[]): void {
    if (layers.length === 0) return

    // Validate z-index ordering - should be sequential and valid
    const zIndices = layers.map(layer => layer.zIndex).sort((a, b) => a - b)
    
    for (let i = 0; i < zIndices.length; i++) {
      if (typeof zIndices[i] !== 'number' || zIndices[i] < 0) {
        throw new ValidationError('Layers must be ordered with valid z-index values', 'layers')
      }
    }
  }

  private validateLayerRequirement(layers: LayerData[]): void {
    if (!layers || layers.length === 0) {
      throw new ValidationError('Canvas must contain at least one layer to be valid', 'layers')
    }
  }

  /**
   * Validates if the canvas is in a valid state for operations
   */
  public isValid(): boolean {
    try {
      this.validateCanvasData({
        id: this.id,
        deviceType: this.deviceType,
        dimensions: this.dimensions,
        layers: this.layers,
        metadata: this.metadata,
        state: this.state
      })
      this.validateDeviceAspectRatio(this.deviceType, this.dimensions)
      this.validateLayerOrdering(this.layers)
      this.validateLayerRequirement(this.layers)
      return true
    } catch {
      return false
    }
  }

  /**
   * Creates a copy of the canvas with updated state
   */
  public withState(newState: CanvasState): DesignCanvas {
    return new DesignCanvas({
      id: this.id,
      deviceType: this.deviceType,
      dimensions: this.dimensions,
      layers: this.layers,
      metadata: {
        ...this.metadata,
        modifiedAt: new Date()
      },
      state: newState
    })
  }

  /**
   * Adds a layer to the canvas with proper z-index
   */
  public addLayer(layerData: Omit<LayerData, 'zIndex'>): DesignCanvas {
    const maxZIndex = Math.max(...this.layers.map(l => l.zIndex), -1)
    const newLayer: LayerData = {
      ...layerData,
      zIndex: maxZIndex + 1
    }

    return new DesignCanvas({
      id: this.id,
      deviceType: this.deviceType,
      dimensions: this.dimensions,
      layers: [...this.layers, newLayer],
      metadata: {
        ...this.metadata,
        modifiedAt: new Date()
      },
      state: this.state
    })
  }

  /**
   * Updates a layer by ID
   */
  public updateLayer(layerId: string, updates: Partial<LayerData>): DesignCanvas {
    const updatedLayers = this.layers.map(layer => 
      layer.id === layerId ? { ...layer, ...updates } : layer
    )

    return new DesignCanvas({
      id: this.id,
      deviceType: this.deviceType,
      dimensions: this.dimensions,
      layers: updatedLayers,
      metadata: {
        ...this.metadata,
        modifiedAt: new Date()
      },
      state: this.state
    })
  }

  /**
   * Removes a layer by ID
   */
  public removeLayer(layerId: string): DesignCanvas {
    const filteredLayers = this.layers.filter(layer => layer.id !== layerId)
    
    if (filteredLayers.length === 0) {
      throw new ValidationError('Canvas must contain at least one layer to be valid', 'layers')
    }

    return new DesignCanvas({
      id: this.id,
      deviceType: this.deviceType,
      dimensions: this.dimensions,
      layers: filteredLayers,
      metadata: {
        ...this.metadata,
        modifiedAt: new Date()
      },
      state: this.state
    })
  }

  /**
   * Exports canvas data for serialization
   */
  public toJSON(): DesignCanvasData {
    return {
      id: this.id,
      deviceType: this.deviceType,
      dimensions: this.dimensions,
      layers: this.layers,
      metadata: this.metadata,
      state: this.state
    }
  }

  /**
   * Creates a DesignCanvas from serialized data
   */
  public static fromJSON(data: DesignCanvasData): DesignCanvas {
    return new DesignCanvas(data)
  }
}
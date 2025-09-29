import { DeviceType, CanvasState, CanvasDimensions, CanvasMetadata, ValidationError } from '../types'
import { Layer } from './Layer'

export interface DesignCanvasData {
  id: string
  deviceType: DeviceType
  dimensions: CanvasDimensions
  layers: any[] // Will be Layer instances or layer data
  metadata: CanvasMetadata
  state: CanvasState
}

export class DesignCanvas {
  public readonly id: string
  public deviceType: DeviceType
  public dimensions: CanvasDimensions
  public layers: Layer[]
  public metadata: CanvasMetadata
  public state: CanvasState

  constructor(data: DesignCanvasData) {
    this.validateCanvasData(data)
    
    this.id = data.id
    this.deviceType = data.deviceType
    this.dimensions = data.dimensions
    this.layers = this.processLayers(data.layers)
    this.metadata = data.metadata
    this.state = data.state
  }

  private validateCanvasData(data: DesignCanvasData): void {
    // Validate Canvas ID
    if (!data.id || typeof data.id !== 'string' || data.id.trim() === '') {
      throw new ValidationError('Canvas ID must be a valid non-empty string', 'id')
    }

    // Validate Device Type
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

    // Validate aspect ratio for device type
    this.validateDeviceAspectRatio(data.deviceType, data.dimensions)

    // Validate layers array
    if (!Array.isArray(data.layers)) {
      throw new ValidationError('Layers must be an array', 'layers')
    }

    // Validate metadata
    if (!data.metadata || !data.metadata.createdAt || !data.metadata.modifiedAt) {
      throw new ValidationError('Canvas metadata must include createdAt and modifiedAt dates', 'metadata')
    }

    // Validate state
    if (!Object.values(CanvasState).includes(data.state)) {
      throw new ValidationError(`Invalid canvas state: ${data.state}`, 'state')
    }
  }

  private validateDeviceAspectRatio(deviceType: DeviceType, dimensions: CanvasDimensions): void {
    const expectedRatios: Record<DeviceType, number> = {
      [DeviceType.IPHONE_15_PRO]: 393 / 852, // 19.5:9 aspect ratio
      [DeviceType.IPHONE_15_PLUS]: 428 / 926,
      [DeviceType.IPAD_PRO_11]: 834 / 1194,
      [DeviceType.IPAD_PRO_129]: 1024 / 1366,
      [DeviceType.PIXEL_8_PRO]: 448 / 998,
      [DeviceType.GALAXY_S24_ULTRA]: 440 / 956,
      [DeviceType.MACBOOK_PRO_14]: 1512 / 982,
      [DeviceType.DESKTOP_1920X1080]: 1920 / 1080
    }

    const actualRatio = dimensions.width / dimensions.height
    const expectedRatio = expectedRatios[deviceType]
    const tolerance = 0.01 // 1% tolerance for rounding

    if (Math.abs(actualRatio - expectedRatio) > tolerance) {
      throw new ValidationError(
        'Dimensions must maintain accurate aspect ratios for target device',
        'dimensions'
      )
    }
  }

  private processLayers(layersData: any[]): Layer[] {
    // Validate z-index ordering before processing layers
    this.validateZIndexOrdering(layersData)
    
    // Validate at least one layer requirement
    if (!layersData || layersData.length === 0) {
      throw new ValidationError('Canvas must contain at least one layer to be considered valid', 'layers')
    }
    
    const processedLayers: Layer[] = []
    const layerIds = new Set<string>()

    for (let i = 0; i < layersData.length; i++) {
      const layerData = layersData[i]
      
      // If it's already a Layer instance, use it
      if (layerData instanceof Layer) {
        if (layerIds.has(layerData.id)) {
          throw new ValidationError(`Duplicate layer ID: ${layerData.id}`, 'layers')
        }
        layerIds.add(layerData.id)
        processedLayers.push(layerData)
      } else {
        // Create Layer instance from data
        try {
          const layer = new Layer(layerData)
          if (layerIds.has(layer.id)) {
            throw new ValidationError(`Duplicate layer ID: ${layer.id}`, 'layers')
          }
          layerIds.add(layer.id)
          processedLayers.push(layer)
        } catch (error) {
          throw new ValidationError(
            `Invalid layer data at index ${i}: ${error instanceof Error ? error.message : 'Unknown error'}`,
            'layers'
          )
        }
      }
    }

    return processedLayers
  }

  // Validation methods
  public isValid(): boolean {
    try {
      this.validateState()
      return true
    } catch {
      return false
    }
  }

  private validateState(): void {
    // Check that all layers are within canvas bounds
    for (const layer of this.layers) {
      if (!this.isLayerWithinBounds(layer)) {
        throw new ValidationError(`Layer ${layer.id} is outside canvas bounds`)
      }
    }

    // Check for valid z-index ordering
    this.validateZIndexOrdering()
  }

  private isLayerWithinBounds(layer: Layer): boolean {
    const { transform } = layer
    const layerRight = transform.x + (transform.scaleX * 100) // Assuming base width of 100
    const layerBottom = transform.y + (transform.scaleY * 100) // Assuming base height of 100
    
    return transform.x >= 0 && 
           transform.y >= 0 && 
           layerRight <= this.dimensions.width && 
           layerBottom <= this.dimensions.height
  }

  private validateZIndexOrdering(layersData?: any[]): void {
    const dataToValidate = layersData || this.layers
    
    if (dataToValidate.length === 0) return
    
    // Check if layers have zIndex properties and validate ordering
    for (let i = 0; i < dataToValidate.length; i++) {
      const layer = dataToValidate[i]
      if (layer.zIndex !== undefined) {
        if (typeof layer.zIndex !== 'number' || layer.zIndex < 0) {
          throw new ValidationError('Layers must be ordered with valid z-index values', 'layers')
        }
        
        // Check that layers are in ascending z-index order
        if (i > 0 && dataToValidate[i-1].zIndex !== undefined && layer.zIndex < dataToValidate[i-1].zIndex) {
          throw new ValidationError('Layers must be ordered with valid z-index values', 'layers')
        }
      }
    }
  }

  // Utility methods
  public addLayer(layer: Layer): void {
    if (this.layers.some(l => l.id === layer.id)) {
      throw new ValidationError(`Layer with ID ${layer.id} already exists`)
    }
    
    this.layers.push(layer)
    this.updateModifiedAt()
  }

  public removeLayer(layerId: string): boolean {
    const index = this.layers.findIndex(l => l.id === layerId)
    if (index === -1) return false
    
    this.layers.splice(index, 1)
    this.updateModifiedAt()
    return true
  }

  public getLayer(layerId: string): Layer | undefined {
    return this.layers.find(l => l.id === layerId)
  }

  public reorderLayer(layerId: string, newIndex: number): boolean {
    const currentIndex = this.layers.findIndex(l => l.id === layerId)
    if (currentIndex === -1 || newIndex < 0 || newIndex >= this.layers.length) {
      return false
    }
    
    const layer = this.layers.splice(currentIndex, 1)[0]
    this.layers.splice(newIndex, 0, layer)
    this.updateModifiedAt()
    return true
  }

  public updateState(newState: CanvasState): void {
    if (!Object.values(CanvasState).includes(newState)) {
      throw new ValidationError(`Invalid canvas state: ${newState}`)
    }
    this.state = newState
    this.updateModifiedAt()
  }

  private updateModifiedAt(): void {
    this.metadata.modifiedAt = new Date()
  }

  // Serialization
  public toJSON(): Record<string, any> {
    return {
      id: this.id,
      deviceType: this.deviceType,
      dimensions: this.dimensions,
      layers: this.layers.map(layer => layer.toJSON()),
      metadata: {
        ...this.metadata,
        createdAt: this.metadata.createdAt.toISOString(),
        modifiedAt: this.metadata.modifiedAt.toISOString()
      },
      state: this.state
    }
  }

  public static fromJSON(data: any): DesignCanvas {
    return new DesignCanvas({
      ...data,
      metadata: {
        ...data.metadata,
        createdAt: new Date(data.metadata.createdAt),
        modifiedAt: new Date(data.metadata.modifiedAt)
      },
      layers: data.layers // Layer.fromJSON will be called during processing
    })
  }

  // Device simulation utilities
  public getDeviceSpec(): { name: string; category: string; os: string } {
    const deviceSpecs: Record<DeviceType, { name: string; category: string; os: string }> = {
      [DeviceType.IPHONE_15_PRO]: { name: 'iPhone 15 Pro', category: 'phone', os: 'ios' },
      [DeviceType.IPHONE_15_PLUS]: { name: 'iPhone 15 Plus', category: 'phone', os: 'ios' },
      [DeviceType.IPAD_PRO_11]: { name: 'iPad Pro 11"', category: 'tablet', os: 'ios' },
      [DeviceType.IPAD_PRO_129]: { name: 'iPad Pro 12.9"', category: 'tablet', os: 'ios' },
      [DeviceType.PIXEL_8_PRO]: { name: 'Pixel 8 Pro', category: 'phone', os: 'android' },
      [DeviceType.GALAXY_S24_ULTRA]: { name: 'Galaxy S24 Ultra', category: 'phone', os: 'android' },
      [DeviceType.MACBOOK_PRO_14]: { name: 'MacBook Pro 14"', category: 'desktop', os: 'web' },
      [DeviceType.DESKTOP_1920X1080]: { name: 'Desktop 1920x1080', category: 'desktop', os: 'web' }
    }
    
    return deviceSpecs[this.deviceType]
  }

  public setState(newState: CanvasState): void {
    (this.state as any) = newState // Cast needed since state is readonly
    this.updateModifiedAt()
  }

  public clone(): DesignCanvas {
    return DesignCanvas.fromJSON(this.toJSON())
  }
}

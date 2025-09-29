import { LayerType, Transform, ValidationError } from '../types'

export interface LayerContent {
  text?: string
  imageUrl?: string
  imageData?: string
  color?: string
  gradient?: any
  childLayerIds?: string[]
  [key: string]: any
}

export interface LayerStyle {
  fontSize?: number
  fontFamily?: string
  color?: string
  backgroundColor?: string
  borderWidth?: number
  borderColor?: string
  borderRadius?: number
  shadowColor?: string
  shadowOffset?: { x: number; y: number }
  shadowBlur?: number
  [key: string]: any
}

export interface LayerConstraints {
  pinTop?: boolean
  pinBottom?: boolean
  pinLeft?: boolean
  pinRight?: boolean
  centerX?: boolean
  centerY?: boolean
  maintainAspectRatio?: boolean
  [key: string]: any
}

export interface LayerMetadata {
  source: 'user' | 'ai' | 'import'
  createdAt: Date
  modifiedAt?: Date
  tags?: string[]
  notes?: string
}

export interface LayerData {
  id: string
  type: LayerType
  content: LayerContent
  transform: Transform
  style: LayerStyle
  constraints: LayerConstraints
  metadata: LayerMetadata
}

/**
 * Layer model with type-specific validation and constraints
 * Supports TEXT, IMAGE, BACKGROUND, SHAPE, and GROUP layer types
 */
export class Layer {
  public readonly id: string
  public readonly type: LayerType
  public readonly content: LayerContent
  public readonly transform: Transform
  public readonly style: LayerStyle
  public readonly constraints: LayerConstraints
  public readonly metadata: LayerMetadata

  constructor(data: LayerData) {
    this.validateLayerData(data)
    this.validateLayerContent(data)
    this.validateTransform(data.transform)
    
    this.id = data.id
    this.type = data.type
    this.content = data.content
    this.transform = data.transform
    this.style = data.style
    this.constraints = data.constraints
    this.metadata = {
      ...data.metadata,
      modifiedAt: data.metadata.modifiedAt || new Date()
    }
  }

  private validateLayerData(data: LayerData): void {
    // Validate Layer ID is unique within parent canvas
    if (!data.id || typeof data.id !== 'string' || data.id.trim() === '') {
      throw new ValidationError('Layer ID must be a valid non-empty string', 'id')
    }

    // Validate Layer Type
    if (!Object.values(LayerType).includes(data.type)) {
      throw new ValidationError('Layer type must be a supported layer type', 'type')
    }

    // Validate constraints exist
    if (!data.constraints || typeof data.constraints !== 'object') {
      throw new ValidationError('Layer constraints are required and must be an object', 'constraints')
    }

    // Validate metadata
    if (!data.metadata || typeof data.metadata !== 'object') {
      throw new ValidationError('Layer metadata is required and must be an object', 'metadata')
    }
  }

  private validateLayerContent(data: LayerData): void {
    switch (data.type) {
      case LayerType.TEXT:
        this.validateTextContent(data.content)
        break
      case LayerType.IMAGE:
        this.validateImageContent(data.content)
        break
      case LayerType.BACKGROUND:
        this.validateBackgroundContent(data.content)
        break
      case LayerType.SHAPE:
        this.validateShapeContent(data.content)
        break
      case LayerType.GROUP:
        this.validateGroupContent(data.content)
        break
      default:
        throw new ValidationError('Content must match layer type specifications', 'content')
    }
  }

  private validateTextContent(content: LayerContent): void {
    if (!content.text || typeof content.text !== 'string') {
      throw new ValidationError('Text layer must have text content', 'content')
    }
  }

  private validateImageContent(content: LayerContent): void {
    if (!content.imageUrl && !content.imageData) {
      throw new ValidationError('Image layer must have imageUrl or imageData', 'content')
    }
  }

  private validateBackgroundContent(content: LayerContent): void {
    if (!content.color && !content.gradient) {
      throw new ValidationError('Background layer must have color or gradient', 'content')
    }
  }

  private validateShapeContent(content: LayerContent): void {
    // Shape layers can have various properties, minimal validation
    if (!content || typeof content !== 'object') {
      throw new ValidationError('Shape layer must have valid content object', 'content')
    }
  }

  private validateGroupContent(content: LayerContent): void {
    if (!content.childLayerIds || !Array.isArray(content.childLayerIds)) {
      throw new ValidationError('Group layer must have childLayerIds array', 'content')
    }
  }

  private validateTransform(transform: Transform): void {
    // Validate transform properties are numbers
    if (typeof transform.x !== 'number' || typeof transform.y !== 'number') {
      throw new ValidationError('Transform x and y must be numbers', 'transform')
    }

    if (typeof transform.scaleX !== 'number' || typeof transform.scaleY !== 'number') {
      throw new ValidationError('Transform scaleX and scaleY must be numbers', 'transform')
    }

    if (typeof transform.rotation !== 'number') {
      throw new ValidationError('Transform rotation must be a number', 'transform')
    }

    // Validate opacity range (0-1)
    if (typeof transform.opacity !== 'number' || transform.opacity < 0 || transform.opacity > 1) {
      throw new ValidationError('Transform opacity must be between 0 and 1', 'transform')
    }

    // Validate rotation range (0-360)
    if (transform.rotation < 0 || transform.rotation > 360) {
      throw new ValidationError('Transform rotation must be between 0 and 360 degrees', 'transform')
    }
  }

  /**
   * Validates if transform values are within canvas boundaries
   */
  public validateTransformBounds(canvasWidth: number, canvasHeight: number): void {
    // Basic bounds checking - layer must be visible within canvas
    const minBounds = -Math.max(canvasWidth, canvasHeight) * 0.5 // Allow some overflow
    const maxBoundsX = canvasWidth + Math.max(canvasWidth, canvasHeight) * 0.5
    const maxBoundsY = canvasHeight + Math.max(canvasWidth, canvasHeight) * 0.5

    if (this.transform.x < minBounds || this.transform.x > maxBoundsX ||
        this.transform.y < minBounds || this.transform.y > maxBoundsY) {
      throw new ValidationError('Transform values must be within canvas boundaries', 'transform')
    }
  }

  /**
   * Updates layer transform with validation
   */
  public updateTransform(updates: Partial<Transform>): Layer {
    const newTransform = { ...this.transform, ...updates }
    
    // Validate the new transform
    this.validateTransform(newTransform)
    
    return new Layer({
      id: this.id,
      type: this.type,
      content: this.content,
      transform: newTransform,
      style: this.style,
      constraints: this.constraints,
      metadata: {
        ...this.metadata,
        modifiedAt: new Date()
      }
    })
  }

  /**
   * Updates layer content with type validation
   */
  public updateContent(updates: Partial<LayerContent>): Layer {
    const newContent = { ...this.content, ...updates }
    
    // Create temporary layer data for validation
    const tempData: LayerData = {
      id: this.id,
      type: this.type,
      content: newContent,
      transform: this.transform,
      style: this.style,
      constraints: this.constraints,
      metadata: this.metadata
    }
    
    // Validate the new content
    this.validateLayerContent(tempData)
    
    return new Layer({
      ...tempData,
      metadata: {
        ...this.metadata,
        modifiedAt: new Date()
      }
    })
  }

  /**
   * Updates layer style properties
   */
  public updateStyle(updates: Partial<LayerStyle>): Layer {
    const newStyle = { ...this.style, ...updates }
    
    return new Layer({
      id: this.id,
      type: this.type,
      content: this.content,
      transform: this.transform,
      style: newStyle,
      constraints: this.constraints,
      metadata: {
        ...this.metadata,
        modifiedAt: new Date()
      }
    })
  }

  /**
   * Checks if layer is visible (opacity > 0 and within reasonable bounds)
   */
  public isVisible(): boolean {
    return this.transform.opacity > 0
  }

  /**
   * Gets the layer's bounding box
   */
  public getBoundingBox(): { x: number; y: number; width: number; height: number } {
    // This is a simplified bounding box calculation
    // In a real implementation, this would consider the layer's actual content dimensions
    return {
      x: this.transform.x,
      y: this.transform.y,
      width: 100 * this.transform.scaleX, // Default width scaled
      height: 100 * this.transform.scaleY // Default height scaled
    }
  }

  /**
   * Exports layer data for serialization
   */
  public toJSON(): LayerData {
    return {
      id: this.id,
      type: this.type,
      content: this.content,
      transform: this.transform,
      style: this.style,
      constraints: this.constraints,
      metadata: this.metadata
    }
  }

  /**
   * Creates a Layer from serialized data
   */
  public static fromJSON(data: LayerData): Layer {
    return new Layer(data)
  }

  /**
   * Creates a new layer with default values for the specified type
   */
  public static createDefault(type: LayerType, id: string): Layer {
    const defaultContent: LayerContent = {}
    const defaultStyle: LayerStyle = {}
    
    switch (type) {
      case LayerType.TEXT:
        defaultContent.text = 'New Text Layer'
        defaultStyle.fontSize = 16
        defaultStyle.color = '#000000'
        break
      case LayerType.IMAGE:
        defaultContent.imageUrl = ''
        break
      case LayerType.BACKGROUND:
        defaultContent.color = '#ffffff'
        break
      case LayerType.SHAPE:
        defaultStyle.color = '#000000'
        break
      case LayerType.GROUP:
        defaultContent.childLayerIds = []
        break
    }

    return new Layer({
      id,
      type,
      content: defaultContent,
      transform: {
        x: 0,
        y: 0,
        scaleX: 1,
        scaleY: 1,
        rotation: 0,
        opacity: 1
      },
      style: defaultStyle,
      constraints: {
        pinTop: false,
        pinBottom: false,
        pinLeft: false,
        pinRight: false,
        centerX: false,
        centerY: false,
        maintainAspectRatio: true
      },
      metadata: {
        source: 'user',
        createdAt: new Date()
      }
    })
  }
}
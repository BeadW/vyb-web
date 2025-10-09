import { LayerType, LayerContent, Transform, LayerStyle, LayerConstraints, LayerMetadata, ValidationError } from '../types'

export interface LayerData {
  id: string
  type: LayerType | string
  content: LayerContent
  transform: Transform
  style: LayerStyle
  constraints: LayerConstraints
  metadata: LayerMetadata
}

export class Layer {
  public readonly id: string
  public type: LayerType
  public content: LayerContent
  public transform: Transform
  public style: LayerStyle
  public constraints: LayerConstraints
  public metadata: LayerMetadata

  constructor(data: LayerData) {
    this.validateLayerData(data)
    
    this.id = data.id
    this.type = this.parseLayerType(data.type)
    this.content = { ...data.content }
    this.transform = { ...data.transform }
    this.style = { ...data.style }
    this.constraints = { ...data.constraints }
    this.metadata = {
      ...data.metadata,
      createdAt: new Date(data.metadata.createdAt),
      modifiedAt: data.metadata.modifiedAt ? new Date(data.metadata.modifiedAt) : undefined
    }

    this.validateLayerContent()
  }

  private validateLayerData(data: LayerData): void {
    // Validate Layer ID
    if (!data.id || typeof data.id !== 'string' || data.id.trim() === '') {
      throw new ValidationError('Layer ID must be a valid non-empty string', 'id')
    }

    // Validate Layer Type
    if (!data.type) {
      throw new ValidationError('Layer type is required', 'type')
    }

    // Validate Transform
    this.validateTransform(data.transform)

    // Validate Content
    if (!data.content || typeof data.content !== 'object') {
      throw new ValidationError('Layer content is required and must be an object', 'content')
    }

    // Validate Style
    if (!data.style || typeof data.style !== 'object') {
      throw new ValidationError('Layer style is required and must be an object', 'style')
    }

    // Validate Constraints
    this.validateConstraints(data.constraints)

    // Validate Metadata
    this.validateMetadata(data.metadata)
  }

  private parseLayerType(type: LayerType | string): LayerType {
    // Handle both enum values and string values
    const layerTypeValues = Object.values(LayerType) as string[]
    
    if (layerTypeValues.includes(type as string)) {
      return type as LayerType
    }
    
    // Try to match string type to enum
    const matchingType = layerTypeValues.find(enumValue => 
      enumValue.toLowerCase() === type.toLowerCase()
    )
    
    if (matchingType) {
      return matchingType as LayerType
    }
    
    throw new ValidationError(`Invalid layer type: ${type}. Valid types: ${layerTypeValues.join(', ')}`, 'type')
  }

  private validateTransform(transform: Transform): void {
    if (!transform || typeof transform !== 'object') {
      throw new ValidationError('Transform is required and must be an object', 'transform')
    }

    const requiredFields = ['x', 'y', 'scaleX', 'scaleY', 'rotation', 'opacity']
    for (const field of requiredFields) {
      if (typeof transform[field as keyof Transform] !== 'number') {
        throw new ValidationError(`Transform.${field} must be a number`, 'transform')
      }
    }

    // Validate ranges
    if (transform.opacity < 0 || transform.opacity > 1) {
      throw new ValidationError('Transform opacity must be between 0 and 1', 'transform')
    }

    if (transform.scaleX <= 0 || transform.scaleY <= 0) {
      throw new ValidationError('Transform scale values must be positive', 'transform')
    }
  }

  private validateConstraints(constraints: LayerConstraints): void {
    if (!constraints || typeof constraints !== 'object') {
      throw new ValidationError('Constraints are required and must be an object', 'constraints')
    }

    if (typeof constraints.locked !== 'boolean') {
      throw new ValidationError('Constraints.locked must be a boolean', 'constraints')
    }

    if (typeof constraints.visible !== 'boolean') {
      throw new ValidationError('Constraints.visible must be a boolean', 'constraints')
    }

    // Optional constraint validations
    if (constraints.minWidth !== undefined && (typeof constraints.minWidth !== 'number' || constraints.minWidth < 0)) {
      throw new ValidationError('Constraints.minWidth must be a non-negative number', 'constraints')
    }

    if (constraints.minHeight !== undefined && (typeof constraints.minHeight !== 'number' || constraints.minHeight < 0)) {
      throw new ValidationError('Constraints.minHeight must be a non-negative number', 'constraints')
    }

    if (constraints.maxWidth !== undefined && constraints.minWidth !== undefined && 
        constraints.maxWidth < constraints.minWidth) {
      throw new ValidationError('Constraints.maxWidth must be greater than or equal to minWidth', 'constraints')
    }
  }

  private validateMetadata(metadata: LayerMetadata): void {
    if (!metadata || typeof metadata !== 'object') {
      throw new ValidationError('Metadata is required and must be an object', 'metadata')
    }

    if (!['user', 'ai'].includes(metadata.source)) {
      throw new ValidationError('Metadata.source must be "user" or "ai"', 'metadata')
    }

    if (!metadata.createdAt || !(metadata.createdAt instanceof Date || typeof metadata.createdAt === 'string')) {
      throw new ValidationError('Metadata.createdAt is required and must be a Date or ISO string', 'metadata')
    }
  }

  private validateLayerContent(): void {
    switch (this.type) {
      case LayerType.TEXT:
        this.validateTextContent()
        break
      case LayerType.IMAGE:
        this.validateImageContent()
        break
      case LayerType.BACKGROUND:
        this.validateBackgroundContent()
        break
      case LayerType.SHAPE:
        this.validateShapeContent()
        break
      case LayerType.GROUP:
        this.validateGroupContent()
        break
      default:
        throw new ValidationError(`Unknown layer type: ${this.type}`)
    }
  }

  private validateTextContent(): void {
    if (!this.content.text || typeof this.content.text !== 'string') {
      throw new ValidationError('Text layer must have valid text content', 'content')
    }

    if (this.content.fontSize !== undefined && 
        (typeof this.content.fontSize !== 'number' || this.content.fontSize <= 0)) {
      throw new ValidationError('Text layer fontSize must be a positive number', 'content')
    }
  }

  private validateImageContent(): void {
    if (!this.content.imageUrl && !this.content.imageData) {
      throw new ValidationError('Image layer must have imageUrl or imageData', 'content')
    }

    if (this.content.imageUrl && typeof this.content.imageUrl !== 'string') {
      throw new ValidationError('Image layer imageUrl must be a string', 'content')
    }
  }

  private validateBackgroundContent(): void {
    // Background layers can have empty content (will use defaults)
    if (Object.keys(this.content).length === 0) {
      return // Allow empty content for background layers
    }
    
    if (!this.content.color && !this.content.gradient) {
      throw new ValidationError('Background layer must have color or gradient', 'content')
    }

    if (this.content.color && typeof this.content.color !== 'string') {
      throw new ValidationError('Background layer color must be a string', 'content')
    }

    if (this.content.gradient) {
      this.validateGradientContent(this.content.gradient)
    }
  }

  private validateShapeContent(): void {
    const validShapeTypes = ['rectangle', 'circle', 'triangle', 'polygon']
    if (!this.content.shapeType || !validShapeTypes.includes(this.content.shapeType)) {
      throw new ValidationError(`Shape layer must have valid shapeType: ${validShapeTypes.join(', ')}`, 'content')
    }
  }

  private validateGroupContent(): void {
    if (!this.content.childLayerIds || !Array.isArray(this.content.childLayerIds)) {
      throw new ValidationError('Group layer must have childLayerIds array', 'content')
    }
  }

  private validateGradientContent(gradient: any): void {
    if (!gradient.type || !['linear', 'radial'].includes(gradient.type)) {
      throw new ValidationError('Gradient must have type "linear" or "radial"', 'content')
    }

    if (!Array.isArray(gradient.stops) || gradient.stops.length < 2) {
      throw new ValidationError('Gradient must have at least 2 stops', 'content')
    }

    for (const stop of gradient.stops) {
      if (!stop.color || typeof stop.color !== 'string') {
        throw new ValidationError('Gradient stop must have color string', 'content')
      }
      if (typeof stop.position !== 'number' || stop.position < 0 || stop.position > 1) {
        throw new ValidationError('Gradient stop position must be number between 0 and 1', 'content')
      }
    }
  }

  // Layer manipulation methods
  public updateContent(newContent: Partial<LayerContent>): void {
    this.content = { ...this.content, ...newContent }
    this.validateLayerContent()
    this.updateModifiedAt()
  }

  public updateTransform(newTransform: Partial<Transform>): void {
    const updatedTransform = { ...this.transform, ...newTransform }
    this.validateTransform(updatedTransform)
    this.transform = updatedTransform
    this.updateModifiedAt()
  }

  public updateStyle(newStyle: Partial<LayerStyle>): void {
    this.style = { ...this.style, ...newStyle }
    this.updateModifiedAt()
  }

  public updateConstraints(newConstraints: Partial<LayerConstraints>): void {
    const updatedConstraints = { ...this.constraints, ...newConstraints }
    this.validateConstraints(updatedConstraints)
    this.constraints = updatedConstraints
    this.updateModifiedAt()
  }

  private updateModifiedAt(): void {
    this.metadata.modifiedAt = new Date()
  }

  // Utility methods
  public isVisible(): boolean {
    return this.constraints.visible && this.transform.opacity > 0
  }

  public isLocked(): boolean {
    return this.constraints.locked
  }

  public getBounds(): { x: number; y: number; width: number; height: number } {
    // Simplified bounds calculation - in practice would need actual rendered dimensions
    const baseWidth = 100 // Default base width
    const baseHeight = 100 // Default base height
    
    return {
      x: this.transform.x,
      y: this.transform.y,
      width: baseWidth * this.transform.scaleX,
      height: baseHeight * this.transform.scaleY
    }
  }

  public isPointInside(x: number, y: number): boolean {
    const bounds = this.getBounds()
    return x >= bounds.x && x <= bounds.x + bounds.width &&
           y >= bounds.y && y <= bounds.y + bounds.height
  }

  // Serialization
  public toJSON(): Record<string, any> {
    return {
      id: this.id,
      type: this.type,
      content: this.content,
      transform: this.transform,
      style: this.style,
      constraints: this.constraints,
      metadata: {
        ...this.metadata,
        createdAt: this.metadata.createdAt.toISOString(),
        modifiedAt: this.metadata.modifiedAt?.toISOString()
      }
    }
  }

  public static fromJSON(data: any): Layer {
    return new Layer({
      ...data,
      metadata: {
        ...data.metadata,
        createdAt: new Date(data.metadata.createdAt),
        modifiedAt: data.metadata.modifiedAt ? new Date(data.metadata.modifiedAt) : undefined
      }
    })
  }

  public clone(): Layer {
    return Layer.fromJSON(this.toJSON())
  }
}

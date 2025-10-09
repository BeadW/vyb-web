import { VariationNode, ValidationError } from '../types'
import { DesignCanvas } from './DesignCanvas'

export interface DesignVariationData {
  id: string
  parentId: string | null
  childIds: string[]
  canvasData: any // Serialized DesignCanvas data
  metadata: {
    createdAt: Date | string
    source: 'user' | 'ai'
    aiMetadata?: {
      confidence: number
      prompt: string
      model: string
    }
  }
}

export class DesignVariation implements VariationNode {
  public readonly id: string
  public parentId: string | null
  public childIds: string[]
  public canvasData: any
  public metadata: {
    createdAt: Date
    source: 'user' | 'ai'
    aiMetadata?: {
      confidence: number
      prompt: string
      model: string
    }
  }

  constructor(data: DesignVariationData) {
    this.validateVariationData(data)
    
    this.id = data.id
    this.parentId = data.parentId
    this.childIds = [...data.childIds]
    this.canvasData = data.canvasData
    this.metadata = {
      ...data.metadata,
      createdAt: data.metadata.createdAt instanceof Date 
        ? data.metadata.createdAt 
        : new Date(data.metadata.createdAt)
    }
  }

  private validateVariationData(data: DesignVariationData): void {
    // Validate ID
    if (!data.id || typeof data.id !== 'string' || data.id.trim() === '') {
      throw new ValidationError('Variation ID must be a valid non-empty string', 'id')
    }

    // Validate parentId (can be null for root variations)
    if (data.parentId !== null && (typeof data.parentId !== 'string' || data.parentId.trim() === '')) {
      throw new ValidationError('Parent ID must be null or a valid non-empty string', 'parentId')
    }

    // Validate childIds
    if (!Array.isArray(data.childIds)) {
      throw new ValidationError('Child IDs must be an array', 'childIds')
    }

    for (const childId of data.childIds) {
      if (typeof childId !== 'string' || childId.trim() === '') {
        throw new ValidationError('All child IDs must be valid non-empty strings', 'childIds')
      }
    }

    // Check for duplicate child IDs
    const uniqueChildIds = new Set(data.childIds)
    if (uniqueChildIds.size !== data.childIds.length) {
      throw new ValidationError('Child IDs must be unique', 'childIds')
    }

    // Validate canvasData
    if (!data.canvasData) {
      throw new ValidationError('Canvas data is required', 'canvasData')
    }

    // Validate metadata
    this.validateMetadata(data.metadata)
  }

  private validateMetadata(metadata: DesignVariationData['metadata']): void {
    if (!metadata || typeof metadata !== 'object') {
      throw new ValidationError('Metadata is required and must be an object', 'metadata')
    }

    if (!metadata.createdAt) {
      throw new ValidationError('Metadata.createdAt is required', 'metadata')
    }

    if (!['user', 'ai'].includes(metadata.source)) {
      throw new ValidationError('Metadata.source must be "user" or "ai"', 'metadata')
    }

    // Validate AI metadata if present
    if (metadata.aiMetadata) {
      this.validateAIMetadata(metadata.aiMetadata)
    }
  }

  private validateAIMetadata(aiMetadata: NonNullable<DesignVariationData['metadata']['aiMetadata']>): void {
    if (typeof aiMetadata.confidence !== 'number' || aiMetadata.confidence < 0 || aiMetadata.confidence > 1) {
      throw new ValidationError('AI confidence must be a number between 0 and 1', 'metadata.aiMetadata')
    }

    if (!aiMetadata.prompt || typeof aiMetadata.prompt !== 'string') {
      throw new ValidationError('AI prompt must be a non-empty string', 'metadata.aiMetadata')
    }

    if (!aiMetadata.model || typeof aiMetadata.model !== 'string') {
      throw new ValidationError('AI model must be a non-empty string', 'metadata.aiMetadata')
    }
  }

  // DAG structure methods
  public addChild(childId: string): void {
    if (this.childIds.includes(childId)) {
      throw new ValidationError(`Child ID ${childId} already exists`, 'childIds')
    }
    this.childIds.push(childId)
  }

  public removeChild(childId: string): boolean {
    const index = this.childIds.indexOf(childId)
    if (index === -1) return false
    
    this.childIds.splice(index, 1)
    return true
  }

  public hasChild(childId: string): boolean {
    return this.childIds.includes(childId)
  }

  public isRoot(): boolean {
    return this.parentId === null
  }

  public isLeaf(): boolean {
    return this.childIds.length === 0
  }

  public getDepth(variationMap: Map<string, DesignVariation>): number {
    if (this.isRoot()) return 0
    
    let depth = 0
    let currentId = this.parentId
    
    while (currentId !== null) {
      const parentVariation = variationMap.get(currentId)
      if (!parentVariation) break
      
      depth++
      currentId = parentVariation.parentId
    }
    
    return depth
  }

  public getBranches(): string[] {
    return [...this.childIds]
  }

  // Canvas data methods
  public getCanvas(): DesignCanvas | null {
    try {
      if (this.canvasData && typeof this.canvasData === 'object') {
        return DesignCanvas.fromJSON(this.canvasData)
      }
      return null
    } catch (error) {
      console.error('Failed to deserialize canvas data:', error)
      return null
    }
  }

  public updateCanvas(canvas: DesignCanvas): void {
    this.canvasData = canvas.toJSON()
  }

  public setCanvasData(canvasData: any): void {
    // Validate that canvasData can be used to create a valid DesignCanvas
    try {
      DesignCanvas.fromJSON(canvasData)
      this.canvasData = canvasData
    } catch (error) {
      throw new ValidationError(
        `Invalid canvas data: ${error instanceof Error ? error.message : 'Unknown error'}`,
        'canvasData'
      )
    }
  }

  // Utility methods
  public isAIGenerated(): boolean {
    return this.metadata.source === 'ai'
  }

  public getAIConfidence(): number | null {
    return this.metadata.aiMetadata?.confidence ?? null
  }

  public getAIPrompt(): string | null {
    return this.metadata.aiMetadata?.prompt ?? null
  }

  public getAIModel(): string | null {
    return this.metadata.aiMetadata?.model ?? null
  }

  // Path finding methods
  public getPathToRoot(variationMap: Map<string, DesignVariation>): string[] {
    const path: string[] = [this.id]
    let currentId = this.parentId
    
    while (currentId !== null) {
      path.unshift(currentId)
      const parentVariation = variationMap.get(currentId)
      if (!parentVariation) break
      
      currentId = parentVariation.parentId
    }
    
    return path
  }

  public getPathTo(targetId: string, variationMap: Map<string, DesignVariation>): string[] | null {
    // Simplified path finding - in a full implementation would use more sophisticated algorithms
    const visited = new Set<string>()
    const queue: { id: string; path: string[] }[] = [{ id: this.id, path: [this.id] }]
    
    while (queue.length > 0) {
      const { id, path } = queue.shift()!
      
      if (id === targetId) {
        return path
      }
      
      if (visited.has(id)) continue
      visited.add(id)
      
      const variation = variationMap.get(id)
      if (!variation) continue
      
      // Add children to queue
      for (const childId of variation.childIds) {
        if (!visited.has(childId)) {
          queue.push({ id: childId, path: [...path, childId] })
        }
      }
      
      // Add parent to queue
      if (variation.parentId && !visited.has(variation.parentId)) {
        queue.push({ id: variation.parentId, path: [...path, variation.parentId] })
      }
    }
    
    return null // No path found
  }

  // Serialization
  public toJSON(): Record<string, any> {
    return {
      id: this.id,
      parentId: this.parentId,
      childIds: [...this.childIds],
      canvasData: this.canvasData,
      metadata: {
        ...this.metadata,
        createdAt: this.metadata.createdAt.toISOString()
      }
    }
  }

  public static fromJSON(data: any): DesignVariation {
    return new DesignVariation({
      ...data,
      metadata: {
        ...data.metadata,
        createdAt: new Date(data.metadata.createdAt)
      }
    })
  }

  public clone(): DesignVariation {
    return DesignVariation.fromJSON(this.toJSON())
  }

  // DAG validation (static methods for working with collections)
  public static validateDAG(variations: DesignVariation[]): { isValid: boolean; errors: string[] } {
    const errors: string[] = []
    const variationMap = new Map(variations.map(v => [v.id, v]))
    const visited = new Set<string>()
    const recursionStack = new Set<string>()

    // Check for cycles
    for (const variation of variations) {
      if (this.hasCycle(variation.id, variationMap, visited, recursionStack)) {
        errors.push(`Cycle detected involving variation ${variation.id}`)
      }
    }

    // Check for orphaned nodes (non-root nodes with invalid parents)
    for (const variation of variations) {
      if (variation.parentId && !variationMap.has(variation.parentId)) {
        errors.push(`Variation ${variation.id} has invalid parent ${variation.parentId}`)
      }
    }

    // Check for invalid child references
    for (const variation of variations) {
      for (const childId of variation.childIds) {
        if (!variationMap.has(childId)) {
          errors.push(`Variation ${variation.id} has invalid child ${childId}`)
        }
      }
    }

    return {
      isValid: errors.length === 0,
      errors
    }
  }

  private static hasCycle(
    nodeId: string, 
    variationMap: Map<string, DesignVariation>, 
    visited: Set<string>, 
    recursionStack: Set<string>
  ): boolean {
    if (recursionStack.has(nodeId)) {
      return true // Cycle detected
    }

    if (visited.has(nodeId)) {
      return false // Already processed this path
    }

    visited.add(nodeId)
    recursionStack.add(nodeId)

    const variation = variationMap.get(nodeId)
    if (variation) {
      for (const childId of variation.childIds) {
        if (this.hasCycle(childId, variationMap, visited, recursionStack)) {
          return true
        }
      }
    }

    recursionStack.delete(nodeId)
    return false
  }
}

import { VariationSource, ValidationError } from '../types'
import { DesignCanvas } from './DesignCanvas'

export interface VariationMetadata {
  tags: string[]
  notes: string
  approvalStatus: 'pending' | 'approved' | 'rejected'
  aiMetadata?: {
    model: string
    temperature?: number
    processingTime?: number
  }
}

export interface DesignVariationData {
  id: string
  parentId: string | null
  canvasState: DesignCanvas
  source: VariationSource
  prompt: string
  confidence: number
  timestamp: Date
  metadata: VariationMetadata
}

/**
 * DesignVariation model with DAG (Directed Acyclic Graph) structure
 * Manages the branching history of design variations with validation
 */
export class DesignVariation {
  public readonly id: string
  public readonly parentId: string | null
  public readonly canvasState: DesignCanvas
  public readonly source: VariationSource
  public readonly prompt: string
  public readonly confidence: number
  public readonly timestamp: Date
  public readonly metadata: VariationMetadata

  // DAG management
  private childIds: string[] = []
  private static readonly MAX_DEPTH = 50 // Prevent infinite branching

  constructor(data: DesignVariationData) {
    this.validateVariationData(data)
    
    this.id = data.id
    this.parentId = data.parentId
    this.canvasState = data.canvasState
    this.source = data.source
    this.prompt = data.prompt
    this.confidence = data.confidence
    this.timestamp = data.timestamp
    this.metadata = data.metadata
  }

  private validateVariationData(data: DesignVariationData): void {
    // Validate Variation ID uniqueness
    if (!data.id || typeof data.id !== 'string' || data.id.trim() === '') {
      throw new ValidationError('Variation ID must be a valid non-empty string', 'id')
    }

    // Validate confidence score range (0-1)
    if (typeof data.confidence !== 'number' || data.confidence < 0 || data.confidence > 1) {
      throw new ValidationError('Confidence score must be between 0 and 1', 'confidence')
    }

    // Validate source type
    if (!Object.values(VariationSource).includes(data.source)) {
      throw new ValidationError('Source must be a valid VariationSource', 'source')
    }

    // Validate prompt
    if (!data.prompt || typeof data.prompt !== 'string') {
      throw new ValidationError('Prompt must be a non-empty string', 'prompt')
    }

    // Validate canvas state completeness
    if (!data.canvasState || !data.canvasState.isValid()) {
      throw new ValidationError('Canvas state must be a complete snapshot', 'canvasState')
    }

    // Prevent circular references - variation cannot be parent of itself
    if (data.id === data.parentId) {
      throw new ValidationError('Variation cannot be parent of itself', 'parentId')
    }
  }

  /**
   * Validates DAG depth limits to prevent infinite chains
   */
  public static validateDAGDepth(parentChain: string[], maxDepth: number = DesignVariation.MAX_DEPTH): void {
    if (parentChain.length > maxDepth) {
      throw new ValidationError('Variation depth exceeds maximum allowed limit', 'depth')
    }
  }

  /**
   * Adds a child variation ID to this variation
   */
  public addChild(childId: string): void {
    if (!this.childIds.includes(childId)) {
      this.childIds.push(childId)
    }
  }

  /**
   * Removes a child variation ID from this variation
   */
  public removeChild(childId: string): void {
    this.childIds = this.childIds.filter(id => id !== childId)
  }

  /**
   * Gets all child variation IDs
   */
  public getChildren(): string[] {
    return [...this.childIds]
  }

  /**
   * Checks if this variation has children (is a branch point)
   */
  public hasBranches(): boolean {
    return this.childIds.length > 1
  }

  /**
   * Checks if this variation is a root variation (no parent)
   */
  public isRoot(): boolean {
    return this.parentId === null
  }

  /**
   * Checks if this variation is a leaf (no children)
   */
  public isLeaf(): boolean {
    return this.childIds.length === 0
  }

  /**
   * Creates a new variation branching from this one
   */
  public createBranch(branchData: {
    id: string
    source: VariationSource
    prompt: string
    confidence: number
    canvasState: DesignCanvas
    metadata?: Partial<VariationMetadata>
  }): DesignVariation {
    const newVariation = new DesignVariation({
      id: branchData.id,
      parentId: this.id, // This variation becomes the parent
      canvasState: branchData.canvasState,
      source: branchData.source,
      prompt: branchData.prompt,
      confidence: branchData.confidence,
      timestamp: new Date(),
      metadata: {
        tags: [],
        notes: '',
        approvalStatus: 'pending',
        ...branchData.metadata
      }
    })

    // Add this branch as a child
    this.addChild(branchData.id)

    return newVariation
  }

  /**
   * Gets the variation tree path from root to this variation
   */
  public getPath(): string[] {
    const path: string[] = []
    let currentId: string | null = this.id
    
    // Build path by traversing up to root
    while (currentId !== null) {
      path.unshift(currentId)
      // In a real implementation, this would require access to the full variation tree
      // For now, we'll return the current path
      break
    }
    
    return path
  }

  /**
   * Calculates similarity to another variation (0-1 scale)
   */
  public calculateSimilarity(other: DesignVariation): number {
    // Simplified similarity calculation based on various factors
    let similarity = 0

    // Source similarity
    if (this.source === other.source) {
      similarity += 0.2
    }

    // Confidence similarity
    const confidenceDiff = Math.abs(this.confidence - other.confidence)
    similarity += (1 - confidenceDiff) * 0.3

    // Canvas state similarity (simplified)
    if (this.canvasState.deviceType === other.canvasState.deviceType) {
      similarity += 0.2
    }

    if (this.canvasState.layers.length === other.canvasState.layers.length) {
      similarity += 0.3
    }

    return Math.min(1, similarity)
  }

  /**
   * Updates variation metadata
   */
  public updateMetadata(updates: Partial<VariationMetadata>): DesignVariation {
    return new DesignVariation({
      id: this.id,
      parentId: this.parentId,
      canvasState: this.canvasState,
      source: this.source,
      prompt: this.prompt,
      confidence: this.confidence,
      timestamp: this.timestamp,
      metadata: {
        ...this.metadata,
        ...updates
      }
    })
  }

  /**
   * Approves this variation
   */
  public approve(): DesignVariation {
    return this.updateMetadata({ approvalStatus: 'approved' })
  }

  /**
   * Rejects this variation
   */
  public reject(): DesignVariation {
    return this.updateMetadata({ approvalStatus: 'rejected' })
  }

  /**
   * Exports variation data for serialization
   */
  public toJSON(): DesignVariationData & { childIds: string[] } {
    return {
      id: this.id,
      parentId: this.parentId,
      canvasState: this.canvasState,
      source: this.source,
      prompt: this.prompt,
      confidence: this.confidence,
      timestamp: this.timestamp,
      metadata: this.metadata,
      childIds: this.childIds
    }
  }

  /**
   * Creates a DesignVariation from serialized data
   */
  public static fromJSON(data: DesignVariationData & { childIds?: string[] }): DesignVariation {
    const variation = new DesignVariation(data)
    if (data.childIds) {
      variation.childIds = [...data.childIds]
    }
    return variation
  }

  /**
   * Creates a root variation (no parent)
   */
  public static createRoot(data: Omit<DesignVariationData, 'parentId'>): DesignVariation {
    return new DesignVariation({
      ...data,
      parentId: null
    })
  }

  /**
   * Validates and creates a variation chain to prevent cycles
   */
  public static createWithValidation(
    data: DesignVariationData,
    existingVariations: Map<string, DesignVariation>
  ): DesignVariation {
    // Check for circular references by traversing the parent chain
    const parentChain: string[] = []
    let currentId = data.parentId
    
    while (currentId !== null) {
      if (parentChain.includes(currentId)) {
        throw new ValidationError('Circular reference detected in variation DAG', 'parentId')
      }
      
      if (currentId === data.id) {
        throw new ValidationError('Variation cannot be parent of itself', 'parentId')
      }
      
      parentChain.push(currentId)
      
      const parentVariation = existingVariations.get(currentId)
      if (parentVariation) {
        currentId = parentVariation.parentId
      } else {
        break // Parent not found, assume it's valid
      }
    }
    
    // Validate depth limits
    DesignVariation.validateDAGDepth(parentChain)
    
    return new DesignVariation(data)
  }
}
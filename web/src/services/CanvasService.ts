import { DesignCanvas } from '../entities/DesignCanvas'
import { DesignVariation } from '../entities/DesignVariation'
import { Layer } from '../entities/Layer'

/**
 * Canvas response with versioning
 */
export interface CanvasResponse {
  canvas: DesignCanvas
  version: number
  lastModified?: string
}

/**
 * Canvas update request with optimistic concurrency
 */
export interface CanvasUpdateRequest {
  canvas: DesignCanvas
  version: number
  changeDescription?: string
}

/**
 * Variation history response
 */
export interface VariationHistoryResponse {
  canvasId: string
  variations: DesignVariation[]
  totalCount: number
  maxDepth: number
}

/**
 * Create variation request
 */
export interface CreateVariationRequest {
  parentId?: string
  description: string
  changes: any[]
}

/**
 * Variation created response
 */
export interface VariationCreatedResponse {
  variationId: string
  canvas: DesignCanvas
  version: number
}

/**
 * Layer update request
 */
export interface LayerUpdateRequest {
  layer: Layer
  version: number
}

/**
 * Canvas service error
 */
export class CanvasServiceError extends Error {
  constructor(
    message: string,
    public code: 'NOT_FOUND' | 'CONFLICT' | 'VALIDATION_ERROR' | 'NETWORK_ERROR'
  ) {
    super(message)
    this.name = 'CanvasServiceError'
  }
}

/**
 * Canvas Service for canvas state management and persistence
 * Implements the contract specifications from canvas-api.yaml
 */
export class CanvasService {
  private baseUrl: string
  private apiKey: string

  constructor(baseUrl?: string, apiKey?: string) {
    // In test environment, use a full URL; in browser, relative paths are fine
    this.baseUrl = baseUrl || (typeof window === 'undefined' ? 'http://localhost:3000/api/v1' : '/api/v1')
    this.apiKey = apiKey || ''
  }

  /**
   * Retrieve canvas state
   * GET /canvas/{canvasId}
   */
  async getCanvas(canvasId: string): Promise<CanvasResponse> {
    try {
      if (!canvasId || canvasId.trim() === '') {
        throw new CanvasServiceError('Canvas ID is required', 'VALIDATION_ERROR')
      }

      // Validate UUID format
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
      if (!uuidRegex.test(canvasId)) {
        throw new CanvasServiceError('Invalid UUID format', 'VALIDATION_ERROR')
      }

      const response = await fetch(`${this.baseUrl}/canvas/${canvasId}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          ...(this.apiKey && { 'Authorization': `Bearer ${this.apiKey}` })
        }
      })

      if (response.status === 404) {
        throw new CanvasServiceError(`Canvas not found`, 'NOT_FOUND')
      }

      if (!response.ok) {
        const error = await response.text()
        throw new CanvasServiceError(`Failed to get canvas: ${error}`, 'NETWORK_ERROR')
      }

      const data = await response.json()

      return {
        canvas: DesignCanvas.fromJSON(data.canvas),
        version: data.version,
        lastModified: data.lastModified
      }
    } catch (error) {
      if (error instanceof CanvasServiceError) {
        throw error
      }
      throw new CanvasServiceError(`Get canvas failed: ${error}`, 'NETWORK_ERROR')
    }
  }

  /**
   * Update canvas state
   * PUT /canvas/{canvasId}
   */
  async updateCanvas(canvasId: string, request: CanvasUpdateRequest): Promise<void> {
    try {
      if (!canvasId || canvasId.trim() === '') {
        throw new CanvasServiceError('Canvas ID is required', 'VALIDATION_ERROR')
      }

      if (!request.canvas?.isValid()) {
        throw new CanvasServiceError('Invalid canvas data', 'VALIDATION_ERROR')
      }

      if (!Number.isInteger(request.version) || request.version < 0) {
        throw new CanvasServiceError('Valid version number is required', 'VALIDATION_ERROR')
      }

      const response = await fetch(`${this.baseUrl}/canvas/${canvasId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          ...(this.apiKey && { 'Authorization': `Bearer ${this.apiKey}` })
        },
        body: JSON.stringify({
          canvas: request.canvas.toJSON(),
          version: request.version,
          changeDescription: request.changeDescription
        })
      })

      if (response.status === 409) {
        throw new CanvasServiceError('Canvas has been modified by another session', 'CONFLICT')
      }

      if (!response.ok) {
        const error = await response.text()
        throw new CanvasServiceError(`Failed to update canvas: ${error}`, 'NETWORK_ERROR')
      }
    } catch (error) {
      if (error instanceof CanvasServiceError) {
        throw error
      }
      throw new CanvasServiceError(`Update canvas failed: ${error}`, 'NETWORK_ERROR')
    }
  }

  /**
   * Get design variation history
   * GET /canvas/{canvasId}/variations
   */
  async getVariations(canvasId: string, depth = 5): Promise<VariationHistoryResponse> {
    try {
      if (!canvasId || canvasId.trim() === '') {
        throw new CanvasServiceError('Canvas ID is required', 'VALIDATION_ERROR')
      }

      if (depth < 1 || depth > 10) {
        throw new CanvasServiceError('Depth must be between 1 and 10', 'VALIDATION_ERROR')
      }

      const response = await fetch(`${this.baseUrl}/canvas/${canvasId}/variations?depth=${depth}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          ...(this.apiKey && { 'Authorization': `Bearer ${this.apiKey}` })
        }
      })

      if (response.status === 404) {
        throw new CanvasServiceError(`Canvas ${canvasId} not found`, 'NOT_FOUND')
      }

      if (!response.ok) {
        const error = await response.text()
        throw new CanvasServiceError(`Failed to get variations: ${error}`, 'NETWORK_ERROR')
      }

      const data = await response.json()

      const variations = data.variations.map((variationData: any) =>
        DesignVariation.fromJSON(variationData)
      )

      return {
        canvasId: data.canvasId,
        variations,
        totalCount: data.totalCount,
        maxDepth: data.maxDepth
      }
    } catch (error) {
      if (error instanceof CanvasServiceError) {
        throw error
      }
      throw new CanvasServiceError(`Get variations failed: ${error}`, 'NETWORK_ERROR')
    }
  }

  /**
   * Create new design variation
   * POST /canvas/{canvasId}/variations
   */
  async createVariation(canvasId: string, request: CreateVariationRequest): Promise<VariationCreatedResponse> {
    try {
      if (!canvasId || canvasId.trim() === '') {
        throw new CanvasServiceError('Canvas ID is required', 'VALIDATION_ERROR')
      }

      if (!request.description || request.description.trim() === '') {
        throw new CanvasServiceError('Variation description is required', 'VALIDATION_ERROR')
      }

      const response = await fetch(`${this.baseUrl}/canvas/${canvasId}/variations`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(this.apiKey && { 'Authorization': `Bearer ${this.apiKey}` })
        },
        body: JSON.stringify(request)
      })

      if (!response.ok) {
        const error = await response.text()
        throw new CanvasServiceError(`Failed to create variation: ${error}`, 'NETWORK_ERROR')
      }

      const data = await response.json()

      return {
        variationId: data.variationId,
        canvas: DesignCanvas.fromJSON(data.canvas),
        version: data.version
      }
    } catch (error) {
      if (error instanceof CanvasServiceError) {
        throw error
      }
      throw new CanvasServiceError(`Create variation failed: ${error}`, 'NETWORK_ERROR')
    }
  }

  /**
   * Update specific layer
   * PUT /canvas/{canvasId}/layers/{layerId}
   */
  async updateLayer(canvasId: string, layerId: string, request: LayerUpdateRequest): Promise<void> {
    try {
      if (!canvasId || canvasId.trim() === '') {
        throw new CanvasServiceError('Canvas ID is required', 'VALIDATION_ERROR')
      }

      if (!layerId || layerId.trim() === '') {
        throw new CanvasServiceError('Layer ID is required', 'VALIDATION_ERROR')
      }

      // Layer validation happens in constructor, so if it exists it's valid
      if (!request.layer || typeof request.layer !== 'object') {
        throw new CanvasServiceError('Valid layer data is required', 'VALIDATION_ERROR')
      }

      const response = await fetch(`${this.baseUrl}/canvas/${canvasId}/layers/${layerId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          ...(this.apiKey && { 'Authorization': `Bearer ${this.apiKey}` })
        },
        body: JSON.stringify({
          layer: request.layer.toJSON(),
          version: request.version
        })
      })

      if (response.status === 404) {
        throw new CanvasServiceError(`Canvas ${canvasId} or layer ${layerId} not found`, 'NOT_FOUND')
      }

      if (!response.ok) {
        const error = await response.text()
        throw new CanvasServiceError(`Failed to update layer: ${error}`, 'NETWORK_ERROR')
      }
    } catch (error) {
      if (error instanceof CanvasServiceError) {
        throw error
      }
      throw new CanvasServiceError(`Update layer failed: ${error}`, 'NETWORK_ERROR')
    }
  }

  /**
   * Remove layer from canvas
   * DELETE /canvas/{canvasId}/layers/{layerId}
   */
  async deleteLayer(canvasId: string, layerId: string): Promise<void> {
    try {
      if (!canvasId || canvasId.trim() === '') {
        throw new CanvasServiceError('Canvas ID is required', 'VALIDATION_ERROR')
      }

      if (!layerId || layerId.trim() === '') {
        throw new CanvasServiceError('Layer ID is required', 'VALIDATION_ERROR')
      }

      const response = await fetch(`${this.baseUrl}/canvas/${canvasId}/layers/${layerId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          ...(this.apiKey && { 'Authorization': `Bearer ${this.apiKey}` })
        }
      })

      if (response.status === 404) {
        throw new CanvasServiceError(`Canvas ${canvasId} or layer ${layerId} not found`, 'NOT_FOUND')
      }

      if (!response.ok) {
        const error = await response.text()
        throw new CanvasServiceError(`Failed to delete layer: ${error}`, 'NETWORK_ERROR')
      }
    } catch (error) {
      if (error instanceof CanvasServiceError) {
        throw error
      }
      throw new CanvasServiceError(`Delete layer failed: ${error}`, 'NETWORK_ERROR')
    }
  }

  /**
   * Configure service settings
   */
  configure(options: { baseUrl?: string; apiKey?: string }) {
    if (options.baseUrl) {
      this.baseUrl = options.baseUrl
    }
    if (options.apiKey) {
      this.apiKey = options.apiKey
    }
  }
}
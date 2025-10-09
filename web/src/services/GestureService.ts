/**
 * Gesture navigation request structure
 */
export interface GestureNavigationRequest {
  currentVariationId: string
  gestureType: 'scroll_up' | 'scroll_down' | 'swipe_left' | 'swipe_right'
  velocity: number
  deviceType?: string
}

/**
 * Gesture navigation response structure
 */
export interface GestureNavigationResponse {
  targetVariationId: string
  transitionType: 'immediate' | 'animated' | 'momentum'
  animationDuration?: number
  preloadVariations?: string[]
}

/**
 * Gesture service error
 */
export class GestureServiceError extends Error {
  constructor(
    message: string,
    public code: 'VALIDATION_ERROR' | 'NOT_FOUND' | 'NETWORK_ERROR'
  ) {
    super(message)
    this.name = 'GestureServiceError'
  }
}

/**
 * Gesture Service for gesture-based navigation
 * Implements the contract specifications from canvas-api.yaml
 */
export class GestureService {
  private baseUrl: string
  private apiKey: string

  constructor(baseUrl?: string, apiKey?: string) {
    this.baseUrl = baseUrl || '/api/v1'
    this.apiKey = apiKey || ''
  }

  /**
   * Process gesture navigation
   * POST /gesture/navigate
   */
  async navigate(request: GestureNavigationRequest): Promise<GestureNavigationResponse> {
    try {
      // Validate request
      if (!request.currentVariationId || request.currentVariationId.trim() === '') {
        throw new GestureServiceError('Current variation ID is required', 'VALIDATION_ERROR')
      }

      if (!['scroll_up', 'scroll_down', 'swipe_left', 'swipe_right'].includes(request.gestureType)) {
        throw new GestureServiceError('Invalid gesture type', 'VALIDATION_ERROR')
      }

      if (typeof request.velocity !== 'number' || isNaN(request.velocity)) {
        throw new GestureServiceError('Valid velocity is required', 'VALIDATION_ERROR')
      }

      // Make API call for navigation
      const response = await fetch(`${this.baseUrl}/gesture/navigate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(this.apiKey && { 'Authorization': `Bearer ${this.apiKey}` })
        },
        body: JSON.stringify(request)
      })

      if (!response.ok) {
        const error = await response.text()
        throw new GestureServiceError(`Navigation failed: ${error}`, 'NETWORK_ERROR')
      }

      const data = await response.json()

      return {
        targetVariationId: data.targetVariationId,
        transitionType: data.transitionType,
        animationDuration: data.animationDuration,
        preloadVariations: data.preloadVariations
      }
    } catch (error) {
      if (error instanceof GestureServiceError) {
        throw error
      }
      throw new GestureServiceError(`Navigation failed: ${error}`, 'NETWORK_ERROR')
    }
  }

  /**
   * Process local gesture navigation without API call
   * Used for offline navigation or local state management
   */
  async processLocalGesture(request: GestureNavigationRequest): Promise<GestureNavigationResponse> {
    try {
      // Validate request
      if (!request.currentVariationId || request.currentVariationId.trim() === '') {
        throw new GestureServiceError('Current variation ID is required', 'VALIDATION_ERROR')
      }

      // Calculate navigation based on gesture type and velocity
      let transitionType: 'immediate' | 'animated' | 'momentum' = 'immediate'
      let animationDuration = 0

      const absVelocity = Math.abs(request.velocity)
      
      if (absVelocity > 50) {
        transitionType = 'momentum'
        animationDuration = Math.min(800, absVelocity * 10)
      } else if (absVelocity > 10) {
        transitionType = 'animated'
        animationDuration = 300
      }

      // Generate target variation ID based on gesture
      const targetVariationId = this.generateTargetVariationId(
        request.currentVariationId, 
        request.gestureType
      )

      return {
        targetVariationId,
        transitionType,
        animationDuration: animationDuration > 0 ? animationDuration : undefined,
        preloadVariations: this.generatePreloadVariations(targetVariationId)
      }
    } catch (error) {
      if (error instanceof GestureServiceError) {
        throw error
      }
      throw new GestureServiceError(`Local navigation failed: ${error}`, 'VALIDATION_ERROR')
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

  /**
   * Generate target variation ID based on gesture (mock implementation)
   */
  private generateTargetVariationId(currentId: string, gestureType: string): string {
    // This is a mock implementation - in reality would traverse variation tree
    const hash = this.simpleHash(currentId + gestureType)
    return `variation-${hash.toString(36).substr(0, 8)}`
  }

  /**
   * Generate preload variations (mock implementation)
   */
  private generatePreloadVariations(targetId: string): string[] {
    // Mock implementation - in reality would get adjacent variations
    const hash1 = this.simpleHash(targetId + 'next')
    const hash2 = this.simpleHash(targetId + 'prev')
    return [
      `variation-${hash1.toString(36).substr(0, 8)}`,
      `variation-${hash2.toString(36).substr(0, 8)}`
    ]
  }

  /**
   * Simple hash function for generating mock IDs
   */
  private simpleHash(str: string): number {
    let hash = 0
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash = hash & hash // Convert to 32-bit integer
    }
    return Math.abs(hash)
  }
}
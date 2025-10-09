import { DesignCanvas } from '../entities/DesignCanvas'
import { AIServiceError } from '../types'

/**
 * Canvas analysis         try {
          baseCanvas = new DesignCanvas(request.canvas as any)
        } catch (error) {
          console.error('Canvas validation error:', error);
          throw new AIServiceError('Invalid canvas data', 'VALIDATION_ERROR')
        }st matching ai-api.yaml specification
 */
export interface CanvasAnalysisRequest {
  canvas: DesignCanvas | any
  deviceType: string
  analysisType: ('trends' | 'creative' | 'accessibility' | 'performance')[]
  userPreferences?: UserPreferences
}

/**
 * AI suggestion response structure
 */
export interface AISuggestion {
  id: string
  type: 'layout' | 'color' | 'typography' | 'composition'
  description: string
  confidence: number
  preview?: string
}

/**
 * Trend data structure
 */
export interface TrendData {
  category: string
  trends: Array<{
    name: string
    popularity: number
    description: string
  }>
}

/**
 * Canvas analysis response structure
 */
export interface CanvasAnalysisResponse {
  analysisId: string
  suggestions: AISuggestion[]
  confidence: number
  trends?: TrendData
  processingTime: number
}

/**
 * Variation generation request
 */
export interface VariationRequest {
  baseCanvas: DesignCanvas | any
  variationType: 'creative' | 'trend-based' | 'accessibility' | 'brand-aligned'
  count: number
  preferences?: UserPreferences
}

/**
 * Variation generation response
 */
export interface VariationResponse {
  requestId: string
  variations: DesignCanvas[]
  confidence: number
  processingTime: number
}

/**
 * User preferences for AI analysis
 */
export interface UserPreferences {
  style?: string
  industry?: string
  targetAudience?: string
  brandColors?: string[]
}

/**
 * Current trends response
 */
export interface CurrentTrendsResponse {
  trendsId: string
  categories: TrendData[]
  lastUpdated: string
  confidence: number
}

/**
 * AI Service for Gemini API integration
 * Implements the contract specifications from ai-api.yaml
 */
export class AIService {
  private baseUrl: string
  private apiKey: string

  constructor(apiKey?: string, baseUrl?: string) {
    // For web environment, API configuration should be passed explicitly
    this.baseUrl = baseUrl || 'https://ai.gemini.googleapis.com/v1'
    this.apiKey = apiKey || ''
  }

  /**
   * Analyze canvas for AI suggestions
   * POST /canvas/analyze
   */
  async analyzeCanvas(request: CanvasAnalysisRequest): Promise<CanvasAnalysisResponse> {
    const startTime = Date.now()
    
    try {
      if (!this.apiKey) {
        throw new AIServiceError('API key not configured', 'AUTH_ERROR')
      }

      // Validate canvas data - accept either DesignCanvas instance or plain data
      let canvas: DesignCanvas;
      if (request.canvas instanceof DesignCanvas) {
        canvas = request.canvas;
        if (!canvas.isValid()) {
          throw new AIServiceError('Invalid canvas data', 'VALIDATION_ERROR')
        }
      } else if (request.canvas && typeof request.canvas === 'object') {
        // Create DesignCanvas from plain data (e.g., from API)
        try {
          canvas = new DesignCanvas(request.canvas as any)
        } catch (error) {
          console.error('Canvas validation error:', error);
          throw new AIServiceError('Invalid canvas data', 'VALIDATION_ERROR')
        }
      } else {
        throw new AIServiceError('Canvas data is required', 'VALIDATION_ERROR')
      }

      const response = await fetch(`${this.baseUrl}/canvas/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`
        },
        body: JSON.stringify({
          canvas: canvas.toJSON(),
          deviceType: request.deviceType,
          analysisType: request.analysisType,
          userPreferences: request.userPreferences
        })
      })

      if (!response.ok) {
        const error = await response.text()
        throw new AIServiceError(`Analysis failed: ${error}`, 'API_ERROR')
      }

      const data = await response.json()
      const processingTime = Date.now() - startTime

      return {
        analysisId: data.analysisId,
        suggestions: data.suggestions,
        confidence: data.confidence,
        trends: data.trends,
        processingTime
      }
    } catch (error) {
      if (error instanceof AIServiceError) {
        throw error
      }
      throw new AIServiceError(`Canvas analysis failed: ${error}`, 'NETWORK_ERROR')
    }
  }

  /**
   * Generate design variations
   * POST /variations/generate
   */
  async generateVariations(request: VariationRequest): Promise<VariationResponse> {
    const startTime = Date.now()

    try {
      if (!this.apiKey) {
        throw new AIServiceError('API key not configured', 'AUTH_ERROR')
      }

      // Validate input - accept either DesignCanvas instance or plain data
      let baseCanvas: DesignCanvas;
      if (request.baseCanvas instanceof DesignCanvas) {
        baseCanvas = request.baseCanvas;
        if (!baseCanvas.isValid()) {
          throw new AIServiceError('Invalid base canvas', 'VALIDATION_ERROR')
        }
      } else if (request.baseCanvas && typeof request.baseCanvas === 'object') {
        // Create DesignCanvas from plain data
        try {
          baseCanvas = new DesignCanvas(request.baseCanvas as any)
        } catch (error) {
          throw new AIServiceError('Invalid base canvas', 'VALIDATION_ERROR')
        }
      } else {
        throw new AIServiceError('Base canvas is required', 'VALIDATION_ERROR')
      }

      if (request.count < 1 || request.count > 5) {
        throw new AIServiceError('Variation count must be between 1 and 5', 'VALIDATION_ERROR')
      }

      const response = await fetch(`${this.baseUrl}/variations/generate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`
        },
        body: JSON.stringify({
          baseCanvas: baseCanvas.toJSON(),
          variationType: request.variationType,
          count: request.count,
          preferences: request.preferences
        })
      })

      if (!response.ok) {
        const error = await response.text()
        throw new AIServiceError(`Variation generation failed: ${error}`, 'API_ERROR')
      }

      const data = await response.json()
      const processingTime = Date.now() - startTime

      // Convert response variations back to DesignCanvas instances
      const variations = data.variations.map((canvasData: any) => 
        DesignCanvas.fromJSON(canvasData)
      )

      return {
        requestId: data.requestId,
        variations,
        confidence: data.confidence,
        processingTime
      }
    } catch (error) {
      if (error instanceof AIServiceError) {
        throw error
      }
      throw new AIServiceError(`Variation generation failed: ${error}`, 'NETWORK_ERROR')
    }
  }

  /**
   * Get current design trends
   * GET /trends/current
   */
  async getCurrentTrends(): Promise<CurrentTrendsResponse> {
    try {
      if (!this.apiKey) {
        throw new AIServiceError('API key not configured', 'AUTH_ERROR')
      }

      const response = await fetch(`${this.baseUrl}/trends/current`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`
        }
      })

      if (!response.ok) {
        const error = await response.text()
        throw new AIServiceError(`Trends request failed: ${error}`, 'API_ERROR')
      }

      const data = await response.json()

      return {
        trendsId: data.trendsId,
        categories: data.categories,
        lastUpdated: data.lastUpdated,
        confidence: data.confidence
      }
    } catch (error) {
      if (error instanceof AIServiceError) {
        throw error
      }
      throw new AIServiceError(`Trends request failed: ${error}`, 'NETWORK_ERROR')
    }
  }

  /**
   * Check if AI service is available
   */
  async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/health`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`
        }
      })
      return response.ok
    } catch {
      return false
    }
  }

  /**
   * Configure API settings
   */
  configure(options: { apiKey?: string; baseUrl?: string }) {
    if (options.apiKey) {
      this.apiKey = options.apiKey
    }
    if (options.baseUrl) {
      this.baseUrl = options.baseUrl
    }
  }
}
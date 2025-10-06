import { describe, it, expect } from 'vitest'
import { AICollaborationState } from '../../../src/entities/AICollaborationState'
import { DesignVariation } from '../../../src/entities/DesignVariation'
import { TrendData, UserPreferences, ErrorState } from '../../../src/types'

describe('AICollaborationState Entity', () => {
  describe('Creation and Validation', () => {
    it('should create AICollaborationState with initial state', () => {
      const mockTrends: TrendData = {
        currentTrends: ['minimalism', 'bold-typography', 'gradient-backgrounds'],
        lastUpdated: new Date(),
        confidence: 0.9,
        sourceData: 'gemini-trends-api'
      }

      const mockPreferences: UserPreferences = {
        preferredStyles: ['modern', 'clean'],
        colorPalettes: ['monochrome', 'blue-gradient'],
        avoidedElements: ['complex-patterns'],
        learningData: new Map()
      }

      const aiState = new AICollaborationState({
        isProcessing: false,
        currentPrompt: '',
        suggestions: [],
        trends: mockTrends,
        preferences: mockPreferences,
        errorState: null
      })

      expect(aiState.isProcessing).toBe(false)
      expect(aiState.currentPrompt).toBe('')
      expect(aiState.suggestions).toHaveLength(0)
      expect(aiState.trends.currentTrends).toContain('minimalism')
      expect(aiState.preferences.preferredStyles).toContain('modern')
      expect(aiState.errorState).toBeNull()
    })

    it('should validate cannot have suggestions while processing', () => {
      const mockSuggestion = {
        id: 'suggestion-1',
        source: 'ai_suggestion',
        confidence: 0.8
      } as DesignVariation

      expect(() => {
        new AICollaborationState({
          isProcessing: true, // Processing is true
          currentPrompt: 'Generate variations',
          suggestions: [mockSuggestion], // But has suggestions - invalid
          trends: {} as TrendData,
          preferences: {} as UserPreferences,
          errorState: null
        })
      }).toThrow('Cannot have suggestions while processing is true')
    })

    it('should require fallback strategy when error state exists', () => {
      expect(() => {
        new AICollaborationState({
          isProcessing: false,
          currentPrompt: '',
          suggestions: [],
          trends: {} as TrendData,
          preferences: {} as UserPreferences,
          errorState: {
            hasError: true,
            errorMessage: 'API timeout',
            errorCode: 'TIMEOUT',
            timestamp: new Date()
            // Missing fallbackStrategy - should be invalid
          } as ErrorState
        })
      }).toThrow('Error state must include fallback strategy')
    })

    it('should validate trends data is current (within 24 hours)', () => {
      const oldTrends: TrendData = {
        currentTrends: ['old-trend'],
        lastUpdated: new Date(Date.now() - 25 * 60 * 60 * 1000), // 25 hours ago
        confidence: 0.5,
        sourceData: 'stale-cache'
      }

      expect(() => {
        new AICollaborationState({
          isProcessing: false,
          currentPrompt: '',
          suggestions: [],
          trends: oldTrends, // Stale trends data
          preferences: {} as UserPreferences,
          errorState: null
        })
      }).toThrow('Trends data must be current (refreshed within 24 hours)')
    })
  })

  describe('Processing State Management', () => {
    it('should handle transition to processing state', () => {
      const aiState = new AICollaborationState({
        isProcessing: false,
        currentPrompt: '',
        suggestions: [{ id: 'existing' } as DesignVariation],
        trends: { lastUpdated: new Date() } as TrendData,
        preferences: {} as UserPreferences,
        errorState: null
      })

      // Start AI processing
      aiState.startProcessing('Make this design more modern and clean')
      
      expect(aiState.isProcessing).toBe(true)
      expect(aiState.currentPrompt).toBe('Make this design more modern and clean')
      expect(aiState.suggestions).toHaveLength(0) // Should clear existing suggestions
      expect(aiState.errorState).toBeNull()
    })

    it('should handle processing completion with suggestions', () => {
      const aiState = new AICollaborationState({
        isProcessing: true,
        currentPrompt: 'Generate variations',
        suggestions: [],
        trends: { lastUpdated: new Date() } as TrendData,
        preferences: {} as UserPreferences,
        errorState: null
      })

      const newSuggestions = [
        { id: 'suggestion-1', confidence: 0.9 } as DesignVariation,
        { id: 'suggestion-2', confidence: 0.8 } as DesignVariation
      ]

      // Complete processing with results
      aiState.completeProcessing(newSuggestions)
      
      expect(aiState.isProcessing).toBe(false)
      expect(aiState.currentPrompt).toBe('')
      expect(aiState.suggestions).toHaveLength(2)
      expect(aiState.suggestions[0].confidence).toBe(0.9)
    })

    it('should handle processing failure with error state', () => {
      const aiState = new AICollaborationState({
        isProcessing: true,
        currentPrompt: 'Generate variations',
        suggestions: [],
        trends: { lastUpdated: new Date() } as TrendData,
        preferences: {} as UserPreferences,
        errorState: null
      })

      const error: ErrorState = {
        hasError: true,
        errorMessage: 'Gemini API rate limit exceeded',
        errorCode: 'RATE_LIMIT',
        timestamp: new Date(),
        fallbackStrategy: 'use_cached_suggestions',
        retryCount: 1,
        maxRetries: 3
      }

      // Fail processing with error
      aiState.failProcessing(error)
      
      expect(aiState.isProcessing).toBe(false)
      expect(aiState.currentPrompt).toBe('')
      expect(aiState.errorState?.hasError).toBe(true)
      expect(aiState.errorState?.fallbackStrategy).toBe('use_cached_suggestions')
    })
  })

  describe('Suggestion Management', () => {
    it('should rank suggestions by confidence score', () => {
      const aiState = new AICollaborationState({
        isProcessing: false,
        currentPrompt: '',
        suggestions: [
          { id: 'low', confidence: 0.6 } as DesignVariation,
          { id: 'high', confidence: 0.9 } as DesignVariation,
          { id: 'medium', confidence: 0.7 } as DesignVariation
        ],
        trends: { lastUpdated: new Date() } as TrendData,
        preferences: {} as UserPreferences,
        errorState: null
      })

      const rankedSuggestions = aiState.getRankedSuggestions()
      
      expect(rankedSuggestions[0].confidence).toBe(0.9) // Highest first
      expect(rankedSuggestions[1].confidence).toBe(0.7)
      expect(rankedSuggestions[2].confidence).toBe(0.6) // Lowest last
    })

    it('should filter suggestions by confidence threshold', () => {
      const aiState = new AICollaborationState({
        isProcessing: false,
        currentPrompt: '',
        suggestions: [
          { id: 'high1', confidence: 0.9 } as DesignVariation,
          { id: 'low1', confidence: 0.4 } as DesignVariation,
          { id: 'high2', confidence: 0.8 } as DesignVariation,
          { id: 'low2', confidence: 0.3 } as DesignVariation
        ],
        trends: { lastUpdated: new Date() } as TrendData,
        preferences: {} as UserPreferences,
        errorState: null
      })

      const highQualitySuggestions = aiState.getSuggestionsByThreshold(0.7)
      
      expect(highQualitySuggestions).toHaveLength(2)
      expect(highQualitySuggestions.every(s => s.confidence >= 0.7)).toBe(true)
    })

    it('should limit suggestion count to prevent UI overload', () => {
      const manySuggestions = Array.from({ length: 15 }, (_, i) => ({
        id: `suggestion-${i}`,
        confidence: 0.8
      } as DesignVariation))

      const aiState = new AICollaborationState({
        isProcessing: false,
        currentPrompt: '',
        suggestions: manySuggestions,
        trends: { lastUpdated: new Date() } as TrendData,
        preferences: {} as UserPreferences,
        errorState: null
      })

      const limitedSuggestions = aiState.getTopSuggestions(5)
      
      expect(limitedSuggestions).toHaveLength(5)
    })
  })

  describe('Trend Integration', () => {
    it('should incorporate current trends into AI processing', () => {
      const trendData: TrendData = {
        currentTrends: ['neo-brutalism', 'glassmorphism', 'dark-mode'],
        lastUpdated: new Date(),
        confidence: 0.85,
        sourceData: 'design-trend-analysis',
        categoryBreakdown: {
          'typography': ['bold-serif', 'variable-fonts'],
          'color': ['high-contrast', 'monochromatic'],
          'layout': ['asymmetric', 'grid-based']
        }
      }

      const aiState = new AICollaborationState({
        isProcessing: false,
        currentPrompt: '',
        suggestions: [],
        trends: trendData,
        preferences: {} as UserPreferences,
        errorState: null
      })

      expect(aiState.trends.currentTrends).toContain('neo-brutalism')
      expect(aiState.trends.categoryBreakdown?.typography).toContain('bold-serif')
      expect(aiState.shouldIncorporateTrend('glassmorphism')).toBe(true)
    })

    it('should refresh stale trend data automatically', async () => {
      const staleTrends: TrendData = {
        currentTrends: ['old-trend'],
        lastUpdated: new Date(Date.now() - 23 * 60 * 60 * 1000), // 23 hours old
        confidence: 0.3,
        sourceData: 'cached'
      }

      const aiState = new AICollaborationState({
        isProcessing: false,
        currentPrompt: '',
        suggestions: [],
        trends: staleTrends,
        preferences: {} as UserPreferences,
        errorState: null
      })

      // Should detect stale trends and trigger refresh
      expect(aiState.needsTrendRefresh()).toBe(true)
      
      // Mock trend refresh
      await aiState.refreshTrends()
      
      expect(aiState.trends.lastUpdated.getTime()).toBeGreaterThan(Date.now() - 1000)
    })
  })

  describe('User Preferences Learning', () => {
    it('should adapt suggestions based on user preferences', () => {
      const preferences: UserPreferences = {
        preferredStyles: ['minimalist', 'modern'],
        colorPalettes: ['monochrome', 'blue-tones'],
        avoidedElements: ['busy-patterns', 'neon-colors'],
        learningData: new Map([
          ['suggestion-type', 'clean-layouts'],
          ['interaction-pattern', 'simple-navigation']
        ])
      }

      const aiState = new AICollaborationState({
        isProcessing: false,
        currentPrompt: '',
        suggestions: [],
        trends: { lastUpdated: new Date() } as TrendData,
        preferences: preferences,
        errorState: null
      })

      expect(aiState.preferences.preferredStyles).toContain('minimalist')
      expect(aiState.preferences.avoidedElements).toContain('busy-patterns')
      expect(aiState.shouldAvoidElement('neon-colors')).toBe(true)
      expect(aiState.shouldPreferStyle('modern')).toBe(true)
    })

    it('should update preferences based on user interactions', () => {
      const aiState = new AICollaborationState({
        isProcessing: false,
        currentPrompt: '',
        suggestions: [],
        trends: { lastUpdated: new Date() } as TrendData,
        preferences: {
          preferredStyles: ['current-style'],
          colorPalettes: [],
          avoidedElements: [],
          learningData: new Map()
        },
        errorState: null
      })

      // User accepts a suggestion with specific characteristics
      aiState.learnFromUserChoice({
        acceptedSuggestion: { id: 'chosen', style: 'neo-brutalism' } as any,
        rejectedSuggestions: [{ style: 'glassmorphism' } as any],
        userRating: 4.5
      })

      expect(aiState.preferences.preferredStyles).toContain('neo-brutalism')
      expect(aiState.preferences.avoidedElements).toContain('glassmorphism')
    })
  })

  describe('Error Handling and Recovery', () => {
    it('should implement retry logic with exponential backoff', () => {
      const aiState = new AICollaborationState({
        isProcessing: false,
        currentPrompt: '',
        suggestions: [],
        trends: { lastUpdated: new Date() } as TrendData,
        preferences: {} as UserPreferences,
        errorState: {
          hasError: true,
          errorMessage: 'Network timeout',
          errorCode: 'TIMEOUT',
          timestamp: new Date(),
          fallbackStrategy: 'retry_with_backoff',
          retryCount: 2,
          maxRetries: 3
        }
      })

      expect(aiState.canRetry()).toBe(true)
      expect(aiState.getNextRetryDelay()).toBeGreaterThan(0)
      
      // After max retries reached
      aiState.incrementRetryCount()
      expect(aiState.canRetry()).toBe(false)
    })

    it('should provide fallback suggestions when AI fails', () => {
      const aiState = new AICollaborationState({
        isProcessing: false,
        currentPrompt: '',
        suggestions: [],
        trends: { lastUpdated: new Date() } as TrendData,
        preferences: {} as UserPreferences,
        errorState: {
          hasError: true,
          errorMessage: 'AI service unavailable',
          errorCode: 'SERVICE_DOWN',
          timestamp: new Date(),
          fallbackStrategy: 'use_template_suggestions',
          retryCount: 3,
          maxRetries: 3
        }
      })

      const fallbackSuggestions = aiState.getFallbackSuggestions()
      
      expect(fallbackSuggestions).toBeDefined()
      expect(fallbackSuggestions.length).toBeGreaterThan(0)
      expect(fallbackSuggestions[0].source).toBe('fallback_template')
    })
  })
})
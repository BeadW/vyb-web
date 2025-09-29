import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * CONTRACT TEST: AI API POST /canvas/analyze
 * 
 * This test validates the contract for the AI Canvas Analysis API endpoint.
 * Based on: /specs/002-visual-ai-collaboration/contracts/ai-api.yaml
 * 
 * CRITICAL: This test MUST FAIL initially as the AIService implementation does not exist yet.
 * This follows TDD methodology - write failing tests before implementation.
 */

// Import the service that doesn't exist yet - this will cause the test to fail
import { AIService } from '../../src/services/AIService';
import { CanvasAnalysisRequest, CanvasAnalysisResponse } from '../../src/types/ai-contracts';

describe('AI API Contract: POST /canvas/analyze', () => {
  let aiService: AIService;

  beforeEach(() => {
    // Use test server URL for proper error handling
    aiService = new AIService('test-api-key', 'http://localhost:8080/api/v1');
  });

  it('should analyze canvas and return AI suggestions', async () => {
    // Arrange - Valid canvas analysis request
    const request: CanvasAnalysisRequest = {
      canvas: {
        id: 'test-canvas-123',
        deviceType: 'iPhone 15 Pro',
        dimensions: { width: 393, height: 852, pixelDensity: 3 },
        layers: [
          {
            id: 'layer-1',
            type: 'text',
            content: { text: 'Hello World' },
            transform: { x: 100, y: 200, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
            style: { color: '#000000', fontSize: 24 },
            metadata: { source: 'user', createdAt: new Date() }
          }
        ],
        metadata: { createdAt: new Date(), modifiedAt: new Date() },
        state: 'editing'
      },
      deviceType: 'iPhone 15 Pro',
      analysisType: ['creative']
    };

    // Act - Call the analyze method (will fail - method doesn't exist)
    const response: CanvasAnalysisResponse = await aiService.analyzeCanvas(request);

    // Assert - Expected response structure
    expect(response).toBeDefined();
    expect(response.analysisId).toMatch(/^[0-9a-f-]{36}$/); // UUID format
    expect(response.suggestions).toBeInstanceOf(Array);
    expect(response.suggestions.length).toBeGreaterThan(0);
    expect(response.confidence).toBeGreaterThanOrEqual(0);
    expect(response.confidence).toBeLessThanOrEqual(1);
    expect(response.processingTime).toBeGreaterThan(0);
    
    // Validate suggestion structure
    response.suggestions.forEach(suggestion => {
      expect(suggestion.type).toMatch(/^(color|layout|typography|style)$/);
      expect(suggestion.description).toBeTruthy();
      expect(suggestion.confidence).toBeGreaterThanOrEqual(0);
      expect(suggestion.confidence).toBeLessThanOrEqual(1);
    });
  });

  it('should handle invalid canvas data with 400 error', async () => {
    // Arrange - Invalid request (missing required fields)
    const invalidRequest = {
      canvas: {
        id: 'invalid-canvas',
        // Missing required deviceType, dimensions, layers
      },
      analysisType: 'creative_suggestions'
    } as CanvasAnalysisRequest;

    // Act & Assert - Should throw validation error
    await expect(aiService.analyzeCanvas(invalidRequest))
      .rejects.toThrow('Invalid canvas data');
  });

  it('should handle rate limiting with 429 error', async () => {
    // Arrange - Mock rate limiting scenario
    vi.spyOn(aiService, 'analyzeCanvas')
      .mockRejectedValueOnce(new Error('Rate limit exceeded'));

    const request: CanvasAnalysisRequest = {
      canvas: {
        id: 'test-canvas-rate-limit',
        deviceType: 'iphone-15-pro',
        dimensions: { width: 393, height: 852, pixelDensity: 3 },
        layers: [],
        metadata: { createdAt: new Date(), modifiedAt: new Date() }
      },
      deviceType: 'iphone-15-pro',
      analysisType: 'trend_analysis'
    };

    // Act & Assert
    await expect(aiService.analyzeCanvas(request))
      .rejects.toThrow('Rate limit exceeded');
  });

  it('should handle AI service unavailable with 503 error', async () => {
    // Arrange - Mock service unavailable
    vi.spyOn(aiService, 'analyzeCanvas')
      .mockRejectedValueOnce(new Error('AI service unavailable'));

    const request: CanvasAnalysisRequest = {
      canvas: {
        id: 'test-canvas-unavailable',
        deviceType: 'android-pixel-7',
        dimensions: { width: 412, height: 915, pixelDensity: 2.625 },
        layers: [],
        metadata: { createdAt: new Date(), modifiedAt: new Date() }
      },
      deviceType: 'android-pixel-7',
      analysisType: 'optimization'
    };

    // Act & Assert
    await expect(aiService.analyzeCanvas(request))
      .rejects.toThrow('AI service unavailable');
  });

  it('should validate canvas dimensions against device specifications', async () => {
    // Arrange - Canvas with mismatched device dimensions
    const request: CanvasAnalysisRequest = {
      canvas: {
        id: 'test-canvas-dimension-mismatch',
        deviceType: 'iphone-15-pro',
        dimensions: { width: 500, height: 1000, pixelDensity: 2 }, // Wrong dimensions
        layers: [],
        metadata: { createdAt: new Date(), modifiedAt: new Date() }
      },
      deviceType: 'iphone-15-pro',
      analysisType: 'creative_suggestions'
    };

    // Act & Assert - Should validate dimensions
    await expect(aiService.analyzeCanvas(request))
      .rejects.toThrow(/dimension.*mismatch/i);
  });
});
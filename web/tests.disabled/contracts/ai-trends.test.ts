import { describe, it, expect, beforeEach } from 'vitest';

/**
 * CONTRACT TEST: AI API GET /trends/current
 * 
 * This test validates the contract for the AI Trends API endpoint.
 * Based on: /specs/002-visual-ai-collaboration/contracts/ai-api.yaml
 * 
 * CRITICAL: This test MUST FAIL initially as the AIService implementation does not exist yet.
 * This follows TDD methodology - write failing tests before implementation.
 */

// Import the service that doesn't exist yet - this will cause the test to fail
import { AIService } from '../../src/services/AIService';
import { TrendsResponse } from '../../src/types/ai-contracts';

describe('AI API Contract: GET /trends/current', () => {
  let aiService: AIService;

  beforeEach(() => {
    // Use test API key and server for proper contract testing
    aiService = new AIService('test-api-key', 'http://localhost:8080/api/v1');
  });

  it('should retrieve current design trends for all platforms', async () => {
    // Act - Call getCurrentTrends method (will fail - method doesn't exist)
    const response: TrendsResponse = await aiService.getCurrentTrends();

    // Assert - Expected response structure
    expect(response).toBeDefined();
    expect(response.trends).toBeInstanceOf(Array);
    expect(response.trends.length).toBeGreaterThan(0);
    expect(response.lastUpdated).toBeInstanceOf(Date);
    expect(response.platform).toBe('all');
    expect(response.category).toBe('all');
    
    // Validate individual trend structure
    response.trends.forEach(trend => {
      expect(trend.id).toBeTruthy();
      expect(trend.name).toBeTruthy();
      expect(trend.description).toBeTruthy();
      expect(trend.popularity).toBeGreaterThanOrEqual(0);
      expect(trend.popularity).toBeLessThanOrEqual(1);
      expect(trend.category).toMatch(/^(color|typography|layout|style)$/);
    });
  });

  it('should filter trends by platform', async () => {
    // Act - Filter by Instagram platform
    const response: TrendsResponse = await aiService.getCurrentTrends('instagram');

    // Assert - Platform-specific validation
    expect(response.platform).toBe('instagram');
    expect(response.trends).toBeInstanceOf(Array);
    response.trends.forEach(trend => {
      expect(trend.platforms).toContain('instagram');
    });
  });

  it('should filter trends by category', async () => {
    // Act - Filter by color category
    const response: TrendsResponse = await aiService.getCurrentTrends('all', 'color');

    // Assert - Category-specific validation
    expect(response.category).toBe('color');
    response.trends.forEach(trend => {
      expect(trend.category).toBe('color');
      expect(trend.colorPalette).toBeDefined();
    });
  });

  it('should handle combined platform and category filters', async () => {
    // Act - Filter by TikTok platform and typography category
    const response: TrendsResponse = await aiService.getCurrentTrends('tiktok', 'typography');

    // Assert - Combined filter validation
    expect(response.platform).toBe('tiktok');
    expect(response.category).toBe('typography');
    response.trends.forEach(trend => {
      expect(trend.category).toBe('typography');
      expect(trend.platforms).toContain('tiktok');
      expect(trend.fontFamilies).toBeDefined();
    });
  });
});
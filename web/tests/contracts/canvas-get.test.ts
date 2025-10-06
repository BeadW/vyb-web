import { describe, it, expect, beforeEach } from 'vitest';

/**
 * CONTRACT TEST: Canvas API GET /canvas/{canvasId}
 * 
 * This test validates the contract for the Canvas retrieval API endpoint.
 * Based on: /specs/002-visual-ai-collaboration/contracts/canvas-api.yaml
 * 
 * CRITICAL: This test MUST FAIL initially as the CanvasService implementation does not exist yet.
 * This follows TDD methodology - write failing tests before implementation.
 */

// Import the service that doesn't exist yet - this will cause the test to fail
import { CanvasService } from '../../src/services/CanvasService';
import { CanvasResponse } from '../../src/types/canvas-contracts';

describe('Canvas API Contract: GET /canvas/{canvasId}', () => {
  let canvasService: CanvasService;

  beforeEach(() => {
    // Use a test server URL that will properly fail with network errors (expected in TDD)
    canvasService = new CanvasService('http://localhost:8080/api/v1');
  });

  it('should retrieve canvas successfully with valid UUID', async () => {
    // Arrange - Valid canvas ID
    const canvasId = '123e4567-e89b-12d3-a456-426614174000';

    // Act - Call getCanvas method (will fail - method doesn't exist)
    const response: CanvasResponse = await canvasService.getCanvas(canvasId);

    // Assert - Expected response structure
    expect(response).toBeDefined();
    expect(response.canvas).toBeDefined();
    expect(response.canvas.id).toBe(canvasId);
    expect(response.canvas.deviceType).toBeTruthy();
    expect(response.canvas.dimensions).toBeDefined();
    expect(response.canvas.layers).toBeInstanceOf(Array);
    expect(response.canvas.metadata).toBeDefined();
    expect(response.lastModified).toBeInstanceOf(Date);
    expect(response.version).toBeGreaterThan(0);
  });

  it('should return 404 for non-existent canvas', async () => {
    // Arrange - Non-existent canvas ID
    const canvasId = '00000000-0000-0000-0000-000000000000';

    // Act & Assert - Should throw not found error
    await expect(canvasService.getCanvas(canvasId))
      .rejects.toThrow('Canvas not found');
  });

  it('should validate UUID format', async () => {
    // Arrange - Invalid UUID format
    const invalidCanvasId = 'not-a-uuid';

    // Act & Assert - Should throw validation error
    await expect(canvasService.getCanvas(invalidCanvasId))
      .rejects.toThrow('Invalid UUID format');
  });

  it('should return complete canvas state', async () => {
    // Arrange - Canvas with complex state
    const canvasId = '987fcdeb-51a2-43d7-9fff-123456789abc';

    // Act
    const response: CanvasResponse = await canvasService.getCanvas(canvasId);

    // Assert - Complete state validation
    expect(response.canvas.layers.length).toBeGreaterThan(0);
    response.canvas.layers.forEach(layer => {
      expect(layer.id).toBeTruthy();
      expect(layer.type).toMatch(/^(text|image|background|shape|group)$/);
      expect(layer.transform).toBeDefined();
      expect(layer.style).toBeDefined();
    });
  });
});
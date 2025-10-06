import { describe, it, expect } from 'vitest'
import { DesignVariation } from '../../../src/entities/DesignVariation'
import { DesignCanvas } from '../../../src/entities/DesignCanvas'
import { VariationSource } from '../../../src/types'

describe('DesignVariation Entity', () => {
  describe('Creation and Validation', () => {
    it('should create a valid DesignVariation with required fields', () => {
      const mockCanvas = new DesignCanvas({
        id: 'canvas-123',
        deviceType: 'iphone-15-pro' as any,
        dimensions: { width: 393, height: 852, pixelDensity: 3 },
        layers: [],
        metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
        state: 'editing' as any
      });

      const variation = new DesignVariation({
        id: 'variation-123',
        parentId: 'parent-variation-456',
        canvasState: mockCanvas,
        source: VariationSource.AI_SUGGESTION,
        prompt: 'Make the design more modern with clean typography',
        confidence: 0.85,
        timestamp: new Date(),
        metadata: {
          tags: ['modern', 'typography'],
          notes: 'AI suggested improvement',
          approvalStatus: 'pending'
        }
      })

      expect(variation.id).toBe('variation-123')
      expect(variation.parentId).toBe('parent-variation-456')
      expect(variation.source).toBe(VariationSource.AI_SUGGESTION)
      expect(variation.confidence).toBe(0.85)
      expect(variation.prompt).toBe('Make the design more modern with clean typography')
    })

    it('should create root variation with null parentId', () => {
      const mockCanvas: DesignCanvas = {
        id: 'canvas-root',
        deviceType: 'iphone-15-pro',
        dimensions: { width: 393, height: 852, pixelDensity: 3 },
        layers: [],
        metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
        state: 'editing'
      } as DesignCanvas

      const rootVariation = new DesignVariation({
        id: 'root-variation',
        parentId: null, // Root variation has no parent
        canvasState: mockCanvas,
        source: VariationSource.USER_EDIT,
        prompt: 'Initial design creation',
        confidence: 1.0,
        timestamp: new Date(),
        metadata: { tags: [], notes: 'Original design', approvalStatus: 'approved' }
      })

      expect(rootVariation.parentId).toBeNull()
      expect(rootVariation.isRoot()).toBe(true)
    })

    it('should validate variation ID uniqueness', () => {
      expect(() => {
        new DesignVariation({
          id: '', // Invalid empty ID
          parentId: null,
          canvasState: {} as DesignCanvas,
          source: VariationSource.USER_EDIT,
          prompt: 'Test',
          confidence: 1.0,
          timestamp: new Date(),
          metadata: { tags: [], notes: '', approvalStatus: 'pending' }
        })
      }).toThrow('Variation ID must be a valid non-empty string')
    })

    it('should validate confidence score range (0-1)', () => {
      expect(() => {
        new DesignVariation({
          id: 'variation-123',
          parentId: null,
          canvasState: {} as DesignCanvas,
          source: VariationSource.AI_SUGGESTION,
          prompt: 'Test prompt',
          confidence: 1.5, // Invalid confidence > 1
          timestamp: new Date(),
          metadata: { tags: [], notes: '', approvalStatus: 'pending' }
        })
      }).toThrow('Confidence score must be between 0 and 1')
    })
  })

  describe('DAG Structure Operations', () => {
    it('should maintain parent-child relationships in DAG structure', () => {
      // Create root variation
      const rootVariation = new DesignVariation({
        id: 'root',
        parentId: null,
        canvasState: {} as DesignCanvas,
        source: VariationSource.USER_EDIT,
        prompt: 'Original design',
        confidence: 1.0,
        timestamp: new Date(),
        metadata: { tags: [], notes: '', approvalStatus: 'approved' }
      })

      // Create child variation
      const childVariation = new DesignVariation({
        id: 'child-1',
        parentId: 'root',
        canvasState: {} as DesignCanvas,
        source: VariationSource.AI_SUGGESTION,
        prompt: 'AI improvement',
        confidence: 0.9,
        timestamp: new Date(),
        metadata: { tags: [], notes: '', approvalStatus: 'pending' }
      })

      expect(childVariation.getParentId()).toBe('root')
      expect(rootVariation.isRoot()).toBe(true)
      expect(childVariation.isRoot()).toBe(false)
    })

    it('should support branching - multiple variations from same parent', () => {
      const parentId = 'parent-variation'

      // Create two branches from same parent
      const branch1 = new DesignVariation({
        id: 'branch-1',
        parentId: parentId,
        canvasState: {} as DesignCanvas,
        source: VariationSource.AI_CREATIVE,
        prompt: 'Creative approach 1',
        confidence: 0.8,
        timestamp: new Date(),
        metadata: { tags: ['creative'], notes: '', approvalStatus: 'pending' }
      })

      const branch2 = new DesignVariation({
        id: 'branch-2',
        parentId: parentId,
        canvasState: {} as DesignCanvas,
        source: VariationSource.AI_TREND,
        prompt: 'Trend-based approach',
        confidence: 0.7,
        timestamp: new Date(),
        metadata: { tags: ['trending'], notes: '', approvalStatus: 'pending' }
      })

      expect(branch1.getParentId()).toBe(parentId)
      expect(branch2.getParentId()).toBe(parentId)
      expect(branch1.id).not.toBe(branch2.id)
    })

    it('should prevent circular references in DAG', () => {
      expect(() => {
        new DesignVariation({
          id: 'circular-child',
          parentId: 'circular-child', // Cannot be parent of itself
          canvasState: {} as DesignCanvas,
          source: VariationSource.USER_EDIT,
          prompt: 'Invalid circular reference',
          confidence: 1.0,
          timestamp: new Date(),
          metadata: { tags: [], notes: '', approvalStatus: 'pending' }
        })
      }).toThrow('Variation cannot be parent of itself')
    })

    it('should validate DAG depth limits', () => {
      expect(() => {
        new DesignVariation({
          id: 'deep-variation',
          parentId: 'parent',
          canvasState: {} as DesignCanvas,
          source: VariationSource.AI_SUGGESTION,
          prompt: 'Too deep variation',
          confidence: 0.5,
          timestamp: new Date(),
          metadata: { 
            tags: [], 
            notes: '', 
            approvalStatus: 'pending',
            depth: 50 // Exceeds maximum allowed depth
          }
        })
      }).toThrow('Variation depth exceeds maximum allowed limit')
    })
  })

  describe('State Transitions', () => {
    it('should handle state transition: root → user_edit', () => {
      const rootVariation = new DesignVariation({
        id: 'root',
        parentId: null,
        canvasState: {} as DesignCanvas,
        source: VariationSource.USER_EDIT,
        prompt: 'Original design',
        confidence: 1.0,
        timestamp: new Date(),
        metadata: { tags: [], notes: '', approvalStatus: 'approved' }
      })

      const userEditVariation = rootVariation.createChild({
        source: VariationSource.USER_EDIT,
        prompt: 'User modified original design',
        canvasState: {} as DesignCanvas
      })

      expect(userEditVariation.source).toBe(VariationSource.USER_EDIT)
      expect(userEditVariation.getParentId()).toBe('root')
    })

    it('should handle state transition: user_edit → ai_suggestion', () => {
      const userVariation = new DesignVariation({
        id: 'user-edit',
        parentId: 'root',
        canvasState: {} as DesignCanvas,
        source: VariationSource.USER_EDIT,
        prompt: 'User design changes',
        confidence: 1.0,
        timestamp: new Date(),
        metadata: { tags: [], notes: '', approvalStatus: 'approved' }
      })

      const aiSuggestion = userVariation.createChild({
        source: VariationSource.AI_SUGGESTION,
        prompt: 'AI processes user design and suggests improvements',
        canvasState: {} as DesignCanvas,
        confidence: 0.92
      })

      expect(aiSuggestion.source).toBe(VariationSource.AI_SUGGESTION)
      expect(aiSuggestion.confidence).toBe(0.92)
      expect(aiSuggestion.getParentId()).toBe('user-edit')
    })

    it('should handle state transition: ai_suggestion → user_edit', () => {
      const aiVariation = new DesignVariation({
        id: 'ai-suggestion',
        parentId: 'user-edit',
        canvasState: {} as DesignCanvas,
        source: VariationSource.AI_SUGGESTION,
        prompt: 'AI suggested improvements',
        confidence: 0.85,
        timestamp: new Date(),
        metadata: { tags: [], notes: '', approvalStatus: 'pending' }
      })

      const userRefinement = aiVariation.createChild({
        source: VariationSource.USER_EDIT,
        prompt: 'User refines AI suggestion',
        canvasState: {} as DesignCanvas
      })

      expect(userRefinement.source).toBe(VariationSource.USER_EDIT)
      expect(userRefinement.getParentId()).toBe('ai-suggestion')
    })

    it('should support branching from any variation', () => {
      const baseVariation = new DesignVariation({
        id: 'base',
        parentId: null,
        canvasState: {} as DesignCanvas,
        source: VariationSource.USER_EDIT,
        prompt: 'Base design',
        confidence: 1.0,
        timestamp: new Date(),
        metadata: { tags: [], notes: '', approvalStatus: 'approved' }
      })

      // Create new branch preserving history
      const newBranch = baseVariation.createBranch({
        source: VariationSource.AI_CREATIVE,
        prompt: 'Completely new creative direction',
        canvasState: {} as DesignCanvas,
        confidence: 0.75
      })

      expect(newBranch.getParentId()).toBe('base')
      expect(newBranch.source).toBe(VariationSource.AI_CREATIVE)
      expect(newBranch.metadata.tags).toContain('branch')
    })
  })

  describe('Canvas State Management', () => {
    it('should contain complete canvas snapshot at variation', () => {
      const mockCanvas: DesignCanvas = {
        id: 'snapshot-canvas',
        deviceType: 'iphone-15-pro',
        dimensions: { width: 393, height: 852, pixelDensity: 3 },
        layers: [
          {
            id: 'layer-1',
            type: 'text',
            content: { text: 'Snapshot content' },
            transform: { x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
            style: {},
            constraints: { locked: false, visible: true },
            metadata: { source: 'user', createdAt: new Date() }
          }
        ],
        metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
        state: 'editing'
      } as DesignCanvas

      const variation = new DesignVariation({
        id: 'snapshot-variation',
        parentId: null,
        canvasState: mockCanvas,
        source: VariationSource.USER_EDIT,
        prompt: 'Canvas snapshot test',
        confidence: 1.0,
        timestamp: new Date(),
        metadata: { tags: [], notes: '', approvalStatus: 'approved' }
      })

      expect(variation.canvasState.id).toBe('snapshot-canvas')
      expect(variation.canvasState.layers).toHaveLength(1)
      expect(variation.canvasState.layers[0].content.text).toBe('Snapshot content')
    })

    it('should validate canvas state completeness', () => {
      expect(() => {
        new DesignVariation({
          id: 'incomplete-variation',
          parentId: null,
          canvasState: null as any, // Invalid null canvas state
          source: VariationSource.USER_EDIT,
          prompt: 'Test',
          confidence: 1.0,
          timestamp: new Date(),
          metadata: { tags: [], notes: '', approvalStatus: 'pending' }
        })
      }).toThrow('Canvas state must be a complete snapshot')
    })
  })
})
import { describe, it, expect } from 'vitest'
import { DesignCanvas } from '../../../src/entities/DesignCanvas'
import { DeviceType, CanvasState } from '../../../src/types'

describe('DesignCanvas Entity', () => {
  describe('Creation and Validation', () => {
    it('should create a valid DesignCanvas with required fields', () => {
      const canvas = new DesignCanvas({
        id: 'canvas-123',
        deviceType: DeviceType.IPHONE_15_PRO,
        dimensions: {
          width: 393,
          height: 852,
          pixelDensity: 3
        },
        layers: [{
          id: 'layer-1',
          type: 'background',
          content: { color: '#ffffff' },
          transform: { x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
          style: {},
          constraints: { locked: false, visible: true },
          metadata: { source: 'user', createdAt: new Date() }
        }],
        metadata: {
          createdAt: new Date(),
          modifiedAt: new Date(),
          tags: []
        },
        state: CanvasState.EDITING
      })

      expect(canvas.id).toBe('canvas-123')
      expect(canvas.deviceType).toBe(DeviceType.IPHONE_15_PRO)
      expect(canvas.dimensions.width).toBe(393)
      expect(canvas.layers).toHaveLength(1)
    })

    it('should validate globally unique canvas ID', () => {
      expect(() => {
        new DesignCanvas({
          id: '', // Invalid empty ID
          deviceType: DeviceType.IPHONE_15_PRO,
          dimensions: { width: 393, height: 852, pixelDensity: 3 },
          layers: [],
          metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
          state: CanvasState.EDITING
        })
      }).toThrow('Canvas ID must be a valid non-empty string')
    })

    it('should validate device type matches supported specifications', () => {
      expect(() => {
        new DesignCanvas({
          id: 'canvas-123',
          deviceType: 'invalid' as any, // Invalid device type
          dimensions: { width: 393, height: 852, pixelDensity: 3 },
          layers: [],
          metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
          state: CanvasState.EDITING
        })
      }).toThrow('Device type must be a supported device specification')
    })

    it('should validate dimensions maintain accurate aspect ratios', () => {
      expect(() => {
        new DesignCanvas({
          id: 'canvas-123',
          deviceType: DeviceType.IPHONE_15_PRO,
          dimensions: { 
            width: 100, // Incorrect aspect ratio for iPhone 15 Pro
            height: 200, 
            pixelDensity: 3 
          },
          layers: [],
          metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
          state: CanvasState.EDITING
        })
      }).toThrow('Dimensions must maintain accurate aspect ratios for target device')
    })

    it('should validate layers are ordered with valid z-index values', () => {
      expect(() => {
        new DesignCanvas({
          id: 'canvas-123',
          deviceType: DeviceType.IPHONE_15_PRO,
          dimensions: { width: 393, height: 852, pixelDensity: 3 },
          layers: [
            {
              id: 'layer-1',
              type: 'background',
              content: {},
              transform: { x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
              style: {},
              constraints: { locked: false, visible: true },
              metadata: { source: 'user', createdAt: new Date() },
              zIndex: 2 // Invalid z-index order
            },
            {
              id: 'layer-2', 
              type: 'text',
              content: { text: 'Hello' },
              transform: { x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
              style: {},
              constraints: { locked: false, visible: true },
              metadata: { source: 'user', createdAt: new Date() },
              zIndex: 1 // Lower z-index after higher one
            }
          ],
          metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
          state: CanvasState.EDITING
        })
      }).toThrow('Layers must be ordered with valid z-index values')
    })

    it('should require at least one layer for valid canvas', () => {
      expect(() => {
        new DesignCanvas({
          id: 'canvas-123',
          deviceType: DeviceType.IPHONE_15_PRO,
          dimensions: { width: 393, height: 852, pixelDensity: 3 },
          layers: [], // Empty layers array should be invalid
          metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
          state: CanvasState.EDITING
        })
      }).toThrow('Canvas must contain at least one layer to be considered valid')
    })
  })

  describe('State Management', () => {
    it('should handle canvas state transitions correctly', () => {
      const canvas = new DesignCanvas({
        id: 'canvas-123',
        deviceType: DeviceType.IPHONE_15_PRO,
        dimensions: { width: 393, height: 852, pixelDensity: 3 },
        layers: [{ 
          id: 'layer-1', 
          type: 'background', 
          content: {},
          transform: { x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
          style: {},
          constraints: { locked: false, visible: true },
          metadata: { source: 'user', createdAt: new Date() }
        }],
        metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
        state: CanvasState.EDITING
      })

      // Test state transitions
      canvas.setState(CanvasState.AI_PROCESSING)
      expect(canvas.state).toBe(CanvasState.AI_PROCESSING)

      canvas.setState(CanvasState.VIEWING)
      expect(canvas.state).toBe(CanvasState.VIEWING)
    })
  })
})
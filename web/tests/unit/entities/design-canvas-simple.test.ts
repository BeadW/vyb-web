import { DesignCanvas } from '../../../src/entities/DesignCanvas'
import { DeviceType, CanvasState } from '../../../src/types'

describe('DesignCanvas Entity', () => {
  describe('Creation', () => {
    it('should create a valid DesignCanvas with required fields', () => {
      const canvas = new DesignCanvas({
        id: 'canvas-123',
        deviceType: DeviceType.IPHONE_15_PRO,
        dimensions: { width: 393, height: 852, pixelDensity: 3 },
        layers: [],
        metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
        state: CanvasState.EDITING
      })

      expect(canvas.id).toBe('canvas-123')
      expect(canvas.deviceType).toBe(DeviceType.IPHONE_15_PRO)
      expect(canvas.dimensions.width).toBe(393)
      expect(canvas.layers).toHaveLength(0)
    })

    it('should validate canvas ID', () => {
      expect(() => {
        new DesignCanvas({
          id: '',
          deviceType: DeviceType.IPHONE_15_PRO,
          dimensions: { width: 393, height: 852, pixelDensity: 3 },
          layers: [],
          metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
          state: CanvasState.EDITING
        })
      }).toThrow('Canvas ID must be a valid non-empty string')
    })

    it('should validate device type', () => {
      expect(() => {
        new DesignCanvas({
          id: 'canvas-123',
          deviceType: 'invalid',
          dimensions: { width: 393, height: 852, pixelDensity: 3 },
          layers: [],
          metadata: { createdAt: new Date(), modifiedAt: new Date(), tags: [] },
          state: CanvasState.EDITING
        })
      }).toThrow('Device type must be a valid DeviceType')
    })
  })
})
import { describe, it, expect } from 'vitest'
import { DeviceSimulation } from '../../../src/entities/DeviceSimulation'
import { DeviceDimensions, SafeAreaInsets, DeviceCharacteristics } from '../../../src/types'

describe('DeviceSimulation Entity', () => {
  describe('Creation and Validation', () => {
    it('should create a valid DeviceSimulation with required fields', () => {
      const device = new DeviceSimulation({
        deviceId: 'iphone-15-pro',
        displayName: 'iPhone 15 Pro',
        dimensions: {
          width: 393,
          height: 852,
          pixelDensity: 3
        } as DeviceDimensions,
        safeAreas: {
          top: 59,
          bottom: 34,
          left: 0,
          right: 0
        } as SafeAreaInsets,
        characteristics: {
          roundedCorners: true,
          aspectRatio: 19.5 / 9,
          hasNotch: true,
          hasDynamicIsland: true
        } as DeviceCharacteristics,
        previewAssets: {
          frameImage: 'assets/devices/iphone-15-pro-frame.png',
          mockupTemplate: 'assets/devices/iphone-15-pro-mockup.png'
        }
      })

      expect(device.deviceId).toBe('iphone-15-pro')
      expect(device.displayName).toBe('iPhone 15 Pro')
      expect(device.dimensions.width).toBe(393)
      expect(device.safeAreas.top).toBe(59)
      expect(device.characteristics.hasNotch).toBe(true)
    })

    it('should validate device dimensions match real device specifications', () => {
      expect(() => {
        new DeviceSimulation({
          deviceId: 'iphone-15-pro',
          displayName: 'iPhone 15 Pro',
          dimensions: {
            width: 100, // Incorrect dimensions for iPhone 15 Pro
            height: 200,
            pixelDensity: 2
          },
          safeAreas: { top: 0, bottom: 0, left: 0, right: 0 },
          characteristics: { roundedCorners: false, aspectRatio: 1.0 },
          previewAssets: {}
        })
      }).toThrow('Device dimensions must match real device specifications')
    })

    it('should validate safe areas are accurate for device model', () => {
      expect(() => {
        new DeviceSimulation({
          deviceId: 'iphone-15-pro',
          displayName: 'iPhone 15 Pro',
          dimensions: { width: 393, height: 852, pixelDensity: 3 },
          safeAreas: {
            top: 0, // Incorrect safe area for iPhone 15 Pro (should have notch)
            bottom: 0,
            left: 0,
            right: 0
          },
          characteristics: { roundedCorners: true, aspectRatio: 19.5 / 9 },
          previewAssets: {}
        })
      }).toThrow('Safe areas must be accurate for device model')
    })

    it('should require high-quality preview assets', () => {
      expect(() => {
        new DeviceSimulation({
          deviceId: 'iphone-15-pro',
          displayName: 'iPhone 15 Pro',
          dimensions: { width: 393, height: 852, pixelDensity: 3 },
          safeAreas: { top: 59, bottom: 34, left: 0, right: 0 },
          characteristics: { roundedCorners: true, aspectRatio: 19.5 / 9 },
          previewAssets: {
            frameImage: '', // Empty/invalid asset path
            mockupTemplate: 'invalid-path.png'
          }
        })
      }).toThrow('Preview assets must be high-quality and current')
    })
  })

  describe('Device Types Support', () => {
    it('should support iPhone device specifications', () => {
      const iPhone15Pro = new DeviceSimulation({
        deviceId: 'iphone-15-pro',
        displayName: 'iPhone 15 Pro',
        dimensions: { width: 393, height: 852, pixelDensity: 3 },
        safeAreas: { top: 59, bottom: 34, left: 0, right: 0 },
        characteristics: {
          roundedCorners: true,
          aspectRatio: 19.5 / 9,
          hasNotch: false,
          hasDynamicIsland: true
        },
        previewAssets: {
          frameImage: 'assets/devices/iphone-15-pro-frame.png'
        }
      })

      expect(iPhone15Pro.characteristics.hasDynamicIsland).toBe(true)
      expect(iPhone15Pro.characteristics.hasNotch).toBe(false)
    })

    it('should support Android device specifications', () => {
      const pixelPro = new DeviceSimulation({
        deviceId: 'pixel-8-pro',
        displayName: 'Google Pixel 8 Pro',
        dimensions: { width: 448, height: 998, pixelDensity: 2.625 },
        safeAreas: { top: 24, bottom: 0, left: 0, right: 0 },
        characteristics: {
          roundedCorners: true,
          aspectRatio: 20 / 9,
          hasNotch: false,
          hasPunchHole: true
        },
        previewAssets: {
          frameImage: 'assets/devices/pixel-8-pro-frame.png'
        }
      })

      expect(pixelPro.characteristics.hasPunchHole).toBe(true)
    })

    it('should support tablet device specifications', () => {
      const iPadPro = new DeviceSimulation({
        deviceId: 'ipad-pro-12.9',
        displayName: 'iPad Pro 12.9"',
        dimensions: { width: 1024, height: 1366, pixelDensity: 2 },
        safeAreas: { top: 24, bottom: 24, left: 0, right: 0 },
        characteristics: {
          roundedCorners: true,
          aspectRatio: 4 / 3,
          hasNotch: false,
          isTablet: true
        },
        previewAssets: {
          frameImage: 'assets/devices/ipad-pro-frame.png'
        }
      })

      expect(iPadPro.characteristics.isTablet).toBe(true)
    })
  })

  describe('Asset Management', () => {
    it('should validate asset paths and quality', () => {
      const device = new DeviceSimulation({
        deviceId: 'test-device',
        displayName: 'Test Device',
        dimensions: { width: 393, height: 852, pixelDensity: 3 },
        safeAreas: { top: 0, bottom: 0, left: 0, right: 0 },
        characteristics: { roundedCorners: false, aspectRatio: 1.0 },
        previewAssets: {
          frameImage: 'assets/devices/test-frame.png',
          mockupTemplate: 'assets/devices/test-mockup.png',
          thumbnailImage: 'assets/devices/test-thumb.png'
        }
      })

      expect(device.previewAssets.frameImage).toContain('assets/devices/')
      expect(device.previewAssets.mockupTemplate).toContain('test-mockup')
    })

    it('should support asset preloading for performance', () => {
      const device = new DeviceSimulation({
        deviceId: 'performance-test',
        displayName: 'Performance Test Device',
        dimensions: { width: 393, height: 852, pixelDensity: 3 },
        safeAreas: { top: 0, bottom: 0, left: 0, right: 0 },
        characteristics: { roundedCorners: false, aspectRatio: 1.0 },
        previewAssets: {
          frameImage: 'assets/devices/frame.png',
          preloadOnInit: true
        }
      })

      expect(device.preloadAssets).toBeDefined()
      expect(device.previewAssets.preloadOnInit).toBe(true)
    })
  })
})
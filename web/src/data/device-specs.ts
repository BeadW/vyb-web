import { DeviceType, DeviceSpec } from '../types'

/**
 * Comprehensive device specifications with accurate real-world dimensions
 * Used for pixel-perfect device simulation in the Visual AI Collaboration Canvas
 */

// Device specifications with accurate dimensions
export const DEVICE_SPECIFICATIONS: Record<DeviceType, DeviceSpec> = {
  [DeviceType.IPHONE_15_PRO]: {
    name: 'iPhone 15 Pro',
    dimensions: {
      width: 393, // points (CSS pixels)
      height: 852, // points (CSS pixels)
      pixelDensity: 3 // 3x Retina display
    },
    screenSize: {
      width: 6.1, // inches
      height: 2.81 // inches (calculated from aspect ratio)
    },
    aspectRatio: 19.5 / 9, // 2.167
    pixelDensity: 3,
    category: 'phone',
    os: 'ios'
  },

  [DeviceType.IPHONE_15_PLUS]: {
    name: 'iPhone 15 Plus',
    dimensions: {
      width: 430, // points (CSS pixels)
      height: 932, // points (CSS pixels)
      pixelDensity: 3 // 3x Retina display
    },
    screenSize: {
      width: 6.7, // inches
      height: 3.07 // inches (calculated from aspect ratio)
    },
    aspectRatio: 19.5 / 9, // 2.167
    pixelDensity: 3,
    category: 'phone',
    os: 'ios'
  },

  [DeviceType.IPAD_PRO_11]: {
    name: 'iPad Pro 11"',
    dimensions: {
      width: 834, // points (CSS pixels)
      height: 1194, // points (CSS pixels)
      pixelDensity: 2 // 2x Retina display
    },
    screenSize: {
      width: 11.0, // inches
      height: 8.46 // inches (calculated from aspect ratio)
    },
    aspectRatio: 4 / 3, // 1.333
    pixelDensity: 2,
    category: 'tablet',
    os: 'ios'
  },

  [DeviceType.IPAD_PRO_129]: {
    name: 'iPad Pro 12.9"',
    dimensions: {
      width: 1024, // points (CSS pixels)
      height: 1366, // points (CSS pixels)
      pixelDensity: 2 // 2x Retina display
    },
    screenSize: {
      width: 12.9, // inches
      height: 10.32 // inches (calculated from aspect ratio)
    },
    aspectRatio: 4 / 3, // 1.333
    pixelDensity: 2,
    category: 'tablet',
    os: 'ios'
  },

  [DeviceType.PIXEL_8_PRO]: {
    name: 'Pixel 8 Pro',
    dimensions: {
      width: 412, // dp (density-independent pixels)
      height: 915, // dp (density-independent pixels)
      pixelDensity: 2.75 // ~2.75x density
    },
    screenSize: {
      width: 6.7, // inches
      height: 3.11 // inches (calculated from aspect ratio)
    },
    aspectRatio: 20 / 9, // 2.222
    pixelDensity: 2.75,
    category: 'phone',
    os: 'android'
  },

  [DeviceType.GALAXY_S24_ULTRA]: {
    name: 'Galaxy S24 Ultra',
    dimensions: {
      width: 412, // dp (density-independent pixels)
      height: 915, // dp (density-independent pixels)
      pixelDensity: 3.0 // 3x density
    },
    screenSize: {
      width: 6.8, // inches
      height: 3.11 // inches (calculated from aspect ratio)
    },
    aspectRatio: 19.3 / 9, // 2.144
    pixelDensity: 3.0,
    category: 'phone',
    os: 'android'
  },

  [DeviceType.MACBOOK_PRO_14]: {
    name: 'MacBook Pro 14"',
    dimensions: {
      width: 1512, // points (CSS pixels)
      height: 982, // points (CSS pixels)
      pixelDensity: 2 // 2x Retina display
    },
    screenSize: {
      width: 14.2, // inches
      height: 9.48 // inches (calculated from aspect ratio)
    },
    aspectRatio: 16 / 10, // 1.6
    pixelDensity: 2,
    category: 'desktop',
    os: 'web'
  },

  [DeviceType.DESKTOP_1920X1080]: {
    name: 'Desktop 1920x1080',
    dimensions: {
      width: 1920, // pixels
      height: 1080, // pixels
      pixelDensity: 1 // Standard display
    },
    screenSize: {
      width: 24.0, // inches (typical)
      height: 13.5 // inches (calculated from aspect ratio)
    },
    aspectRatio: 16 / 9, // 1.778
    pixelDensity: 1,
    category: 'desktop',
    os: 'web'
  }
}

/**
 * Device categories for filtering and organization
 */
export const DEVICE_CATEGORIES = {
  phone: [DeviceType.IPHONE_15_PRO, DeviceType.IPHONE_15_PLUS, DeviceType.PIXEL_8_PRO, DeviceType.GALAXY_S24_ULTRA],
  tablet: [DeviceType.IPAD_PRO_11, DeviceType.IPAD_PRO_129],
  desktop: [DeviceType.MACBOOK_PRO_14, DeviceType.DESKTOP_1920X1080]
} as const

/**
 * Operating systems for platform-specific features
 */
export const DEVICE_BY_OS = {
  ios: [DeviceType.IPHONE_15_PRO, DeviceType.IPHONE_15_PLUS, DeviceType.IPAD_PRO_11, DeviceType.IPAD_PRO_129],
  android: [DeviceType.PIXEL_8_PRO, DeviceType.GALAXY_S24_ULTRA],
  web: [DeviceType.MACBOOK_PRO_14, DeviceType.DESKTOP_1920X1080]
} as const

/**
 * Popular devices for quick selection
 */
export const POPULAR_DEVICES = [
  DeviceType.IPHONE_15_PRO,
  DeviceType.PIXEL_8_PRO,
  DeviceType.IPAD_PRO_11,
  DeviceType.MACBOOK_PRO_14
] as const

/**
 * Safe area specifications for devices with notches/rounded corners
 */
export interface SafeAreaInsets {
  top: number
  right: number
  bottom: number
  left: number
}

export const DEVICE_SAFE_AREAS: Partial<Record<DeviceType, SafeAreaInsets>> = {
  [DeviceType.IPHONE_15_PRO]: {
    top: 59, // Status bar + Dynamic Island
    right: 0,
    bottom: 34, // Home indicator
    left: 0
  },
  [DeviceType.IPHONE_15_PLUS]: {
    top: 59, // Status bar + Dynamic Island
    right: 0,
    bottom: 34, // Home indicator
    left: 0
  },
  [DeviceType.IPAD_PRO_11]: {
    top: 24, // Status bar
    right: 0,
    bottom: 20, // Home indicator (when present)
    left: 0
  },
  [DeviceType.IPAD_PRO_129]: {
    top: 24, // Status bar
    right: 0,
    bottom: 20, // Home indicator (when present)
    left: 0
  },
  [DeviceType.PIXEL_8_PRO]: {
    top: 28, // Status bar
    right: 0,
    bottom: 24, // Navigation bar
    left: 0
  },
  [DeviceType.GALAXY_S24_ULTRA]: {
    top: 28, // Status bar
    right: 0,
    bottom: 24, // Navigation bar
    left: 0
  }
}

/**
 * Device corner radius for accurate visual simulation
 */
export const DEVICE_CORNER_RADIUS: Partial<Record<DeviceType, number>> = {
  [DeviceType.IPHONE_15_PRO]: 47.33, // points
  [DeviceType.IPHONE_15_PLUS]: 47.33, // points
  [DeviceType.IPAD_PRO_11]: 18.0, // points
  [DeviceType.IPAD_PRO_129]: 18.0, // points
  [DeviceType.PIXEL_8_PRO]: 28.0, // dp
  [DeviceType.GALAXY_S24_ULTRA]: 32.0 // dp
}

/**
 * Device preview assets (placeholder paths - to be replaced with actual assets)
 */
export const DEVICE_ASSETS: Record<DeviceType, { frame?: string; preview?: string }> = {
  [DeviceType.IPHONE_15_PRO]: {
    frame: '/assets/devices/iphone-15-pro-frame.png',
    preview: '/assets/devices/iphone-15-pro-preview.jpg'
  },
  [DeviceType.IPHONE_15_PLUS]: {
    frame: '/assets/devices/iphone-15-plus-frame.png',
    preview: '/assets/devices/iphone-15-plus-preview.jpg'
  },
  [DeviceType.IPAD_PRO_11]: {
    frame: '/assets/devices/ipad-pro-11-frame.png',
    preview: '/assets/devices/ipad-pro-11-preview.jpg'
  },
  [DeviceType.IPAD_PRO_129]: {
    frame: '/assets/devices/ipad-pro-129-frame.png',
    preview: '/assets/devices/ipad-pro-129-preview.jpg'
  },
  [DeviceType.PIXEL_8_PRO]: {
    frame: '/assets/devices/pixel-8-pro-frame.png',
    preview: '/assets/devices/pixel-8-pro-preview.jpg'
  },
  [DeviceType.GALAXY_S24_ULTRA]: {
    frame: '/assets/devices/galaxy-s24-ultra-frame.png',
    preview: '/assets/devices/galaxy-s24-ultra-preview.jpg'
  },
  [DeviceType.MACBOOK_PRO_14]: {
    frame: '/assets/devices/macbook-pro-14-frame.png',
    preview: '/assets/devices/macbook-pro-14-preview.jpg'
  },
  [DeviceType.DESKTOP_1920X1080]: {
    preview: '/assets/devices/desktop-preview.jpg'
  }
}

/**
 * Utility functions for device specifications
 */
export const DeviceUtils = {
  /**
   * Get device specification by device type
   */
  getDeviceSpec(deviceType: DeviceType): DeviceSpec {
    return DEVICE_SPECIFICATIONS[deviceType]
  },

  /**
   * Get devices by category
   */
  getDevicesByCategory(category: 'phone' | 'tablet' | 'desktop'): DeviceType[] {
    return [...DEVICE_CATEGORIES[category]]
  },

  /**
   * Get devices by operating system
   */
  getDevicesByOS(os: 'ios' | 'android' | 'web'): DeviceType[] {
    return [...DEVICE_BY_OS[os]]
  },

  /**
   * Get safe area insets for device (if applicable)
   */
  getSafeAreaInsets(deviceType: DeviceType): SafeAreaInsets | null {
    return DEVICE_SAFE_AREAS[deviceType] || null
  },

  /**
   * Get corner radius for device (if applicable)
   */
  getCornerRadius(deviceType: DeviceType): number | null {
    return DEVICE_CORNER_RADIUS[deviceType] || null
  },

  /**
   * Calculate actual pixel dimensions (CSS pixels * pixel density)
   */
  getActualPixelDimensions(deviceType: DeviceType): { width: number; height: number } {
    const spec = DEVICE_SPECIFICATIONS[deviceType]
    return {
      width: spec.dimensions.width * spec.pixelDensity,
      height: spec.dimensions.height * spec.pixelDensity
    }
  },

  /**
   * Check if device has safe areas (notch, home indicator, etc.)
   */
  hasSafeAreas(deviceType: DeviceType): boolean {
    return deviceType in DEVICE_SAFE_AREAS
  },

  /**
   * Check if device has rounded corners
   */
  hasRoundedCorners(deviceType: DeviceType): boolean {
    return deviceType in DEVICE_CORNER_RADIUS
  },

  /**
   * Get all available device types
   */
  getAllDeviceTypes(): DeviceType[] {
    return Object.values(DeviceType)
  },

  /**
   * Get popular devices for quick selection
   */
  getPopularDevices(): DeviceType[] {
    return [...POPULAR_DEVICES]
  }
}

export default DEVICE_SPECIFICATIONS
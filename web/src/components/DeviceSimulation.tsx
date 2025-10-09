import React, { useState, useEffect, useRef } from 'react'
import { DeviceType } from '../types'
import { DEVICE_SPECIFICATIONS, DeviceUtils } from '../data/device-specs'

/**
 * Props for the DeviceSimulation component
 */
export interface DeviceSimulationProps {
  deviceType: DeviceType
  children?: React.ReactNode
  className?: string
  showFrame?: boolean
  scale?: number
  onDeviceChange?: (deviceType: DeviceType) => void
}

/**
 * DeviceSimulation component provides pixel-perfect device simulation
 * with accurate dimensions, safe areas, and visual styling
 */
export const DeviceSimulation: React.FC<DeviceSimulationProps> = ({
  deviceType,
  children,
  className = '',
  showFrame = true,
  scale = 1,
  onDeviceChange
}) => {
  const containerRef = useRef<HTMLDivElement>(null)

  // Get device specifications
  const deviceSpec = DeviceUtils.getDeviceSpec(deviceType)
  const safeAreas = DeviceUtils.getSafeAreaInsets(deviceType)
  const cornerRadius = DeviceUtils.getCornerRadius(deviceType)

  // Calculate scaled dimensions
  const scaledWidth = deviceSpec.dimensions.width * scale
  const scaledHeight = deviceSpec.dimensions.height * scale
  const scaledCornerRadius = cornerRadius ? cornerRadius * scale : 0

  // Safe area styles
  const safeAreaStyles = safeAreas ? {
    paddingTop: safeAreas.top * scale,
    paddingRight: safeAreas.right * scale,
    paddingBottom: safeAreas.bottom * scale,
    paddingLeft: safeAreas.left * scale
  } : {}

  useEffect(() => {
    // Component initialization
  }, [deviceType])

  // Device frame styles
  const frameStyles: React.CSSProperties = {
    width: scaledWidth,
    height: scaledHeight,
    borderRadius: scaledCornerRadius,
    backgroundColor: deviceSpec.category === 'phone' ? '#000' : '#f5f5f5',
    border: showFrame ? '2px solid #333' : 'none',
    boxShadow: showFrame ? '0 4px 20px rgba(0, 0, 0, 0.15)' : 'none',
    overflow: 'hidden',
    position: 'relative',
    margin: 'auto'
  }

  // Content area styles
  const contentStyles: React.CSSProperties = {
    width: '100%',
    height: '100%',
    backgroundColor: '#fff',
    borderRadius: scaledCornerRadius > 0 ? scaledCornerRadius - (2 * scale) : 0,
    overflow: 'hidden',
    position: 'relative',
    ...safeAreaStyles
  }

  // Device info for debugging/development
  const deviceInfo = {
    name: deviceSpec.name,
    dimensions: `${deviceSpec.dimensions.width}×${deviceSpec.dimensions.height}`,
    pixelDensity: `${deviceSpec.pixelDensity}x`,
    aspectRatio: deviceSpec.aspectRatio.toFixed(3),
    category: deviceSpec.category,
    os: deviceSpec.os
  }

  return (
    <div 
      ref={containerRef}
      className={`device-simulation ${className}`}
      data-device-type={deviceType}
      data-device-category={deviceSpec.category}
      data-device-os={deviceSpec.os}
    >
      {/* Device selector dropdown (if onDeviceChange provided) */}
      {onDeviceChange && (
        <div className="device-selector mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Device Type
          </label>
          <select
            value={deviceType}
            onChange={(e) => onDeviceChange(e.target.value as DeviceType)}
            className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          >
            {DeviceUtils.getPopularDevices().map((type) => (
              <option key={type} value={type}>
                {DEVICE_SPECIFICATIONS[type].name}
              </option>
            ))}
            <optgroup label="All Devices">
              {DeviceUtils.getAllDeviceTypes().map((type) => (
                <option key={type} value={type}>
                  {DEVICE_SPECIFICATIONS[type].name}
                </option>
              ))}
            </optgroup>
          </select>
        </div>
      )}

      {/* Device frame container */}
      <div
        className="device-frame"
        style={frameStyles}
        data-testid="device-frame"
      >
        {/* Device screen content area */}
        <div
          className="device-screen"
          style={contentStyles}
          data-testid="device-screen"
        >
          {children}
        </div>

        {/* Device UI chrome (status bar, home indicator, etc.) */}
        {showFrame && safeAreas && (
          <>
            {/* Status bar area */}
            {safeAreas.top > 0 && (
              <div
                className="absolute top-0 left-0 right-0 bg-black bg-opacity-90"
                style={{ height: safeAreas.top * scale }}
                data-testid="status-bar"
              >
                <div className="flex justify-between items-center h-full px-4 text-white text-xs">
                  <span>9:41 AM</span>
                  <div className="flex space-x-1">
                    <span>📶</span>
                    <span>📶</span>
                    <span>🔋</span>
                  </div>
                </div>
              </div>
            )}

            {/* Home indicator (iPhone/iPad) */}
            {safeAreas.bottom > 20 && deviceSpec.os === 'ios' && (
              <div
                className="absolute bottom-0 left-1/2 transform -translate-x-1/2 bg-white bg-opacity-60 rounded-full"
                style={{
                  width: 134 * scale,
                  height: 5 * scale,
                  marginBottom: 8 * scale
                }}
                data-testid="home-indicator"
              />
            )}

            {/* Navigation bar (Android) */}
            {safeAreas.bottom > 0 && deviceSpec.os === 'android' && (
              <div
                className="absolute bottom-0 left-0 right-0 bg-black bg-opacity-90"
                style={{ height: safeAreas.bottom * scale }}
                data-testid="navigation-bar"
              >
                <div className="flex justify-center items-center h-full">
                  <div className="flex space-x-8 text-white text-lg">
                    <span>◀</span>
                    <span>●</span>
                    <span>▢</span>
                  </div>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {/* Device info panel (development mode) */}
      {typeof window !== 'undefined' && window.location.hostname === 'localhost' && (
        <details className="mt-4 text-xs">
          <summary className="cursor-pointer font-medium">Device Info</summary>
          <pre className="mt-2 p-2 bg-gray-100 rounded text-xs overflow-auto">
            {JSON.stringify(deviceInfo, null, 2)}
          </pre>
        </details>
      )}
    </div>
  )
}

/**
 * DeviceSimulationGrid component for showing multiple device previews
 */
export interface DeviceSimulationGridProps {
  devices?: DeviceType[]
  children?: React.ReactNode
  scale?: number
  showLabels?: boolean
  onDeviceSelect?: (deviceType: DeviceType) => void
}

export const DeviceSimulationGrid: React.FC<DeviceSimulationGridProps> = ({
  devices = DeviceUtils.getPopularDevices(),
  children,
  scale = 0.3,
  showLabels = true,
  onDeviceSelect
}) => {
  return (
    <div className="device-simulation-grid grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {devices.map((deviceType) => (
        <div
          key={deviceType}
          className={`device-preview ${onDeviceSelect ? 'cursor-pointer hover:scale-105 transition-transform' : ''}`}
          onClick={() => onDeviceSelect?.(deviceType)}
        >
          {showLabels && (
            <h3 className="text-sm font-medium text-center mb-2">
              {DEVICE_SPECIFICATIONS[deviceType].name}
            </h3>
          )}
          <DeviceSimulation
            deviceType={deviceType}
            scale={scale}
            showFrame={true}
          >
            {children}
          </DeviceSimulation>
          {showLabels && (
            <p className="text-xs text-gray-500 text-center mt-2">
              {DEVICE_SPECIFICATIONS[deviceType].dimensions.width}×
              {DEVICE_SPECIFICATIONS[deviceType].dimensions.height}
            </p>
          )}
        </div>
      ))}
    </div>
  )
}

/**
 * Responsive DeviceSimulation that automatically scales based on container size
 */
export interface ResponsiveDeviceSimulationProps extends Omit<DeviceSimulationProps, 'scale'> {
  maxWidth?: number
  maxHeight?: number
}

export const ResponsiveDeviceSimulation: React.FC<ResponsiveDeviceSimulationProps> = ({
  deviceType,
  maxWidth = 400,
  maxHeight = 600,
  ...props
}) => {
  const [scale, setScale] = useState(1)
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const calculateScale = () => {
      const deviceSpec = DeviceUtils.getDeviceSpec(deviceType)
      const scaleX = maxWidth / deviceSpec.dimensions.width
      const scaleY = maxHeight / deviceSpec.dimensions.height
      const optimalScale = Math.min(scaleX, scaleY, 1) // Don't scale up beyond 1x
      setScale(optimalScale)
    }

    calculateScale()
    window.addEventListener('resize', calculateScale)
    return () => window.removeEventListener('resize', calculateScale)
  }, [deviceType, maxWidth, maxHeight])

  return (
    <div ref={containerRef} className="responsive-device-simulation">
      <DeviceSimulation
        deviceType={deviceType}
        scale={scale}
        {...props}
      />
    </div>
  )
}

export default DeviceSimulation
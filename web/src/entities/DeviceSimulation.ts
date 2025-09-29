import { DeviceType, DeviceSpec, CanvasDimensions, ValidationError } from '../types'

export interface DeviceSimulationData {
  id: string
  deviceType: DeviceType
  specs: DeviceSpec
  isActive: boolean
  simulationSettings: {
    showFrame: boolean
    showNotch: boolean
    showButtons: boolean
    frameColor: string
    backgroundColor: string
  }
  performanceMetrics: {
    renderTime: number
    memoryUsage: number
    accuracy: number // percentage
  }
  metadata: {
    createdAt: Date | string
    lastUsed: Date | string
  }
}

export class DeviceSimulation {
  public readonly id: string
  public deviceType: DeviceType
  public specs: DeviceSpec
  public isActive: boolean
  public simulationSettings: {
    showFrame: boolean
    showNotch: boolean
    showButtons: boolean
    frameColor: string
    backgroundColor: string
  }
  public performanceMetrics: {
    renderTime: number
    memoryUsage: number
    accuracy: number
  }
  public metadata: {
    createdAt: Date
    lastUsed: Date
  }

  constructor(data: DeviceSimulationData) {
    this.validateDeviceSimulationData(data)
    
    this.id = data.id
    this.deviceType = data.deviceType
    this.specs = { ...data.specs }
    this.isActive = data.isActive
    this.simulationSettings = { ...data.simulationSettings }
    this.performanceMetrics = { ...data.performanceMetrics }
    this.metadata = {
      createdAt: data.metadata.createdAt instanceof Date 
        ? data.metadata.createdAt 
        : new Date(data.metadata.createdAt),
      lastUsed: data.metadata.lastUsed instanceof Date 
        ? data.metadata.lastUsed 
        : new Date(data.metadata.lastUsed)
    }
  }

  private validateDeviceSimulationData(data: DeviceSimulationData): void {
    // Validate ID
    if (!data.id || typeof data.id !== 'string' || data.id.trim() === '') {
      throw new ValidationError('Device simulation ID must be a valid non-empty string', 'id')
    }

    // Validate device type
    if (!Object.values(DeviceType).includes(data.deviceType)) {
      throw new ValidationError(`Invalid device type: ${data.deviceType}`, 'deviceType')
    }

    // Validate specs
    this.validateDeviceSpecs(data.specs)

    // Validate isActive
    if (typeof data.isActive !== 'boolean') {
      throw new ValidationError('isActive must be a boolean', 'isActive')
    }

    // Validate simulation settings
    this.validateSimulationSettings(data.simulationSettings)

    // Validate performance metrics
    this.validatePerformanceMetrics(data.performanceMetrics)

    // Validate metadata
    this.validateMetadata(data.metadata)
  }

  private validateDeviceSpecs(specs: DeviceSpec): void {
    if (!specs || typeof specs !== 'object') {
      throw new ValidationError('Device specs are required and must be an object', 'specs')
    }

    if (!specs.name || typeof specs.name !== 'string') {
      throw new ValidationError('Device spec name must be a non-empty string', 'specs')
    }

    // Validate dimensions
    if (!specs.dimensions || typeof specs.dimensions !== 'object') {
      throw new ValidationError('Device spec dimensions are required', 'specs')
    }

    if (typeof specs.dimensions.width !== 'number' || specs.dimensions.width <= 0) {
      throw new ValidationError('Device spec width must be a positive number', 'specs')
    }

    if (typeof specs.dimensions.height !== 'number' || specs.dimensions.height <= 0) {
      throw new ValidationError('Device spec height must be a positive number', 'specs')
    }

    if (typeof specs.dimensions.pixelDensity !== 'number' || specs.dimensions.pixelDensity <= 0) {
      throw new ValidationError('Device spec pixelDensity must be a positive number', 'specs')
    }

    // Validate screen size
    if (!specs.screenSize || typeof specs.screenSize !== 'object') {
      throw new ValidationError('Device spec screenSize is required', 'specs')
    }

    if (typeof specs.screenSize.width !== 'number' || specs.screenSize.width <= 0) {
      throw new ValidationError('Device spec screen width must be a positive number', 'specs')
    }

    if (typeof specs.screenSize.height !== 'number' || specs.screenSize.height <= 0) {
      throw new ValidationError('Device spec screen height must be a positive number', 'specs')
    }

    // Validate aspect ratio
    if (typeof specs.aspectRatio !== 'number' || specs.aspectRatio <= 0) {
      throw new ValidationError('Device spec aspectRatio must be a positive number', 'specs')
    }

    // Validate category
    const validCategories = ['phone', 'tablet', 'desktop']
    if (!validCategories.includes(specs.category)) {
      throw new ValidationError(`Device spec category must be one of: ${validCategories.join(', ')}`, 'specs')
    }

    // Validate OS
    const validOS = ['ios', 'android', 'web']
    if (!validOS.includes(specs.os)) {
      throw new ValidationError(`Device spec OS must be one of: ${validOS.join(', ')}`, 'specs')
    }
  }

  private validateSimulationSettings(settings: DeviceSimulationData['simulationSettings']): void {
    if (!settings || typeof settings !== 'object') {
      throw new ValidationError('Simulation settings are required and must be an object', 'simulationSettings')
    }

    const booleanFields = ['showFrame', 'showNotch', 'showButtons']
    for (const field of booleanFields) {
      if (typeof settings[field as keyof typeof settings] !== 'boolean') {
        throw new ValidationError(`Simulation setting ${field} must be a boolean`, 'simulationSettings')
      }
    }

    if (!settings.frameColor || typeof settings.frameColor !== 'string') {
      throw new ValidationError('Simulation setting frameColor must be a non-empty string', 'simulationSettings')
    }

    if (!settings.backgroundColor || typeof settings.backgroundColor !== 'string') {
      throw new ValidationError('Simulation setting backgroundColor must be a non-empty string', 'simulationSettings')
    }
  }

  private validatePerformanceMetrics(metrics: DeviceSimulationData['performanceMetrics']): void {
    if (!metrics || typeof metrics !== 'object') {
      throw new ValidationError('Performance metrics are required and must be an object', 'performanceMetrics')
    }

    if (typeof metrics.renderTime !== 'number' || metrics.renderTime < 0) {
      throw new ValidationError('Performance metric renderTime must be a non-negative number', 'performanceMetrics')
    }

    if (typeof metrics.memoryUsage !== 'number' || metrics.memoryUsage < 0) {
      throw new ValidationError('Performance metric memoryUsage must be a non-negative number', 'performanceMetrics')
    }

    if (typeof metrics.accuracy !== 'number' || metrics.accuracy < 0 || metrics.accuracy > 100) {
      throw new ValidationError('Performance metric accuracy must be a number between 0 and 100', 'performanceMetrics')
    }
  }

  private validateMetadata(metadata: DeviceSimulationData['metadata']): void {
    if (!metadata || typeof metadata !== 'object') {
      throw new ValidationError('Metadata is required and must be an object', 'metadata')
    }

    if (!metadata.createdAt) {
      throw new ValidationError('Metadata.createdAt is required', 'metadata')
    }

    if (!metadata.lastUsed) {
      throw new ValidationError('Metadata.lastUsed is required', 'metadata')
    }
  }

  // Device simulation methods
  public activate(): void {
    this.isActive = true
    this.updateLastUsed()
  }

  public deactivate(): void {
    this.isActive = false
  }

  public updateSimulationSettings(newSettings: Partial<DeviceSimulationData['simulationSettings']>): void {
    const updatedSettings = { ...this.simulationSettings, ...newSettings }
    this.validateSimulationSettings(updatedSettings)
    this.simulationSettings = updatedSettings
    this.updateLastUsed()
  }

  public updatePerformanceMetrics(newMetrics: Partial<DeviceSimulationData['performanceMetrics']>): void {
    const updatedMetrics = { ...this.performanceMetrics, ...newMetrics }
    this.validatePerformanceMetrics(updatedMetrics)
    this.performanceMetrics = updatedMetrics
  }

  private updateLastUsed(): void {
    this.metadata.lastUsed = new Date()
  }

  // Device simulation utilities
  public getPixelRatio(): number {
    return this.specs.dimensions.pixelDensity
  }

  public getLogicalDimensions(): { width: number; height: number } {
    return {
      width: this.specs.dimensions.width / this.specs.dimensions.pixelDensity,
      height: this.specs.dimensions.height / this.specs.dimensions.pixelDensity
    }
  }

  public getPhysicalDimensions(): CanvasDimensions {
    return this.specs.dimensions
  }

  public getScreenSizeInches(): { width: number; height: number } {
    return this.specs.screenSize
  }

  public getDiagonalSize(): number {
    const { width, height } = this.specs.screenSize
    return Math.sqrt(width * width + height * height)
  }

  public getAspectRatio(): number {
    return this.specs.aspectRatio
  }

  public isPortrait(): boolean {
    return this.specs.dimensions.height > this.specs.dimensions.width
  }

  public isLandscape(): boolean {
    return this.specs.dimensions.width > this.specs.dimensions.height
  }

  public isMobile(): boolean {
    return this.specs.category === 'phone'
  }

  public isTablet(): boolean {
    return this.specs.category === 'tablet'
  }

  public isDesktop(): boolean {
    return this.specs.category === 'desktop'
  }

  // Accuracy validation
  public validateAccuracy(targetAccuracy: number = 95): boolean {
    return this.performanceMetrics.accuracy >= targetAccuracy
  }

  public getAccuracyStatus(): 'excellent' | 'good' | 'fair' | 'poor' {
    const accuracy = this.performanceMetrics.accuracy
    if (accuracy >= 98) return 'excellent'
    if (accuracy >= 90) return 'good'
    if (accuracy >= 75) return 'fair'
    return 'poor'
  }

  // Performance analysis
  public isPerformant(maxRenderTime: number = 16.67): boolean {
    return this.performanceMetrics.renderTime <= maxRenderTime // 60fps = 16.67ms per frame
  }

  public getPerformanceStatus(): 'optimal' | 'good' | 'slow' | 'critical' {
    const renderTime = this.performanceMetrics.renderTime
    if (renderTime <= 16.67) return 'optimal' // 60fps
    if (renderTime <= 33.33) return 'good'    // 30fps
    if (renderTime <= 66.67) return 'slow'    // 15fps
    return 'critical' // < 15fps
  }

  public getMemoryUsageStatus(): 'low' | 'moderate' | 'high' | 'critical' {
    const usage = this.performanceMetrics.memoryUsage
    if (usage < 50) return 'low'
    if (usage < 100) return 'moderate'
    if (usage < 200) return 'high'
    return 'critical'
  }

  // Static factory methods for common devices
  public static createiPhone15Pro(): DeviceSimulation {
    return new DeviceSimulation({
      id: `device-sim-${Date.now()}-iphone15pro`,
      deviceType: DeviceType.IPHONE_15_PRO,
      specs: {
        name: 'iPhone 15 Pro',
        dimensions: { width: 393, height: 852, pixelDensity: 3 },
        screenSize: { width: 2.81, height: 6.12 },
        aspectRatio: 393 / 852,
        pixelDensity: 3,
        category: 'phone',
        os: 'ios'
      },
      isActive: false,
      simulationSettings: {
        showFrame: true,
        showNotch: true,
        showButtons: true,
        frameColor: '#1d1d1f',
        backgroundColor: '#000000'
      },
      performanceMetrics: {
        renderTime: 8.33, // 120fps
        memoryUsage: 45,
        accuracy: 99.5
      },
      metadata: {
        createdAt: new Date(),
        lastUsed: new Date()
      }
    })
  }

  public static createPixel8Pro(): DeviceSimulation {
    return new DeviceSimulation({
      id: `device-sim-${Date.now()}-pixel8pro`,
      deviceType: DeviceType.PIXEL_8_PRO,
      specs: {
        name: 'Pixel 8 Pro',
        dimensions: { width: 448, height: 998, pixelDensity: 2.625 },
        screenSize: { width: 2.74, height: 6.1 },
        aspectRatio: 448 / 998,
        pixelDensity: 2.625,
        category: 'phone',
        os: 'android'
      },
      isActive: false,
      simulationSettings: {
        showFrame: true,
        showNotch: false, // Pixel uses punch hole
        showButtons: false, // Gesture navigation
        frameColor: '#5f6368',
        backgroundColor: '#000000'
      },
      performanceMetrics: {
        renderTime: 8.33, // 120fps
        memoryUsage: 52,
        accuracy: 98.8
      },
      metadata: {
        createdAt: new Date(),
        lastUsed: new Date()
      }
    })
  }

  // Serialization
  public toJSON(): Record<string, any> {
    return {
      id: this.id,
      deviceType: this.deviceType,
      specs: this.specs,
      isActive: this.isActive,
      simulationSettings: this.simulationSettings,
      performanceMetrics: this.performanceMetrics,
      metadata: {
        createdAt: this.metadata.createdAt.toISOString(),
        lastUsed: this.metadata.lastUsed.toISOString()
      }
    }
  }

  public static fromJSON(data: any): DeviceSimulation {
    return new DeviceSimulation({
      ...data,
      metadata: {
        createdAt: new Date(data.metadata.createdAt),
        lastUsed: new Date(data.metadata.lastUsed)
      }
    })
  }

  public clone(): DeviceSimulation {
    return DeviceSimulation.fromJSON(this.toJSON())
  }
}

import { GestureState, GesturePhysics, ValidationError } from '../types'

export interface GestureNavigationData {
  id: string
  currentState: GestureState
  currentVariationId: string | null
  physics: GesturePhysics
  navigationHistory: {
    variationId: string
    timestamp: Date | string
    source: 'gesture' | 'direct'
  }[]
  settings: {
    sensitivity: number
    momentumEnabled: boolean
    hapticFeedback: boolean
    soundEnabled: boolean
  }
  metrics: {
    totalGestures: number
    totalNavigations: number
    averageVelocity: number
    lastGestureTime: Date | string | null
  }
}

export class GestureNavigation {
  public readonly id: string
  public currentState: GestureState
  public currentVariationId: string | null
  public physics: GesturePhysics
  public navigationHistory: {
    variationId: string
    timestamp: Date
    source: 'gesture' | 'direct'
  }[]
  public settings: {
    sensitivity: number
    momentumEnabled: boolean
    hapticFeedback: boolean
    soundEnabled: boolean
  }
  public metrics: {
    totalGestures: number
    totalNavigations: number
    averageVelocity: number
    lastGestureTime: Date | null
  }

  constructor(data: GestureNavigationData) {
    this.validateGestureNavigationData(data)
    
    this.id = data.id
    this.currentState = data.currentState
    this.currentVariationId = data.currentVariationId
    this.physics = { ...data.physics }
    this.settings = { ...data.settings }
    
    // Process navigation history
    this.navigationHistory = data.navigationHistory.map(entry => ({
      variationId: entry.variationId,
      timestamp: entry.timestamp instanceof Date ? entry.timestamp : new Date(entry.timestamp),
      source: entry.source
    }))
    
    // Process metrics
    this.metrics = {
      ...data.metrics,
      lastGestureTime: data.metrics.lastGestureTime 
        ? (data.metrics.lastGestureTime instanceof Date 
            ? data.metrics.lastGestureTime 
            : new Date(data.metrics.lastGestureTime))
        : null
    }
  }

  private validateGestureNavigationData(data: GestureNavigationData): void {
    // Validate ID
    if (!data.id || typeof data.id !== 'string' || data.id.trim() === '') {
      throw new ValidationError('Gesture navigation ID must be a valid non-empty string', 'id')
    }

    // Validate current state
    if (!Object.values(GestureState).includes(data.currentState)) {
      throw new ValidationError(`Invalid gesture state: ${data.currentState}`, 'currentState')
    }

    // Validate current variation ID (can be null)
    if (data.currentVariationId !== null && 
        (typeof data.currentVariationId !== 'string' || data.currentVariationId.trim() === '')) {
      throw new ValidationError('Current variation ID must be null or a valid non-empty string', 'currentVariationId')
    }

    // Validate physics
    this.validatePhysics(data.physics)

    // Validate navigation history
    this.validateNavigationHistory(data.navigationHistory)

    // Validate settings
    this.validateSettings(data.settings)

    // Validate metrics
    this.validateMetrics(data.metrics)
  }

  private validatePhysics(physics: GesturePhysics): void {
    if (!physics || typeof physics !== 'object') {
      throw new ValidationError('Physics configuration is required and must be an object', 'physics')
    }

    const requiredFields = ['velocity', 'acceleration', 'friction', 'threshold']
    for (const field of requiredFields) {
      if (typeof physics[field as keyof GesturePhysics] !== 'number') {
        throw new ValidationError(`Physics.${field} must be a number`, 'physics')
      }
    }

    // Validate ranges
    if (physics.friction < 0 || physics.friction > 1) {
      throw new ValidationError('Physics friction must be between 0 and 1', 'physics')
    }

    if (physics.threshold <= 0) {
      throw new ValidationError('Physics threshold must be positive', 'physics')
    }
  }

  private validateNavigationHistory(history: GestureNavigationData['navigationHistory']): void {
    if (!Array.isArray(history)) {
      throw new ValidationError('Navigation history must be an array', 'navigationHistory')
    }

    for (let i = 0; i < history.length; i++) {
      const entry = history[i]
      
      if (!entry.variationId || typeof entry.variationId !== 'string') {
        throw new ValidationError(`Navigation history entry ${i} must have a valid variationId`, 'navigationHistory')
      }

      if (!entry.timestamp) {
        throw new ValidationError(`Navigation history entry ${i} must have a timestamp`, 'navigationHistory')
      }

      if (!['gesture', 'direct'].includes(entry.source)) {
        throw new ValidationError(`Navigation history entry ${i} source must be 'gesture' or 'direct'`, 'navigationHistory')
      }
    }
  }

  private validateSettings(settings: GestureNavigationData['settings']): void {
    if (!settings || typeof settings !== 'object') {
      throw new ValidationError('Settings are required and must be an object', 'settings')
    }

    if (typeof settings.sensitivity !== 'number' || settings.sensitivity <= 0) {
      throw new ValidationError('Settings sensitivity must be a positive number', 'settings')
    }

    const booleanFields = ['momentumEnabled', 'hapticFeedback', 'soundEnabled']
    for (const field of booleanFields) {
      if (typeof settings[field as keyof typeof settings] !== 'boolean') {
        throw new ValidationError(`Settings.${field} must be a boolean`, 'settings')
      }
    }
  }

  private validateMetrics(metrics: GestureNavigationData['metrics']): void {
    if (!metrics || typeof metrics !== 'object') {
      throw new ValidationError('Metrics are required and must be an object', 'metrics')
    }

    const numberFields = ['totalGestures', 'totalNavigations', 'averageVelocity'] as const
    for (const field of numberFields) {
      const value = metrics[field]
      if (typeof value !== 'number' || value < 0) {
        throw new ValidationError(`Metrics.${field} must be a non-negative number`, 'metrics')
      }
    }

    if (metrics.lastGestureTime !== null && !metrics.lastGestureTime) {
      throw new ValidationError('Metrics.lastGestureTime must be null or a valid date', 'metrics')
    }
  }

  // State management methods
  public startGesture(): void {
    if (this.currentState !== GestureState.IDLE) {
      throw new ValidationError(`Cannot start gesture from state: ${this.currentState}`)
    }
    this.currentState = GestureState.ACTIVE
    this.metrics.totalGestures++
    this.metrics.lastGestureTime = new Date()
  }

  public endGesture(finalVelocity: number): void {
    if (this.currentState !== GestureState.ACTIVE) {
      throw new ValidationError(`Cannot end gesture from state: ${this.currentState}`)
    }

    this.physics.velocity = finalVelocity
    this.updateAverageVelocity(finalVelocity)

    if (this.settings.momentumEnabled && Math.abs(finalVelocity) > this.physics.threshold) {
      this.currentState = GestureState.MOMENTUM
    } else {
      this.currentState = GestureState.IDLE
    }
  }

  public stopMomentum(): void {
    if (this.currentState === GestureState.MOMENTUM) {
      this.currentState = GestureState.IDLE
      this.physics.velocity = 0
    }
  }

  public resetGesture(): void {
    this.currentState = GestureState.IDLE
    this.physics.velocity = 0
    this.physics.acceleration = 0
  }

  private updateAverageVelocity(newVelocity: number): void {
    const totalGestures = this.metrics.totalGestures
    const currentAverage = this.metrics.averageVelocity
    
    // Running average calculation
    this.metrics.averageVelocity = ((currentAverage * (totalGestures - 1)) + Math.abs(newVelocity)) / totalGestures
  }

  // Navigation methods
  public navigateToVariation(variationId: string, source: 'gesture' | 'direct' = 'direct'): void {
    if (!variationId || typeof variationId !== 'string') {
      throw new ValidationError('Variation ID must be a valid non-empty string')
    }

    const previousVariationId = this.currentVariationId
    this.currentVariationId = variationId

    // Add to navigation history
    this.navigationHistory.push({
      variationId,
      timestamp: new Date(),
      source
    })

    // Update metrics if this was a successful navigation
    if (previousVariationId !== variationId) {
      this.metrics.totalNavigations++
    }

    // Limit history size to prevent memory issues
    const maxHistorySize = 1000
    if (this.navigationHistory.length > maxHistorySize) {
      this.navigationHistory = this.navigationHistory.slice(-maxHistorySize)
    }
  }

  public canNavigate(): boolean {
    return this.currentState === GestureState.IDLE || 
           this.currentState === GestureState.MOMENTUM
  }

  public getCurrentVariation(): string | null {
    return this.currentVariationId
  }

  // Physics calculations
  public updatePhysics(deltaTime: number): void {
    if (this.currentState === GestureState.MOMENTUM) {
      // Apply friction to velocity
      const frictionForce = this.physics.velocity * this.physics.friction
      this.physics.velocity -= frictionForce * deltaTime

      // Stop momentum when velocity falls below threshold
      if (Math.abs(this.physics.velocity) < this.physics.threshold) {
        this.stopMomentum()
      }
    }
  }

  public calculateNavigationDirection(): 'forward' | 'backward' | 'none' {
    if (Math.abs(this.physics.velocity) < this.physics.threshold) {
      return 'none'
    }
    return this.physics.velocity > 0 ? 'forward' : 'backward'
  }

  public shouldTriggerNavigation(): boolean {
    return Math.abs(this.physics.velocity) > this.physics.threshold
  }

  // History analysis
  public getRecentHistory(count: number = 10): typeof this.navigationHistory {
    return this.navigationHistory.slice(-count)
  }

  public getHistoryByTimeRange(startTime: Date, endTime: Date): typeof this.navigationHistory {
    return this.navigationHistory.filter(entry => 
      entry.timestamp >= startTime && entry.timestamp <= endTime
    )
  }

  public getGestureNavigationCount(): number {
    return this.navigationHistory.filter(entry => entry.source === 'gesture').length
  }

  public getDirectNavigationCount(): number {
    return this.navigationHistory.filter(entry => entry.source === 'direct').length
  }

  public getLastNavigationTime(): Date | null {
    if (this.navigationHistory.length === 0) return null
    return this.navigationHistory[this.navigationHistory.length - 1].timestamp
  }

  // Settings management
  public updateSettings(newSettings: Partial<GestureNavigationData['settings']>): void {
    const updatedSettings = { ...this.settings, ...newSettings }
    this.validateSettings(updatedSettings)
    this.settings = updatedSettings
  }

  public updatePhysicsSettings(newPhysics: Partial<GesturePhysics>): void {
    const updatedPhysics = { ...this.physics, ...newPhysics }
    this.validatePhysics(updatedPhysics)
    
    // Preserve current velocity and acceleration during update
    const currentVelocity = this.physics.velocity
    const currentAcceleration = this.physics.acceleration
    
    this.physics = updatedPhysics
    this.physics.velocity = currentVelocity
    this.physics.acceleration = currentAcceleration
  }

  // Performance analysis
  public getNavigationEfficiency(): number {
    if (this.metrics.totalGestures === 0) return 0
    return this.metrics.totalNavigations / this.metrics.totalGestures
  }

  public getAverageNavigationTime(): number {
    if (this.navigationHistory.length < 2) return 0
    
    const timeDiffs: number[] = []
    for (let i = 1; i < this.navigationHistory.length; i++) {
      const diff = this.navigationHistory[i].timestamp.getTime() - 
                   this.navigationHistory[i - 1].timestamp.getTime()
      timeDiffs.push(diff)
    }
    
    return timeDiffs.reduce((sum, diff) => sum + diff, 0) / timeDiffs.length
  }

  public isActive(): boolean {
    return this.currentState !== GestureState.IDLE
  }

  public isGestureInProgress(): boolean {
    return this.currentState === GestureState.ACTIVE
  }

  public hasMomentum(): boolean {
    return this.currentState === GestureState.MOMENTUM
  }

  // Static factory method
  public static createDefault(id?: string): GestureNavigation {
    return new GestureNavigation({
      id: id || `gesture-nav-${Date.now()}`,
      currentState: GestureState.IDLE,
      currentVariationId: null,
      physics: {
        velocity: 0,
        acceleration: 0,
        friction: 0.95, // 5% friction per frame
        threshold: 10 // minimum velocity to trigger navigation
      },
      navigationHistory: [],
      settings: {
        sensitivity: 1.0,
        momentumEnabled: true,
        hapticFeedback: true,
        soundEnabled: false
      },
      metrics: {
        totalGestures: 0,
        totalNavigations: 0,
        averageVelocity: 0,
        lastGestureTime: null
      }
    })
  }

  // Serialization
  public toJSON(): Record<string, any> {
    return {
      id: this.id,
      currentState: this.currentState,
      currentVariationId: this.currentVariationId,
      physics: this.physics,
      navigationHistory: this.navigationHistory.map(entry => ({
        ...entry,
        timestamp: entry.timestamp.toISOString()
      })),
      settings: this.settings,
      metrics: {
        ...this.metrics,
        lastGestureTime: this.metrics.lastGestureTime?.toISOString() || null
      }
    }
  }

  public static fromJSON(data: any): GestureNavigation {
    return new GestureNavigation({
      ...data,
      navigationHistory: data.navigationHistory.map((entry: any) => ({
        ...entry,
        timestamp: new Date(entry.timestamp)
      })),
      metrics: {
        ...data.metrics,
        lastGestureTime: data.metrics.lastGestureTime ? new Date(data.metrics.lastGestureTime) : null
      }
    })
  }

  public clone(): GestureNavigation {
    return GestureNavigation.fromJSON(this.toJSON())
  }
}

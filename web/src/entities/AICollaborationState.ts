import { AIProcessingState, AICollaborationMetadata, ValidationError } from '../types'

export interface AICollaborationStateData {
  id: string
  currentState: AIProcessingState
  variationId: string | null
  metadata: AICollaborationMetadata
  processingQueue: {
    id: string
    type: 'analyze' | 'generate' | 'variations' | 'trends'
    prompt: string
    priority: number
    timestamp: Date | string
    status: 'pending' | 'processing' | 'completed' | 'failed'
    result?: any
    error?: string
  }[]
  sessionMetrics: {
    totalRequests: number
    successfulRequests: number
    failedRequests: number
    averageResponseTime: number
    lastRequestTime: Date | string | null
    sessionStartTime: Date | string
  }
  settings: {
    autoGenerateVariations: boolean
    maxVariationsPerRequest: number
    confidenceThreshold: number
    enableTrendAnalysis: boolean
    cacheResponses: boolean
  }
}

export class AICollaborationState {
  public readonly id: string
  public currentState: AIProcessingState
  public variationId: string | null
  public metadata: AICollaborationMetadata
  public processingQueue: {
    id: string
    type: 'analyze' | 'generate' | 'variations' | 'trends'
    prompt: string
    priority: number
    timestamp: Date
    status: 'pending' | 'processing' | 'completed' | 'failed'
    result?: any
    error?: string
  }[]
  public sessionMetrics: {
    totalRequests: number
    successfulRequests: number
    failedRequests: number
    averageResponseTime: number
    lastRequestTime: Date | null
    sessionStartTime: Date
  }
  public settings: {
    autoGenerateVariations: boolean
    maxVariationsPerRequest: number
    confidenceThreshold: number
    enableTrendAnalysis: boolean
    cacheResponses: boolean
  }

  constructor(data: AICollaborationStateData) {
    this.validateAICollaborationStateData(data)
    
    this.id = data.id
    this.currentState = data.currentState
    this.variationId = data.variationId
    this.metadata = { ...data.metadata }
    this.settings = { ...data.settings }
    
    // Process processing queue
    this.processingQueue = data.processingQueue.map(item => ({
      ...item,
      timestamp: item.timestamp instanceof Date ? item.timestamp : new Date(item.timestamp)
    }))
    
    // Process session metrics
    this.sessionMetrics = {
      ...data.sessionMetrics,
      lastRequestTime: data.sessionMetrics.lastRequestTime 
        ? (data.sessionMetrics.lastRequestTime instanceof Date 
            ? data.sessionMetrics.lastRequestTime 
            : new Date(data.sessionMetrics.lastRequestTime))
        : null,
      sessionStartTime: data.sessionMetrics.sessionStartTime instanceof Date 
        ? data.sessionMetrics.sessionStartTime 
        : new Date(data.sessionMetrics.sessionStartTime)
    }
  }

  private validateAICollaborationStateData(data: AICollaborationStateData): void {
    // Validate ID
    if (!data.id || typeof data.id !== 'string' || data.id.trim() === '') {
      throw new ValidationError('AI collaboration state ID must be a valid non-empty string', 'id')
    }

    // Validate current state
    if (!Object.values(AIProcessingState).includes(data.currentState)) {
      throw new ValidationError(`Invalid AI processing state: ${data.currentState}`, 'currentState')
    }

    // Validate variation ID (can be null)
    if (data.variationId !== null && 
        (typeof data.variationId !== 'string' || data.variationId.trim() === '')) {
      throw new ValidationError('Variation ID must be null or a valid non-empty string', 'variationId')
    }

    // Validate metadata
    this.validateMetadata(data.metadata)

    // Validate processing queue
    this.validateProcessingQueue(data.processingQueue)

    // Validate session metrics
    this.validateSessionMetrics(data.sessionMetrics)

    // Validate settings
    this.validateSettings(data.settings)
  }

  private validateMetadata(metadata: AICollaborationMetadata): void {
    if (!metadata || typeof metadata !== 'object') {
      throw new ValidationError('Metadata is required and must be an object', 'metadata')
    }

    // Validate confidence scores
    if (!metadata.confidenceScores || typeof metadata.confidenceScores !== 'object') {
      throw new ValidationError('Metadata.confidenceScores is required and must be an object', 'metadata')
    }

    for (const [key, score] of Object.entries(metadata.confidenceScores)) {
      if (typeof score !== 'number' || score < 0 || score > 1) {
        throw new ValidationError(`Confidence score for '${key}' must be a number between 0 and 1`, 'metadata')
      }
    }

    // Validate current prompt (optional)
    if (metadata.currentPrompt && typeof metadata.currentPrompt !== 'string') {
      throw new ValidationError('Metadata.currentPrompt must be a string', 'metadata')
    }

    // Validate last analysis (optional)
    if (metadata.lastAnalysis) {
      this.validateLastAnalysis(metadata.lastAnalysis)
    }

    // Validate error message (optional)
    if (metadata.errorMessage && typeof metadata.errorMessage !== 'string') {
      throw new ValidationError('Metadata.errorMessage must be a string', 'metadata')
    }
  }

  private validateLastAnalysis(analysis: NonNullable<AICollaborationMetadata['lastAnalysis']>): void {
    if (!analysis.timestamp || !(analysis.timestamp instanceof Date)) {
      throw new ValidationError('Last analysis timestamp must be a Date', 'metadata.lastAnalysis')
    }

    if (!Array.isArray(analysis.insights)) {
      throw new ValidationError('Last analysis insights must be an array', 'metadata.lastAnalysis')
    }

    if (!Array.isArray(analysis.suggestions)) {
      throw new ValidationError('Last analysis suggestions must be an array', 'metadata.lastAnalysis')
    }

    for (const insight of analysis.insights) {
      if (typeof insight !== 'string') {
        throw new ValidationError('All insights must be strings', 'metadata.lastAnalysis')
      }
    }

    for (const suggestion of analysis.suggestions) {
      if (typeof suggestion !== 'string') {
        throw new ValidationError('All suggestions must be strings', 'metadata.lastAnalysis')
      }
    }
  }

  private validateProcessingQueue(queue: AICollaborationStateData['processingQueue']): void {
    if (!Array.isArray(queue)) {
      throw new ValidationError('Processing queue must be an array', 'processingQueue')
    }

    const validTypes = ['analyze', 'generate', 'variations', 'trends']
    const validStatuses = ['pending', 'processing', 'completed', 'failed']

    for (let i = 0; i < queue.length; i++) {
      const item = queue[i]

      if (!item.id || typeof item.id !== 'string') {
        throw new ValidationError(`Queue item ${i} must have a valid ID`, 'processingQueue')
      }

      if (!validTypes.includes(item.type)) {
        throw new ValidationError(`Queue item ${i} type must be one of: ${validTypes.join(', ')}`, 'processingQueue')
      }

      if (!item.prompt || typeof item.prompt !== 'string') {
        throw new ValidationError(`Queue item ${i} must have a valid prompt`, 'processingQueue')
      }

      if (typeof item.priority !== 'number' || item.priority < 0) {
        throw new ValidationError(`Queue item ${i} priority must be a non-negative number`, 'processingQueue')
      }

      if (!item.timestamp) {
        throw new ValidationError(`Queue item ${i} must have a timestamp`, 'processingQueue')
      }

      if (!validStatuses.includes(item.status)) {
        throw new ValidationError(`Queue item ${i} status must be one of: ${validStatuses.join(', ')}`, 'processingQueue')
      }
    }
  }

  private validateSessionMetrics(metrics: AICollaborationStateData['sessionMetrics']): void {
    if (!metrics || typeof metrics !== 'object') {
      throw new ValidationError('Session metrics are required and must be an object', 'sessionMetrics')
    }

    const numberFields = ['totalRequests', 'successfulRequests', 'failedRequests', 'averageResponseTime'] as const
    for (const field of numberFields) {
      const value = metrics[field]
      if (typeof value !== 'number' || value < 0) {
        throw new ValidationError(`Session metrics.${field} must be a non-negative number`, 'sessionMetrics')
      }
    }

    if (!metrics.sessionStartTime) {
      throw new ValidationError('Session metrics.sessionStartTime is required', 'sessionMetrics')
    }
  }

  private validateSettings(settings: AICollaborationStateData['settings']): void {
    if (!settings || typeof settings !== 'object') {
      throw new ValidationError('Settings are required and must be an object', 'settings')
    }

    const booleanFields = ['autoGenerateVariations', 'enableTrendAnalysis', 'cacheResponses']
    for (const field of booleanFields) {
      if (typeof settings[field as keyof typeof settings] !== 'boolean') {
        throw new ValidationError(`Settings.${field} must be a boolean`, 'settings')
      }
    }

    if (typeof settings.maxVariationsPerRequest !== 'number' || settings.maxVariationsPerRequest < 1) {
      throw new ValidationError('Settings.maxVariationsPerRequest must be a positive number', 'settings')
    }

    if (typeof settings.confidenceThreshold !== 'number' || 
        settings.confidenceThreshold < 0 || settings.confidenceThreshold > 1) {
      throw new ValidationError('Settings.confidenceThreshold must be a number between 0 and 1', 'settings')
    }
  }

  // State management methods
  public setState(newState: AIProcessingState): void {
    if (!Object.values(AIProcessingState).includes(newState)) {
      throw new ValidationError(`Invalid AI processing state: ${newState}`)
    }
    this.currentState = newState
  }

  public startProcessing(prompt: string): void {
    if (this.currentState !== AIProcessingState.IDLE) {
      throw new ValidationError(`Cannot start processing from state: ${this.currentState}`)
    }
    
    this.currentState = AIProcessingState.ANALYZING
    this.metadata.currentPrompt = prompt
    this.clearError()
  }

  public setGenerating(): void {
    if (this.currentState !== AIProcessingState.ANALYZING) {
      throw new ValidationError(`Cannot set generating from state: ${this.currentState}`)
    }
    this.currentState = AIProcessingState.GENERATING
  }

  public setReady(): void {
    if (this.currentState !== AIProcessingState.GENERATING) {
      throw new ValidationError(`Cannot set ready from state: ${this.currentState}`)
    }
    this.currentState = AIProcessingState.READY
  }

  public setError(errorMessage: string): void {
    this.currentState = AIProcessingState.ERROR
    this.metadata.errorMessage = errorMessage
  }

  public clearError(): void {
    if (this.currentState === AIProcessingState.ERROR) {
      this.currentState = AIProcessingState.IDLE
    }
    this.metadata.errorMessage = undefined
  }

  public reset(): void {
    this.currentState = AIProcessingState.IDLE
    this.metadata.currentPrompt = undefined
    this.metadata.errorMessage = undefined
  }

  // Processing queue management
  public addToQueue(request: {
    type: 'analyze' | 'generate' | 'variations' | 'trends'
    prompt: string
    priority?: number
  }): string {
    const queueItem = {
      id: `ai-request-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      type: request.type,
      prompt: request.prompt,
      priority: request.priority || 0,
      timestamp: new Date(),
      status: 'pending' as const
    }

    this.processingQueue.push(queueItem)
    this.sortQueueByPriority()
    
    return queueItem.id
  }

  public updateQueueItem(id: string, updates: {
    status?: 'pending' | 'processing' | 'completed' | 'failed'
    result?: any
    error?: string
  }): boolean {
    const item = this.processingQueue.find(item => item.id === id)
    if (!item) return false

    if (updates.status) item.status = updates.status
    if (updates.result !== undefined) item.result = updates.result
    if (updates.error !== undefined) item.error = updates.error

    return true
  }

  public removeFromQueue(id: string): boolean {
    const index = this.processingQueue.findIndex(item => item.id === id)
    if (index === -1) return false
    
    this.processingQueue.splice(index, 1)
    return true
  }

  public getNextQueueItem(): typeof this.processingQueue[0] | null {
    const pendingItem = this.processingQueue.find(item => item.status === 'pending')
    return pendingItem || null
  }

  public clearQueue(): void {
    this.processingQueue = []
  }

  private sortQueueByPriority(): void {
    this.processingQueue.sort((a, b) => b.priority - a.priority)
  }

  // Metadata management
  public updateConfidenceScore(key: string, score: number): void {
    if (typeof score !== 'number' || score < 0 || score > 1) {
      throw new ValidationError('Confidence score must be a number between 0 and 1')
    }
    this.metadata.confidenceScores[key] = score
  }

  public getConfidenceScore(key: string): number | undefined {
    return this.metadata.confidenceScores[key]
  }

  public setLastAnalysis(insights: string[], suggestions: string[]): void {
    this.metadata.lastAnalysis = {
      timestamp: new Date(),
      insights: [...insights],
      suggestions: [...suggestions]
    }
  }

  public clearLastAnalysis(): void {
    this.metadata.lastAnalysis = undefined
  }

  // Session metrics management
  public recordRequest(responseTime: number, success: boolean): void {
    this.sessionMetrics.totalRequests++
    this.sessionMetrics.lastRequestTime = new Date()
    
    if (success) {
      this.sessionMetrics.successfulRequests++
    } else {
      this.sessionMetrics.failedRequests++
    }
    
    // Update average response time
    const totalSuccessful = this.sessionMetrics.successfulRequests
    const currentAverage = this.sessionMetrics.averageResponseTime
    
    if (success && totalSuccessful > 0) {
      this.sessionMetrics.averageResponseTime = 
        ((currentAverage * (totalSuccessful - 1)) + responseTime) / totalSuccessful
    }
  }

  public getSuccessRate(): number {
    if (this.sessionMetrics.totalRequests === 0) return 0
    return this.sessionMetrics.successfulRequests / this.sessionMetrics.totalRequests
  }

  public getFailureRate(): number {
    if (this.sessionMetrics.totalRequests === 0) return 0
    return this.sessionMetrics.failedRequests / this.sessionMetrics.totalRequests
  }

  public getSessionDuration(): number {
    return new Date().getTime() - this.sessionMetrics.sessionStartTime.getTime()
  }

  // Settings management
  public updateSettings(newSettings: Partial<AICollaborationStateData['settings']>): void {
    const updatedSettings = { ...this.settings, ...newSettings }
    this.validateSettings(updatedSettings)
    this.settings = updatedSettings
  }

  // Status checks
  public isIdle(): boolean {
    return this.currentState === AIProcessingState.IDLE
  }

  public isProcessing(): boolean {
    return this.currentState === AIProcessingState.ANALYZING || 
           this.currentState === AIProcessingState.GENERATING
  }

  public isReady(): boolean {
    return this.currentState === AIProcessingState.READY
  }

  public hasError(): boolean {
    return this.currentState === AIProcessingState.ERROR
  }

  public getErrorMessage(): string | null {
    return this.metadata.errorMessage || null
  }

  public canAcceptNewRequest(): boolean {
    return this.currentState === AIProcessingState.IDLE || 
           this.currentState === AIProcessingState.READY
  }

  // Queue analysis
  public getQueueSize(): number {
    return this.processingQueue.length
  }

  public getPendingRequestsCount(): number {
    return this.processingQueue.filter(item => item.status === 'pending').length
  }

  public getProcessingRequestsCount(): number {
    return this.processingQueue.filter(item => item.status === 'processing').length
  }

  public getCompletedRequestsCount(): number {
    return this.processingQueue.filter(item => item.status === 'completed').length
  }

  public getFailedRequestsCount(): number {
    return this.processingQueue.filter(item => item.status === 'failed').length
  }

  // Static factory method
  public static createDefault(id?: string): AICollaborationState {
    return new AICollaborationState({
      id: id || `ai-collab-${Date.now()}`,
      currentState: AIProcessingState.IDLE,
      variationId: null,
      metadata: {
        confidenceScores: {}
      },
      processingQueue: [],
      sessionMetrics: {
        totalRequests: 0,
        successfulRequests: 0,
        failedRequests: 0,
        averageResponseTime: 0,
        lastRequestTime: null,
        sessionStartTime: new Date()
      },
      settings: {
        autoGenerateVariations: true,
        maxVariationsPerRequest: 5,
        confidenceThreshold: 0.7,
        enableTrendAnalysis: true,
        cacheResponses: true
      }
    })
  }

  // Serialization
  public toJSON(): Record<string, any> {
    return {
      id: this.id,
      currentState: this.currentState,
      variationId: this.variationId,
      metadata: {
        ...this.metadata,
        lastAnalysis: this.metadata.lastAnalysis ? {
          ...this.metadata.lastAnalysis,
          timestamp: this.metadata.lastAnalysis.timestamp.toISOString()
        } : undefined
      },
      processingQueue: this.processingQueue.map(item => ({
        ...item,
        timestamp: item.timestamp.toISOString()
      })),
      sessionMetrics: {
        ...this.sessionMetrics,
        lastRequestTime: this.sessionMetrics.lastRequestTime?.toISOString() || null,
        sessionStartTime: this.sessionMetrics.sessionStartTime.toISOString()
      },
      settings: this.settings
    }
  }

  public static fromJSON(data: any): AICollaborationState {
    return new AICollaborationState({
      ...data,
      metadata: {
        ...data.metadata,
        lastAnalysis: data.metadata.lastAnalysis ? {
          ...data.metadata.lastAnalysis,
          timestamp: new Date(data.metadata.lastAnalysis.timestamp)
        } : undefined
      },
      processingQueue: data.processingQueue.map((item: any) => ({
        ...item,
        timestamp: new Date(item.timestamp)
      })),
      sessionMetrics: {
        ...data.sessionMetrics,
        lastRequestTime: data.sessionMetrics.lastRequestTime 
          ? new Date(data.sessionMetrics.lastRequestTime) 
          : null,
        sessionStartTime: new Date(data.sessionMetrics.sessionStartTime)
      }
    })
  }

  public clone(): AICollaborationState {
    return AICollaborationState.fromJSON(this.toJSON())
  }
}

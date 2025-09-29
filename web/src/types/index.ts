// Core Types for Visual AI Collaboration Canvas

// Device Types for Accurate Simulation
export enum DeviceType {
  IPHONE_15_PRO = 'iPhone 15 Pro',
  IPHONE_15_PLUS = 'iPhone 15 Plus',
  IPAD_PRO_11 = 'iPad Pro 11"',
  IPAD_PRO_129 = 'iPad Pro 12.9"',
  PIXEL_8_PRO = 'Pixel 8 Pro',
  GALAXY_S24_ULTRA = 'Galaxy S24 Ultra',
  MACBOOK_PRO_14 = 'MacBook Pro 14"',
  DESKTOP_1920X1080 = 'Desktop 1920x1080'
}

// Canvas States
export enum CanvasState {
  EDITING = 'editing',
  AI_PROCESSING = 'ai-processing',
  VIEWING = 'viewing',
  LOADING = 'loading'
}

// Variation Sources for DAG tracking
export enum VariationSource {
  USER_EDIT = 'user_edit',
  AI_SUGGESTION = 'ai_suggestion',
  AI_CREATIVE = 'ai_creative',
  IMPORT = 'import',
  BRANCH = 'branch'
}

// Layer Types
export enum LayerType {
  TEXT = 'text',
  IMAGE = 'image',
  BACKGROUND = 'background',
  SHAPE = 'shape',
  GROUP = 'group'
}

// Canvas Dimensions
export interface CanvasDimensions {
  width: number
  height: number
  pixelDensity: number
}

// Transform Properties
export interface Transform {
  x: number
  y: number
  scaleX: number
  scaleY: number
  rotation: number // in degrees
  opacity: number // 0-1
}

// Layer Content (type-specific)
export interface LayerContent {
  // Text layer
  text?: string
  fontSize?: number
  fontFamily?: string
  // Image layer
  imageUrl?: string
  imageData?: string
  // Background layer
  color?: string
  gradient?: {
    type: 'linear' | 'radial'
    stops: Array<{ color: string; position: number }>
  }
  // Shape layer
  shapeType?: 'rectangle' | 'circle' | 'triangle' | 'polygon'
  fill?: string
  stroke?: string
  strokeWidth?: number
  // Group layer
  childLayerIds?: string[]
}

// Layer Style Properties
export interface LayerStyle {
  backgroundColor?: string
  borderRadius?: number
  borderWidth?: number
  borderColor?: string
  boxShadow?: {
    x: number
    y: number
    blur: number
    spread: number
    color: string
  }
  filter?: {
    blur?: number
    brightness?: number
    contrast?: number
    saturate?: number
  }
}

// Layer Constraints
export interface LayerConstraints {
  locked: boolean
  visible: boolean
  maintainAspectRatio?: boolean
  minWidth?: number
  minHeight?: number
  maxWidth?: number
  maxHeight?: number
}

// Metadata Types
export interface LayerMetadata {
  source: 'user' | 'ai'
  createdAt: Date
  modifiedAt?: Date
  version?: number
}

export interface CanvasMetadata {
  createdAt: Date
  modifiedAt: Date
  tags: string[]
  description?: string
  author?: string
}

// Variation and History Types
export interface VariationNode {
  id: string
  parentId: string | null
  childIds: string[]
  canvasData: any // JSON serialized canvas state
  metadata: {
    createdAt: Date
    source: 'user' | 'ai'
    aiMetadata?: {
      confidence: number
      prompt: string
      model: string
    }
  }
}

// AI Collaboration States
export enum AIProcessingState {
  IDLE = 'idle',
  ANALYZING = 'analyzing',
  GENERATING = 'generating',
  READY = 'ready',
  ERROR = 'error'
}

export interface AICollaborationMetadata {
  currentPrompt?: string
  confidenceScores: Record<string, number>
  lastAnalysis?: {
    timestamp: Date
    insights: string[]
    suggestions: string[]
  }
  errorMessage?: string
}

// Gesture Navigation Types
export enum GestureState {
  IDLE = 'idle',
  ACTIVE = 'active',
  MOMENTUM = 'momentum'
}

export interface GesturePhysics {
  velocity: number
  acceleration: number
  friction: number
  threshold: number
}

// Device Simulation Types
export interface DeviceSpec {
  name: string
  dimensions: CanvasDimensions
  screenSize: { width: number; height: number } // in inches
  aspectRatio: number
  pixelDensity: number
  category: 'phone' | 'tablet' | 'desktop'
  os: 'ios' | 'android' | 'web'
}

// Error Types
export class ValidationError extends Error {
  constructor(message: string, public field?: string) {
    super(message)
    this.name = 'ValidationError'
  }
}

export class AIServiceError extends Error {
  constructor(message: string, public code?: string) {
    super(message)
    this.name = 'AIServiceError'
  }
}

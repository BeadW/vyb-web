/**
 * Generated TypeScript types for VYB AI Services
 * DO NOT EDIT - Generated from ai-request.schema.json and ai-response.schema.json
 */

// AI Request Types
export interface AIRequest {
  requestId: string;
  type: AIRequestType;
  timestamp: string;
  context?: RequestContext;
  parameters?: AIRequestParams;
  priority?: 'low' | 'normal' | 'high' | 'urgent';
  timeout?: number;
}

export type AIRequestType = 
  | 'generate-image'
  | 'generate-text'
  | 'suggest-improvement'
  | 'analyze-composition'
  | 'color-palette'
  | 'style-transfer'
  | 'background-removal'
  | 'object-detection'
  | 'content-aware-fill';

export interface RequestContext {
  canvasId?: string;
  elementIds?: string[];
  selectionBounds?: Rectangle;
  canvasDimensions?: Dimensions;
  visibleElements?: {
    id: string;
    type: string;
    bounds: Rectangle;
  }[];
}

export type AIRequestParams = 
  | ImageGenerationParams
  | TextGenerationParams
  | SuggestionParams
  | AnalysisParams
  | ColorPaletteParams
  | StyleTransferParams
  | BackgroundRemovalParams
  | ObjectDetectionParams
  | ContentFillParams;

export interface ImageGenerationParams {
  prompt: string;
  negativePrompt?: string;
  style?: 'photorealistic' | 'illustration' | 'cartoon' | 'abstract' | 'minimalist' | 'vintage' | 'modern' | 'artistic' | 'technical';
  aspectRatio?: '1:1' | '16:9' | '9:16' | '4:3' | '3:4' | '21:9' | 'custom';
  dimensions?: Dimensions;
  seed?: number;
  steps?: number;
  guidance?: number;
  model?: 'gemini-visual' | 'dalle-3' | 'midjourney' | 'stable-diffusion';
}

export interface TextGenerationParams {
  prompt: string;
  maxLength?: number;
  tone?: 'professional' | 'casual' | 'creative' | 'technical' | 'marketing' | 'educational' | 'humorous' | 'formal';
  format?: 'paragraph' | 'bullet-points' | 'headline' | 'tagline' | 'description';
  audience?: 'general' | 'technical' | 'business' | 'creative' | 'academic' | 'social';
  language?: string;
}

export interface SuggestionParams {
  focus?: 'layout' | 'color' | 'typography' | 'spacing' | 'hierarchy' | 'overall';
  goals?: ('engagement' | 'clarity' | 'aesthetics' | 'branding' | 'accessibility' | 'conversion' | 'emotion' | 'simplicity')[];
  constraints?: {
    brandColors?: string[];
    fonts?: string[];
    dimensions?: Dimensions;
  };
}

export interface AnalysisParams {
  analysisType?: 'composition' | 'color-harmony' | 'readability' | 'brand-consistency' | 'accessibility' | 'emotional-impact';
  includeRecommendations?: boolean;
  detailLevel?: 'basic' | 'detailed' | 'comprehensive';
}

export interface ColorPaletteParams {
  baseColor?: string;
  paletteType?: 'monochromatic' | 'analogous' | 'complementary' | 'triadic' | 'tetradic' | 'custom';
  colorCount?: number;
  mood?: 'warm' | 'cool' | 'vibrant' | 'muted' | 'energetic' | 'calming' | 'professional';
  accessibility?: boolean;
}

export interface StyleTransferParams {
  targetStyle: 'watercolor' | 'oil-painting' | 'sketch' | 'digital-art' | 'vintage' | 'modern' | 'minimalist' | 'abstract' | 'realistic';
  strength?: number;
  preserveColors?: boolean;
  preserveStructure?: boolean;
}

export interface BackgroundRemovalParams {
  precision?: 'fast' | 'balanced' | 'precise';
  edgeSmoothing?: boolean;
  returnMask?: boolean;
}

export interface ObjectDetectionParams {
  objectTypes?: ('person' | 'face' | 'text' | 'logo' | 'product' | 'vehicle' | 'building' | 'nature' | 'animal' | 'all')[];
  confidence?: number;
  returnBounds?: boolean;
  returnLabels?: boolean;
}

export interface ContentFillParams {
  maskRegion: Rectangle;
  fillType?: 'smart-fill' | 'pattern-match' | 'blend' | 'generate';
  contextRadius?: number;
}

// AI Response Types
export interface AIResponse {
  requestId: string;
  status: 'success' | 'error' | 'partial' | 'processing';
  timestamp: string;
  processingTime?: number;
  result?: AIResult;
  error?: AIError;
  metadata?: ResponseMetadata;
}

export type AIResult = 
  | ImageResult
  | TextResult
  | SuggestionResult
  | AnalysisResult
  | ColorPaletteResult
  | StyleTransferResult
  | BackgroundRemovalResult
  | ObjectDetectionResult
  | ContentFillResult;

export interface ImageResult {
  images: GeneratedImage[];
  prompt?: string;
  negativePrompt?: string;
  seed?: number;
  model?: string;
}

export interface TextResult {
  text: string;
  alternatives?: string[];
  wordCount?: number;
  readabilityScore?: number;
  tone?: string;
  language?: string;
}

export interface SuggestionResult {
  suggestions: Suggestion[];
  priority?: 'low' | 'medium' | 'high' | 'critical';
  category?: string;
}

export interface AnalysisResult {
  analysis: CanvasAnalysis;
  score?: number;
  recommendations?: Suggestion[];
}

export interface ColorPaletteResult {
  palette: ColorPalette;
  harmony?: 'excellent' | 'good' | 'fair' | 'poor';
  accessibility?: AccessibilityInfo;
}

export interface StyleTransferResult {
  image: GeneratedImage;
  appliedStyle?: string;
  strength?: number;
}

export interface BackgroundRemovalResult {
  image: GeneratedImage;
  mask?: GeneratedImage;
  confidence?: number;
}

export interface ObjectDetectionResult {
  objects: DetectedObject[];
  totalObjects?: number;
}

export interface ContentFillResult {
  image: GeneratedImage;
  fillQuality?: number;
  method?: string;
}

export interface GeneratedImage {
  url: string;
  width: number;
  height: number;
  format?: 'png' | 'jpg' | 'webp' | 'svg';
  size?: number;
  thumbnail?: string;
}

export interface Suggestion {
  id: string;
  type: 'color-change' | 'layout-adjustment' | 'font-change' | 'spacing-improvement' | 
        'element-addition' | 'element-removal' | 'style-enhancement' | 'accessibility-fix' | 'branding-alignment';
  description: string;
  impact?: 'low' | 'medium' | 'high';
  effort?: 'easy' | 'medium' | 'complex';
  targetElementIds?: string[];
  previewUrl?: string;
  actionable?: boolean;
  parameters?: Record<string, any>;
}

export interface CanvasAnalysis {
  composition?: CompositionAnalysis;
  colorHarmony?: ColorAnalysis;
  typography?: TypographyAnalysis;
  accessibility?: AccessibilityAnalysis;
  branding?: BrandingAnalysis;
  emotional?: EmotionalAnalysis;
}

export interface CompositionAnalysis {
  balance?: number;
  hierarchy?: number;
  spacing?: number;
  alignment?: number;
  density?: 'sparse' | 'balanced' | 'dense' | 'overcrowded';
  focusPoints?: FocusPoint[];
}

export interface ColorAnalysis {
  harmony?: number;
  contrast?: number;
  dominantColors?: string[];
  mood?: 'warm' | 'cool' | 'vibrant' | 'muted' | 'energetic' | 'calming';
  accessibilityIssues?: number;
}

export interface TypographyAnalysis {
  readability?: number;
  hierarchy?: number;
  consistency?: number;
  fontCount?: number;
  averageFontSize?: number;
}

export interface AccessibilityAnalysis {
  overallScore?: number;
  colorContrast?: number;
  textSize?: number;
  issues?: AccessibilityIssue[];
}

export interface BrandingAnalysis {
  consistency?: number;
  brandAlignment?: number;
  recognizability?: number;
}

export interface EmotionalAnalysis {
  mood?: 'happy' | 'sad' | 'energetic' | 'calm' | 'professional' | 'playful' | 'serious';
  confidence?: number;
  emotions?: {
    emotion: string;
    strength: number;
  }[];
}

export interface ColorPalette {
  colors: PaletteColor[];
  name?: string;
  type?: string;
}

export interface PaletteColor {
  hex: string;
  name?: string;
  role?: 'primary' | 'secondary' | 'accent' | 'background' | 'text' | 'neutral';
  usage?: string;
}

export interface DetectedObject {
  label: string;
  confidence: number;
  bounds: Rectangle;
  attributes?: Record<string, any>;
}

export interface FocusPoint {
  x: number;
  y: number;
  strength: number;
  elementId?: string;
}

export interface AccessibilityIssue {
  type: 'contrast' | 'text-size' | 'color-only' | 'focus-order' | 'alt-text';
  severity: 'low' | 'medium' | 'high' | 'critical';
  description: string;
  elementId?: string;
  fix?: string;
}

export interface AccessibilityInfo {
  wcagAA?: boolean;
  wcagAAA?: boolean;
  contrastRatios?: {
    foreground: string;
    background: string;
    ratio: number;
  }[];
}

export interface Rectangle {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface Dimensions {
  width: number;
  height: number;
}

export interface AIError {
  code: 'INVALID_REQUEST' | 'TIMEOUT' | 'RATE_LIMIT_EXCEEDED' | 'CONTENT_FILTERED' | 
        'MODEL_UNAVAILABLE' | 'QUOTA_EXCEEDED' | 'INTERNAL_ERROR' | 
        'AUTHENTICATION_FAILED' | 'VALIDATION_ERROR';
  message: string;
  details?: Record<string, any>;
  retryable?: boolean;
  retryAfter?: number;
}

export interface ResponseMetadata {
  model?: string;
  version?: string;
  tokensUsed?: number;
  creditsUsed?: number;
  region?: string;
  cacheHit?: boolean;
}
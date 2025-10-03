/**
 * Generated TypeScript types for VYB Canvas State
 * DO NOT EDIT - Generated from canvas-state.schema.json
 */

export interface CanvasState {
  version: string;
  id: string;
  createdAt: string;
  updatedAt: string;
  title?: string;
  description?: string;
  dimensions?: {
    width: number;
    height: number;
  };
  elements: CanvasElement[];
  history: HistoryNode;
  currentBranch?: string;
  metadata?: {
    tags?: string[];
    collaborators?: string[];
    exportFormats?: ('png' | 'jpg' | 'svg' | 'pdf')[];
  };
}

export interface CanvasElement {
  id: string;
  type: 'text' | 'shape' | 'image' | 'drawing' | 'ai-generated';
  position: Position;
  dimensions?: Dimensions;
  rotation?: number;
  opacity?: number;
  visible?: boolean;
  locked?: boolean;
  createdAt: string;
  updatedAt?: string;
  properties?: TextProperties | ShapeProperties | ImageProperties | DrawingProperties | AIGeneratedProperties;
}

export interface Position {
  x: number;
  y: number;
  z?: number;
}

export interface Dimensions {
  width: number;
  height: number;
}

export interface TextProperties {
  text: string;
  fontSize: number;
  fontFamily?: string;
  fontWeight?: 'normal' | 'bold' | '100' | '200' | '300' | '400' | '500' | '600' | '700' | '800' | '900';
  fontStyle?: 'normal' | 'italic' | 'oblique';
  color?: string;
  backgroundColor?: string;
  textAlign?: 'left' | 'center' | 'right' | 'justify';
  lineHeight?: number;
}

export interface ShapeProperties {
  shapeType: 'rectangle' | 'circle' | 'ellipse' | 'triangle' | 'polygon' | 'line' | 'arrow';
  fill?: string;
  stroke?: Stroke;
  cornerRadius?: number;
  sides?: number;
}

export interface ImageProperties {
  src: string;
  alt?: string;
  crop?: CropRegion;
  filters?: ImageFilters;
}

export interface DrawingProperties {
  paths: DrawingPath[];
  brush?: BrushSettings;
}

export interface AIGeneratedProperties {
  prompt: string;
  generatedAt: string;
  model?: string;
  seed?: number;
  parameters?: Record<string, any>;
  contentType?: 'image' | 'text' | 'shape' | 'suggestion';
}

export interface Stroke {
  color?: string;
  width?: number;
  dashArray?: number[];
  lineCap?: 'butt' | 'round' | 'square';
  lineJoin?: 'miter' | 'round' | 'bevel';
}

export interface CropRegion {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface ImageFilters {
  brightness?: number;
  contrast?: number;
  saturation?: number;
  blur?: number;
  sepia?: number;
  grayscale?: number;
}

export interface DrawingPath {
  points: PathPoint[];
  smooth?: boolean;
}

export interface PathPoint {
  x: number;
  y: number;
  pressure?: number;
  timestamp?: number;
}

export interface BrushSettings {
  size?: number;
  opacity?: number;
  color?: string;
  pressureSensitive?: boolean;
  blendMode?: 'normal' | 'multiply' | 'screen' | 'overlay' | 'darken' | 'lighten';
}

export interface HistoryNode {
  id: string;
  createdAt: string;
  action: HistoryAction;
  parentIds?: string[];
  childIds?: string[];
  branchName?: string;
  metadata?: {
    user?: string;
    device?: string;
    snapshot?: boolean;
  };
}

export interface HistoryAction {
  type: 'create' | 'update' | 'delete' | 'move' | 'rotate' | 'resize' | 
        'style' | 'group' | 'ungroup' | 'duplicate' | 'ai-generate' |
        'import' | 'export' | 'branch' | 'merge';
  elementIds?: string[];
  changes?: Record<string, any>;
  description?: string;
}

// Color type for consistency
export type Color = string; // Hex, RGB, RGBA, HSL, HSLA
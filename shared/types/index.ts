/**
 * Shared utility types and constants for VYB multi-platform app
 */

// Re-export all types for easy importing
export * from './canvas';
export * from './ai';

// Resolve naming conflicts by explicitly re-exporting
export type { Dimensions as CanvasDimensions } from './canvas';
export type { Dimensions as AIDimensions } from './ai';

// Common utility types
export interface Result<T, E = Error> {
  success: boolean;
  data?: T;
  error?: E;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasNext: boolean;
  hasPrevious: boolean;
}

export interface APIResponse<T> {
  status: number;
  message?: string;
  data?: T;
  errors?: string[];
  timestamp: string;
}

// Device simulation types
export interface DeviceProfile {
  id: string;
  name: string;
  category: 'mobile' | 'tablet' | 'desktop' | 'social';
  dimensions: {
    width: number;
    height: number;
  };
  pixelRatio?: number;
  userAgent?: string;
}

export interface DevicePreview {
  deviceId: string;
  canvasId: string;
  scale: number;
  position: {
    x: number;
    y: number;
  };
}

// Common constants
export const SUPPORTED_IMAGE_FORMATS = ['png', 'jpg', 'jpeg', 'webp', 'svg'] as const;
export const SUPPORTED_EXPORT_FORMATS = ['png', 'jpg', 'svg', 'pdf'] as const;
export const MAX_CANVAS_DIMENSION = 10000;
export const MIN_CANVAS_DIMENSION = 100;
export const DEFAULT_CANVAS_DIMENSIONS = { width: 1920, height: 1080 };

export type SupportedImageFormat = typeof SUPPORTED_IMAGE_FORMATS[number];
export type SupportedExportFormat = typeof SUPPORTED_EXPORT_FORMATS[number];

// Validation helpers
export interface ValidationResult {
  valid: boolean;
  errors: string[];
}

// Event types for real-time collaboration
export interface CollaborationEvent {
  id: string;
  type: 'cursor-move' | 'element-select' | 'element-edit' | 'user-join' | 'user-leave';
  userId: string;
  canvasId: string;
  timestamp: string;
  data: Record<string, any>;
}

// Storage types
export interface StorageAdapter {
  get<T>(key: string): Promise<T | null>;
  set<T>(key: string, value: T): Promise<void>;
  delete(key: string): Promise<void>;
  clear(): Promise<void>;
  keys(): Promise<string[]>;
}

// Platform-specific types
export interface PlatformCapabilities {
  supportsTouch: boolean;
  supportsStylus: boolean;
  supportsMultiTouch: boolean;
  maxTouchPoints: number;
  supportsFileSystem: boolean;
  supportsClipboard: boolean;
  supportsCameraAccess: boolean;
  supportsNotifications: boolean;
}
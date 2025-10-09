/**
 * Schema validation utilities for VYB types
 * Uses JSON Schema validation for runtime type checking
 */

import type { CanvasState, CanvasElement } from '../types/canvas';
import type { AIRequest, AIResponse } from '../types/ai';
import type { ValidationResult } from '../types';

// Schema validation would typically use a library like Ajv
// This is a simplified version for type safety

export class SchemaValidator {
  
  /**
   * Validates a canvas state against the schema
   */
  static validateCanvasState(data: unknown): ValidationResult {
    const errors: string[] = [];
    
    if (!data || typeof data !== 'object') {
      return { valid: false, errors: ['Data must be an object'] };
    }
    
    const state = data as Partial<CanvasState>;
    
    // Required fields
    if (!state.version) errors.push('version is required');
    if (!state.id) errors.push('id is required');
    if (!state.createdAt) errors.push('createdAt is required');
    if (!state.updatedAt) errors.push('updatedAt is required');
    if (!Array.isArray(state.elements)) errors.push('elements must be an array');
    if (!state.history) errors.push('history is required');
    
    // Version format
    if (state.version && !/^\d+\.\d+\.\d+$/.test(state.version)) {
      errors.push('version must be in semver format (x.y.z)');
    }
    
    // UUID format (simplified check)
    if (state.id && !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(state.id)) {
      errors.push('id must be a valid UUID');
    }
    
    // Date format
    if (state.createdAt && isNaN(Date.parse(state.createdAt))) {
      errors.push('createdAt must be a valid ISO 8601 date');
    }
    
    if (state.updatedAt && isNaN(Date.parse(state.updatedAt))) {
      errors.push('updatedAt must be a valid ISO 8601 date');
    }
    
    // Title length
    if (state.title && state.title.length > 200) {
      errors.push('title must be 200 characters or less');
    }
    
    // Description length
    if (state.description && state.description.length > 1000) {
      errors.push('description must be 1000 characters or less');
    }
    
    // Dimensions
    if (state.dimensions) {
      if (typeof state.dimensions.width !== 'number' || state.dimensions.width < 100 || state.dimensions.width > 10000) {
        errors.push('dimensions.width must be between 100 and 10000');
      }
      if (typeof state.dimensions.height !== 'number' || state.dimensions.height < 100 || state.dimensions.height > 10000) {
        errors.push('dimensions.height must be between 100 and 10000');
      }
    }
    
    // Validate elements
    if (Array.isArray(state.elements)) {
      state.elements.forEach((element, index) => {
        const elementErrors = this.validateCanvasElement(element);
        if (!elementErrors.valid) {
          errors.push(...elementErrors.errors.map(err => `elements[${index}].${err}`));
        }
      });
    }
    
    return { valid: errors.length === 0, errors };
  }
  
  /**
   * Validates a canvas element against the schema
   */
  static validateCanvasElement(data: unknown): ValidationResult {
    const errors: string[] = [];
    
    if (!data || typeof data !== 'object') {
      return { valid: false, errors: ['Element must be an object'] };
    }
    
    const element = data as Partial<CanvasElement>;
    
    // Required fields
    if (!element.id) errors.push('id is required');
    if (!element.type) errors.push('type is required');
    if (!element.position) errors.push('position is required');
    if (!element.createdAt) errors.push('createdAt is required');
    
    // UUID format
    if (element.id && !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(element.id)) {
      errors.push('id must be a valid UUID');
    }
    
    // Element type
    const validTypes = ['text', 'shape', 'image', 'drawing', 'ai-generated'];
    if (element.type && !validTypes.includes(element.type)) {
      errors.push(`type must be one of: ${validTypes.join(', ')}`);
    }
    
    // Position
    if (element.position) {
      if (typeof element.position.x !== 'number') errors.push('position.x must be a number');
      if (typeof element.position.y !== 'number') errors.push('position.y must be a number');
      if (element.position.z !== undefined && (typeof element.position.z !== 'number' || element.position.z < 0)) {
        errors.push('position.z must be a non-negative number');
      }
    }
    
    // Dimensions
    if (element.dimensions) {
      if (typeof element.dimensions.width !== 'number' || element.dimensions.width < 1) {
        errors.push('dimensions.width must be a positive number');
      }
      if (typeof element.dimensions.height !== 'number' || element.dimensions.height < 1) {
        errors.push('dimensions.height must be a positive number');
      }
    }
    
    // Rotation
    if (element.rotation !== undefined && (typeof element.rotation !== 'number' || element.rotation < 0 || element.rotation > 360)) {
      errors.push('rotation must be between 0 and 360');
    }
    
    // Opacity
    if (element.opacity !== undefined && (typeof element.opacity !== 'number' || element.opacity < 0 || element.opacity > 1)) {
      errors.push('opacity must be between 0 and 1');
    }
    
    // Date format
    if (element.createdAt && isNaN(Date.parse(element.createdAt))) {
      errors.push('createdAt must be a valid ISO 8601 date');
    }
    
    if (element.updatedAt && isNaN(Date.parse(element.updatedAt))) {
      errors.push('updatedAt must be a valid ISO 8601 date');
    }
    
    return { valid: errors.length === 0, errors };
  }
  
  /**
   * Validates an AI request against the schema
   */
  static validateAIRequest(data: unknown): ValidationResult {
    const errors: string[] = [];
    
    if (!data || typeof data !== 'object') {
      return { valid: false, errors: ['Request must be an object'] };
    }
    
    const request = data as Partial<AIRequest>;
    
    // Required fields
    if (!request.requestId) errors.push('requestId is required');
    if (!request.type) errors.push('type is required');
    if (!request.timestamp) errors.push('timestamp is required');
    
    // UUID format
    if (request.requestId && !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(request.requestId)) {
      errors.push('requestId must be a valid UUID');
    }
    
    // Request type
    const validTypes = [
      'generate-image', 'generate-text', 'suggest-improvement', 'analyze-composition',
      'color-palette', 'style-transfer', 'background-removal', 'object-detection', 'content-aware-fill'
    ];
    if (request.type && !validTypes.includes(request.type)) {
      errors.push(`type must be one of: ${validTypes.join(', ')}`);
    }
    
    // Date format
    if (request.timestamp && isNaN(Date.parse(request.timestamp))) {
      errors.push('timestamp must be a valid ISO 8601 date');
    }
    
    // Priority
    if (request.priority && !['low', 'normal', 'high', 'urgent'].includes(request.priority)) {
      errors.push('priority must be one of: low, normal, high, urgent');
    }
    
    // Timeout
    if (request.timeout !== undefined && (typeof request.timeout !== 'number' || request.timeout < 1000 || request.timeout > 300000)) {
      errors.push('timeout must be between 1000 and 300000 milliseconds');
    }
    
    return { valid: errors.length === 0, errors };
  }
  
  /**
   * Validates an AI response against the schema
   */
  static validateAIResponse(data: unknown): ValidationResult {
    const errors: string[] = [];
    
    if (!data || typeof data !== 'object') {
      return { valid: false, errors: ['Response must be an object'] };
    }
    
    const response = data as Partial<AIResponse>;
    
    // Required fields
    if (!response.requestId) errors.push('requestId is required');
    if (!response.status) errors.push('status is required');
    if (!response.timestamp) errors.push('timestamp is required');
    
    // UUID format
    if (response.requestId && !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(response.requestId)) {
      errors.push('requestId must be a valid UUID');
    }
    
    // Status
    if (response.status && !['success', 'error', 'partial', 'processing'].includes(response.status)) {
      errors.push('status must be one of: success, error, partial, processing');
    }
    
    // Date format
    if (response.timestamp && isNaN(Date.parse(response.timestamp))) {
      errors.push('timestamp must be a valid ISO 8601 date');
    }
    
    // Processing time
    if (response.processingTime !== undefined && (typeof response.processingTime !== 'number' || response.processingTime < 0)) {
      errors.push('processingTime must be a non-negative number');
    }
    
    return { valid: errors.length === 0, errors };
  }
  
  /**
   * Validates a color string
   */
  static validateColor(color: string): boolean {
    // Hex color (#RGB, #RRGGBB, #RRGGBBAA)
    if (/^#[0-9A-Fa-f]{3}$/.test(color) || /^#[0-9A-Fa-f]{6}$/.test(color) || /^#[0-9A-Fa-f]{8}$/.test(color)) {
      return true;
    }
    
    // RGB/RGBA
    if (/^rgba?\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*(,\s*[0-1]?(\.[0-9]+)?)?\s*\)$/.test(color)) {
      return true;
    }
    
    // HSL/HSLA
    if (/^hsla?\(\s*\d+\s*,\s*\d+%\s*,\s*\d+%\s*(,\s*[0-1]?(\.[0-9]+)?)?\s*\)$/.test(color)) {
      return true;
    }
    
    return false;
  }
  
  /**
   * Validates a UUID string
   */
  static validateUUID(uuid: string): boolean {
    return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(uuid);
  }
  
  /**
   * Validates an ISO 8601 date string
   */
  static validateISO8601Date(date: string): boolean {
    return !isNaN(Date.parse(date));
  }
}

// Utility functions for common validations
export const isValidColor = SchemaValidator.validateColor;
export const isValidUUID = SchemaValidator.validateUUID;
export const isValidISO8601Date = SchemaValidator.validateISO8601Date;

// Type guards
export function isCanvasState(data: unknown): data is CanvasState {
  return SchemaValidator.validateCanvasState(data).valid;
}

export function isCanvasElement(data: unknown): data is CanvasElement {
  return SchemaValidator.validateCanvasElement(data).valid;
}

export function isAIRequest(data: unknown): data is AIRequest {
  return SchemaValidator.validateAIRequest(data).valid;
}

export function isAIResponse(data: unknown): data is AIResponse {
  return SchemaValidator.validateAIResponse(data).valid;
}
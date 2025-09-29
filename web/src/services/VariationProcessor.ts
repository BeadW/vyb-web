/**
 * Variation Processor - AI response processing and variation generation
 * Implements T047: Web Variation Processing
 * Handles AI response processing, design variation management, and DAG history structure
 */

import React from 'react';
import { DesignCanvas, LayerData } from '../models/DesignCanvas';
import { DesignVariation } from '../models/DesignVariation';
import { AISuggestion, VariationResponse } from './AIService';

// MARK: - Processing Types

export interface LayerChange {
  layerId: string;
  property: string;
  currentValue: any;
  suggestedValue: any;
  reason: string;
}

export interface ProcessingOptions {
  preserveOriginal: boolean;
  maxVariations: number;
  confidenceThreshold: number;
  enableBatching: boolean;
  autoSave: boolean;
}

export interface ProcessingResult {
  processedVariations: DesignVariation[];
  appliedChanges: LayerChange[];
  rejectedChanges: LayerChange[];
  processingTime: number;
  confidence: number;
}

export interface VariationMetrics {
  totalProcessed: number;
  successful: number;
  failed: number;
  averageConfidence: number;
  averageProcessingTime: number;
}

export interface ChangeApplication {
  layerId: string;
  property: string;
  previousValue: any;
  newValue: any;
  success: boolean;
  error?: string;
}

export interface VariationTree {
  root: DesignVariation;
  branches: Map<string, DesignVariation[]>;
  metadata: {
    totalVariations: number;
    maxDepth: number;
    branchCount: number;
  };
}

// MARK: - Variation Processor Class

export class VariationProcessor {
  private metrics: VariationMetrics = {
    totalProcessed: 0,
    successful: 0,
    failed: 0,
    averageConfidence: 0,
    averageProcessingTime: 0
  };

  private defaultOptions: ProcessingOptions = {
    preserveOriginal: true,
    maxVariations: 5,
    confidenceThreshold: 0.5,
    enableBatching: true,
    autoSave: true
  };

  // MARK: - Public API

  /**
   * Process AI response and generate variations
   */
  async processAIResponse(
    aiResponse: VariationResponse,
    baseCanvas: DesignCanvas,
    options?: Partial<ProcessingOptions>
  ): Promise<ProcessingResult> {
    const processOptions = { ...this.defaultOptions, ...options };
    const startTime = Date.now();

    try {
      // Validate AI response
      this.validateAIResponse(aiResponse);

      // Process each variation
      const processedVariations: DesignVariation[] = [];
      const appliedChanges: LayerChange[] = [];
      const rejectedChanges: LayerChange[] = [];

      for (const variationData of aiResponse.variations) {
        if (processedVariations.length >= processOptions.maxVariations) {
          break;
        }

        // Convert DesignCanvas to DesignVariation if needed
        const variation = this.ensureDesignVariation(variationData, baseCanvas);

        if (variation.confidence < processOptions.confidenceThreshold) {
          console.warn(`Skipping variation ${variation.id} due to low confidence: ${variation.confidence}`);
          continue;
        }

        try {
          const processedVariation = await this.processVariation(
            variation,
            processOptions
          );

          processedVariations.push(processedVariation.variation);
          appliedChanges.push(...processedVariation.appliedChanges);
          rejectedChanges.push(...processedVariation.rejectedChanges);

        } catch (error) {
          console.error(`Failed to process variation ${variation.id}:`, error);
          this.metrics.failed++;
        }
      }

      const processingTime = Date.now() - startTime;
      const overallConfidence = this.calculateOverallConfidence(processedVariations);

      // Update metrics
      this.updateMetrics(processedVariations.length, processingTime, overallConfidence);

      return {
        processedVariations,
        appliedChanges,
        rejectedChanges,
        processingTime,
        confidence: overallConfidence
      };

    } catch (error) {
      this.metrics.failed++;
      throw new VariationProcessingError(`Failed to process AI response: ${error}`);
    }
  }

  /**
   * Apply AI suggestions to canvas
   */
  async applySuggestions(
    suggestions: (AISuggestion & { changes?: LayerChange[] })[],
    targetCanvas: DesignCanvas,
    options?: Partial<ProcessingOptions>
  ): Promise<{ canvas: DesignCanvas; changes: ChangeApplication[] }> {
    const processOptions = { ...this.defaultOptions, ...options };
    const changes: ChangeApplication[] = [];

    // Create a deep copy of the canvas
    const modifiedCanvas = this.deepCloneCanvas(targetCanvas);

    for (const suggestion of suggestions) {
      if (suggestion.confidence < processOptions.confidenceThreshold) {
        continue;
      }

      if (suggestion.changes) {
        for (const change of suggestion.changes) {
          try {
            const application = await this.applyLayerChange(modifiedCanvas, change);
            changes.push(application);
          } catch (error) {
            changes.push({
              layerId: change.layerId,
              property: change.property,
              previousValue: change.currentValue,
              newValue: change.suggestedValue,
              success: false,
              error: error instanceof Error ? error.message : String(error)
            });
          }
        }
      }
    }

    return { canvas: modifiedCanvas, changes };
  }

  /**
   * Generate variation preview
   */
  async generateVariationPreview(
    variation: DesignVariation,
    size: { width: number; height: number } = { width: 300, height: 200 }
  ): Promise<string> {
    try {
      // Create a temporary canvas element for rendering
      const canvas = document.createElement('canvas');
      canvas.width = size.width;
      canvas.height = size.height;
      const ctx = canvas.getContext('2d');

      if (!ctx) {
        throw new Error('Cannot create canvas context');
      }

      // Render canvas background
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(0, 0, size.width, size.height);

      // Scale to fit canvas dimensions
      const scaleX = size.width / variation.canvasState.dimensions.width;
      const scaleY = size.height / variation.canvasState.dimensions.height;
      const scale = Math.min(scaleX, scaleY);

      ctx.scale(scale, scale);

      // Render layers
      for (const layer of variation.canvasState.layers) {
        await this.renderLayerToCanvas(ctx, layer);
      }

      // Return base64 data URL
      return canvas.toDataURL('image/png');

    } catch (error) {
      console.error('Failed to generate variation preview:', error);
      throw new VariationProcessingError(`Preview generation failed: ${error}`);
    }
  }

  // MARK: - Private Processing Methods

  private ensureDesignVariation(data: any, baseCanvas: DesignCanvas): DesignVariation {
    // If data is already a DesignVariation, return it
    if (data instanceof DesignVariation) {
      return data;
    }

    // Convert from API response format to DesignVariation
    return new DesignVariation({
      id: data.id || this.generateId(),
      parentId: data.parentId || baseCanvas.id,
      canvasState: data.canvas || data.canvasState || data,
      source: data.source || 'ai_suggestion',
      prompt: data.prompt || 'AI generated variation',
      confidence: data.confidence || 0.5,
      timestamp: new Date(data.timestamp || Date.now()),
      metadata: data.metadata || {
        tags: [],
        notes: '',
        approvalStatus: 'pending' as const
      }
    });
  }

  private async processVariation(
    variation: DesignVariation,
    _options: ProcessingOptions
  ): Promise<{
    variation: DesignVariation;
    appliedChanges: LayerChange[];
    rejectedChanges: LayerChange[];
  }> {
    const appliedChanges: LayerChange[] = [];
    const rejectedChanges: LayerChange[] = [];

    // Validate variation canvas
    this.validateVariationCanvas(variation.canvasState);

    // For now, we'll just return the variation as-is
    // In a real implementation, you might process actual changes
    return {
      variation,
      appliedChanges,
      rejectedChanges
    };
  }

  private async applyLayerChange(
    canvas: DesignCanvas,
    change: LayerChange
  ): Promise<ChangeApplication> {
    const layer = canvas.layers.find(l => l.id === change.layerId);
    
    if (!layer) {
      throw new Error(`Layer ${change.layerId} not found`);
    }

    const previousValue = this.getLayerProperty(layer, change.property);
    
    try {
      this.setLayerProperty(layer, change.property, change.suggestedValue);
      
      return {
        layerId: change.layerId,
        property: change.property,
        previousValue,
        newValue: change.suggestedValue,
        success: true
      };
    } catch (error) {
      throw new Error(`Failed to apply change: ${error}`);
    }
  }

  private getLayerProperty(layer: LayerData, propertyPath: string): any {
    const path = propertyPath.split('.');
    let current: any = layer;
    
    for (const segment of path) {
      if (current && typeof current === 'object' && segment in current) {
        current = current[segment];
      } else {
        throw new Error(`Property ${propertyPath} not found on layer`);
      }
    }
    
    return current;
  }

  private setLayerProperty(layer: LayerData, propertyPath: string, value: any): void {
    const path = propertyPath.split('.');
    let current: any = layer;
    
    for (let i = 0; i < path.length - 1; i++) {
      const segment = path[i];
      if (current && typeof current === 'object' && segment in current) {
        current = current[segment];
      } else {
        throw new Error(`Property path ${propertyPath} not valid`);
      }
    }
    
    const finalProperty = path[path.length - 1];
    current[finalProperty] = value;
  }

  private async renderLayerToCanvas(ctx: CanvasRenderingContext2D, layer: LayerData): Promise<void> {
    ctx.save();
    
    // Apply transform
    ctx.globalAlpha = layer.transform.opacity;
    ctx.translate(layer.transform.x, layer.transform.y);
    ctx.scale(layer.transform.scaleX, layer.transform.scaleY);
    ctx.rotate((layer.transform.rotation * Math.PI) / 180);

    try {
      switch (layer.type) {
        case 'text':
          await this.renderTextLayer(ctx, layer);
          break;
        case 'shape':
          await this.renderShapeLayer(ctx, layer);
          break;
        case 'image':
          await this.renderImageLayer(ctx, layer);
          break;
        case 'background':
          await this.renderBackgroundLayer(ctx, layer);
          break;
        default:
          console.warn(`Unknown layer type: ${layer.type}`);
      }
    } catch (error) {
      console.error(`Failed to render layer ${layer.id}:`, error);
    }

    ctx.restore();
  }

  private async renderTextLayer(ctx: CanvasRenderingContext2D, layer: LayerData): Promise<void> {
    if (!layer.content.text) return;

    const fontSize = layer.content.fontSize || 16;
    const fontFamily = layer.content.fontFamily || 'Inter';
    const color = layer.style?.color || '#000000';

    ctx.font = `${fontSize}px ${fontFamily}`;
    ctx.fillStyle = color;
    ctx.textAlign = 'left';
    ctx.textBaseline = 'top';

    ctx.fillText(layer.content.text, 0, 0);
  }

  private async renderShapeLayer(ctx: CanvasRenderingContext2D, layer: LayerData): Promise<void> {
    const width = 100; // Default shape size
    const height = 100;
    const fill = layer.content.fill || '#3B82F6';
    const stroke = layer.content.stroke;
    const strokeWidth = layer.content.strokeWidth || 0;

    ctx.fillStyle = fill;
    ctx.fillRect(0, 0, width, height);

    if (stroke && strokeWidth > 0) {
      ctx.strokeStyle = stroke;
      ctx.lineWidth = strokeWidth;
      ctx.strokeRect(0, 0, width, height);
    }
  }

  private async renderImageLayer(ctx: CanvasRenderingContext2D, _layer: LayerData): Promise<void> {
    // Placeholder for image rendering
    ctx.fillStyle = '#E5E7EB';
    ctx.fillRect(0, 0, 100, 100);
    
    ctx.fillStyle = '#9CA3AF';
    ctx.font = '12px Inter';
    ctx.textAlign = 'center';
    ctx.fillText('Image', 50, 50);
  }

  private async renderBackgroundLayer(ctx: CanvasRenderingContext2D, layer: LayerData): Promise<void> {
    const color = layer.content.color || '#ffffff';
    ctx.fillStyle = color;
    ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
  }

  // MARK: - Validation Methods

  private validateAIResponse(response: VariationResponse): void {
    if (!response.variations || !Array.isArray(response.variations)) {
      throw new VariationProcessingError('Invalid AI response: missing variations array');
    }

    if (response.variations.length === 0) {
      throw new VariationProcessingError('AI response contains no variations');
    }

    for (const variation of response.variations) {
      if (!variation.id) {
        throw new VariationProcessingError('Invalid variation: missing id');
      }
    }
  }

  private validateVariationCanvas(canvas: DesignCanvas): void {
    if (!canvas.layers || canvas.layers.length === 0) {
      throw new VariationProcessingError('Variation canvas must contain at least one layer');
    }

    for (const layer of canvas.layers) {
      if (!layer.id || !layer.type) {
        throw new VariationProcessingError(`Invalid layer: missing id or type`);
      }
    }
  }

  // MARK: - Utility Methods

  private generateId(): string {
    return crypto.randomUUID();
  }

  private deepCloneCanvas(canvas: DesignCanvas): DesignCanvas {
    return JSON.parse(JSON.stringify(canvas)) as DesignCanvas;
  }

  private calculateOverallConfidence(variations: DesignVariation[]): number {
    if (variations.length === 0) return 0;
    
    const totalConfidence = variations.reduce((sum, v) => sum + v.confidence, 0);
    return totalConfidence / variations.length;
  }

  private updateMetrics(processed: number, time: number, confidence: number): void {
    this.metrics.totalProcessed += processed;
    this.metrics.successful += processed;
    
    // Running average calculation
    const total = this.metrics.successful;
    if (total > 0) {
      this.metrics.averageProcessingTime = 
        (this.metrics.averageProcessingTime * (total - processed) + time) / total;
      
      this.metrics.averageConfidence = 
        (this.metrics.averageConfidence * (total - processed) + confidence * processed) / total;
    }
  }

  // MARK: - Public Utility Methods

  public getMetrics(): VariationMetrics {
    return { ...this.metrics };
  }

  public clearMetrics(): void {
    this.metrics = {
      totalProcessed: 0,
      successful: 0,
      failed: 0,
      averageConfidence: 0,
      averageProcessingTime: 0
    };
  }
}

// MARK: - Error Classes

export class VariationProcessingError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'VariationProcessingError';
  }
}

// MARK: - Singleton Instance

export const variationProcessor = new VariationProcessor();

// MARK: - React Hook Integration

export interface UseVariationProcessorOptions {
  autoProcess?: boolean;
  preserveOriginal?: boolean;
  confidenceThreshold?: number;
}

export function useVariationProcessor(options: UseVariationProcessorOptions = {}) {
  const [isProcessing, setIsProcessing] = React.useState(false);
  const [error, setError] = React.useState<Error | null>(null);
  const [metrics, setMetrics] = React.useState<VariationMetrics>(() => 
    variationProcessor.getMetrics()
  );

  const processAIResponse = React.useCallback(async (
    response: VariationResponse,
    baseCanvas: DesignCanvas,
    processingOptions?: Partial<ProcessingOptions>
  ) => {
    setIsProcessing(true);
    setError(null);

    try {
      const result = await variationProcessor.processAIResponse(
        response,
        baseCanvas,
        {
          preserveOriginal: options.preserveOriginal ?? true,
          confidenceThreshold: options.confidenceThreshold ?? 0.5,
          ...processingOptions
        }
      );

      setMetrics(variationProcessor.getMetrics());
      return result;
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      setError(error);
      throw error;
    } finally {
      setIsProcessing(false);
    }
  }, [options]);

  const generatePreview = React.useCallback(async (
    variation: DesignVariation,
    size?: { width: number; height: number }
  ) => {
    try {
      return await variationProcessor.generateVariationPreview(variation, size);
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      setError(error);
      throw error;
    }
  }, []);

  return {
    processAIResponse,
    generatePreview,
    isProcessing,
    error,
    metrics,
    clearError: () => setError(null),
    clearMetrics: () => {
      variationProcessor.clearMetrics();
      setMetrics(variationProcessor.getMetrics());
    }
  };
}
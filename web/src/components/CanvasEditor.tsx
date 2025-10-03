import React, { useEffect, useRef, useState } from 'react';
import { fabric } from 'fabric';
import { DeviceType, LayerType } from '../types';
import { DeviceUtils } from '../data/device-specs';
import FacebookPost from './FacebookPost';

// Simplified interfaces for the Canvas Editor
interface CanvasLayer {
  id: string;
  type: LayerType;
  name: string;
  visible: boolean;
  locked: boolean;
  opacity: number;
  transform: {
    x: number;
    y: number;
    rotation: number;
    scaleX: number;
    scaleY: number;
    opacity: number;
  };
  content: {
    text?: string;
    fontSize?: number;
    fontFamily?: string;
    color?: string;
    fontWeight?: string;
    shapeType?: 'rectangle' | 'circle';
    width?: number;
    height?: number;
    radius?: number;
    fillColor?: string;
    strokeColor?: string | null;
    strokeWidth?: number;
    url?: string;
  };
}

interface CanvasEditorProps {
  deviceType?: DeviceType;
  onCanvasChange?: (layers: CanvasLayer[]) => void;
  className?: string;
}

interface CanvasState {
  fabricCanvas: fabric.Canvas | null;
  selectedLayer: CanvasLayer | null;
  zoomLevel: number;
  isLoading: boolean;
}

/**
 * CanvasEditor - Main canvas component with Fabric.js integration
 * Provides layer management, object manipulation, and device simulation integration
 */
export const CanvasEditor: React.FC<CanvasEditorProps> = ({
  deviceType = DeviceType.IPHONE_15_PRO,
  onCanvasChange = () => {},
  className = ''
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [layers, setLayers] = useState<CanvasLayer[]>([
    // Default post text layer
    {
      id: 'post_text_default',
      type: LayerType.POST_TEXT,
      name: 'Post Text',
      visible: true,
      locked: false,
      opacity: 1,
      transform: {
        x: 0,
        y: 0,
        rotation: 0,
        scaleX: 1,
        scaleY: 1,
        opacity: 1
      },
      content: {
        text: 'Just had an amazing day at the beach! 🏖️ The sunset was absolutely gorgeous and I couldn\'t resist sharing this moment with you all. Life is beautiful when you take time to appreciate the little things. ✨',
        fontSize: 14,
        fontFamily: 'system-ui',
        color: '#1f2937',
        fontWeight: 'normal'
      }
    }
  ]);
  const [canvasState, setCanvasState] = useState<CanvasState>({
    fabricCanvas: null,
    selectedLayer: null,
    zoomLevel: 1,
    isLoading: false  // Start with false for testing
  });

  // Get device specifications
  const deviceSpec = DeviceUtils.getDeviceSpec(deviceType);
  const canvasWidth = deviceSpec.dimensions.width;
  const canvasHeight = deviceSpec.dimensions.height;

  // Initialize canvas immediately 
  useEffect(() => {
    console.log('🎨 CanvasEditor: Starting initialization...');
    
    if (!canvasRef.current) {
      console.log('❌ CanvasEditor: Canvas ref not ready');
      return;
    }

    // Set loading to false immediately for testing
    console.log('✅ CanvasEditor: Canvas ref ready, stopping loading state');
    setCanvasState(prev => ({
      ...prev,
      isLoading: false
    }));

    // Try to initialize Fabric.js
    try {
      console.log('🔧 CanvasEditor: Initializing Fabric.js canvas for drawing...');
      
      if (!canvasRef.current) return;
      
      // Initialize Fabric.js canvas
      // Calculate height based on aspect ratio (16:10 as defined in FacebookPost)
      const aspectRatio = 16 / 10;
      const calculatedHeight = canvasWidth / aspectRatio;
      
      const fabricCanvas = new fabric.Canvas(canvasRef.current, {
        width: canvasWidth,
        height: calculatedHeight,
        backgroundColor: '#ec4899', // Use pink from the gradient as solid background
        preserveObjectStacking: true
      });

      // Enable canvas interaction
      fabricCanvas.selection = true;
      fabricCanvas.defaultCursor = 'default';
      fabricCanvas.moveCursor = 'move';
      
      setCanvasState(prev => ({
        ...prev,
        fabricCanvas: fabricCanvas,
        isLoading: false
      }));

      console.log('✅ CanvasEditor: Fabric.js canvas initialized successfully');

      // Cleanup function
      return () => {
        fabricCanvas?.dispose();
      };
    } catch (error) {
      console.error('❌ CanvasEditor: Fabric.js initialization failed:', error);
      // Still set loading to false so we don't get stuck
      setCanvasState(prev => ({
        ...prev,
        isLoading: false
      }));
    }
  }, [canvasWidth, canvasHeight]);

  // Simplified for testing - no event handlers

  // Update post text layer
  const updatePostText = (newText: string) => {
    const updatedLayers = layers.map(layer => {
      if (layer.type === LayerType.POST_TEXT) {
        return {
          ...layer,
          content: {
            ...layer.content,
            text: newText
          }
        };
      }
      return layer;
    });
    setLayers(updatedLayers);
    onCanvasChange(updatedLayers);
  };

  // Public methods for external layer management
  const addTextLayer = (text: string = 'New Text') => {
    if (!canvasState.fabricCanvas) return;

    const newLayer: CanvasLayer = {
      id: `layer_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      type: LayerType.TEXT,
      name: 'Text Layer',
      visible: true,
      locked: false,
      opacity: 1,
      transform: {
        x: 50,
        y: 50,
        rotation: 0,
        scaleX: 1,
        scaleY: 1,
        opacity: 1
      },
      content: {
        text,
        fontSize: 16,
        fontFamily: 'Arial',
        color: '#000000',
        fontWeight: 'normal'
      }
    };

    // Create and add fabric object directly
    const fabricText = new fabric.Text(text, {
      left: 50,
      top: 50,
      fontSize: 16,
      fontFamily: 'Arial',
      fill: '#000000'
    });

    (fabricText as any).layerId = newLayer.id;
    canvasState.fabricCanvas.add(fabricText);
    canvasState.fabricCanvas.renderAll();

    const newLayers = [...layers, newLayer];
    setLayers(newLayers);
    onCanvasChange(newLayers);
  };

  const addShapeLayer = (shapeType: 'rectangle' | 'circle' = 'rectangle') => {
    if (!canvasState.fabricCanvas) return;

    const newLayer: CanvasLayer = {
      id: `layer_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      type: LayerType.SHAPE,
      name: `${shapeType} Layer`,
      visible: true,
      locked: false,
      opacity: 1,
      transform: {
        x: 100,
        y: 100,
        rotation: 0,
        scaleX: 1,
        scaleY: 1,
        opacity: 1
      },
      content: {
        shapeType,
        width: shapeType === 'rectangle' ? 100 : undefined,
        height: shapeType === 'rectangle' ? 100 : undefined,
        radius: shapeType === 'circle' ? 50 : undefined,
        fillColor: '#3b82f6',
        strokeColor: null,
        strokeWidth: 0
      }
    };

    // Create and add fabric object directly
    let fabricObject: fabric.Object;
    if (shapeType === 'rectangle') {
      fabricObject = new fabric.Rect({
        left: 100,
        top: 100,
        width: 100,
        height: 100,
        fill: '#3b82f6'
      });
    } else {
      fabricObject = new fabric.Circle({
        left: 100,
        top: 100,
        radius: 50,
        fill: '#3b82f6'
      });
    }

    (fabricObject as any).layerId = newLayer.id;
    canvasState.fabricCanvas.add(fabricObject);
    canvasState.fabricCanvas.renderAll();

    const newLayers = [...layers, newLayer];
    setLayers(newLayers);
    onCanvasChange(newLayers);
  };

  // Simplified for testing - no event handlers

  if (canvasState.isLoading) {
    console.log('🔄 CanvasEditor: Rendering loading state...');
    return (
      <div className={`flex items-center justify-center h-96 ${className}`}>
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading canvas...</p>
        </div>
      </div>
    );
  }

  console.log('✅ CanvasEditor: Rendering canvas element...');

  return (
    <FacebookPost 
      className={className} 
      ref={containerRef}
      layers={layers}
      onAddText={() => addTextLayer()}
      onAddRect={() => addShapeLayer('rectangle')}
      onAddCircle={() => addShapeLayer('circle')}
      onUpdatePostText={updatePostText}
    >
      <canvas
        ref={canvasRef}
        className="block w-full h-full bg-gradient-to-br from-orange-400 via-pink-500 to-purple-600"
        style={{ maxWidth: '100%', maxHeight: '100%' }}
      />
    </FacebookPost>
  );
};

export default CanvasEditor;
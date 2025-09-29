import React, { useEffect, useRef, useState } from 'react';
import { fabric } from 'fabric';
import { DeviceType, LayerType } from '../types';
import { DeviceUtils } from '../data/device-specs';

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
  const [layers, setLayers] = useState<CanvasLayer[]>([]);
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
      console.log('🔧 CanvasEditor: Initializing Fabric.js for Facebook post...');
      
      if (!containerRef.current) return;
      
      const containerRect = containerRef.current.getBoundingClientRect();
      const containerWidth = containerRect.width || 400;
      
      const fabricCanvas = new fabric.Canvas(canvasRef.current, {
        width: containerWidth,
        height: Math.round(containerWidth * 10 / 16), // Facebook image ratio 16:10
        backgroundColor: '#ffffff',
        selection: true,
        preserveObjectStacking: true,
      });

      // Keep canvas completely empty - no placeholder text or objects
      fabricCanvas.clear();
      fabricCanvas.renderAll();
      
      // Force clear any cached objects and reset completely
      fabricCanvas.getObjects().forEach(obj => {
        fabricCanvas.remove(obj);
      });
      fabricCanvas.requestRenderAll();
      
      // Clear any browser storage that might be restoring objects
      try {
        localStorage.removeItem('canvasState');
        localStorage.removeItem('fabricCanvasObjects');
        sessionStorage.removeItem('canvasState');
        sessionStorage.removeItem('fabricCanvasObjects');
      } catch (e) {
        // ignore storage errors
      }
      
      setCanvasState(prev => ({
        ...prev,
        fabricCanvas,
        isLoading: false
      }));

      console.log('✅ CanvasEditor: Fabric.js initialized successfully');

      return () => {
        fabricCanvas.dispose();
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
    <div className={`w-full h-full ${className}`} style={{ backgroundColor: '#f0f2f5' }}>
      {/* Facebook-like Background with Post Card */}
      <div className="max-w-md mx-auto bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        
        {/* Facebook Post Header */}
        <div className="flex items-center justify-between p-3">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center overflow-hidden">
              <svg className="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
              </svg>
            </div>
            <div>
              <div className="font-semibold text-gray-900 text-sm">Facebook User</div>
              <div className="flex items-center text-xs text-gray-500">
                <span>10 hrs</span>
                <span className="mx-1">·</span>
                <svg className="w-2 h-2" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd"/>
                </svg>
              </div>
            </div>
          </div>
          <button className="text-gray-400 hover:bg-gray-100 p-1 rounded-full">
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
              <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z"/>
            </svg>
          </button>
        </div>

        {/* Facebook Post Text */}
        <div className="px-3 pb-3">
          <p className="text-gray-900 text-sm leading-5">
            This is a regular Facebook post mockup as viewed from the Desktop site. Easily add your own text here and drop your image below into the placeholder.
          </p>
        </div>

        {/* Facebook Image Area (Our Canvas) - This is the main design area */}
        <div className="w-full">
          <div 
            ref={containerRef} 
            className="w-full relative bg-gray-100 border-t border-b border-gray-200"
            style={{ aspectRatio: '16/10' }} // Facebook image ratio
          >
            <canvas
              ref={canvasRef}
              className="w-full h-full block"
            />
          </div>
        </div>

        {/* Facebook Post Stats */}
        <div className="px-3 py-2">
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center space-x-1">
              <div className="flex items-center">
                <div className="w-4 h-4 bg-blue-600 rounded-full flex items-center justify-center mr-1">
                  <span className="text-white text-xs">👍</span>
                </div>
                <div className="w-4 h-4 bg-red-500 rounded-full flex items-center justify-center -ml-1">
                  <span className="text-white text-xs">❤️</span>
                </div>
              </div>
              <span className="text-gray-600 ml-1">12</span>
            </div>
            <div className="text-gray-500 text-sm">
              
            </div>
          </div>
        </div>

        {/* Facebook Action Buttons */}
        <div className="border-t border-gray-200 px-1 py-1">
          <div className="flex">
            <button className="flex-1 flex items-center justify-center py-2 text-gray-600 hover:bg-gray-50 rounded transition-colors">
              <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V8a2 2 0 00-2-2H4.5c-.9 0-1.5.6-1.5 1.5v1c0 .9.6 1.5 1.5 1.5H7m7-10v2m0 0V8c0-1.1-.9-2-2-2H7m7 0h3"/>
              </svg>
              <span className="text-sm">Like</span>
            </button>
            <button className="flex-1 flex items-center justify-center py-2 text-gray-600 hover:bg-gray-50 rounded transition-colors">
              <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
              </svg>
              <span className="text-sm">Comment</span>
            </button>
            <button className="flex-1 flex items-center justify-center py-2 text-gray-600 hover:bg-gray-50 rounded transition-colors">
              <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z"/>
              </svg>
              <span className="text-sm">Share</span>
            </button>
          </div>
        </div>

      </div>

      {/* Design Tools - Fixed at bottom */}
      <div className="mt-auto bg-blue-50 border-t border-blue-200 p-2">
        <div className="flex items-center justify-center space-x-3">
          <button
            onClick={() => addTextLayer()}
            className="px-3 py-1.5 bg-blue-600 text-white rounded text-sm hover:bg-blue-700"
          >
            Add Text
          </button>
          <button
            onClick={() => addShapeLayer('rectangle')}
            className="px-3 py-1.5 bg-green-600 text-white rounded text-sm hover:bg-green-700"
          >
            Add Shape
          </button>
          <button
            onClick={() => addShapeLayer('circle')}
            className="px-3 py-1.5 bg-purple-600 text-white rounded text-sm hover:bg-purple-700"
          >
            Add Circle
          </button>
        </div>
        <div className="text-center mt-1">
          <span className="text-xs text-gray-600">{layers.length} design elements</span>
        </div>
      </div>
    </div>
  );
};

export default CanvasEditor;
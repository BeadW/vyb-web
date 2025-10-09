import React, { useState } from 'react'
import { CanvasEditor } from '../components/CanvasEditor'
import { DeviceType } from '../types'

interface CanvasLayer {
  id: string;
  type: any;
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
  content: any;
}

/**
 * Demo page for testing the CanvasEditor component
 */
export const CanvasDemo: React.FC = () => {
  const [selectedDevice, setSelectedDevice] = useState<DeviceType>(DeviceType.IPHONE_15_PRO);
  const [layers, setLayers] = useState<CanvasLayer[]>([]);

  const handleCanvasChange = (updatedLayers: CanvasLayer[]) => {
    setLayers(updatedLayers);
    console.log('Canvas updated:', updatedLayers);
  };

  const handleDeviceChange = (device: DeviceType) => {
    setSelectedDevice(device);
  };

  return (
    <div className="canvas-demo h-screen flex flex-col bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200 p-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Visual AI Collaboration Canvas</h1>
            <p className="text-gray-600">Interactive design canvas with device simulation</p>
          </div>
          
          {/* Device Selector */}
          <div className="flex items-center space-x-4">
            <label htmlFor="device-select" className="text-sm font-medium text-gray-700">
              Device:
            </label>
            <select
              id="device-select"
              value={selectedDevice}
              onChange={(e) => handleDeviceChange(e.target.value as DeviceType)}
              className="px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value={DeviceType.IPHONE_15_PRO}>iPhone 15 Pro</option>
              <option value={DeviceType.IPHONE_15_PLUS}>iPhone 15 Plus</option>
              <option value={DeviceType.IPAD_PRO_11}>iPad Pro 11"</option>
              <option value={DeviceType.IPAD_PRO_129}>iPad Pro 12.9"</option>
              <option value={DeviceType.PIXEL_8_PRO}>Pixel 8 Pro</option>
              <option value={DeviceType.GALAXY_S24_ULTRA}>Galaxy S24 Ultra</option>
            </select>
          </div>
        </div>
      </header>

      {/* Main Canvas Area */}
      <main className="flex-1 overflow-hidden">
        <CanvasEditor
          deviceType={selectedDevice}
          onCanvasChange={handleCanvasChange}
          className="h-full"
        />
      </main>

      {/* Status Bar */}
      <footer className="bg-white border-t border-gray-200 p-3">
        <div className="flex items-center justify-between text-sm text-gray-600">
          <div className="flex items-center space-x-6">
            <span>Device: {selectedDevice}</span>
            <span>Layers: {layers.length}</span>
            <span>Ready</span>
          </div>
          
          <div className="flex items-center space-x-4">
            <span className="text-xs text-gray-500">
              Use toolbar to add elements • Click layers to select • Arrow keys for precise movement
            </span>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default CanvasDemo;
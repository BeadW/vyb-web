import { describe, it, expect } from 'vitest'
import { Layer } from '../../../src/entities/Layer'
import { LayerType, LayerContent, Transform, LayerStyle, LayerConstraints } from '../../../src/types'

describe('Layer Entity', () => {
  describe('Creation and Validation', () => {
    it('should create a valid Layer with required fields', () => {
      const layer = new Layer({
        id: 'layer-123',
        type: LayerType.TEXT,
        content: { 
          text: 'Hello World',
          fontSize: 16,
          fontFamily: 'Arial'
        } satisfies LayerContent,
        transform: {
          x: 100,
          y: 200,
          scaleX: 1.5,
          scaleY: 1.5,
          rotation: 45,
          opacity: 0.8
        } as Transform,
        style: {
          color: '#333333',
          backgroundColor: '#ffffff',
          borderRadius: 8
        } as LayerStyle,
        constraints: {
          locked: false,
          visible: true,
          interactive: true
        } as LayerConstraints,
        metadata: {
          source: 'user',
          createdAt: new Date(),
          modifiedAt: new Date()
        }
      })

      expect(layer.id).toBe('layer-123')
      expect(layer.type).toBe(LayerType.TEXT)
      expect(layer.content.text).toBe('Hello World')
      expect(layer.transform.x).toBe(100)
      expect(layer.style.color).toBe('#333333')
    })

    it('should validate layer ID is unique within canvas', () => {
      expect(() => {
        new Layer({
          id: '', // Invalid empty ID
          type: LayerType.TEXT,
          content: { text: 'Test' },
          transform: { x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
          style: {},
          constraints: { locked: false, visible: true },
          metadata: { source: 'user', createdAt: new Date() }
        })
      }).toThrow('Layer ID must be unique within parent canvas')
    })

    it('should validate transform values are within canvas boundaries', () => {
      expect(() => {
        new Layer({
          id: 'layer-123',
          type: LayerType.TEXT,
          content: { text: 'Test' },
          transform: { 
            x: -500, // Outside canvas boundaries
            y: 2000, // Outside canvas boundaries
            scaleX: 1, 
            scaleY: 1, 
            rotation: 0, 
            opacity: 1 
          },
          style: {},
          constraints: { locked: false, visible: true },
          metadata: { source: 'user', createdAt: new Date() }
        })
      }).toThrow('Transform values must be within canvas boundaries')
    })

    it('should validate content matches layer type specifications', () => {
      expect(() => {
        new Layer({
          id: 'layer-123',
          type: LayerType.IMAGE,
          content: { 
            text: 'This is text content' // Wrong content type for IMAGE layer
          },
          transform: { x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
          style: {},
          constraints: { locked: false, visible: true },
          metadata: { source: 'user', createdAt: new Date() }
        })
      }).toThrow('Content must match layer type specifications')
    })

    it('should validate style properties are valid for layer type', () => {
      expect(() => {
        new Layer({
          id: 'layer-123',
          type: LayerType.TEXT,
          content: { text: 'Test', fontSize: 16 },
          transform: { x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
          style: { 
            src: 'invalid-property-for-text.jpg' // Invalid style for text layer
          },
          constraints: { locked: false, visible: true },
          metadata: { source: 'user', createdAt: new Date() }
        })
      }).toThrow('Style properties must be valid for layer type')
    })
  })

  describe('Layer Type Validation', () => {
    it('should validate TEXT layer content structure', () => {
      const textLayer = new Layer({
        id: 'text-layer',
        type: LayerType.TEXT,
        content: {
          text: 'Sample text',
          fontSize: 18,
          fontFamily: 'Helvetica',
          fontWeight: 'bold',
          textAlign: 'center'
        },
        transform: { x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
        style: { color: '#000000' },
        constraints: { locked: false, visible: true },
        metadata: { source: 'user', createdAt: new Date() }
      })

      expect(textLayer.content.text).toBe('Sample text')
      expect(textLayer.content.fontSize).toBe(18)
    })

    it('should validate IMAGE layer content structure', () => {
      const imageLayer = new Layer({
        id: 'image-layer',
        type: LayerType.IMAGE,
        content: {
          src: 'https://example.com/image.jpg',
          alt: 'Sample image',
          width: 300,
          height: 200
        },
        transform: { x: 50, y: 50, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
        style: { borderRadius: 10 },
        constraints: { locked: false, visible: true },
        metadata: { source: 'ai', createdAt: new Date() }
      })

      expect(imageLayer.content.src).toBe('https://example.com/image.jpg')
      expect(imageLayer.content.width).toBe(300)
    })

    it('should validate SHAPE layer content structure', () => {
      const shapeLayer = new Layer({
        id: 'shape-layer',
        type: LayerType.SHAPE,
        content: {
          shapeType: 'rectangle',
          width: 150,
          height: 100,
          fill: '#ff0000',
          stroke: '#000000',
          strokeWidth: 2
        },
        transform: { x: 100, y: 100, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
        style: { borderRadius: 5 },
        constraints: { locked: false, visible: true },
        metadata: { source: 'user', createdAt: new Date() }
      })

      expect(shapeLayer.content.shapeType).toBe('rectangle')
      expect(shapeLayer.content.fill).toBe('#ff0000')
    })

    it('should validate GROUP layer can contain other layers', () => {
      const groupLayer = new Layer({
        id: 'group-layer',
        type: LayerType.GROUP,
        content: {
          children: ['child-layer-1', 'child-layer-2'],
          groupType: 'container'
        },
        transform: { x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
        style: {},
        constraints: { locked: false, visible: true },
        metadata: { source: 'user', createdAt: new Date() }
      })

      expect(groupLayer.content.children).toHaveLength(2)
      expect(groupLayer.content.children[0]).toBe('child-layer-1')
    })
  })

  describe('Transform Operations', () => {
    it('should validate transform boundary constraints', () => {
      const layer = new Layer({
        id: 'transform-layer',
        type: LayerType.TEXT,
        content: { text: 'Test' },
        transform: { x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, opacity: 1 },
        style: {},
        constraints: { locked: false, visible: true },
        metadata: { source: 'user', createdAt: new Date() }
      })

      // Test valid transform update
      layer.updateTransform({ x: 50, y: 100 })
      expect(layer.transform.x).toBe(50)
      expect(layer.transform.y).toBe(100)

      // Test invalid transform (outside boundaries)
      expect(() => {
        layer.updateTransform({ x: -1000, y: -1000 })
      }).toThrow('Transform values must be within canvas boundaries')
    })

    it('should validate opacity range (0-1)', () => {
      expect(() => {
        new Layer({
          id: 'opacity-layer',
          type: LayerType.TEXT,
          content: { text: 'Test' },
          transform: { 
            x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, 
            opacity: 1.5 // Invalid opacity > 1
          },
          style: {},
          constraints: { locked: false, visible: true },
          metadata: { source: 'user', createdAt: new Date() }
        })
      }).toThrow('Opacity must be between 0 and 1')
    })

    it('should validate rotation range (0-360)', () => {
      expect(() => {
        new Layer({
          id: 'rotation-layer',
          type: LayerType.TEXT,
          content: { text: 'Test' },
          transform: { 
            x: 0, y: 0, scaleX: 1, scaleY: 1, 
            rotation: 400, // Invalid rotation > 360
            opacity: 1 
          },
          style: {},
          constraints: { locked: false, visible: true },
          metadata: { source: 'user', createdAt: new Date() }
        })
      }).toThrow('Rotation must be between 0 and 360 degrees')
    })
  })
})
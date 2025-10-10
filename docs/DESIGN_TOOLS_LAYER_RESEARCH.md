# Design Tools Layer System Research

**Research Date**: October 9, 2025  
**Purpose**: Identify MVP layer types for VYB based on industry-leading design tools  
**Focus**: SVG-based implementation with essential features for social media design  

## Research Summary

### Canva Layer System Analysis

**Core Layer Types** (MVP Priority):
1. **Text Layers**
   - Rich text with fonts, sizes, colors
   - Text effects (shadows, outlines, gradients)
   - Auto-resize containers
   - Text on path support

2. **Shape Layers**
   - Rectangles, circles, triangles, polygons
   - Custom SVG paths
   - Fill, stroke, gradient support
   - Smart corner radius

3. **Image Layers**
   - Photo uploads and stock images
   - Crop, filters, masks
   - Background removal
   - Smart resize and positioning

4. **Background Layers**
   - Solid colors, gradients
   - Pattern fills, textures
   - Image backgrounds with opacity

5. **Group Layers**
   - Logical grouping for bulk operations
   - Nested hierarchy support
   - Group transformations

### Figma Layer System Analysis

**Key Features**:
- **Vector Networks**: Advanced path editing
- **Auto Layout**: Responsive constraints
- **Components**: Reusable design elements
- **Effects**: Drop shadow, inner shadow, blur
- **Blend Modes**: Multiply, overlay, screen, etc.

### Adobe Creative Suite Analysis

**InDesign/Illustrator Layers**:
- **Layer hierarchy** with sublayers
- **Clipping masks** for advanced effects
- **Blend modes** for compositing
- **Style sheets** for consistent formatting

## MVP Layer Types for VYB

Based on research and social media design needs:

### 1. Text Layer (`text`)
```typescript
interface TextLayerContent {
  text: string
  fontSize: number
  fontFamily: string
  fontWeight: 'normal' | 'bold' | '100' | '200' | '300' | '400' | '500' | '600' | '700' | '800' | '900'
  color: string
  textAlign: 'left' | 'center' | 'right'
  lineHeight: number
  letterSpacing?: number
}
```

### 2. Shape Layer (`shape`)
```typescript
interface ShapeLayerContent {
  shapeType: 'rectangle' | 'circle' | 'triangle' | 'polygon' | 'line' | 'arrow'
  fill: string
  stroke?: {
    color: string
    width: number
  }
  cornerRadius?: number // for rectangles
  sides?: number // for polygons
}
```

### 3. Image Layer (`image`)
```typescript
interface ImageLayerContent {
  src: string // URL or base64
  alt?: string
  crop?: {
    x: number
    y: number
    width: number
    height: number
  }
  filters?: {
    brightness?: number
    contrast?: number
    saturation?: number
    blur?: number
  }
}
```

### 4. Background Layer (`background`)
```typescript
interface BackgroundLayerContent {
  type: 'solid' | 'gradient'
  color?: string
  gradient?: {
    type: 'linear' | 'radial'
    angle?: number // for linear
    stops: Array<{
      color: string
      position: number // 0-1
    }>
  }
}
```

### 5. Group Layer (`group`)
```typescript
interface GroupLayerContent {
  childLayerIds: string[]
  name: string
}
```

## Essential Layer Properties

### Transform (All Layers)
```typescript
interface Transform {
  x: number
  y: number
  scaleX: number
  scaleY: number
  rotation: number // degrees
  opacity: number // 0-1
}
```

### Style Properties
```typescript
interface LayerStyle {
  // Drop Shadow
  dropShadow?: {
    x: number
    y: number
    blur: number
    spread: number
    color: string
  }
  
  // Inner Shadow
  innerShadow?: {
    x: number
    y: number
    blur: number
    spread: number
    color: string
  }
  
  // Border
  border?: {
    width: number
    color: string
    style: 'solid' | 'dashed' | 'dotted'
  }
  
  // Border Radius
  borderRadius?: number
  
  // Blend Mode (future)
  blendMode?: 'normal' | 'multiply' | 'screen' | 'overlay'
}
```

### Constraints
```typescript
interface LayerConstraints {
  locked: boolean
  visible: boolean
  
  // User-defined locks for AI protection
  lockPosition?: boolean
  lockSize?: boolean
  lockRotation?: boolean
  lockContent?: boolean
  lockStyle?: boolean
  
  // Auto-layout constraints
  maintainAspectRatio?: boolean
  minWidth?: number
  minHeight?: number
  maxWidth?: number
  maxHeight?: number
}
```

## SVG Implementation Strategy

### Why SVG?
1. **Scalability**: Perfect for social media's varied sizes
2. **Performance**: Lightweight, fast rendering
3. **AI-Friendly**: Text-based format for AI processing
4. **Cross-Platform**: Works on iOS, web, Android

### SVG Structure for Each Layer Type

#### Text Layer SVG
```svg
<text x="100" y="100" 
      font-family="Arial" 
      font-size="16" 
      fill="#000000" 
      transform="rotate(45 100 100) scale(1.2)">
  Hello World
</text>
```

#### Shape Layer SVG
```svg
<rect x="50" y="50" 
      width="100" 
      height="100" 
      fill="#ff0000" 
      stroke="#000000" 
      stroke-width="2" 
      rx="10" 
      transform="rotate(30 100 100)"/>
```

#### Image Layer SVG
```svg
<image x="0" y="0" 
       width="200" 
       height="200" 
       href="data:image/jpeg;base64,..."
       transform="scale(0.8) rotate(15)"
       opacity="0.9"/>
```

#### Group Layer SVG
```svg
<g id="group-1" transform="translate(50, 50) rotate(10)">
  <rect x="0" y="0" width="100" height="50" fill="#red"/>
  <text x="50" y="30" text-anchor="middle">Label</text>
</g>
```

## Technical Implementation Notes

### 1. Layer Management
- Each layer = one SVG element
- Layer ordering = SVG z-index
- Grouping = SVG `<g>` elements
- Transformations = SVG `transform` attribute

### 2. iOS SwiftUI Integration
- Use `SVGKit` or custom SVG parser
- Render SVG to `UIImage` for visual AI
- Export full canvas as SVG string
- Convert SVG to PNG/JPEG for sharing

### 3. Performance Considerations
- Limit total layers (max 50-100)
- Lazy loading for complex shapes
- Caching for repeated renders
- Efficient diff detection for changes

### 4. Brand Integration
- Predefined color palettes
- Brand font restrictions
- Template-based constraints
- Style inheritance from groups

## Recommendations

### Phase 1 MVP
- ✅ Text Layer (basic)
- ✅ Rectangle Shape Layer
- ✅ Circle Shape Layer
- ✅ Image Layer (basic)
- ✅ Solid Background Layer

### Phase 2 Enhanced
- ✅ Drop shadows
- ✅ Group layers
- ✅ Gradient backgrounds
- ✅ Text effects
- ✅ More shape types

### Phase 3 Advanced
- ✅ Blend modes
- ✅ Masks and clipping
- ✅ Path editing
- ✅ Animation support

## Competitive Analysis Summary

| Feature | Canva | Figma | Adobe | VYB Priority |
|---------|-------|-------|--------|--------------|
| Text Layers | ✅ | ✅ | ✅ | High |
| Basic Shapes | ✅ | ✅ | ✅ | High |
| Images | ✅ | ✅ | ✅ | High |
| Backgrounds | ✅ | ✅ | ✅ | High |
| Groups | ✅ | ✅ | ✅ | Medium |
| Drop Shadows | ✅ | ✅ | ✅ | Medium |
| Gradients | ✅ | ✅ | ✅ | Medium |
| Blend Modes | Limited | ✅ | ✅ | Low |
| Masks | Limited | ✅ | ✅ | Low |
| Animations | Limited | ✅ | ✅ | Future |

This research provides the foundation for implementing a competitive yet focused layer system optimized for social media design and AI collaboration.
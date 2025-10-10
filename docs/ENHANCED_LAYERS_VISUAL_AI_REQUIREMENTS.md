# Enhanced Layers & Visual AI - Requirements Gathering

**Project**: VYB Enhanced Layer System & Visual AI Integration  
**Branch**: `enhanced-layers-visual-ai`  
**Date**: October 9, 2025  
**Status**: Requirements Gathering Phase  

## Current System Analysis

Based on the existing codebase, we currently have:
- ✅ Basic layer system with text/image/shape layers
- ✅ Gemini AI integration for design suggestions via text prompts
- ✅ TikTok-style navigation through AI-generated variations
- ✅ Screenshot capabilities for testing
- ✅ iOS SwiftUI implementation with proper state management
- ✅ Web TypeScript implementation with Fabric.js canvas

## Requirements Questions

Please answer the following questions to define the enhanced requirements:

---

### 📐 **Enhanced Layer System Questions:**

#### 1. Layer Complexity
**Question**: What new layer types do you want to add?

**Options to consider**:
- Gradients (linear, radial, conic)
- Filters (blur, brightness, contrast, saturation)
- Masks (clipping paths, transparency masks)
- Groups (logical grouping of layers)
- SVG shapes (vector graphics)
- Animations (transitions, keyframes)
- Other: ________________

**Your Answer**:
```
I actualy want all layers to be "implemented" as svgs.
I would like to take inspiration from Canva and their layer types to start with I want to keep things simple as much as possible so only a few kinds of layers but with the ability to stretch them, moove them, adjst their transparancy etc.
Do some research on similar design products and cover the main types they have so we can at least get an mvp up.
```

#### 2. Layer Properties
**Question**: What additional properties should layers have?

**Options to consider**:
- Blend modes (multiply, overlay, screen, etc.)
- Opacity controls (0-100%)
- Drop shadows and inner shadows
- Borders and outlines
- Advanced transformations (skew, perspective)
- Responsive constraints (auto-layout)
- Other: ________________

**Your Answer**:
```
- Opacity controls (0-100%)
- Drop shadows and inner shadows
- Borders and outlines
- Advanced transformations (skew, perspective)
- Responsive constraints (auto-layout)
- ability for the user to "lock" the attribute so the AI can't actually change it
```

#### 3. Layer Interactions
**Question**: Do you want layers to have relationships?

**Options to consider**:
- Parent-child hierarchies
- Groups with shared properties
- Linked properties (changing one affects others)
- Responsive behaviors
- Layer dependencies
- Other: ________________

**Your Answer**:
```
Grouping would be useful

```

#### 4. Layer Tools
**Question**: What manipulation tools should be available?

**Options to consider**:
- Alignment guides and snap-to-grid
- Rotation handles with angle indicators
- Resize handles with proportional constraints
- Copy/paste layer properties
- Layer ordering (bring to front, send to back)
- Bulk operations (select multiple, transform together)
- Other: ________________

**Your Answer**:
```
- Alignment guides and snap-to-grid
- Rotation handles with angle indicators
- Resize handles with proportional constraints
- Copy/paste layer properties
- Layer ordering (bring to front, send to back)
- Bulk operations (select multiple, transform together)
```

---

### 🖼️ **Visual AI Integration Questions:**

#### 5. Canvas Rendering
**Question**: Should we capture the entire canvas or specific regions? What format?

**Options to consider**:
- Full canvas capture vs. selected region
- Format: PNG (high quality), JPEG (smaller size), SVG (vector)
- Resolution: Screen resolution, 2x retina, custom DPI
- Background: Transparent, white, or preserve canvas background
- Other: ________________

**Your Answer**:
```
I think if we follow my thing above and make the enture thing work as an SVG then we could send SVG. At a minimum I think we send a compressed JPEG
```

#### 6. AI Visual Analysis
**Question**: What should the AI "see" and analyze?

**Options to consider**:
- Composition and layout balance
- Color harmony and palette analysis
- Spacing and alignment consistency
- Visual hierarchy and flow
- Accessibility (contrast, readability)
- Brand consistency
- Other: ________________

**Your Answer**:
```
It should "see" the canvas then it can use its knowledge of best practice for social posting
to suggest it's changes based on how the post actually "looks" to a human.
```

#### 7. Visual Prompts
**Question**: How should visual + text prompts work?

**Options to consider**:
- "Make this look more professional" + canvas image
- "Analyze the current design and suggest improvements"
- "Match this style" + reference image + canvas
- "Fix spacing and alignment issues"
- "Suggest better color combinations"
- Other: ________________

**Your Answer**:
```
THere should user prompts don't even think about implmementing them.
```

#### 8. AI Capabilities
**Question**: What visual AI features do you want?

**Options to consider**:
- Style transfer (apply visual style from reference)
- Color palette extraction and suggestions
- Layout improvements and alignment fixes
- Accessibility analysis and recommendations
- Content-aware suggestions (better text, imagery)
- Trend analysis ("make this more 2025")
- Other: ________________

**Your Answer**:
```
I would like to be able to have "brand" colours and fonts etc which we can then add to the prompt when we call the AI so it can keep things on branch
```

---

### 🔧 **Implementation Priorities:**

#### 9. Platform Focus
**Question**: Should we implement this primarily in iOS first, then web, or both simultaneously?

**Options**:
- iOS first (SwiftUI), then port to web
- Web first (TypeScript/Fabric.js), then port to iOS
- Both platforms simultaneously
- Focus on one platform only

**Your Answer**:
```
IOS completely ignore the other platforms
```

#### 10. Performance Constraints
**Question**: Any constraints on image size/quality for AI processing?

**Options to consider**:
- Maximum image size (e.g., 1024x1024 pixels)
- Compression quality vs. AI accuracy tradeoffs
- Real-time processing vs. background processing
- Local processing vs. cloud API limits
- Cost considerations for AI API calls

**Your Answer**:
```
Main bottleneck will be the AI API calls. We need to keep an eye on that.
```

---

### 🎯 **Additional Considerations:**

#### 11. User Experience
**Question**: How should users interact with these new features?

**Your Answer**:
```
They should use the existing UI and tik tok style swiping tools
```

#### 12. Integration Points
**Question**: How should this integrate with the existing TikTok-style navigation and history system?

**Your Answer**:
```
It should fit exactly with it, no deviation.
```

#### 13. Success Metrics
**Question**: How will we measure success of these enhancements?

**Your Answer**:
```
We will do UI testing that is codified
```

---

## Next Steps

Once you've filled out these requirements:

1. **Review & Validate**: We'll review your answers together
2. **Technical Spec**: I'll create a detailed technical specification
3. **Implementation Plan**: Break down into manageable todo items
4. **Prototype**: Start with core features and iterate
5. **Testing Strategy**: Ensure quality with comprehensive tests

## Notes

Add any additional thoughts, constraints, or requirements here:

```
You need to do this in a TDD manner, You should create tests and design docucmentation for the features and then refer back to it prior to making further changes. You need to be EXTREMENLY CAREFUL to ensure you aren't lying about progress
```

---

**Instructions**: Please fill in your answers in the sections marked with `[Please fill in your requirements here]` and save the document. Once complete, let me know and I'll create the technical specification and implementation plan.
# Data Model: Visual AI Collaboration Canvas

## Core Entities

### DesignCanvas
Primary workspace containing all visual elements within device simulation boundaries.

**Fields:**
- `id`: String (UUID) - Unique canvas identifier
- `deviceType`: DeviceType - Target device simulation (iPhone, iPad, Android, etc.)
- `dimensions`: CanvasDimensions - Width, height, pixel density for device accuracy
- `layers`: Layer[] - Ordered collection of design elements
- `metadata`: CanvasMetadata - Creation date, modification date, tags
- `state`: CanvasState - Current interaction state (editing, ai-processing, viewing)

**Validation Rules:**
- Canvas ID must be globally unique across all user designs
- Device type must match supported device specifications
- Dimensions must maintain accurate aspect ratios for target devices
- Layers must be ordered with valid z-index values
- Canvas must contain at least one layer to be considered valid

### Layer
Individual design elements that can be manipulated independently by users and AI.

**Fields:**
- `id`: String (UUID) - Unique layer identifier within canvas
- `type`: LayerType - text, image, background, shape, group
- `content`: LayerContent - Type-specific content data
- `transform`: Transform - Position, scale, rotation, opacity
- `style`: LayerStyle - Visual properties (colors, fonts, effects)
- `constraints`: LayerConstraints - Locking, visibility, interaction rules
- `metadata`: LayerMetadata - Creation source (user, ai), timestamps

**Relationships:**
- Belongs to one DesignCanvas
- Can be grouped with other Layers
- References external assets for image/media content

**Validation Rules:**
- Layer ID must be unique within parent canvas
- Transform values must be within canvas boundaries
- Content must match layer type specifications
- Style properties must be valid for layer type

### DesignVariation
AI-generated or user-modified versions of designs, stored in branching DAG structure.

**Fields:**
- `id`: String (UUID) - Unique variation identifier
- `parentId`: String (UUID) - Parent variation or null for root
- `canvasState`: DesignCanvas - Complete canvas snapshot at this variation
- `source`: VariationSource - user_edit, ai_suggestion, ai_trend, ai_creative
- `prompt`: String - AI prompt or user action description
- `confidence`: Number - AI confidence score (0-1) for AI-generated variations
- `timestamp`: DateTime - Creation timestamp
- `metadata`: VariationMetadata - Tags, notes, approval status

**Relationships:**
- Forms DAG structure with parent-child relationships
- Multiple variations can share same parent (branching)
- Contains complete DesignCanvas state snapshot

**State Transitions:**
- root → user_edit (user modifies original)
- user_edit → ai_suggestion (AI processes user design)  
- ai_suggestion → user_edit (user modifies AI suggestion)
- Any variation → new branch (preserves history)

### DeviceSimulation
Virtual representation of target devices with accurate specifications.

**Fields:**
- `deviceId`: String - Unique device identifier (e.g., "iphone-15-pro")
- `displayName`: String - Human-readable device name
- `dimensions`: DeviceDimensions - Screen width, height, pixel density
- `safeAreas`: SafeAreaInsets - Status bar, home indicator, notch areas
- `characteristics`: DeviceCharacteristics - Rounded corners, aspect ratio
- `previewAssets`: DeviceAssets - Device frame images, mockup resources

**Validation Rules:**
- Device dimensions must match real device specifications
- Safe areas must be accurate for device model
- Preview assets must be high-quality and current

### GestureNavigation
Scroll-based interaction system for browsing design variations.

**Fields:**
- `currentVariationId`: String (UUID) - Currently displayed variation
- `navigationHistory`: String[] - Stack of recently viewed variations
- `scrollVelocity`: Number - Current scroll momentum for physics simulation
- `direction`: ScrollDirection - up (previous) or down (next)
- `transitionState`: TransitionState - idle, scrolling, animating

**State Transitions:**
- idle → scrolling (user begins gesture)
- scrolling → animating (gesture ends, momentum continues)
- animating → idle (animation completes)

### AICollaborationState
Status and context for AI processing and suggestions.

**Fields:**
- `isProcessing`: Boolean - AI currently generating suggestions
- `currentPrompt`: String - Active AI processing context
- `suggestions`: DesignVariation[] - Available AI-generated variations
- `trends`: TrendData - Current design trends influencing AI
- `preferences`: UserPreferences - Learned user preferences for AI suggestions
- `errorState`: ErrorState - AI service errors or fallback status

**Validation Rules:**
- Cannot have suggestions while processing is true
- Error state must include fallback strategy
- Trends data must be current (refreshed within 24 hours)

## Relationships

### Canvas → Layer (One-to-Many)
- One canvas contains multiple layers
- Layers are ordered by z-index
- Layer deletion updates canvas state
- Canvas deletion cascades to all layers

### DesignVariation → DesignCanvas (One-to-One)
- Each variation contains complete canvas snapshot
- Canvas state is immutable within variation
- New variations created for any modifications

### DesignVariation → DesignVariation (DAG Structure)
- Parent-child relationships form directed acyclic graph
- Multiple children allowed (branching)
- Root variations have no parent
- Circular references prevented by design

### DeviceSimulation → DesignCanvas (One-to-Many)
- Multiple canvases can use same device simulation
- Device change preserves canvas content with dimension adjustments
- Device specifications drive canvas constraints

## Storage Considerations

### Platform-Specific Implementation
- **Web**: IndexedDB with structured data and blob storage for images
- **iOS**: Core Data with CloudKit preparation and NSManagedObject contexts
- **Android**: Room database with entities and DAOs for structured queries

### Cloud Abstraction Layer
- Abstract repository interfaces for future cloud synchronization
- Conflict-free replicated data types (CRDTs) for eventual consistency
- Event sourcing for change tracking and synchronization

### Performance Optimizations  
- Lazy loading for large variation histories
- Canvas state compression for storage efficiency
- Image assets cached separately with reference counting
- Incremental synchronization for cloud preparation

## JSON Schema Validation

All entities must support JSON serialization for cross-platform compatibility and AI integration. Schema validation ensures data integrity during platform transitions and AI processing.

Key validation points:
- Device dimensions match real specifications
- Layer content matches type requirements  
- DAG structure maintains acyclic property
- AI confidence scores within valid ranges
- Transform values within canvas boundaries
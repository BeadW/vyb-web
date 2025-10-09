package com.vyb.services

import androidx.compose.runtime.*
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.vyb.models.Layer
import com.vyb.models.LayerType
import com.vyb.models.Transform
import kotlinx.coroutines.launch
import kotlin.math.*

/**
 * Android Canvas Manipulation Service - Advanced gesture-based manipulation with constraints
 * Implements T045: Android Canvas Manipulation with professional-grade manipulation tools
 * Provides cross-platform parity with iOS and Web implementations
 */
class CanvasManipulation : ViewModel() {
    
    // MARK: - Published Properties
    private val _isManipulating = mutableStateOf(false)
    val isManipulating: State<Boolean> = _isManipulating
    
    private val _currentTool = mutableStateOf(ManipulationTool.SELECT)
    val currentTool: State<ManipulationTool> = _currentTool
    
    private val _snapToGrid = mutableStateOf(false)
    val snapToGrid: State<Boolean> = _snapToGrid
    
    private val _snapToObjects = mutableStateOf(true)
    val snapToObjects: State<Boolean> = _snapToObjects
    
    private val _gridSize = mutableStateOf(10f)
    val gridSize: State<Float> = _gridSize
    
    private val _manipulationConstraints = mutableStateOf(ManipulationConstraints())
    val manipulationConstraints: State<ManipulationConstraints> = _manipulationConstraints
    
    // MARK: - Private Properties
    private var activeLayer: Layer? = null
    private var initialTransform: Transform? = null
    private var manipulationStartPoint: Offset = Offset.Zero
    private val snapThreshold = 5f
    private val undoStack = mutableListOf<ManipulationAction>()
    private val redoStack = mutableListOf<ManipulationAction>()
    
    // MARK: - Callbacks
    var onLayerChanged: ((Layer) -> Unit)? = null
    var onSelectionChanged: ((String?) -> Unit)? = null
    var onManipulationStart: (() -> Unit)? = null
    var onManipulationEnd: (() -> Unit)? = null
    
    // MARK: - Initialization
    init {
        setupDefaultConstraints()
    }
    
    // MARK: - Public Interface
    
    /**
     * Start manipulation on a specific layer
     */
    fun startManipulation(layer: Layer, at: Offset, tool: ManipulationTool = ManipulationTool.SELECT) {
        activeLayer = layer
        initialTransform = layer.transform
        manipulationStartPoint = at
        _currentTool.value = tool
        _isManipulating.value = true
        
        recordAction(ManipulationAction.Start(layer.id, layer.transform))
        onManipulationStart?.invoke()
    }
    
    /**
     * Update manipulation based on gesture
     */
    fun updateManipulation(
        translation: Offset = Offset.Zero,
        scale: Float = 1f,
        rotation: Float = 0f,
        velocity: Offset = Offset.Zero
    ) {
        val layer = activeLayer ?: return
        val initial = initialTransform ?: return
        
        var newTransform = initial
        
        when (_currentTool.value) {
            ManipulationTool.SELECT, ManipulationTool.MOVE -> {
                newTransform = applyTranslation(newTransform, translation, layer)
            }
            ManipulationTool.SCALE -> {
                newTransform = applyScaling(newTransform, scale, layer)
            }
            ManipulationTool.ROTATE -> {
                newTransform = applyRotation(newTransform, rotation, layer)
            }
        }
        
        // Apply constraints
        newTransform = applyConstraints(newTransform, layer)
        
        // Apply snapping
        if (_snapToGrid.value || _snapToObjects.value) {
            newTransform = applySnapping(newTransform, layer)
        }
        
        // Update layer
        val updatedLayer = layer.copy(transform = newTransform)
        onLayerChanged?.invoke(updatedLayer)
    }
    
    /**
     * End manipulation and commit changes
     */
    fun endManipulation() {
        val layer = activeLayer ?: return
        val initial = initialTransform ?: return
        
        if (layer.transform != initial) {
            recordAction(ManipulationAction.End(layer.id, layer.transform))
        }
        
        activeLayer = null
        initialTransform = null
        _isManipulating.value = false
        
        onManipulationEnd?.invoke()
    }
    
    /**
     * Cancel current manipulation
     */
    fun cancelManipulation() {
        val layer = activeLayer ?: return
        val initial = initialTransform ?: return
        
        val canceledLayer = layer.copy(transform = initial)
        onLayerChanged?.invoke(canceledLayer)
        
        activeLayer = null
        initialTransform = null
        _isManipulating.value = false
        
        onManipulationEnd?.invoke()
    }
    
    // MARK: - Advanced Manipulation Methods
    
    /**
     * Move layer to specific position with constraints
     */
    fun moveLayer(layer: Layer, to: Offset) {
        val constrainedPosition = applyPositionConstraints(to, layer)
        
        val newTransform = layer.transform.copy(
            x = constrainedPosition.x.toDouble(),
            y = constrainedPosition.y.toDouble()
        )
        
        val updatedLayer = layer.copy(transform = newTransform)
        
        recordAction(
            ManipulationAction.Move(
                layer.id,
                Offset(layer.transform.x.toFloat(), layer.transform.y.toFloat()),
                constrainedPosition
            )
        )
        onLayerChanged?.invoke(updatedLayer)
    }
    
    /**
     * Scale layer with aspect ratio constraints
     */
    fun scaleLayer(layer: Layer, scale: Float, maintainAspectRatio: Boolean = true) {
        val constrainedScale = applyScaleConstraints(scale, layer)
        
        val newTransform = layer.transform.copy(
            scaleX = constrainedScale.toDouble(),
            scaleY = if (maintainAspectRatio) constrainedScale.toDouble() else layer.transform.scaleY
        )
        
        val updatedLayer = layer.copy(transform = newTransform)
        
        recordAction(
            ManipulationAction.Scale(
                layer.id,
                layer.transform.scaleX.toFloat(),
                constrainedScale
            )
        )
        onLayerChanged?.invoke(updatedLayer)
    }
    
    /**
     * Rotate layer with snap angles
     */
    fun rotateLayer(layer: Layer, angle: Float) {
        val constrainedAngle = applyRotationConstraints(angle, layer)
        
        val newTransform = layer.transform.copy(rotation = constrainedAngle.toDouble())
        val updatedLayer = layer.copy(transform = newTransform)
        
        recordAction(
            ManipulationAction.Rotate(
                layer.id,
                layer.transform.rotation.toFloat(),
                constrainedAngle
            )
        )
        onLayerChanged?.invoke(updatedLayer)
    }
    
    // MARK: - Batch Operations
    
    /**
     * Group selected layers
     */
    fun groupLayers(layers: List<Layer>): Layer? {
        if (layers.size <= 1) return null
        
        val groupId = generateId()
        val bounds = calculateBounds(layers)
        
        val groupLayer = Layer(
            id = groupId,
            type = LayerType.GROUP,
            transform = Transform(
                x = bounds.center.x.toDouble(),
                y = bounds.center.y.toDouble(),
                scaleX = 1.0,
                scaleY = 1.0,
                rotation = 0.0,
                opacity = 1.0
            ),
            content = com.vyb.models.LayerContent(
                childLayerIds = layers.map { it.id }
            ),
            style = null,
            constraints = com.vyb.models.LayerConstraints(locked = false, visible = true),
            order = 0,
            parentId = null,
            createdAt = System.currentTimeMillis(),
            updatedAt = System.currentTimeMillis()
        )
        
        recordAction(ManipulationAction.Group(layers.map { it.id }, groupId))
        return groupLayer
    }
    
    /**
     * Align layers
     */
    fun alignLayers(layers: List<Layer>, alignment: AlignmentType) {
        if (layers.size <= 1) return
        
        val bounds = calculateBounds(layers)
        val alignedLayers = mutableListOf<Layer>()
        
        for (layer in layers) {
            var newTransform = layer.transform
            
            when (alignment) {
                AlignmentType.LEFT -> newTransform = newTransform.copy(x = bounds.left.toDouble())
                AlignmentType.RIGHT -> newTransform = newTransform.copy(x = bounds.right.toDouble())
                AlignmentType.TOP -> newTransform = newTransform.copy(y = bounds.top.toDouble())
                AlignmentType.BOTTOM -> newTransform = newTransform.copy(y = bounds.bottom.toDouble())
                AlignmentType.CENTER_HORIZONTAL -> newTransform = newTransform.copy(x = bounds.center.x.toDouble())
                AlignmentType.CENTER_VERTICAL -> newTransform = newTransform.copy(y = bounds.center.y.toDouble())
            }
            
            val alignedLayer = layer.copy(transform = newTransform)
            alignedLayers.add(alignedLayer)
        }
        
        recordAction(ManipulationAction.Align(layers.map { it.id }, alignment))
        
        alignedLayers.forEach { layer ->
            onLayerChanged?.invoke(layer)
        }
    }
    
    /**
     * Distribute layers evenly
     */
    fun distributeLayers(layers: List<Layer>, distribution: DistributionType) {
        if (layers.size <= 2) return
        
        val sortedLayers = layers.sortedWith { layer1, layer2 ->
            when (distribution) {
                DistributionType.HORIZONTAL -> layer1.transform.x.compareTo(layer2.transform.x)
                DistributionType.VERTICAL -> layer1.transform.y.compareTo(layer2.transform.y)
            }
        }
        
        val first = sortedLayers.first()
        val last = sortedLayers.last()
        val totalDistance = when (distribution) {
            DistributionType.HORIZONTAL -> last.transform.x - first.transform.x
            DistributionType.VERTICAL -> last.transform.y - first.transform.y
        }
        
        val spacing = totalDistance / (sortedLayers.size - 1)
        
        sortedLayers.forEachIndexed { index, layer ->
            if (index > 0 && index < sortedLayers.size - 1) {
                var newTransform = layer.transform
                
                when (distribution) {
                    DistributionType.HORIZONTAL -> {
                        newTransform = newTransform.copy(x = first.transform.x + (spacing * index))
                    }
                    DistributionType.VERTICAL -> {
                        newTransform = newTransform.copy(y = first.transform.y + (spacing * index))
                    }
                }
                
                val distributedLayer = layer.copy(transform = newTransform)
                onLayerChanged?.invoke(distributedLayer)
            }
        }
        
        recordAction(ManipulationAction.Distribute(layers.map { it.id }, distribution))
    }
    
    // MARK: - Undo/Redo Operations
    
    fun undo() {
        if (undoStack.isEmpty()) return
        
        val action = undoStack.removeLastOrNull() ?: return
        redoStack.add(action)
        
        // Apply inverse action
        when (action) {
            is ManipulationAction.Move -> {
                // Move back to original position
                // Implementation would involve finding the layer and updating it
            }
            is ManipulationAction.Scale -> {
                // Scale back to original
            }
            is ManipulationAction.Rotate -> {
                // Rotate back to original
            }
            else -> {}
        }
    }
    
    fun redo() {
        if (redoStack.isEmpty()) return
        
        val action = redoStack.removeLastOrNull() ?: return
        undoStack.add(action)
        
        // Apply action forward
        // Implementation similar to undo but in forward direction
    }
    
    fun canUndo(): Boolean = undoStack.isNotEmpty()
    fun canRedo(): Boolean = redoStack.isNotEmpty()
    
    // MARK: - Configuration Methods
    
    fun setSnapToGrid(enabled: Boolean) {
        _snapToGrid.value = enabled
    }
    
    fun setSnapToObjects(enabled: Boolean) {
        _snapToObjects.value = enabled
    }
    
    fun setGridSize(size: Float) {
        _gridSize.value = size
    }
    
    fun setTool(tool: ManipulationTool) {
        _currentTool.value = tool
    }
    
    // MARK: - Private Helper Methods
    
    private fun setupDefaultConstraints() {
        _manipulationConstraints.value = ManipulationConstraints(
            minScale = 0.1f,
            maxScale = 5.0f,
            allowRotation = true,
            snapAngle = 15f,
            respectLayerBounds = true
        )
    }
    
    private fun applyTranslation(transform: Transform, translation: Offset, layer: Layer): Transform {
        return transform.copy(
            x = transform.x + translation.x,
            y = transform.y + translation.y
        )
    }
    
    private fun applyScaling(transform: Transform, scale: Float, layer: Layer): Transform {
        val constrainedScale = applyScaleConstraints(scale, layer)
        return transform.copy(
            scaleX = constrainedScale.toDouble(),
            scaleY = constrainedScale.toDouble()
        )
    }
    
    private fun applyRotation(transform: Transform, rotation: Float, layer: Layer): Transform {
        val constrainedRotation = applyRotationConstraints(rotation, layer)
        return transform.copy(rotation = constrainedRotation.toDouble())
    }
    
    private fun applyConstraints(transform: Transform, layer: Layer): Transform {
        val constraints = _manipulationConstraints.value
        
        return transform.copy(
            scaleX = transform.scaleX.coerceIn(constraints.minScale.toDouble(), constraints.maxScale.toDouble()),
            scaleY = transform.scaleY.coerceIn(constraints.minScale.toDouble(), constraints.maxScale.toDouble()),
            opacity = transform.opacity.coerceIn(0.0, 1.0)
        )
    }
    
    private fun applySnapping(transform: Transform, layer: Layer): Transform {
        var snappedTransform = transform
        
        if (_snapToGrid.value) {
            val gridSize = _gridSize.value
            snappedTransform = snappedTransform.copy(
                x = (transform.x / gridSize).roundToInt() * gridSize.toDouble(),
                y = (transform.y / gridSize).roundToInt() * gridSize.toDouble()
            )
        }
        
        return snappedTransform
    }
    
    private fun applyPositionConstraints(position: Offset, layer: Layer): Offset {
        // Apply layer-specific position constraints
        return position
    }
    
    private fun applyScaleConstraints(scale: Float, layer: Layer): Float {
        val constraints = _manipulationConstraints.value
        return scale.coerceIn(constraints.minScale, constraints.maxScale)
    }
    
    private fun applyRotationConstraints(rotation: Float, layer: Layer): Float {
        val constraints = _manipulationConstraints.value
        
        return if (constraints.allowRotation) {
            // Snap to common angles if within threshold
            val snapAngles = listOf(0f, 45f, 90f, 135f, 180f, 225f, 270f, 315f)
            for (snapAngle in snapAngles) {
                if (abs(rotation - snapAngle) < constraints.snapAngle) {
                    return snapAngle
                }
            }
            rotation
        } else {
            0f
        }
    }
    
    private fun calculateBounds(layers: List<Layer>): Rect {
        if (layers.isEmpty()) return Rect.Zero
        
        var minX = layers[0].transform.x.toFloat()
        var maxX = layers[0].transform.x.toFloat()
        var minY = layers[0].transform.y.toFloat()
        var maxY = layers[0].transform.y.toFloat()
        
        for (layer in layers) {
            val x = layer.transform.x.toFloat()
            val y = layer.transform.y.toFloat()
            
            minX = minOf(minX, x)
            maxX = maxOf(maxX, x)
            minY = minOf(minY, y)
            maxY = maxOf(maxY, y)
        }
        
        return Rect(
            offset = Offset(minX, minY),
            size = Size(maxX - minX, maxY - minY)
        )
    }
    
    private fun recordAction(action: ManipulationAction) {
        undoStack.add(action)
        redoStack.clear() // Clear redo stack on new action
        
        // Limit undo stack size
        if (undoStack.size > 50) {
            undoStack.removeFirstOrNull()
        }
    }
    
    private fun generateId(): String {
        return "layer_${System.currentTimeMillis()}_${(0..999).random()}"
    }
}

// MARK: - Supporting Enums and Data Classes

enum class ManipulationTool {
    SELECT,
    MOVE,
    SCALE,
    ROTATE
}

data class ManipulationConstraints(
    val minScale: Float = 0.1f,
    val maxScale: Float = 5.0f,
    val allowRotation: Boolean = true,
    val snapAngle: Float = 15f,
    val respectLayerBounds: Boolean = true
)

enum class AlignmentType {
    LEFT,
    RIGHT,
    TOP,
    BOTTOM,
    CENTER_HORIZONTAL,
    CENTER_VERTICAL
}

enum class DistributionType {
    HORIZONTAL,
    VERTICAL
}

sealed class ManipulationAction {
    data class Start(val layerId: String, val transform: Transform) : ManipulationAction()
    data class End(val layerId: String, val transform: Transform) : ManipulationAction()
    data class Move(val layerId: String, val from: Offset, val to: Offset) : ManipulationAction()
    data class Scale(val layerId: String, val from: Float, val to: Float) : ManipulationAction()
    data class Rotate(val layerId: String, val from: Float, val to: Float) : ManipulationAction()
    data class Group(val layerIds: List<String>, val groupId: String) : ManipulationAction()
    data class Ungroup(val groupId: String, val layerIds: List<String>) : ManipulationAction()
    data class Align(val layerIds: List<String>, val alignment: AlignmentType) : ManipulationAction()
    data class Distribute(val layerIds: List<String>, val distribution: DistributionType) : ManipulationAction()
}

// MARK: - Gesture Integration Extensions

/**
 * Extension functions to integrate with Compose gesture system
 */
fun CanvasManipulation.createDragHandler(layer: Layer): (Offset) -> Unit {
    return { dragOffset ->
        if (!isManipulating.value) {
            startManipulation(layer, dragOffset, ManipulationTool.MOVE)
        }
        updateManipulation(translation = dragOffset)
    }
}

fun CanvasManipulation.createScaleHandler(layer: Layer): (Float) -> Unit {
    return { scale ->
        if (!isManipulating.value) {
            startManipulation(layer, Offset.Zero, ManipulationTool.SCALE)
        }
        updateManipulation(scale = scale)
    }
}

fun CanvasManipulation.createRotationHandler(layer: Layer): (Float) -> Unit {
    return { rotation ->
        if (!isManipulating.value) {
            startManipulation(layer, Offset.Zero, ManipulationTool.ROTATE)
        }
        updateManipulation(rotation = rotation)
    }
}

// MARK: - Utility Functions for Performance

/**
 * Performance optimized layer bounds calculation
 */
fun calculateLayerBounds(layer: Layer, includeTransform: Boolean = true): Rect {
    // Base bounds (assuming 100x100 default size for demonstration)
    val baseSize = Size(100f, 100f)
    var bounds = Rect(Offset.Zero, baseSize)
    
    if (includeTransform) {
        val transform = layer.transform
        bounds = Rect(
            offset = Offset(transform.x.toFloat(), transform.y.toFloat()),
            size = Size(
                baseSize.width * transform.scaleX.toFloat(),
                baseSize.height * transform.scaleY.toFloat()
            )
        )
    }
    
    return bounds
}

/**
 * Check if a point intersects with a layer
 */
fun isPointInLayer(point: Offset, layer: Layer): Boolean {
    val bounds = calculateLayerBounds(layer, includeTransform = true)
    return bounds.contains(point)
}
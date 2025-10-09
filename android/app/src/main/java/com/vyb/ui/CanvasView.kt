package com.vyb.ui

import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import androidx.core.graphics.withTranslation
import androidx.core.graphics.withRotation
import androidx.core.graphics.withScale
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import com.vyb.models.DesignCanvas
import com.vyb.models.Layer
import com.vyb.models.LayerType
import com.vyb.models.Transform
import kotlin.math.*

/**
 * Android Canvas View - Custom Canvas with gesture detection for design manipulation
 * Implements T044: Android Canvas View with Jetpack Compose and gesture handling
 * Compatible with Layer and DesignCanvas models for cross-platform consistency
 */

// MARK: - Canvas View Model
class CanvasViewModel : ViewModel() {
    private val _layers = mutableStateListOf<Layer>()
    val layers: List<Layer> = _layers
    
    private val _selectedLayerId = mutableStateOf<String?>(null)
    val selectedLayerId: State<String?> = _selectedLayerId
    
    private val _canvasSize = mutableStateOf(Size(800f, 600f))
    val canvasSize: State<Size> = _canvasSize
    
    private val _zoom = mutableStateOf(1f)
    val zoom: State<Float> = _zoom
    
    private val _panOffset = mutableStateOf(Offset.Zero)
    val panOffset: State<Offset> = _panOffset
    
    fun loadLayers(canvas: DesignCanvas) {
        _layers.clear()
        _layers.addAll(canvas.layers)
    }
    
    fun selectLayer(layerId: String?) {
        _selectedLayerId.value = layerId
    }
    
    fun updateLayerTransform(layerId: String, transform: Transform) {
        val index = _layers.indexOfFirst { it.id == layerId }
        if (index != -1) {
            _layers[index] = _layers[index].copy(transform = transform)
        }
    }
    
    fun addLayer(layer: Layer) {
        _layers.add(layer)
    }
    
    fun removeLayer(layerId: String) {
        _layers.removeAll { it.id == layerId }
    }
    
    fun updateZoom(newZoom: Float) {
        _zoom.value = maxOf(0.1f, minOf(newZoom, 5.0f))
    }
    
    fun updatePanOffset(offset: Offset) {
        _panOffset.value = offset
    }
    
    fun setCanvasSize(size: Size) {
        _canvasSize.value = size
    }
}

// MARK: - Main Canvas Composable
@Composable
fun CanvasView(
    canvas: DesignCanvas,
    modifier: Modifier = Modifier,
    viewModel: CanvasViewModel = viewModel()
) {
    val layers by remember { derivedStateOf { viewModel.layers } }
    val selectedLayerId by viewModel.selectedLayerId
    val canvasSize by viewModel.canvasSize
    val zoom by viewModel.zoom
    val panOffset by viewModel.panOffset
    
    // Initialize canvas
    LaunchedEffect(canvas) {
        viewModel.loadLayers(canvas)
        viewModel.setCanvasSize(Size(canvas.dimensions.width.toFloat(), canvas.dimensions.height.toFloat()))
    }
    
    // Canvas interaction state
    var lastPanValue by remember { mutableStateOf(Offset.Zero) }
    var lastZoomValue by remember { mutableStateOf(1f) }
    
    Box(modifier = modifier.fillMaxSize()) {
        Canvas(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.White)
                .clip(RoundedCornerShape(8.dp))
                .pointerInput(Unit) {
                    detectTransformGestures(
                        panZoomLock = false,
                        onGesture = { centroid, pan, gestureZoom, _ ->
                            // Handle canvas pan and zoom when no layer is selected
                            if (selectedLayerId == null) {
                                val newPan = lastPanValue + pan
                                viewModel.updatePanOffset(newPan)
                                
                                val newZoom = lastZoomValue * gestureZoom
                                viewModel.updateZoom(newZoom)
                            }
                        }
                    )
                }
                .pointerInput(layers) {
                    detectTapGestures { offset ->
                        // Detect layer taps
                        val adjustedOffset = (offset - panOffset) / zoom
                        val tappedLayer = findLayerAt(layers, adjustedOffset)
                        viewModel.selectLayer(tappedLayer?.id)
                    }
                }
        ) {
            // Apply canvas transformations
            translate(panOffset.x, panOffset.y) {
                scale(zoom) {
                    // Draw canvas background
                    drawRect(
                        color = Color.White,
                        size = canvasSize,
                        topLeft = Offset.Zero
                    )
                    
                    // Draw canvas border
                    drawRect(
                        color = Color.Gray.copy(alpha = 0.3f),
                        size = canvasSize,
                        topLeft = Offset.Zero,
                        style = androidx.compose.ui.graphics.drawscope.Stroke(width = 1.dp.toPx())
                    )
                    
                    // Draw all layers
                    layers.forEach { layer ->
                        drawLayer(
                            layer = layer,
                            isSelected = selectedLayerId == layer.id
                        )
                    }
                }
            }
        }
        
        // Layer interaction overlays
        layers.forEach { layer ->
            if (selectedLayerId == layer.id) {
                LayerInteractionOverlay(
                    layer = layer,
                    zoom = zoom,
                    panOffset = panOffset,
                    onTransformUpdate = { transform ->
                        viewModel.updateLayerTransform(layer.id, transform)
                    }
                )
            }
        }
    }
}

// MARK: - Layer Drawing Functions
private fun DrawScope.drawLayer(layer: Layer, isSelected: Boolean) {
    val transform = layer.transform
    
    translate(transform.x.toFloat(), transform.y.toFloat()) {
        scale(transform.scaleX.toFloat(), transform.scaleY.toFloat()) {
            rotate(transform.rotation.toFloat()) {
                when (layer.type) {
                    LayerType.TEXT -> drawTextLayer(layer)
                    LayerType.IMAGE -> drawImageLayer(layer)
                    LayerType.SHAPE -> drawShapeLayer(layer)
                    LayerType.BACKGROUND -> drawBackgroundLayer(layer)
                    LayerType.GROUP -> drawGroupLayer(layer)
                }
                
                // Draw selection outline
                if (isSelected) {
                    drawSelectionOutline()
                }
            }
        }
    }
}

private fun DrawScope.drawTextLayer(layer: Layer) {
    val text = layer.content.text ?: "Text"
    val fontSize = layer.content.fontSize?.sp ?: 16.sp
    val color = parseColor(layer.style?.color) ?: Color.Black
    
    // Note: In real implementation, you'd use a proper text renderer
    // This is a simplified version for demonstration
    drawCircle(
        color = color,
        radius = 20f,
        center = center
    )
}

private fun DrawScope.drawImageLayer(layer: Layer) {
    // Draw placeholder for image
    val color = Color.Gray.copy(alpha = 0.3f)
    drawRect(
        color = color,
        size = Size(100.dp.toPx(), 100.dp.toPx())
    )
    
    // Draw image icon placeholder
    drawCircle(
        color = Color.Gray,
        radius = 15.dp.toPx(),
        center = Offset(50.dp.toPx(), 50.dp.toPx())
    )
}

private fun DrawScope.drawShapeLayer(layer: Layer) {
    val fillColor = parseColor(layer.content.fill) ?: Color.Blue
    val strokeColor = parseColor(layer.content.stroke) ?: Color.Black
    val strokeWidth = layer.content.strokeWidth?.dp?.toPx() ?: 0f
    
    val shapeSize = Size(100.dp.toPx(), 100.dp.toPx())
    
    // Draw filled shape
    drawRect(
        color = fillColor,
        size = shapeSize
    )
    
    // Draw stroke if specified
    if (strokeWidth > 0) {
        drawRect(
            color = strokeColor,
            size = shapeSize,
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = strokeWidth)
        )
    }
}

private fun DrawScope.drawBackgroundLayer(layer: Layer) {
    val backgroundColor = parseColor(layer.content.color) ?: Color.White
    drawRect(
        color = backgroundColor,
        size = size
    )
}

private fun DrawScope.drawGroupLayer(layer: Layer) {
    // Group layers are containers - draw a placeholder
    val color = Color.Gray.copy(alpha = 0.2f)
    drawRect(
        color = color,
        size = Size(100.dp.toPx(), 100.dp.toPx()),
        style = androidx.compose.ui.graphics.drawscope.Stroke(width = 2.dp.toPx())
    )
}

private fun DrawScope.drawSelectionOutline() {
    drawRect(
        color = Color.Blue,
        size = Size(100.dp.toPx(), 100.dp.toPx()),
        style = androidx.compose.ui.graphics.drawscope.Stroke(width = 2.dp.toPx())
    )
}

// MARK: - Layer Interaction Overlay
@Composable
private fun LayerInteractionOverlay(
    layer: Layer,
    zoom: Float,
    panOffset: Offset,
    onTransformUpdate: (Transform) -> Unit
) {
    var isDragging by remember { mutableStateOf(false) }
    var dragOffset by remember { mutableStateOf(Offset.Zero) }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .pointerInput(layer.id) {
                detectDragGestures(
                    onDragStart = { offset ->
                        isDragging = true
                        dragOffset = Offset.Zero
                    },
                    onDragEnd = {
                        isDragging = false
                        dragOffset = Offset.Zero
                    },
                    onDrag = { change ->
                        dragOffset += change
                        val adjustedDrag = dragOffset / zoom
                        
                        val newTransform = layer.transform.copy(
                            x = layer.transform.x + adjustedDrag.x,
                            y = layer.transform.y + adjustedDrag.y
                        )
                        onTransformUpdate(newTransform)
                    }
                )
            }
            .pointerInput(layer.id) {
                detectTransformGestures { _, _, zoom, rotation ->
                    val newTransform = layer.transform.copy(
                        scaleX = maxOf(0.1, minOf(layer.transform.scaleX * zoom, 5.0)),
                        scaleY = maxOf(0.1, minOf(layer.transform.scaleY * zoom, 5.0)),
                        rotation = layer.transform.rotation + rotation
                    )
                    onTransformUpdate(newTransform)
                }
            }
    )
}

// MARK: - Utility Functions
private fun findLayerAt(layers: List<Layer>, point: Offset): Layer? {
    // Find the topmost layer at the given point
    // This is a simplified version - in real implementation you'd check actual layer bounds
    return layers.lastOrNull { layer ->
        val bounds = RectF(
            layer.transform.x.toFloat() - 50f,
            layer.transform.y.toFloat() - 50f,
            layer.transform.x.toFloat() + 50f,
            layer.transform.y.toFloat() + 50f
        )
        bounds.contains(point.x, point.y)
    }
}

private fun parseColor(colorString: String?): Color? {
    if (colorString == null) return null
    
    return try {
        val cleanColor = colorString.removePrefix("#")
        when (cleanColor.length) {
            6 -> {
                val colorInt = cleanColor.toInt(16)
                Color(
                    red = ((colorInt shr 16) and 0xFF) / 255f,
                    green = ((colorInt shr 8) and 0xFF) / 255f,
                    blue = (colorInt and 0xFF) / 255f
                )
            }
            8 -> {
                val colorInt = cleanColor.toLong(16)
                Color(
                    alpha = ((colorInt shr 24) and 0xFF) / 255f,
                    red = ((colorInt shr 16) and 0xFF) / 255f,
                    green = ((colorInt shr 8) and 0xFF) / 255f,
                    blue = (colorInt and 0xFF) / 255f
                )
            }
            else -> null
        }
    } catch (e: NumberFormatException) {
        null
    }
}

// MARK: - Canvas Demo Composable
@Composable
fun CanvasDemo(
    canvas: DesignCanvas,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxSize()
    ) {
        // Canvas toolbar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color.Gray.copy(alpha = 0.1f))
                .padding(8.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "Canvas: ${canvas.deviceType}",
                style = MaterialTheme.typography.bodyMedium
            )
            
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = { /* Add text layer */ },
                    modifier = Modifier.size(32.dp)
                ) {
                    Text("T")
                }
                
                Button(
                    onClick = { /* Add shape layer */ },
                    modifier = Modifier.size(32.dp)
                ) {
                    Text("□")
                }
            }
        }
        
        // Main canvas area
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .background(Color.Gray.copy(alpha = 0.05f)),
            contentAlignment = Alignment.Center
        ) {
            CanvasView(
                canvas = canvas,
                modifier = Modifier
                    .fillMaxWidth(0.9f)
                    .fillMaxHeight(0.9f)
            )
        }
        
        // Status bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color.Gray.copy(alpha = 0.1f))
                .padding(8.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "Layers: ${canvas.layers.size}",
                style = MaterialTheme.typography.bodySmall
            )
            
            Text(
                text = "Ready",
                style = MaterialTheme.typography.bodySmall,
                color = Color.Green
            )
        }
    }
}
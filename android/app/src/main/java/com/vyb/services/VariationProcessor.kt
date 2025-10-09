/*
 * VariationProcessor - AI response processing and variation generation for Android
 * Implements T051: Android Variation Processing
 * Kotlin counterpart to web VariationProcessor with feature parity and Android optimizations
 */

package com.vyb.services

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.gson.Gson
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.*
import kotlin.random.Random

// MARK: - Processing Types

data class LayerChange(
    val id: String = UUID.randomUUID().toString(),
    val layerId: String,
    val property: String,
    val currentValue: JsonElement,
    val suggestedValue: JsonElement,
    val reason: String
)

data class ProcessingOptions(
    val preserveOriginal: Boolean = true,
    val maxVariations: Int = 5,
    val confidenceThreshold: Double = 0.5,
    val enableBatching: Boolean = true,
    val autoSave: Boolean = true
) {
    companion object {
        val DEFAULT = ProcessingOptions()
    }
}

data class ProcessingResult(
    val processedVariations: List<SimpleVariationData>,
    val appliedChanges: List<LayerChange>,
    val rejectedChanges: List<LayerChange>,
    val processingTime: Long,
    val confidence: Double
)

data class VariationMetrics(
    var totalProcessed: Int = 0,
    var successful: Int = 0,
    var failed: Int = 0,
    var averageConfidence: Double = 0.0,
    var averageProcessingTime: Long = 0L
) {
    companion object {
        val EMPTY = VariationMetrics()
    }
}

data class ChangeApplication(
    val layerId: String,
    val property: String,
    val previousValue: JsonElement,
    val newValue: JsonElement,
    val success: Boolean,
    val error: String? = null
)

// MARK: - Variation Data Model

data class SimpleVariationData(
    val id: String,
    val parentId: String?,
    val canvasState: DesignCanvasData,
    val source: String,
    val prompt: String,
    val confidence: Double,
    val timestamp: Date,
    val metadata: VariationMetadata
)

data class VariationMetadata(
    val tags: List<String>,
    val notes: String,
    val approvalStatus: ApprovalStatus
)

enum class ApprovalStatus {
    PENDING, APPROVED, REJECTED
}

// MARK: - Error Types

sealed class VariationProcessingError(message: String) : Exception(message) {
    class InvalidAIResponse(message: String) : VariationProcessingError("Invalid AI Response: $message")
    class InvalidCanvas(message: String) : VariationProcessingError("Invalid Canvas: $message")
    class ProcessingFailed(message: String) : VariationProcessingError("Processing Failed: $message")
    class LayerNotFound(message: String) : VariationProcessingError("Layer Not Found: $message")
    class PropertyNotFound(message: String) : VariationProcessingError("Property Not Found: $message")
    class PreviewGenerationFailed(message: String) : VariationProcessingError("Preview Generation Failed: $message")
}

// MARK: - Variation Processor Class

class VariationProcessor : ViewModel() {
    
    private val gson = Gson()
    private var processingCache = mutableMapOf<String, ProcessingResult>()
    
    var isProcessing by mutableStateOf(false)
        private set
    
    var lastError by mutableStateOf<VariationProcessingError?>(null)
        private set
    
    var metrics by mutableStateOf(VariationMetrics.EMPTY)
        private set
    
    companion object {
        private const val TAG = "VariationProcessor"
    }
    
    // MARK: - Public API
    
    /**
     * Process AI response and generate variations
     */
    suspend fun processAIResponse(
        aiResponse: VariationResponse,
        baseCanvas: DesignCanvasData,
        options: ProcessingOptions = ProcessingOptions.DEFAULT
    ): ProcessingResult {
        val startTime = System.currentTimeMillis()
        
        return withContext(Dispatchers.IO) {
            try {
                isProcessing = true
                lastError = null
                
                // Validate AI response
                validateAIResponse(aiResponse)
                
                // Process each variation
                val processedVariations = mutableListOf<SimpleVariationData>()
                val appliedChanges = mutableListOf<LayerChange>()
                val rejectedChanges = mutableListOf<LayerChange>()
                
                aiResponse.variations.take(options.maxVariations).forEach { variationCanvasData ->
                    val variation = createVariationData(
                        canvasData = variationCanvasData,
                        baseCanvas = baseCanvas,
                        source = "ai_suggestion",
                        prompt = "AI generated variation"
                    )
                    
                    if (variation.confidence < options.confidenceThreshold) {
                        Log.w(TAG, "Skipping variation ${variation.id} due to low confidence: ${variation.confidence}")
                        return@forEach
                    }
                    
                    try {
                        val result = processVariation(variation, options)
                        processedVariations.add(result.variation)
                        appliedChanges.addAll(result.appliedChanges)
                        rejectedChanges.addAll(result.rejectedChanges)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to process variation ${variation.id}: ${e.message}", e)
                        metrics = metrics.copy(failed = metrics.failed + 1)
                    }
                }
                
                val processingTime = System.currentTimeMillis() - startTime
                val overallConfidence = calculateOverallConfidence(processedVariations)
                
                // Update metrics
                updateMetrics(processedVariations.size, processingTime, overallConfidence)
                
                val result = ProcessingResult(
                    processedVariations = processedVariations,
                    appliedChanges = appliedChanges,
                    rejectedChanges = rejectedChanges,
                    processingTime = processingTime,
                    confidence = overallConfidence
                )
                
                isProcessing = false
                result
                
            } catch (e: VariationProcessingError) {
                isProcessing = false
                lastError = e
                throw e
            } catch (e: Exception) {
                val error = VariationProcessingError.ProcessingFailed(e.message ?: "Unknown error")
                isProcessing = false
                lastError = error
                throw error
            }
        }
    }
    
    /**
     * Apply AI suggestions to canvas
     */
    suspend fun applySuggestions(
        suggestions: List<AISuggestionWithChanges>,
        targetCanvas: DesignCanvasData,
        options: ProcessingOptions = ProcessingOptions.DEFAULT
    ): Pair<DesignCanvasData, List<ChangeApplication>> {
        
        return withContext(Dispatchers.IO) {
            var modifiedCanvas = targetCanvas.copy()
            val changes = mutableListOf<ChangeApplication>()
            
            suggestions.forEach { suggestionWithChanges ->
                if (suggestionWithChanges.suggestion.confidence < options.confidenceThreshold) {
                    return@forEach
                }
                
                suggestionWithChanges.changes.forEach { change ->
                    try {
                        val application = applyLayerChange(modifiedCanvas, change)
                        modifiedCanvas = application.first
                        changes.add(application.second)
                    } catch (e: Exception) {
                        val failedApplication = ChangeApplication(
                            layerId = change.layerId,
                            property = change.property,
                            previousValue = change.currentValue,
                            newValue = change.suggestedValue,
                            success = false,
                            error = e.message
                        )
                        changes.add(failedApplication)
                    }
                }
            }
            
            Pair(modifiedCanvas, changes)
        }
    }
    
    /**
     * Generate variation preview image
     */
    suspend fun generateVariationPreview(
        variation: SimpleVariationData,
        width: Int = 300,
        height: Int = 200
    ): Bitmap {
        
        return withContext(Dispatchers.IO) {
            try {
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                
                // Fill background
                canvas.drawColor(Color.WHITE)
                
                // Calculate scale to fit canvas in preview size
                val canvasDimensions = variation.canvasState.dimensions
                val scaleX = width.toFloat() / canvasDimensions.width.toFloat()
                val scaleY = height.toFloat() / canvasDimensions.height.toFloat()
                val scale = minOf(scaleX, scaleY)
                
                canvas.save()
                canvas.scale(scale, scale)
                
                // Render layers
                variation.canvasState.layers.forEach { layer ->
                    renderLayer(layer, canvas)
                }
                
                canvas.restore()
                bitmap
                
            } catch (e: Exception) {
                throw VariationProcessingError.PreviewGenerationFailed(e.message ?: "Preview generation failed")
            }
        }
    }
    
    // MARK: - Flow-based Methods (Jetpack Compose Integration)
    
    /**
     * Process AI response with Flow for reactive UI
     */
    fun processAIResponseFlow(
        aiResponse: VariationResponse,
        baseCanvas: DesignCanvasData,
        options: ProcessingOptions = ProcessingOptions.DEFAULT
    ): Flow<ProcessingResult> = flow {
        val result = processAIResponse(aiResponse, baseCanvas, options)
        emit(result)
    }.flowOn(Dispatchers.IO)
    
    /**
     * Generate preview with Flow
     */
    fun generateVariationPreviewFlow(
        variation: SimpleVariationData,
        width: Int = 300,
        height: Int = 200
    ): Flow<Bitmap> = flow {
        val bitmap = generateVariationPreview(variation, width, height)
        emit(bitmap)
    }.flowOn(Dispatchers.IO)
    
    // MARK: - Private Processing Methods
    
    private fun createVariationData(
        canvasData: DesignCanvasData,
        baseCanvas: DesignCanvasData,
        source: String,
        prompt: String
    ): SimpleVariationData {
        return SimpleVariationData(
            id = UUID.randomUUID().toString(),
            parentId = baseCanvas.id,
            canvasState = canvasData,
            source = source,
            prompt = prompt,
            confidence = 0.8, // Default confidence
            timestamp = Date(),
            metadata = VariationMetadata(
                tags = emptyList(),
                notes = "",
                approvalStatus = ApprovalStatus.PENDING
            )
        )
    }
    
    private suspend fun processVariation(
        variation: SimpleVariationData,
        options: ProcessingOptions
    ): ProcessingVariationResult {
        
        // Validate variation canvas
        validateVariationCanvas(variation.canvasState)
        
        // For now, we'll just return the variation as-is
        // In a real implementation, you might process actual changes
        return ProcessingVariationResult(
            variation = variation,
            appliedChanges = emptyList(),
            rejectedChanges = emptyList()
        )
    }
    
    private data class ProcessingVariationResult(
        val variation: SimpleVariationData,
        val appliedChanges: List<LayerChange>,
        val rejectedChanges: List<LayerChange>
    )
    
    private suspend fun applyLayerChange(
        canvas: DesignCanvasData,
        change: LayerChange
    ): Pair<DesignCanvasData, ChangeApplication> {
        
        val layerIndex = canvas.layers.indexOfFirst { it.id == change.layerId }
        if (layerIndex == -1) {
            throw VariationProcessingError.LayerNotFound(change.layerId)
        }
        
        val layer = canvas.layers[layerIndex]
        val previousValue = getLayerProperty(layer, change.property)
        
        val modifiedLayer = setLayerProperty(layer, change.property, change.suggestedValue)
        val modifiedLayers = canvas.layers.toMutableList().apply {
            set(layerIndex, modifiedLayer)
        }
        
        val modifiedCanvas = canvas.copy(layers = modifiedLayers)
        
        val changeApplication = ChangeApplication(
            layerId = change.layerId,
            property = change.property,
            previousValue = previousValue,
            newValue = change.suggestedValue,
            success = true,
            error = null
        )
        
        return Pair(modifiedCanvas, changeApplication)
    }
    
    private fun getLayerProperty(layer: LayerData, propertyPath: String): JsonElement {
        val components = propertyPath.split(".")
        
        if (components.isEmpty()) {
            throw VariationProcessingError.PropertyNotFound(propertyPath)
        }
        
        // Simple property access for common cases
        return when (components[0]) {
            "transform" -> {
                if (components.size > 1) {
                    when (components[1]) {
                        "x" -> JsonPrimitive(layer.transform.x)
                        "y" -> JsonPrimitive(layer.transform.y)
                        "scaleX" -> JsonPrimitive(layer.transform.scaleX)
                        "scaleY" -> JsonPrimitive(layer.transform.scaleY)
                        "rotation" -> JsonPrimitive(layer.transform.rotation)
                        "opacity" -> JsonPrimitive(layer.transform.opacity)
                        else -> throw VariationProcessingError.PropertyNotFound(propertyPath)
                    }
                } else {
                    throw VariationProcessingError.PropertyNotFound(propertyPath)
                }
            }
            "content" -> {
                if (components.size > 1) {
                    val value = layer.content[components[1]]
                    if (value != null) {
                        gson.toJsonTree(value)
                    } else {
                        throw VariationProcessingError.PropertyNotFound(propertyPath)
                    }
                } else {
                    throw VariationProcessingError.PropertyNotFound(propertyPath)
                }
            }
            "style" -> {
                if (components.size > 1) {
                    val value = layer.style[components[1]]
                    if (value != null) {
                        gson.toJsonTree(value)
                    } else {
                        throw VariationProcessingError.PropertyNotFound(propertyPath)
                    }
                } else {
                    throw VariationProcessingError.PropertyNotFound(propertyPath)
                }
            }
            else -> throw VariationProcessingError.PropertyNotFound(propertyPath)
        }
    }
    
    private fun setLayerProperty(layer: LayerData, propertyPath: String, value: JsonElement): LayerData {
        val components = propertyPath.split(".")
        
        if (components.isEmpty()) return layer
        
        // Simple property setting for common cases
        return when (components[0]) {
            "transform" -> {
                if (components.size > 1 && value.isJsonPrimitive && value.asJsonPrimitive.isNumber) {
                    val doubleValue = value.asDouble
                    val newTransform = when (components[1]) {
                        "x" -> layer.transform.copy(x = doubleValue)
                        "y" -> layer.transform.copy(y = doubleValue)
                        "scaleX" -> layer.transform.copy(scaleX = doubleValue)
                        "scaleY" -> layer.transform.copy(scaleY = doubleValue)
                        "rotation" -> layer.transform.copy(rotation = doubleValue)
                        "opacity" -> layer.transform.copy(opacity = doubleValue)
                        else -> layer.transform
                    }
                    layer.copy(transform = newTransform)
                } else {
                    layer
                }
            }
            "content" -> {
                if (components.size > 1) {
                    val newContent = layer.content.toMutableMap().apply {
                        put(components[1], gson.fromJson(value, Any::class.java))
                    }
                    layer.copy(content = newContent)
                } else {
                    layer
                }
            }
            "style" -> {
                if (components.size > 1) {
                    val newStyle = layer.style.toMutableMap().apply {
                        put(components[1], gson.fromJson(value, Any::class.java))
                    }
                    layer.copy(style = newStyle)
                } else {
                    layer
                }
            }
            else -> layer
        }
    }
    
    private fun renderLayer(layer: LayerData, canvas: Canvas) {
        val paint = Paint().apply {
            alpha = (layer.transform.opacity * 255).toInt()
        }
        
        canvas.save()
        
        // Apply transform
        canvas.translate(layer.transform.x.toFloat(), layer.transform.y.toFloat())
        canvas.scale(layer.transform.scaleX.toFloat(), layer.transform.scaleY.toFloat())
        canvas.rotate(layer.transform.rotation.toFloat())
        
        when (layer.type) {
            "text" -> renderTextLayer(layer, canvas, paint)
            "shape" -> renderShapeLayer(layer, canvas, paint)
            "image" -> renderImageLayer(layer, canvas, paint)
            "background" -> renderBackgroundLayer(layer, canvas, paint)
            else -> Log.w(TAG, "Unknown layer type: ${layer.type}")
        }
        
        canvas.restore()
    }
    
    private fun renderTextLayer(layer: LayerData, canvas: Canvas, paint: Paint) {
        val text = layer.content["text"] as? String ?: return
        val fontSize = (layer.content["fontSize"] as? Number)?.toFloat() ?: 16f
        val color = parseColor(layer.style["color"] as? String ?: "#000000")
        
        paint.apply {
            textSize = fontSize
            this.color = color
            isAntiAlias = true
        }
        
        canvas.drawText(text, 0f, fontSize, paint)
    }
    
    private fun renderShapeLayer(layer: LayerData, canvas: Canvas, paint: Paint) {
        val width = 100f // Default shape size
        val height = 100f
        val fill = parseColor(layer.content["fill"] as? String ?: "#3B82F6")
        val stroke = layer.content["stroke"] as? String
        val strokeWidth = (layer.content["strokeWidth"] as? Number)?.toFloat() ?: 0f
        
        // Fill
        paint.apply {
            style = Paint.Style.FILL
            color = fill
        }
        canvas.drawRect(0f, 0f, width, height, paint)
        
        // Stroke
        if (!stroke.isNullOrEmpty() && strokeWidth > 0) {
            paint.apply {
                style = Paint.Style.STROKE
                color = parseColor(stroke)
                strokeWidth = strokeWidth
            }
            canvas.drawRect(0f, 0f, width, height, paint)
        }
    }
    
    private fun renderImageLayer(layer: LayerData, canvas: Canvas, paint: Paint) {
        // Placeholder for image rendering
        paint.apply {
            style = Paint.Style.FILL
            color = Color.LTGRAY
        }
        canvas.drawRect(0f, 0f, 100f, 100f, paint)
        
        paint.apply {
            color = Color.GRAY
            textSize = 12f
            isAntiAlias = true
        }
        canvas.drawText("Image", 40f, 50f, paint)
    }
    
    private fun renderBackgroundLayer(layer: LayerData, canvas: Canvas, paint: Paint) {
        val color = parseColor(layer.content["color"] as? String ?: "#ffffff")
        
        paint.apply {
            style = Paint.Style.FILL
            this.color = color
        }
        canvas.drawPaint(paint)
    }
    
    private fun parseColor(hexColor: String): Int {
        return try {
            Color.parseColor(hexColor)
        } catch (e: Exception) {
            Color.BLACK
        }
    }
    
    // MARK: - Validation Methods
    
    private fun validateAIResponse(response: VariationResponse) {
        if (response.variations.isEmpty()) {
            throw VariationProcessingError.InvalidAIResponse("Response contains no variations")
        }
        
        response.variations.forEach { variation ->
            if (variation.id.isEmpty()) {
                throw VariationProcessingError.InvalidAIResponse("Variation missing ID")
            }
        }
    }
    
    private fun validateVariationCanvas(canvas: DesignCanvasData) {
        if (canvas.layers.isEmpty()) {
            throw VariationProcessingError.InvalidCanvas("Canvas must contain at least one layer")
        }
        
        canvas.layers.forEach { layer ->
            if (layer.id.isEmpty() || layer.type.isEmpty()) {
                throw VariationProcessingError.InvalidCanvas("Layer missing ID or type")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    private fun calculateOverallConfidence(variations: List<SimpleVariationData>): Double {
        if (variations.isEmpty()) return 0.0
        
        val totalConfidence = variations.sumOf { it.confidence }
        return totalConfidence / variations.size
    }
    
    private fun updateMetrics(processed: Int, time: Long, confidence: Double) {
        val newTotalProcessed = metrics.totalProcessed + processed
        val newSuccessful = metrics.successful + processed
        
        // Running average calculation
        val newAverageProcessingTime = if (newSuccessful > 0) {
            (metrics.averageProcessingTime * (newSuccessful - processed) + time) / newSuccessful
        } else {
            0L
        }
        
        val newAverageConfidence = if (newSuccessful > 0) {
            (metrics.averageConfidence * (newSuccessful - processed) + confidence * processed) / newSuccessful
        } else {
            0.0
        }
        
        metrics = metrics.copy(
            totalProcessed = newTotalProcessed,
            successful = newSuccessful,
            averageProcessingTime = newAverageProcessingTime,
            averageConfidence = newAverageConfidence
        )
    }
    
    // MARK: - Public Utility Methods
    
    fun clearMetrics() {
        metrics = VariationMetrics.EMPTY
    }
    
    fun clearError() {
        lastError = null
    }
    
    fun getProcessingCache(): Map<String, ProcessingResult> {
        return processingCache.toMap()
    }
    
    fun clearProcessingCache() {
        processingCache.clear()
    }
}

// MARK: - Supporting Types

data class AISuggestionWithChanges(
    val suggestion: AISuggestion,
    val changes: List<LayerChange>
)

// MARK: - Singleton Provider

object VariationProcessorProvider {
    private var instance: VariationProcessor? = null
    
    fun getInstance(): VariationProcessor {
        return instance ?: synchronized(this) {
            instance ?: VariationProcessor().also { instance = it }
        }
    }
}
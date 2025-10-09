package com.vyb.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import androidx.room.ColumnInfo
import androidx.room.ForeignKey
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import com.google.gson.reflect.TypeToken
import java.util.*
import kotlin.math.*

// MARK: - Layer Type Enum
enum class LayerType(val value: String) {
    @SerializedName("text")
    TEXT("text"),
    
    @SerializedName("image")
    IMAGE("image"),
    
    @SerializedName("background")
    BACKGROUND("background"),
    
    @SerializedName("shape")
    SHAPE("shape"),
    
    @SerializedName("group")
    GROUP("group");
    
    companion object {
        fun fromString(value: String): LayerType? {
            return values().find { it.value == value }
        }
    }
}

// MARK: - Transform Properties
data class Transform(
    val x: Double,
    val y: Double,
    val scaleX: Double,
    val scaleY: Double,
    val rotation: Double, // in degrees
    val opacity: Double // 0-1
)

// MARK: - Layer Content (type-specific)
data class LayerContent(
    // Text layer
    val text: String? = null,
    val fontSize: Double? = null,
    val fontFamily: String? = null,
    
    // Image layer
    val imageUrl: String? = null,
    val imageData: String? = null,
    
    // Background layer
    val color: String? = null,
    val gradient: GradientData? = null,
    
    // Shape layer
    val shapeType: String? = null,
    val fill: String? = null,
    val stroke: String? = null,
    val strokeWidth: Double? = null,
    
    // Group layer
    val childLayerIds: List<String>? = null
)

data class GradientData(
    val type: String, // 'linear' or 'radial'
    val stops: List<GradientStop>
)

data class GradientStop(
    val color: String,
    val position: Double
)

// MARK: - Layer Style Properties
data class LayerStyle(
    val fontSize: Double? = null,
    val fontFamily: String? = null,
    val color: String? = null,
    val backgroundColor: String? = null,
    val borderRadius: Double? = null,
    val borderWidth: Double? = null,
    val borderColor: String? = null,
    val boxShadow: ShadowData? = null,
    val filter: FilterData? = null
)

data class ShadowData(
    val x: Double,
    val y: Double,
    val blur: Double,
    val spread: Double,
    val color: String
)

data class FilterData(
    val blur: Double? = null,
    val brightness: Double? = null,
    val contrast: Double? = null,
    val saturate: Double? = null
)

// MARK: - Layer Constraints
data class LayerConstraints(
    val locked: Boolean,
    val visible: Boolean,
    val maintainAspectRatio: Boolean? = null,
    val minWidth: Double? = null,
    val minHeight: Double? = null,
    val maxWidth: Double? = null,
    val maxHeight: Double? = null,
    val pinTop: Boolean? = null,
    val pinBottom: Boolean? = null,
    val pinLeft: Boolean? = null,
    val pinRight: Boolean? = null,
    val centerX: Boolean? = null,
    val centerY: Boolean? = null
)

// MARK: - Layer Metadata
data class LayerMetadata(
    val source: String, // 'user' or 'ai'
    val createdAt: Date,
    val modifiedAt: Date? = null,
    val version: Int? = null,
    val tags: List<String>? = null,
    val notes: String? = null
)

// MARK: - Type Converters
class LayerConverters {
    
    private val gson = Gson()
    
    @androidx.room.TypeConverter
    fun fromTransform(transform: Transform): String {
        return gson.toJson(transform)
    }
    
    @androidx.room.TypeConverter
    fun toTransform(transformString: String): Transform {
        return gson.fromJson(transformString, Transform::class.java)
    }
    
    @androidx.room.TypeConverter
    fun fromLayerContent(content: LayerContent): String {
        return gson.toJson(content)
    }
    
    @androidx.room.TypeConverter
    fun toLayerContent(contentString: String): LayerContent {
        return gson.fromJson(contentString, LayerContent::class.java)
    }
    
    @androidx.room.TypeConverter
    fun fromLayerStyle(style: LayerStyle): String {
        return gson.toJson(style)
    }
    
    @androidx.room.TypeConverter
    fun toLayerStyle(styleString: String): LayerStyle {
        return gson.fromJson(styleString, LayerStyle::class.java)
    }
    
    @androidx.room.TypeConverter
    fun fromLayerConstraints(constraints: LayerConstraints): String {
        return gson.toJson(constraints)
    }
    
    @androidx.room.TypeConverter
    fun toLayerConstraints(constraintsString: String): LayerConstraints {
        return gson.fromJson(constraintsString, LayerConstraints::class.java)
    }
    
    @androidx.room.TypeConverter
    fun fromLayerMetadata(metadata: LayerMetadata): String {
        return gson.toJson(metadata)
    }
    
    @androidx.room.TypeConverter
    fun toLayerMetadata(metadataString: String): LayerMetadata {
        return gson.fromJson(metadataString, LayerMetadata::class.java)
    }
    
    @androidx.room.TypeConverter
    fun fromDate(date: Date?): Long? {
        return date?.time
    }
    
    @androidx.room.TypeConverter
    fun toDate(timestamp: Long?): Date? {
        return timestamp?.let { Date(it) }
    }
    
    @androidx.room.TypeConverter
    fun fromStringList(list: List<String>?): String? {
        return list?.let { gson.toJson(it) }
    }
    
    @androidx.room.TypeConverter
    fun toStringList(listString: String?): List<String>? {
        return listString?.let {
            val type = object : TypeToken<List<String>>() {}.type
            gson.fromJson(it, type)
        }
    }
}

// MARK: - Room Entity
@Entity(
    tableName = "layers",
    foreignKeys = [
        ForeignKey(
            entity = DesignCanvas::class,
            parentColumns = ["id"],
            childColumns = ["canvas_id"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
@TypeConverters(LayerConverters::class)
data class Layer(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    
    @ColumnInfo(name = "type")
    var type: LayerType,
    
    @ColumnInfo(name = "content")
    var content: LayerContent,
    
    @ColumnInfo(name = "transform")
    var transform: Transform,
    
    @ColumnInfo(name = "style")
    var style: LayerStyle,
    
    @ColumnInfo(name = "constraints")
    var constraints: LayerConstraints,
    
    @ColumnInfo(name = "metadata")
    var metadata: LayerMetadata,
    
    @ColumnInfo(name = "z_index")
    var zIndex: Int,
    
    @ColumnInfo(name = "canvas_id")
    val canvasId: String,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date(),
    
    @ColumnInfo(name = "updated_at")
    var updatedAt: Date = Date()
) {
    
    // MARK: - Validation Methods
    
    @Throws(LayerValidationException::class)
    fun validateLayerData() {
        // Validate Layer ID
        if (id.isBlank()) {
            throw LayerValidationException("Layer ID must be a valid non-empty string")
        }
        
        // Validate Canvas ID
        if (canvasId.isBlank()) {
            throw LayerValidationException("Canvas ID must be a valid non-empty string")
        }
        
        // Validate content matches layer type
        validateLayerContent()
        
        // Validate transform values
        validateTransform()
        
        // Validate constraints
        validateConstraints()
    }
    
    @Throws(LayerValidationException::class)
    private fun validateLayerContent() {
        when (type) {
            LayerType.TEXT -> validateTextContent()
            LayerType.IMAGE -> validateImageContent()
            LayerType.BACKGROUND -> validateBackgroundContent()
            LayerType.SHAPE -> validateShapeContent()
            LayerType.GROUP -> validateGroupContent()
        }
    }
    
    @Throws(LayerValidationException::class)
    private fun validateTextContent() {
        val text = content.text
        if (text.isNullOrBlank()) {
            throw LayerValidationException("Text layer must have text content")
        }
    }
    
    @Throws(LayerValidationException::class)
    private fun validateImageContent() {
        val imageUrl = content.imageUrl
        val imageData = content.imageData
        
        if (imageUrl.isNullOrBlank() && imageData.isNullOrBlank()) {
            throw LayerValidationException("Image layer must have imageUrl or imageData")
        }
        
        if (!imageUrl.isNullOrBlank() && imageUrl.isBlank()) {
            throw LayerValidationException("Image layer imageUrl must not be empty")
        }
    }
    
    @Throws(LayerValidationException::class)
    private fun validateBackgroundContent() {
        // Background layers can have empty content (will use defaults)
        // Just validate that if color or gradient is provided, they're valid
        val color = content.color
        val gradient = content.gradient
        
        if (color == null && gradient == null) {
            // Allow empty content for background layers - will use defaults
            return
        }
    }
    
    @Throws(LayerValidationException::class)
    private fun validateShapeContent() {
        // Shape layers can have various properties, minimal validation
        // Just ensure we have some shape type
        val shapeType = content.shapeType
        if (shapeType.isNullOrBlank()) {
            // Allow empty shape type - will use defaults
            return
        }
    }
    
    @Throws(LayerValidationException::class)
    private fun validateGroupContent() {
        val childIds = content.childLayerIds
        if (childIds == null) {
            throw LayerValidationException("Group layer must have childLayerIds array")
        }
        
        if (childIds.isEmpty()) {
            throw LayerValidationException("Group layer must contain at least one child layer")
        }
    }
    
    @Throws(LayerValidationException::class)
    private fun validateTransform() {
        // Validate opacity range (0-1)
        if (transform.opacity < 0 || transform.opacity > 1) {
            throw LayerValidationException("Transform opacity must be between 0 and 1")
        }
        
        // Validate rotation range (0-360)
        if (transform.rotation < 0 || transform.rotation > 360) {
            throw LayerValidationException("Transform rotation must be between 0 and 360 degrees")
        }
        
        // Validate scale values
        if (transform.scaleX <= 0 || transform.scaleY <= 0) {
            throw LayerValidationException("Transform scale values must be positive")
        }
    }
    
    @Throws(LayerValidationException::class)
    private fun validateConstraints() {
        val minWidth = constraints.minWidth
        val maxWidth = constraints.maxWidth
        val minHeight = constraints.minHeight
        val maxHeight = constraints.maxHeight
        
        // Validate dimension constraints
        if (minWidth != null && maxWidth != null && minWidth > maxWidth) {
            throw LayerValidationException("minWidth must be less than or equal to maxWidth")
        }
        
        if (minHeight != null && maxHeight != null && minHeight > maxHeight) {
            throw LayerValidationException("minHeight must be less than or equal to maxHeight")
        }
    }
    
    @Throws(LayerValidationException::class)
    fun validateTransformBounds(canvasWidth: Double, canvasHeight: Double) {
        val bounds = getBoundingBox()
        
        // Check if layer is completely outside canvas bounds (with some tolerance)
        val tolerance = max(canvasWidth, canvasHeight) * 0.5
        val minBounds = -tolerance
        val maxBoundsX = canvasWidth + tolerance
        val maxBoundsY = canvasHeight + tolerance
        
        if (bounds.right < minBounds || bounds.left > maxBoundsX ||
            bounds.bottom < minBounds || bounds.top > maxBoundsY) {
            throw LayerValidationException("Transform values must be within canvas boundaries")
        }
    }
    
    // MARK: - Convenience Methods
    
    @Throws(LayerValidationException::class)
    fun updateTransform(updates: Transform): Layer {
        val oldTransform = transform
        transform = updates
        updatedAt = Date()
        
        try {
            validateTransform()
        } catch (e: LayerValidationException) {
            // Restore old transform if validation fails
            transform = oldTransform
            throw e
        }
        
        // Update metadata
        metadata = metadata.copy(modifiedAt = Date())
        
        return this
    }
    
    @Throws(LayerValidationException::class)
    fun updateContent(updates: LayerContent): Layer {
        val oldContent = content
        content = updates
        updatedAt = Date()
        
        try {
            validateLayerContent()
        } catch (e: LayerValidationException) {
            // Restore old content if validation fails
            content = oldContent
            throw e
        }
        
        // Update metadata
        metadata = metadata.copy(modifiedAt = Date())
        
        return this
    }
    
    fun updateStyle(updates: LayerStyle): Layer {
        // Merge style properties
        style = LayerStyle(
            fontSize = updates.fontSize ?: style.fontSize,
            fontFamily = updates.fontFamily ?: style.fontFamily,
            color = updates.color ?: style.color,
            backgroundColor = updates.backgroundColor ?: style.backgroundColor,
            borderRadius = updates.borderRadius ?: style.borderRadius,
            borderWidth = updates.borderWidth ?: style.borderWidth,
            borderColor = updates.borderColor ?: style.borderColor,
            boxShadow = updates.boxShadow ?: style.boxShadow,
            filter = updates.filter ?: style.filter
        )
        
        updatedAt = Date()
        
        // Update metadata
        metadata = metadata.copy(modifiedAt = Date())
        
        return this
    }
    
    fun isVisible(): Boolean {
        return constraints.visible && transform.opacity > 0
    }
    
    data class BoundingBox(
        val left: Double,
        val top: Double,
        val right: Double,
        val bottom: Double
    )
    
    fun getBoundingBox(): BoundingBox {
        // This is a simplified bounding box calculation
        // In a real implementation, this would consider the layer's actual content dimensions
        val width = 100.0 * transform.scaleX // Default width scaled
        val height = 100.0 * transform.scaleY // Default height scaled
        
        return BoundingBox(
            left = transform.x,
            top = transform.y,
            right = transform.x + width,
            bottom = transform.y + height
        )
    }
    
    fun updateConstraints(updates: LayerConstraints): Layer {
        constraints = updates
        updatedAt = Date()
        
        // Update metadata
        metadata = metadata.copy(modifiedAt = Date())
        
        return this
    }
    
    fun lock(): Layer {
        constraints = constraints.copy(locked = true)
        updatedAt = Date()
        metadata = metadata.copy(modifiedAt = Date())
        return this
    }
    
    fun unlock(): Layer {
        constraints = constraints.copy(locked = false)
        updatedAt = Date()
        metadata = metadata.copy(modifiedAt = Date())
        return this
    }
    
    fun show(): Layer {
        constraints = constraints.copy(visible = true)
        updatedAt = Date()
        metadata = metadata.copy(modifiedAt = Date())
        return this
    }
    
    fun hide(): Layer {
        constraints = constraints.copy(visible = false)
        updatedAt = Date()
        metadata = metadata.copy(modifiedAt = Date())
        return this
    }
}

// MARK: - Factory Methods
object LayerFactory {
    
    fun createDefault(
        type: LayerType,
        id: String,
        canvasId: String
    ): Layer {
        val defaultTransform = Transform(
            x = 0.0,
            y = 0.0,
            scaleX = 1.0,
            scaleY = 1.0,
            rotation = 0.0,
            opacity = 1.0
        )
        
        val defaultConstraints = LayerConstraints(
            locked = false,
            visible = true,
            maintainAspectRatio = true
        )
        
        val defaultMetadata = LayerMetadata(
            source = "user",
            createdAt = Date()
        )
        
        val (defaultContent, defaultStyle) = when (type) {
            LayerType.TEXT -> {
                val content = LayerContent(text = "New Text Layer")
                val style = LayerStyle(fontSize = 16.0, color = "#000000")
                Pair(content, style)
            }
            LayerType.IMAGE -> {
                val content = LayerContent(imageUrl = "")
                val style = LayerStyle()
                Pair(content, style)
            }
            LayerType.BACKGROUND -> {
                val content = LayerContent(color = "#ffffff")
                val style = LayerStyle()
                Pair(content, style)
            }
            LayerType.SHAPE -> {
                val content = LayerContent(shapeType = "rectangle")
                val style = LayerStyle(color = "#000000")
                Pair(content, style)
            }
            LayerType.GROUP -> {
                val content = LayerContent(childLayerIds = listOf())
                val style = LayerStyle()
                Pair(content, style)
            }
        }
        
        return Layer(
            id = id,
            type = type,
            content = defaultContent,
            transform = defaultTransform,
            style = defaultStyle,
            constraints = defaultConstraints,
            metadata = defaultMetadata,
            zIndex = 0,
            canvasId = canvasId
        )
    }
}

// MARK: - JSON Serialization
fun Layer.toJson(): Map<String, Any?> {
    return mapOf(
        "id" to id,
        "type" to type.value,
        "content" to encodeContent(),
        "transform" to encodeTransform(),
        "style" to encodeStyle(),
        "constraints" to encodeConstraints(),
        "metadata" to encodeMetadata(),
        "zIndex" to zIndex,
        "canvasId" to canvasId,
        "createdAt" to createdAt.time,
        "updatedAt" to updatedAt.time
    )
}

private fun Layer.encodeContent(): Map<String, Any?> {
    return mutableMapOf<String, Any?>().apply {
        content.text?.let { put("text", it) }
        content.fontSize?.let { put("fontSize", it) }
        content.fontFamily?.let { put("fontFamily", it) }
        content.imageUrl?.let { put("imageUrl", it) }
        content.imageData?.let { put("imageData", it) }
        content.color?.let { put("color", it) }
        content.gradient?.let { gradient ->
            put("gradient", mapOf(
                "type" to gradient.type,
                "stops" to gradient.stops.map { 
                    mapOf("color" to it.color, "position" to it.position) 
                }
            ))
        }
        content.shapeType?.let { put("shapeType", it) }
        content.fill?.let { put("fill", it) }
        content.stroke?.let { put("stroke", it) }
        content.strokeWidth?.let { put("strokeWidth", it) }
        content.childLayerIds?.let { put("childLayerIds", it) }
    }
}

private fun Layer.encodeTransform(): Map<String, Any> {
    return mapOf(
        "x" to transform.x,
        "y" to transform.y,
        "scaleX" to transform.scaleX,
        "scaleY" to transform.scaleY,
        "rotation" to transform.rotation,
        "opacity" to transform.opacity
    )
}

private fun Layer.encodeStyle(): Map<String, Any?> {
    return mutableMapOf<String, Any?>().apply {
        style.fontSize?.let { put("fontSize", it) }
        style.fontFamily?.let { put("fontFamily", it) }
        style.color?.let { put("color", it) }
        style.backgroundColor?.let { put("backgroundColor", it) }
        style.borderRadius?.let { put("borderRadius", it) }
        style.borderWidth?.let { put("borderWidth", it) }
        style.borderColor?.let { put("borderColor", it) }
        style.boxShadow?.let { shadow ->
            put("boxShadow", mapOf(
                "x" to shadow.x,
                "y" to shadow.y,
                "blur" to shadow.blur,
                "spread" to shadow.spread,
                "color" to shadow.color
            ))
        }
        style.filter?.let { filter ->
            put("filter", mutableMapOf<String, Any?>().apply {
                filter.blur?.let { put("blur", it) }
                filter.brightness?.let { put("brightness", it) }
                filter.contrast?.let { put("contrast", it) }
                filter.saturate?.let { put("saturate", it) }
            })
        }
    }
}

private fun Layer.encodeConstraints(): Map<String, Any?> {
    return mutableMapOf<String, Any?>().apply {
        put("locked", constraints.locked)
        put("visible", constraints.visible)
        constraints.maintainAspectRatio?.let { put("maintainAspectRatio", it) }
        constraints.minWidth?.let { put("minWidth", it) }
        constraints.minHeight?.let { put("minHeight", it) }
        constraints.maxWidth?.let { put("maxWidth", it) }
        constraints.maxHeight?.let { put("maxHeight", it) }
        constraints.pinTop?.let { put("pinTop", it) }
        constraints.pinBottom?.let { put("pinBottom", it) }
        constraints.pinLeft?.let { put("pinLeft", it) }
        constraints.pinRight?.let { put("pinRight", it) }
        constraints.centerX?.let { put("centerX", it) }
        constraints.centerY?.let { put("centerY", it) }
    }
}

private fun Layer.encodeMetadata(): Map<String, Any?> {
    return mutableMapOf<String, Any?>().apply {
        put("source", metadata.source)
        put("createdAt", metadata.createdAt.time)
        metadata.modifiedAt?.let { put("modifiedAt", it.time) }
        metadata.version?.let { put("version", it) }
        metadata.tags?.let { put("tags", it) }
        metadata.notes?.let { put("notes", it) }
    }
}

// MARK: - Validation Exceptions
class LayerValidationException(message: String) : Exception(message)
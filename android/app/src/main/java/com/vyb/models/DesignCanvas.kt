package com.vyb.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import androidx.room.ColumnInfo
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import com.google.gson.reflect.TypeToken
import java.util.*

// MARK: - Device Type Enum
enum class DeviceType(val value: String) {
    @SerializedName("mobile")
    MOBILE("mobile"),
    
    @SerializedName("tablet")
    TABLET("tablet"),
    
    @SerializedName("desktop") 
    DESKTOP("desktop"),
    
    @SerializedName("watch")
    WATCH("watch"),
    
    @SerializedName("tv")
    TV("tv");
    
    companion object {
        fun fromString(value: String): DeviceType? {
            return values().find { it.value == value }
        }
    }
}

// MARK: - Canvas State
data class CanvasState(
    val deviceType: DeviceType,
    val width: Double,
    val height: Double,
    val backgroundColor: String,
    val zoom: Double = 1.0,
    val panX: Double = 0.0,
    val panY: Double = 0.0,
    val layers: List<String> = listOf(), // Layer IDs in z-order
    val selectedLayers: List<String> = listOf(), // Selected layer IDs
    val gridEnabled: Boolean = false,
    val snapToGrid: Boolean = false,
    val gridSize: Double = 10.0,
    val showRulers: Boolean = false,
    val lockAspectRatio: Boolean = true
)

// MARK: - Canvas Metadata
data class CanvasMetadata(
    val source: String, // 'user' or 'ai'
    val createdAt: Date,
    val modifiedAt: Date? = null,
    val version: Int = 1,
    val tags: List<String> = listOf(),
    val notes: String? = null,
    val collaborators: List<String> = listOf(),
    val lastEditedBy: String? = null
)

// MARK: - Type Converters
class DesignCanvasConverters {
    
    private val gson = Gson()
    
    @androidx.room.TypeConverter
    fun fromCanvasState(state: CanvasState): String {
        return gson.toJson(state)
    }
    
    @androidx.room.TypeConverter
    fun toCanvasState(stateString: String): CanvasState {
        return gson.fromJson(stateString, CanvasState::class.java)
    }
    
    @androidx.room.TypeConverter
    fun fromCanvasMetadata(metadata: CanvasMetadata): String {
        return gson.toJson(metadata)
    }
    
    @androidx.room.TypeConverter
    fun toCanvasMetadata(metadataString: String): CanvasMetadata {
        return gson.fromJson(metadataString, CanvasMetadata::class.java)
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
    fun fromStringList(list: List<String>): String {
        return gson.toJson(list)
    }
    
    @androidx.room.TypeConverter
    fun toStringList(listString: String): List<String> {
        val type = object : TypeToken<List<String>>() {}.type
        return gson.fromJson(listString, type)
    }
}

// MARK: - Device Specifications
object DeviceSpecifications {
    
    data class DeviceSpec(
        val minWidth: Double,
        val maxWidth: Double,
        val minHeight: Double,
        val maxHeight: Double,
        val aspectRatios: List<AspectRatio>
    )
    
    data class AspectRatio(
        val width: Double,
        val height: Double,
        val name: String
    )
    
    val DEVICE_SPECS = mapOf(
        DeviceType.MOBILE to DeviceSpec(
            minWidth = 320.0,
            maxWidth = 428.0,
            minHeight = 568.0,
            maxHeight = 932.0,
            aspectRatios = listOf(
                AspectRatio(9.0, 16.0, "9:16"),
                AspectRatio(9.0, 19.5, "9:19.5"),
                AspectRatio(9.0, 20.0, "9:20")
            )
        ),
        DeviceType.TABLET to DeviceSpec(
            minWidth = 768.0,
            maxWidth = 1366.0,
            minHeight = 1024.0,
            maxHeight = 1024.0,
            aspectRatios = listOf(
                AspectRatio(3.0, 4.0, "3:4"),
                AspectRatio(4.0, 3.0, "4:3"),
                AspectRatio(16.0, 10.0, "16:10")
            )
        ),
        DeviceType.DESKTOP to DeviceSpec(
            minWidth = 1024.0,
            maxWidth = 3840.0,
            minHeight = 768.0,
            maxHeight = 2160.0,
            aspectRatios = listOf(
                AspectRatio(16.0, 9.0, "16:9"),
                AspectRatio(16.0, 10.0, "16:10"),
                AspectRatio(21.0, 9.0, "21:9")
            )
        ),
        DeviceType.WATCH to DeviceSpec(
            minWidth = 40.0,
            maxWidth = 50.0,
            minHeight = 40.0,
            maxHeight = 50.0,
            aspectRatios = listOf(
                AspectRatio(1.0, 1.0, "1:1")
            )
        ),
        DeviceType.TV to DeviceSpec(
            minWidth = 1920.0,
            maxWidth = 3840.0,
            minHeight = 1080.0,
            maxHeight = 2160.0,
            aspectRatios = listOf(
                AspectRatio(16.0, 9.0, "16:9"),
                AspectRatio(21.0, 9.0, "21:9")
            )
        )
    )
}

// MARK: - Room Entity
@Entity(tableName = "design_canvases")
@TypeConverters(DesignCanvasConverters::class)
data class DesignCanvas(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    
    @ColumnInfo(name = "name")
    var name: String,
    
    @ColumnInfo(name = "description")
    var description: String = "",
    
    @ColumnInfo(name = "state")
    var state: CanvasState,
    
    @ColumnInfo(name = "metadata")
    var metadata: CanvasMetadata,
    
    @ColumnInfo(name = "is_active")
    var isActive: Boolean = true,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date(),
    
    @ColumnInfo(name = "updated_at")
    var updatedAt: Date = Date()
) {
    
    // MARK: - Validation Methods
    
    @Throws(DesignCanvasValidationException::class)
    fun validateCanvasData() {
        // Validate Canvas ID
        if (id.isBlank()) {
            throw DesignCanvasValidationException("Canvas ID must be a valid non-empty string")
        }
        
        // Validate Canvas Name
        if (name.isBlank()) {
            throw DesignCanvasValidationException("Canvas name must be a valid non-empty string")
        }
        
        // Validate device type and dimensions
        validateDeviceSpecifications()
        
        // Validate z-index ordering
        validateZIndexOrdering()
        
        // Validate layers exist and are valid
        validateLayerReferences()
    }
    
    @Throws(DesignCanvasValidationException::class)
    private fun validateDeviceSpecifications() {
        val deviceSpec = DeviceSpecifications.DEVICE_SPECS[state.deviceType]
            ?: throw DesignCanvasValidationException("Unsupported device type: ${state.deviceType}")
        
        // Validate canvas dimensions are within device specifications
        if (state.width < deviceSpec.minWidth || state.width > deviceSpec.maxWidth) {
            throw DesignCanvasValidationException(
                "Canvas width ${state.width} is outside valid range for ${state.deviceType.value} " +
                "(${deviceSpec.minWidth}-${deviceSpec.maxWidth})"
            )
        }
        
        if (state.height < deviceSpec.minHeight || state.height > deviceSpec.maxHeight) {
            throw DesignCanvasValidationException(
                "Canvas height ${state.height} is outside valid range for ${state.deviceType.value} " +
                "(${deviceSpec.minHeight}-${deviceSpec.maxHeight})"
            )
        }
        
        // Validate aspect ratio
        val aspectRatio = state.width / state.height
        val validAspectRatio = deviceSpec.aspectRatios.any { spec ->
            val expectedRatio = spec.width / spec.height
            kotlin.math.abs(aspectRatio - expectedRatio) < 0.1
        }
        
        if (!validAspectRatio) {
            throw DesignCanvasValidationException(
                "Canvas aspect ratio ${String.format("%.2f", aspectRatio)} is not valid for ${state.deviceType.value}"
            )
        }
    }
    
    @Throws(DesignCanvasValidationException::class)
    private fun validateZIndexOrdering() {
        // For now, just validate that layers list doesn't have duplicates
        val uniqueLayers = state.layers.distinct()
        if (uniqueLayers.size != state.layers.size) {
            throw DesignCanvasValidationException("Canvas layers must not contain duplicate IDs")
        }
    }
    
    @Throws(DesignCanvasValidationException::class)
    private fun validateLayerReferences() {
        // Validate selected layers are subset of all layers
        val invalidSelections = state.selectedLayers.filter { it !in state.layers }
        if (invalidSelections.isNotEmpty()) {
            throw DesignCanvasValidationException(
                "Selected layers contain invalid references: ${invalidSelections.joinToString(", ")}"
            )
        }
    }
    
    // MARK: - Canvas State Management
    
    @Throws(DesignCanvasValidationException::class)
    fun setState(newState: CanvasState): DesignCanvas {
        val oldState = this.state
        this.state = newState
        this.updatedAt = Date()
        
        try {
            validateCanvasData()
        } catch (e: DesignCanvasValidationException) {
            // Restore old state if validation fails
            this.state = oldState
            throw e
        }
        
        return this
    }
    
    fun addLayer(layerId: String, zIndex: Int? = null): DesignCanvas {
        val mutableLayers = state.layers.toMutableList()
        
        if (layerId in mutableLayers) {
            // Layer already exists, don't add duplicate
            return this
        }
        
        if (zIndex != null && zIndex in 0..mutableLayers.size) {
            mutableLayers.add(zIndex, layerId)
        } else {
            mutableLayers.add(layerId)
        }
        
        this.state = state.copy(layers = mutableLayers)
        this.updatedAt = Date()
        return this
    }
    
    fun removeLayer(layerId: String): DesignCanvas {
        val mutableLayers = state.layers.toMutableList()
        val mutableSelected = state.selectedLayers.toMutableList()
        
        mutableLayers.remove(layerId)
        mutableSelected.remove(layerId)
        
        this.state = state.copy(
            layers = mutableLayers,
            selectedLayers = mutableSelected
        )
        this.updatedAt = Date()
        return this
    }
    
    fun selectLayer(layerId: String): DesignCanvas {
        if (layerId !in state.layers) {
            return this // Can't select layer that doesn't exist
        }
        
        val mutableSelected = state.selectedLayers.toMutableList()
        if (layerId !in mutableSelected) {
            mutableSelected.add(layerId)
            this.state = state.copy(selectedLayers = mutableSelected)
            this.updatedAt = Date()
        }
        
        return this
    }
    
    fun deselectLayer(layerId: String): DesignCanvas {
        val mutableSelected = state.selectedLayers.toMutableList()
        if (layerId in mutableSelected) {
            mutableSelected.remove(layerId)
            this.state = state.copy(selectedLayers = mutableSelected)
            this.updatedAt = Date()
        }
        
        return this
    }
    
    fun clearSelection(): DesignCanvas {
        if (state.selectedLayers.isNotEmpty()) {
            this.state = state.copy(selectedLayers = listOf())
            this.updatedAt = Date()
        }
        
        return this
    }
    
    fun updateZoom(zoom: Double): DesignCanvas {
        val clampedZoom = zoom.coerceIn(0.1, 5.0)
        if (clampedZoom != state.zoom) {
            this.state = state.copy(zoom = clampedZoom)
            this.updatedAt = Date()
        }
        
        return this
    }
    
    fun updatePan(x: Double, y: Double): DesignCanvas {
        if (x != state.panX || y != state.panY) {
            this.state = state.copy(panX = x, panY = y)
            this.updatedAt = Date()
        }
        
        return this
    }
    
    fun enableGrid(enabled: Boolean, size: Double = 10.0, snap: Boolean = false): DesignCanvas {
        val gridSize = size.coerceAtLeast(1.0)
        if (enabled != state.gridEnabled || gridSize != state.gridSize || snap != state.snapToGrid) {
            this.state = state.copy(
                gridEnabled = enabled,
                gridSize = gridSize,
                snapToGrid = snap
            )
            this.updatedAt = Date()
        }
        
        return this
    }
    
    // MARK: - Convenience Methods
    
    fun getLayerCount(): Int = state.layers.size
    
    fun getSelectedLayerCount(): Int = state.selectedLayers.size
    
    fun hasLayer(layerId: String): Boolean = layerId in state.layers
    
    fun isLayerSelected(layerId: String): Boolean = layerId in state.selectedLayers
    
    fun getAspectRatio(): Double = state.width / state.height
    
    fun getDeviceSpecification(): DeviceSpecifications.DeviceSpec? {
        return DeviceSpecifications.DEVICE_SPECS[state.deviceType]
    }
    
    // MARK: - JSON Serialization
    
    fun toJson(): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "name" to name,
            "description" to description,
            "state" to encodeCanvasState(),
            "metadata" to encodeCanvasMetadata(),
            "isActive" to isActive,
            "createdAt" to createdAt.time,
            "updatedAt" to updatedAt.time
        )
    }
    
    private fun encodeCanvasState(): Map<String, Any?> {
        return mapOf(
            "deviceType" to state.deviceType.value,
            "width" to state.width,
            "height" to state.height,
            "backgroundColor" to state.backgroundColor,
            "zoom" to state.zoom,
            "panX" to state.panX,
            "panY" to state.panY,
            "layers" to state.layers,
            "selectedLayers" to state.selectedLayers,
            "gridEnabled" to state.gridEnabled,
            "snapToGrid" to state.snapToGrid,
            "gridSize" to state.gridSize,
            "showRulers" to state.showRulers,
            "lockAspectRatio" to state.lockAspectRatio
        )
    }
    
    private fun encodeCanvasMetadata(): Map<String, Any?> {
        return mapOf(
            "source" to metadata.source,
            "createdAt" to metadata.createdAt.time,
            "modifiedAt" to metadata.modifiedAt?.time,
            "version" to metadata.version,
            "tags" to metadata.tags,
            "notes" to metadata.notes,
            "collaborators" to metadata.collaborators,
            "lastEditedBy" to metadata.lastEditedBy
        )
    }
}

// MARK: - Factory Methods
object DesignCanvasFactory {
    
    fun createDefault(
        id: String,
        name: String,
        deviceType: DeviceType = DeviceType.MOBILE,
        width: Double? = null,
        height: Double? = null
    ): DesignCanvas {
        val deviceSpec = DeviceSpecifications.DEVICE_SPECS[deviceType]
            ?: throw IllegalArgumentException("Unsupported device type: $deviceType")
        
        // Use provided dimensions or defaults for device type
        val canvasWidth = width ?: when (deviceType) {
            DeviceType.MOBILE -> 375.0
            DeviceType.TABLET -> 768.0
            DeviceType.DESKTOP -> 1920.0
            DeviceType.WATCH -> 44.0
            DeviceType.TV -> 1920.0
        }
        
        val canvasHeight = height ?: when (deviceType) {
            DeviceType.MOBILE -> 812.0
            DeviceType.TABLET -> 1024.0
            DeviceType.DESKTOP -> 1080.0
            DeviceType.WATCH -> 44.0
            DeviceType.TV -> 1080.0
        }
        
        val canvasState = CanvasState(
            deviceType = deviceType,
            width = canvasWidth,
            height = canvasHeight,
            backgroundColor = "#FFFFFF"
        )
        
        val canvasMetadata = CanvasMetadata(
            source = "user",
            createdAt = Date()
        )
        
        return DesignCanvas(
            id = id,
            name = name,
            state = canvasState,
            metadata = canvasMetadata
        )
    }
}

// MARK: - Validation Exceptions
class DesignCanvasValidationException(message: String) : Exception(message)
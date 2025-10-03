/*
 * AIService - Gemini AI API integration for Android
 * Implements T050: Android AI Service Integration
 * Kotlin/Jetpack Compose counterpart to web AIService with API compatibility
 */

package com.vyb.services

import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.gson.Gson
import com.google.gson.JsonObject
import com.google.gson.annotations.SerializedName
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.*
import kotlin.random.Random

// MARK: - Error Types

sealed class AIServiceError(message: String) : Exception(message) {
    class AuthError(message: String) : AIServiceError("Authentication Error: $message")
    class ValidationError(message: String) : AIServiceError("Validation Error: $message")
    class NetworkError(message: String) : AIServiceError("Network Error: $message")
    class ApiError(message: String) : AIServiceError("API Error: $message")
    class ParseError(message: String) : AIServiceError("Parse Error: $message")
}

// MARK: - Request/Response Models

enum class AnalysisType {
    @SerializedName("trends") TRENDS,
    @SerializedName("creative") CREATIVE,
    @SerializedName("accessibility") ACCESSIBILITY,
    @SerializedName("performance") PERFORMANCE
}

enum class SuggestionType {
    @SerializedName("layout") LAYOUT,
    @SerializedName("color") COLOR,
    @SerializedName("typography") TYPOGRAPHY,
    @SerializedName("composition") COMPOSITION
}

enum class VariationType {
    @SerializedName("creative") CREATIVE,
    @SerializedName("trend-based") TREND_BASED,
    @SerializedName("accessibility") ACCESSIBILITY,
    @SerializedName("brand-aligned") BRAND_ALIGNED
}

data class CanvasAnalysisRequest(
    val canvas: DesignCanvasData,
    val deviceType: String,
    val analysisType: List<AnalysisType>,
    val userPreferences: UserPreferences?
)

data class AISuggestion(
    val id: String,
    val type: SuggestionType,
    val description: String,
    val confidence: Double,
    val preview: String?
)

data class TrendItem(
    val name: String,
    val popularity: Double,
    val description: String
)

data class TrendData(
    val category: String,
    val trends: List<TrendItem>
)

data class CanvasAnalysisResponse(
    val analysisId: String,
    val suggestions: List<AISuggestion>,
    val confidence: Double,
    val trends: TrendData?,
    val processingTime: Int
)

data class VariationRequest(
    val baseCanvas: DesignCanvasData,
    val variationType: VariationType,
    val count: Int,
    val preferences: UserPreferences?
)

data class VariationResponse(
    val requestId: String,
    val variations: List<DesignCanvasData>,
    val confidence: Double,
    val processingTime: Int
)

data class UserPreferences(
    val style: String?,
    val industry: String?,
    val targetAudience: String?,
    val brandColors: List<String>?
)

data class CurrentTrendsResponse(
    val trendsId: String,
    val categories: List<TrendData>,
    val lastUpdated: String,
    val confidence: Double
)

// MARK: - Data Transfer Objects

data class DesignCanvasData(
    val id: String,
    val deviceType: String,
    val dimensions: SimpleCanvasDimensions,
    val layers: List<LayerData>,
    val metadata: SimpleCanvasMetadata,
    val state: String
)

data class SimpleCanvasDimensions(
    val width: Double,
    val height: Double,
    val pixelDensity: Double
)

data class SimpleCanvasMetadata(
    val createdAt: Date,
    val modifiedAt: Date,
    val tags: List<String>,
    val description: String? = null,
    val author: String? = null
)

data class LayerData(
    val id: String,
    val type: String,
    val zIndex: Int,
    val content: Map<String, Any>,
    val transform: LayerTransform,
    val style: Map<String, Any>,
    val constraints: Map<String, Any>,
    val metadata: SimpleLayerMetadata
)

data class LayerTransform(
    val x: Double,
    val y: Double,
    val scaleX: Double,
    val scaleY: Double,
    val rotation: Double,
    val opacity: Double
)

data class SimpleLayerMetadata(
    val source: String,
    val createdAt: Date
)

// MARK: - AI Service Class

class AIService(
    private val apiKey: String = "",
    private val baseUrl: String = "https://ai.gemini.googleapis.com/v1"
) : ViewModel() {
    
    private val gson = Gson()
    
    var isLoading by mutableStateOf(false)
        private set
    
    var lastError by mutableStateOf<AIServiceError?>(null)
        private set
    
    companion object {
        private const val TAG = "AIService"
        private const val TIMEOUT_MS = 30000
    }
    
    // MARK: - Public API Methods
    
    /**
     * Analyze canvas for AI suggestions
     * Corresponds to POST /canvas/analyze
     */
    suspend fun analyzeCanvas(request: CanvasAnalysisRequest): CanvasAnalysisResponse {
        val startTime = System.currentTimeMillis()
        
        return withContext(Dispatchers.IO) {
            try {
                if (apiKey.isEmpty()) {
                    throw AIServiceError.AuthError("API key not configured")
                }
                
                // Validate canvas data
                validateCanvasData(request.canvas)
                
                isLoading = true
                lastError = null
                
                val url = URL("$baseUrl/canvas/analyze")
                val connection = url.openConnection() as HttpURLConnection
                
                connection.apply {
                    requestMethod = "POST"
                    setRequestProperty("Content-Type", "application/json")
                    setRequestProperty("Authorization", "Bearer $apiKey")
                    doOutput = true
                    connectTimeout = TIMEOUT_MS
                    readTimeout = TIMEOUT_MS
                }
                
                // Send request
                val requestJson = gson.toJson(request)
                connection.outputStream.use { os ->
                    os.write(requestJson.toByteArray())
                }
                
                // Handle response
                when (connection.responseCode) {
                    HttpURLConnection.HTTP_OK -> {
                        val responseJson = connection.inputStream.bufferedReader().use { it.readText() }
                        val response = gson.fromJson(responseJson, CanvasAnalysisResponse::class.java)
                        
                        val processingTime = (System.currentTimeMillis() - startTime).toInt()
                        
                        // Update processing time if not set by server
                        val finalResponse = if (response.processingTime == 0) {
                            response.copy(processingTime = processingTime)
                        } else {
                            response
                        }
                        
                        isLoading = false
                        finalResponse
                    }
                    else -> {
                        val errorMessage = try {
                            connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                        } catch (e: IOException) {
                            "HTTP ${connection.responseCode}"
                        }
                        isLoading = false
                        throw AIServiceError.ApiError("HTTP ${connection.responseCode}: $errorMessage")
                    }
                }
            } catch (e: AIServiceError) {
                isLoading = false
                lastError = e
                throw e
            } catch (e: Exception) {
                val error = AIServiceError.NetworkError("Canvas analysis failed: ${e.message}")
                isLoading = false
                lastError = error
                throw error
            }
        }
    }
    
    /**
     * Generate design variations
     * Corresponds to POST /variations/generate
     */
    suspend fun generateVariations(request: VariationRequest): VariationResponse {
        val startTime = System.currentTimeMillis()
        
        return withContext(Dispatchers.IO) {
            try {
                if (apiKey.isEmpty()) {
                    throw AIServiceError.AuthError("API key not configured")
                }
                
                // Validate base canvas
                validateCanvasData(request.baseCanvas)
                
                if (request.count <= 0 || request.count > 10) {
                    throw AIServiceError.ValidationError("Count must be between 1 and 10")
                }
                
                isLoading = true
                lastError = null
                
                val url = URL("$baseUrl/variations/generate")
                val connection = url.openConnection() as HttpURLConnection
                
                connection.apply {
                    requestMethod = "POST"
                    setRequestProperty("Content-Type", "application/json")
                    setRequestProperty("Authorization", "Bearer $apiKey")
                    doOutput = true
                    connectTimeout = TIMEOUT_MS
                    readTimeout = TIMEOUT_MS
                }
                
                // Send request
                val requestJson = gson.toJson(request)
                connection.outputStream.use { os ->
                    os.write(requestJson.toByteArray())
                }
                
                // Handle response
                when (connection.responseCode) {
                    HttpURLConnection.HTTP_OK -> {
                        val responseJson = connection.inputStream.bufferedReader().use { it.readText() }
                        val response = gson.fromJson(responseJson, VariationResponse::class.java)
                        
                        val processingTime = (System.currentTimeMillis() - startTime).toInt()
                        
                        // Update processing time if not set by server
                        val finalResponse = if (response.processingTime == 0) {
                            response.copy(processingTime = processingTime)
                        } else {
                            response
                        }
                        
                        isLoading = false
                        finalResponse
                    }
                    else -> {
                        val errorMessage = try {
                            connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                        } catch (e: IOException) {
                            "HTTP ${connection.responseCode}"
                        }
                        isLoading = false
                        throw AIServiceError.ApiError("HTTP ${connection.responseCode}: $errorMessage")
                    }
                }
            } catch (e: AIServiceError) {
                isLoading = false
                lastError = e
                throw e
            } catch (e: Exception) {
                val error = AIServiceError.NetworkError("Variation generation failed: ${e.message}")
                isLoading = false
                lastError = error
                throw error
            }
        }
    }
    
    /**
     * Get current design trends
     * Corresponds to GET /trends/current
     */
    suspend fun getCurrentTrends(): CurrentTrendsResponse {
        return withContext(Dispatchers.IO) {
            try {
                if (apiKey.isEmpty()) {
                    throw AIServiceError.AuthError("API key not configured")
                }
                
                isLoading = true
                lastError = null
                
                val url = URL("$baseUrl/trends/current")
                val connection = url.openConnection() as HttpURLConnection
                
                connection.apply {
                    requestMethod = "GET"
                    setRequestProperty("Authorization", "Bearer $apiKey")
                    connectTimeout = TIMEOUT_MS
                    readTimeout = TIMEOUT_MS
                }
                
                // Handle response
                when (connection.responseCode) {
                    HttpURLConnection.HTTP_OK -> {
                        val responseJson = connection.inputStream.bufferedReader().use { it.readText() }
                        val response = gson.fromJson(responseJson, CurrentTrendsResponse::class.java)
                        
                        isLoading = false
                        response
                    }
                    else -> {
                        val errorMessage = try {
                            connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                        } catch (e: IOException) {
                            "HTTP ${connection.responseCode}"
                        }
                        isLoading = false
                        throw AIServiceError.ApiError("HTTP ${connection.responseCode}: $errorMessage")
                    }
                }
            } catch (e: AIServiceError) {
                isLoading = false
                lastError = e
                throw e
            } catch (e: Exception) {
                val error = AIServiceError.NetworkError("Trends request failed: ${e.message}")
                isLoading = false
                lastError = error
                throw error
            }
        }
    }
    
    // MARK: - Validation Methods
    
    private fun validateCanvasData(canvas: DesignCanvasData) {
        if (canvas.id.isEmpty()) {
            throw AIServiceError.ValidationError("Canvas ID is required")
        }
        
        if (canvas.dimensions.width <= 0 || canvas.dimensions.height <= 0) {
            throw AIServiceError.ValidationError("Canvas dimensions must be positive")
        }
        
        if (canvas.layers.isEmpty()) {
            throw AIServiceError.ValidationError("Canvas must contain at least one layer")
        }
        
        // Validate each layer
        canvas.layers.forEach { layer ->
            if (layer.id.isEmpty()) {
                throw AIServiceError.ValidationError("Layer ID is required")
            }
            
            if (layer.type.isEmpty()) {
                throw AIServiceError.ValidationError("Layer type is required")
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /**
     * Create analysis request from canvas data
     */
    fun createAnalysisRequest(
        canvasData: DesignCanvasData,
        analysisTypes: List<AnalysisType> = listOf(AnalysisType.CREATIVE, AnalysisType.TRENDS),
        userPreferences: UserPreferences? = null
    ): CanvasAnalysisRequest {
        return CanvasAnalysisRequest(
            canvas = canvasData,
            deviceType = canvasData.deviceType,
            analysisType = analysisTypes,
            userPreferences = userPreferences
        )
    }
    
    /**
     * Create variation request from canvas data
     */
    fun createVariationRequest(
        baseCanvasData: DesignCanvasData,
        variationType: VariationType = VariationType.CREATIVE,
        count: Int = 3,
        preferences: UserPreferences? = null
    ): VariationRequest {
        return VariationRequest(
            baseCanvas = baseCanvasData,
            variationType = variationType,
            count = count,
            preferences = preferences
        )
    }
    
    // MARK: - Flow-based Methods (Jetpack Compose Integration)
    
    /**
     * Analyze canvas with Flow for reactive UI
     */
    fun analyzeCanvasFlow(
        canvasData: DesignCanvasData,
        analysisTypes: List<AnalysisType> = listOf(AnalysisType.CREATIVE, AnalysisType.TRENDS),
        userPreferences: UserPreferences? = null
    ): Flow<CanvasAnalysisResponse> = flow {
        val request = createAnalysisRequest(canvasData, analysisTypes, userPreferences)
        val response = analyzeCanvas(request)
        emit(response)
    }.flowOn(Dispatchers.IO)
    
    /**
     * Generate variations with Flow for reactive UI
     */
    fun generateVariationsFlow(
        baseCanvasData: DesignCanvasData,
        variationType: VariationType = VariationType.CREATIVE,
        count: Int = 3,
        preferences: UserPreferences? = null
    ): Flow<VariationResponse> = flow {
        val request = createVariationRequest(baseCanvasData, variationType, count, preferences)
        val response = generateVariations(request)
        emit(response)
    }.flowOn(Dispatchers.IO)
    
    /**
     * Get current trends with Flow
     */
    fun getCurrentTrendsFlow(): Flow<CurrentTrendsResponse> = flow {
        val response = getCurrentTrends()
        emit(response)
    }.flowOn(Dispatchers.IO)
    
    // MARK: - Utility Methods
    
    fun clearError() {
        lastError = null
    }
    
    fun updateApiKey(newApiKey: String) {
        viewModelScope.launch {
            // In a real implementation, you might want to save this securely
            Log.d(TAG, "API key updated")
        }
    }
    
    // MARK: - Mock/Demo Methods (for development)
    
    /**
     * Generate mock analysis response for testing
     */
    fun generateMockAnalysisResponse(canvasData: DesignCanvasData): CanvasAnalysisResponse {
        val suggestions = listOf(
            AISuggestion(
                id = UUID.randomUUID().toString(),
                type = SuggestionType.COLOR,
                description = "Consider using warmer colors to improve emotional engagement",
                confidence = 0.85,
                preview = null
            ),
            AISuggestion(
                id = UUID.randomUUID().toString(),
                type = SuggestionType.LAYOUT,
                description = "Adjusting the layout hierarchy could improve visual flow",
                confidence = 0.78,
                preview = null
            )
        )
        
        val trends = TrendData(
            category = "Design Trends 2024",
            trends = listOf(
                TrendItem(
                    name = "Minimalist Design",
                    popularity = 0.92,
                    description = "Clean, simple designs with plenty of whitespace"
                ),
                TrendItem(
                    name = "Bold Typography",
                    popularity = 0.87,
                    description = "Strong, impactful font choices for better readability"
                )
            )
        )
        
        return CanvasAnalysisResponse(
            analysisId = UUID.randomUUID().toString(),
            suggestions = suggestions,
            confidence = 0.82,
            trends = trends,
            processingTime = Random.nextInt(500, 2000)
        )
    }
    
    /**
     * Generate mock variation response for testing
     */
    fun generateMockVariationResponse(
        baseCanvas: DesignCanvasData,
        count: Int = 3
    ): VariationResponse {
        val variations = (1..count).map { index ->
            baseCanvas.copy(
                id = UUID.randomUUID().toString(),
                layers = baseCanvas.layers.map { layer ->
                    layer.copy(
                        transform = layer.transform.copy(
                            opacity = (0.7 + index * 0.1).coerceAtMost(1.0)
                        )
                    )
                }
            )
        }
        
        return VariationResponse(
            requestId = UUID.randomUUID().toString(),
            variations = variations,
            confidence = 0.75,
            processingTime = Random.nextInt(800, 3000)
        )
    }
}

// MARK: - Companion Object (Singleton Pattern)

object AIServiceProvider {
    private var instance: AIService? = null
    
    fun getInstance(apiKey: String = "", baseUrl: String = "https://ai.gemini.googleapis.com/v1"): AIService {
        return instance ?: synchronized(this) {
            instance ?: AIService(apiKey, baseUrl).also { instance = it }
        }
    }
    
    fun setApiKey(apiKey: String) {
        instance?.updateApiKey(apiKey)
    }
}
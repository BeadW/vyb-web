package com.vyb.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.rememberTransformableState
import androidx.compose.foundation.gestures.transformable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PhoneAndroid
import androidx.compose.material.icons.filled.ScreenRotation
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Device Types for simulation
 */
enum class DeviceType {
    MOBILE, TABLET, DESKTOP, WATCH, TV
}

/**
 * Device specifications for accurate simulation
 */
data class DeviceSpec(
    val minWidth: Float,
    val minHeight: Float,
    val pixelRatio: Float = 1.0f,
    val aspectRatios: List<AspectRatio>
)

data class AspectRatio(
    val name: String,
    val ratio: Float,
    val width: Float,
    val height: Float
)

/**
 * Comprehensive device specifications database
 */
object DeviceSpecifications {
    val DEVICE_SPECS = mapOf(
        DeviceType.MOBILE to DeviceSpec(
            minWidth = 375f,
            minHeight = 812f,
            pixelRatio = 3.0f,
            aspectRatios = listOf(
                AspectRatio("Samsung Galaxy S23", 20f/9f, 360f, 800f),
                AspectRatio("Pixel 7", 19.5f/9f, 393f, 851f),
                AspectRatio("OnePlus 11", 20f/9f, 412f, 915f),
                AspectRatio("Xiaomi 13", 19.5f/9f, 384f, 832f)
            )
        ),
        DeviceType.TABLET to DeviceSpec(
            minWidth = 768f,
            minHeight = 1024f,
            pixelRatio = 2.0f,
            aspectRatios = listOf(
                AspectRatio("Galaxy Tab S8", 16f/10f, 800f, 1280f),
                AspectRatio("Pixel Tablet", 16f/10f, 840f, 1344f),
                AspectRatio("OnePlus Pad", 7f/5f, 900f, 1280f)
            )
        ),
        DeviceType.DESKTOP to DeviceSpec(
            minWidth = 1280f,
            minHeight = 720f,
            pixelRatio = 1.0f,
            aspectRatios = listOf(
                AspectRatio("1080p HD", 16f/9f, 1920f, 1080f),
                AspectRatio("1440p QHD", 16f/9f, 2560f, 1440f),
                AspectRatio("4K UHD", 16f/9f, 3840f, 2160f)
            )
        ),
        DeviceType.WATCH to DeviceSpec(
            minWidth = 184f,
            minHeight = 224f,
            pixelRatio = 2.0f,
            aspectRatios = listOf(
                AspectRatio("Galaxy Watch", 1.0f, 360f, 360f),
                AspectRatio("Wear OS", 1.0f, 320f, 320f)
            )
        ),
        DeviceType.TV to DeviceSpec(
            minWidth = 1920f,
            minHeight = 1080f,
            pixelRatio = 1.0f,
            aspectRatios = listOf(
                AspectRatio("Android TV", 16f/9f, 1920f, 1080f),
                AspectRatio("Google TV 4K", 16f/9f, 3840f, 2160f)
            )
        )
    )
}

/**
 * Device Simulation Composable for Android
 * Provides pixel-perfect device simulation with accurate dimensions and visual fidelity
 * Supports orientation changes, scaling, and device-specific features using Jetpack Compose
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DeviceSimulationScreen(
    deviceType: DeviceType = DeviceType.MOBILE,
    modifier: Modifier = Modifier
) {
    var currentScale by remember { mutableStateOf(1.0f) }
    var isLandscape by remember { mutableStateOf(false) }
    var selectedDeviceType by remember { mutableStateOf(deviceType) }
    
    val deviceSpec = DeviceSpecifications.DEVICE_SPECS[selectedDeviceType] 
        ?: DeviceSpecifications.DEVICE_SPECS[DeviceType.MOBILE]!!
    
    val displayDimensions by remember(selectedDeviceType, isLandscape) {
        derivedStateOf {
            val baseWidth = deviceSpec.minWidth
            val baseHeight = deviceSpec.minHeight
            
            if (isLandscape) {
                Size(baseHeight, baseWidth)
            } else {
                Size(baseWidth, baseHeight)
            }
        }
    }
    
    val animatedScale by animateFloatAsState(
        targetValue = currentScale,
        label = "scale_animation"
    )
    
    Column(
        modifier = modifier.fillMaxSize()
    ) {
        // Device Controls
        DeviceControlsSection(
            deviceSpec = deviceSpec,
            displayDimensions = displayDimensions,
            currentScale = currentScale,
            isLandscape = isLandscape,
            onScaleChanged = { currentScale = it },
            onOrientationToggle = { isLandscape = !isLandscape }
        )
        
        // Device Simulation Area
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.surfaceVariant)
                .padding(24.dp),
            contentAlignment = Alignment.Center
        ) {
            DeviceFrame(
                deviceType = selectedDeviceType,
                displayDimensions = displayDimensions,
                scale = animatedScale,
                modifier = Modifier.shadow(8.dp, RoundedCornerShape(24.dp))
            )
        }
    }
}

@Composable
private fun DeviceControlsSection(
    deviceSpec: DeviceSpec,
    displayDimensions: Size,
    currentScale: Float,
    isLandscape: Boolean,
    onScaleChanged: (Float) -> Unit,
    onOrientationToggle: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface,
        shadowElevation = 4.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            // Device Info
            Column {
                Text(
                    text = deviceSpec.aspectRatios.firstOrNull()?.name ?: "Custom",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = "${displayDimensions.width.toInt()}×${displayDimensions.height.toInt()} • ${if (isLandscape) "Landscape" else "Portrait"}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            // Controls
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Scale Control
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Scale:",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Slider(
                        value = currentScale,
                        onValueChange = onScaleChanged,
                        valueRange = 0.25f..2.0f,
                        steps = 6, // 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0
                        modifier = Modifier.width(120.dp)
                    )
                    
                    Text(
                        text = "${(currentScale * 100).toInt()}%",
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.width(40.dp)
                    )
                }
                
                // Orientation Toggle
                IconButton(
                    onClick = onOrientationToggle,
                    modifier = Modifier
                        .border(
                            1.dp,
                            MaterialTheme.colorScheme.outline,
                            RoundedCornerShape(8.dp)
                        )
                        .size(48.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.ScreenRotation,
                        contentDescription = "Toggle device orientation",
                        tint = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
        }
    }
}

@Composable
private fun DeviceFrame(
    deviceType: DeviceType,
    displayDimensions: Size,
    scale: Float,
    modifier: Modifier = Modifier
) {
    val density = LocalDensity.current
    
    Box(
        modifier = modifier
            .scale(scale)
            .size(
                width = with(density) { displayDimensions.width.toDp() },
                height = with(density) { displayDimensions.height.toDp() }
            )
            .clip(RoundedCornerShape(24.dp))
            .background(Color.Black),
        contentAlignment = Alignment.Center
    ) {
        // Screen Content Area
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(getScreenPadding(deviceType))
                .clip(RoundedCornerShape(getScreenCornerRadius(deviceType)))
                .background(Color.White),
            contentAlignment = Alignment.Center
        ) {
            // Placeholder Content
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Icon(
                    imageVector = Icons.Default.PhoneAndroid,
                    contentDescription = null,
                    modifier = Modifier.size(64.dp),
                    tint = Color.Gray.copy(alpha = 0.3f)
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = "Canvas content will appear here",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.Gray
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "Device: ${deviceType.name}",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray.copy(alpha = 0.7f)
                )
            }
        }
        
        // Device Chrome (overlays)
        DeviceChrome(deviceType = deviceType, displayDimensions = displayDimensions)
    }
}

@Composable
private fun DeviceChrome(
    deviceType: DeviceType,
    displayDimensions: Size,
    modifier: Modifier = Modifier
) {
    Canvas(modifier = modifier.fillMaxSize()) {
        when (deviceType) {
            DeviceType.MOBILE -> drawMobileChrome(size, displayDimensions)
            DeviceType.TABLET -> drawTabletChrome(size, displayDimensions)
            DeviceType.WATCH -> drawWatchChrome(size, displayDimensions)
            else -> {} // No chrome for desktop/TV
        }
    }
}

private fun DrawScope.drawMobileChrome(canvasSize: Size, displayDimensions: Size) {
    // Dynamic Island / Notch
    drawRoundRect(
        color = Color.Black,
        topLeft = Offset(
            x = canvasSize.width / 2 - 60f,
            y = 0f
        ),
        size = Size(120f, 24f),
        cornerRadius = CornerRadius(12f)
    )
    
    // Home Indicator
    drawRoundRect(
        color = Color.Gray,
        topLeft = Offset(
            x = canvasSize.width / 2 - 40f,
            y = canvasSize.height - 8f
        ),
        size = Size(80f, 4f),
        cornerRadius = CornerRadius(2f)
    )
    
    // Volume buttons (left side)
    drawRoundRect(
        color = Color.Gray.copy(alpha = 0.8f),
        topLeft = Offset(x = 0f, y = 80f),
        size = Size(4f, 48f),
        cornerRadius = CornerRadius(2f)
    )
    
    // Power button (right side)
    drawRoundRect(
        color = Color.Gray.copy(alpha = 0.8f),
        topLeft = Offset(x = canvasSize.width - 4f, y = 100f),
        size = Size(4f, 64f),
        cornerRadius = CornerRadius(2f)
    )
}

private fun DrawScope.drawTabletChrome(canvasSize: Size, displayDimensions: Size) {
    // Home indicator for modern tablets
    drawRoundRect(
        color = Color.Gray,
        topLeft = Offset(
            x = canvasSize.width / 2 - 48f,
            y = canvasSize.height - 8f
        ),
        size = Size(96f, 4f),
        cornerRadius = CornerRadius(2f)
    )
    
    // Front camera
    drawCircle(
        color = Color.Gray.copy(alpha = 0.6f),
        radius = 6f,
        center = Offset(x = canvasSize.width / 2, y = 16f)
    )
}

private fun DrawScope.drawWatchChrome(canvasSize: Size, displayDimensions: Size) {
    // Digital Crown
    drawRoundRect(
        color = Color.Gray.copy(alpha = 0.8f),
        topLeft = Offset(x = canvasSize.width - 6f, y = canvasSize.height * 0.3f),
        size = Size(6f, 16f),
        cornerRadius = CornerRadius(3f)
    )
    
    // Side button
    drawRoundRect(
        color = Color.Gray.copy(alpha = 0.8f),
        topLeft = Offset(x = canvasSize.width - 4f, y = canvasSize.height / 2 - 6f),
        size = Size(4f, 12f),
        cornerRadius = CornerRadius(2f)
    )
}

// Helper functions for device-specific styling
private fun getScreenPadding(deviceType: DeviceType): PaddingValues {
    return when (deviceType) {
        DeviceType.MOBILE -> PaddingValues(horizontal = 4.dp, vertical = 12.dp)
        DeviceType.TABLET -> PaddingValues(8.dp)
        DeviceType.DESKTOP -> PaddingValues(24.dp)
        DeviceType.WATCH -> PaddingValues(8.dp)
        DeviceType.TV -> PaddingValues(32.dp)
    }
}

private fun getScreenCornerRadius(deviceType: DeviceType): Dp {
    return when (deviceType) {
        DeviceType.MOBILE -> 20.dp
        DeviceType.TABLET -> 12.dp
        DeviceType.DESKTOP -> 4.dp
        DeviceType.WATCH -> 16.dp // Nearly circular
        DeviceType.TV -> 2.dp
    }
}

@Preview(showBackground = true)
@Composable
fun DeviceSimulationScreenPreview() {
    MaterialTheme {
        DeviceSimulationScreen(deviceType = DeviceType.MOBILE)
    }
}
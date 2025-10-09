package com.vyb

import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.*
import androidx.test.espresso.assertion.ViewAssertions.*
import androidx.test.espresso.matcher.ViewMatchers.*
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.platform.app.InstrumentationRegistry
import org.hamcrest.Matchers.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.test.assertTrue

@RunWith(AndroidJUnit4::class)
@LargeTest
class CanvasManipulationTest {

    @get:Rule
    val activityRule = ActivityScenarioRule(MainActivity::class.java)

    @Before
    fun setUp() {
        // Initialize test environment
        Thread.sleep(1000) // Wait for activity to fully load
    }

    @Test
    fun testCanvasCreationWithDeviceSelection() {
        // Navigate to canvas creation
        onView(withId(R.id.btn_create_design))
            .check(matches(isDisplayed()))
            .perform(click())

        // Select Pixel 8 Pro device simulation
        onView(withId(R.id.btn_device_selector))
            .check(matches(isDisplayed()))
            .perform(click())

        onView(withText("Pixel 8 Pro"))
            .check(matches(isDisplayed()))
            .perform(click())

        // Verify canvas appears with correct dimensions
        onView(withId(R.id.canvas_view))
            .check(matches(isDisplayed()))

        // Verify canvas dimensions match Pixel 8 Pro specs (448x998 dp)
        activityRule.scenario.onActivity { activity ->
            val canvasView = activity.findViewById<android.view.View>(R.id.canvas_view)
            val width = canvasView.width
            val height = canvasView.height
            
            // Allow for some tolerance due to scaling
            assertTrue("Canvas width should be approximately 448dp") {
                kotlin.math.abs(width - 448) <= 10
            }
            assertTrue("Canvas height should be approximately 998dp") {
                kotlin.math.abs(height - 998) <= 10
            }
        }
    }

    @Test
    fun testTextLayerCreationAndManipulation() {
        setupCanvasWithDevice("Pixel 8 Pro")

        // Add text layer
        onView(withId(R.id.btn_add_text))
            .check(matches(isDisplayed()))
            .perform(click())

        // Enter text
        onView(withId(R.id.et_text_input))
            .check(matches(isDisplayed()))
            .perform(typeText("Test Canvas Text"), closeSoftKeyboard())

        onView(withId(R.id.btn_confirm_text))
            .perform(click())

        // Verify text layer appears
        onView(allOf(withId(R.id.text_layer), withText("Test Canvas Text")))
            .check(matches(isDisplayed()))

        // Test text layer manipulation - long press and drag
        onView(withText("Test Canvas Text"))
            .perform(longClick())
            .check(matches(hasDescendant(withId(R.id.selection_indicator))))

        // Perform drag operation
        onView(withText("Test Canvas Text"))
            .perform(
                TestViewActions.dragTo(
                    GeneralLocation.CENTER_RIGHT,
                    GeneralLocation.BOTTOM_RIGHT
                )
            )

        // Verify text moved (position changed)
        activityRule.scenario.onActivity { activity ->
            val textView = activity.findViewById<android.widget.TextView>(R.id.text_layer)
            assertTrue("Text should have moved from original position") {
                textView.x > 100 && textView.y > 100
            }
        }
    }

    @Test
    fun testImageLayerAdditionAndManipulation() {
        setupCanvasWithDevice("Pixel 8 Pro")

        // Add image layer
        onView(withId(R.id.btn_add_image))
            .check(matches(isDisplayed()))
            .perform(click())

        // Select image from gallery (mock)
        onView(withId(R.id.btn_gallery))
            .perform(click())

        // In a real test, you would mock the gallery intent
        // For now, we'll simulate selecting a test image
        onView(withId(R.id.btn_test_image))
            .perform(click())

        onView(withId(R.id.btn_select_image))
            .perform(click())

        // Verify image layer appears
        onView(withId(R.id.image_layer))
            .check(matches(isDisplayed()))

        // Test image scaling with pinch gesture
        onView(withId(R.id.image_layer))
            .perform(TestViewActions.pinchOut())

        // Verify image scaled
        activityRule.scenario.onActivity { activity ->
            val imageView = activity.findViewById<android.widget.ImageView>(R.id.image_layer)
            val scaleX = imageView.scaleX
            val scaleY = imageView.scaleY
            assertTrue("Image should be scaled up") {
                scaleX > 1.0f && scaleY > 1.0f
            }
        }
    }

    @Test
    fun testMultiLayerCanvasInteraction() {
        setupCanvasWithDevice("Pixel 8 Pro")

        // Add multiple layers
        addTextLayer("Layer 1")
        addTextLayer("Layer 2")
        addShapeLayer("Rectangle")

        // Verify all layers exist
        onView(withText("Layer 1")).check(matches(isDisplayed()))
        onView(withText("Layer 2")).check(matches(isDisplayed()))
        onView(withId(R.id.rectangle_shape)).check(matches(isDisplayed()))

        // Test layer selection
        onView(withText("Layer 1")).perform(click())

        // Verify selection indicator
        onView(withId(R.id.selection_indicator))
            .check(matches(isDisplayed()))

        // Test layer reordering via layer panel
        onView(withId(R.id.btn_layer_panel)).perform(click())

        // Drag layer to reorder (using custom drag action)
        onView(withText("Layer 1"))
            .perform(TestViewActions.dragToTarget(withText("Layer 2")))

        // Verify layer order changed
        onView(withId(R.id.layer_panel))
            .check(matches(TestMatchers.hasChildAtPosition(0, withText("Layer 2"))))
            .check(matches(TestMatchers.hasChildAtPosition(1, withText("Layer 1"))))
    }

    @Test
    fun testCanvasPerformanceDuringInteraction() {
        setupCanvasWithDevice("Pixel 8 Pro")

        // Add multiple layers for performance testing
        for (i in 1..10) {
            addTextLayer("Performance Test $i")
        }

        // Verify all layers added successfully
        for (i in 1..10) {
            onView(withText("Performance Test $i"))
                .check(matches(isDisplayed()))
        }

        // Test rapid tap interactions
        val startTime = System.currentTimeMillis()

        for (i in 1..10) {
            onView(withText("Performance Test $i"))
                .perform(click())
            Thread.sleep(50) // 50ms between taps
        }

        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime

        // Verify interactions completed within reasonable time (< 2 seconds)
        assertTrue("Canvas interactions should be responsive") {
            totalTime < 2000
        }
    }

    @Test
    fun testCanvasZoomAndPanGestures() {
        setupCanvasWithDevice("Pixel 8 Pro")
        addTextLayer("Zoom Test")

        // Test zoom in with pinch gesture
        onView(withId(R.id.canvas_view))
            .perform(TestViewActions.pinchOut())

        // Verify zoom level increased
        activityRule.scenario.onActivity { activity ->
            val canvasView = activity.findViewById<android.view.View>(R.id.canvas_view)
            val scaleX = canvasView.scaleX
            assertTrue("Canvas should be zoomed in") { scaleX > 1.0f }
        }

        // Test pan gesture
        onView(withId(R.id.canvas_view))
            .perform(
                TestViewActions.dragTo(
                    GeneralLocation.CENTER,
                    GeneralLocation.TOP_LEFT
                )
            )

        // Verify pan occurred
        activityRule.scenario.onActivity { activity ->
            val canvasView = activity.findViewById<android.view.View>(R.id.canvas_view)
            assertTrue("Canvas should be panned") {
                canvasView.translationX != 0f || canvasView.translationY != 0f
            }
        }
    }

    @Test
    fun testCanvasBoundaryConstraints() {
        setupCanvasWithDevice("Pixel 8 Pro")
        addTextLayer("Boundary Test")

        val textView = onView(withText("Boundary Test"))

        // Try to drag text outside canvas bounds
        textView.perform(
            TestViewActions.dragTo(
                GeneralLocation.CENTER,
                GeneralLocation.BOTTOM_RIGHT,
                overShoot = true // Try to go beyond bounds
            )
        )

        // Verify text stays within canvas bounds
        activityRule.scenario.onActivity { activity ->
            val textLayer = activity.findViewById<android.widget.TextView>(R.id.text_layer)
            val canvasView = activity.findViewById<android.view.View>(R.id.canvas_view)
            
            val textBounds = android.graphics.Rect()
            textLayer.getGlobalVisibleRect(textBounds)
            
            val canvasBounds = android.graphics.Rect()
            canvasView.getGlobalVisibleRect(canvasBounds)
            
            assertTrue("Text should stay within canvas bounds") {
                canvasBounds.contains(textBounds)
            }
        }
    }

    @Test
    fun testUndoRedoFunctionality() {
        setupCanvasWithDevice("Pixel 8 Pro")

        // Perform action
        addTextLayer("Undo Test")
        onView(withText("Undo Test")).check(matches(isDisplayed()))

        // Undo action
        onView(withId(R.id.btn_undo))
            .check(matches(isDisplayed()))
            .perform(click())

        // Verify text layer removed
        onView(withText("Undo Test"))
            .check(doesNotExist())

        // Redo action
        onView(withId(R.id.btn_redo))
            .check(matches(isDisplayed()))
            .perform(click())

        // Verify text layer restored
        onView(withText("Undo Test"))
            .check(matches(isDisplayed()))
    }

    @Test
    fun testLayerTransformations() {
        setupCanvasWithDevice("Pixel 8 Pro")
        addTextLayer("Transform Test")

        val textView = onView(withText("Transform Test"))

        // Test rotation
        textView.perform(longClick())
        onView(withId(R.id.btn_rotate))
            .perform(click())
        
        onView(withId(R.id.rotation_slider))
            .perform(TestViewActions.setSliderValue(45.0f))

        // Verify rotation applied
        activityRule.scenario.onActivity { activity ->
            val textLayer = activity.findViewById<android.widget.TextView>(R.id.text_layer)
            assertTrue("Text should be rotated") {
                kotlin.math.abs(textLayer.rotation - 45.0f) < 1.0f
            }
        }

        // Test scaling
        onView(withId(R.id.btn_scale))
            .perform(click())
            
        onView(withId(R.id.scale_slider))
            .perform(TestViewActions.setSliderValue(1.5f))

        // Verify scaling applied
        activityRule.scenario.onActivity { activity ->
            val textLayer = activity.findViewById<android.widget.TextView>(R.id.text_layer)
            assertTrue("Text should be scaled") {
                textLayer.scaleX > 1.4f && textLayer.scaleY > 1.4f
            }
        }
    }

    @Test
    fun testLayerGrouping() {
        setupCanvasWithDevice("Pixel 8 Pro")
        
        // Add multiple layers
        addTextLayer("Group Test 1")
        addTextLayer("Group Test 2")
        addShapeLayer("Circle")

        // Select multiple layers
        onView(withText("Group Test 1")).perform(click())
        onView(withText("Group Test 2"))
            .perform(TestViewActions.ctrlClick()) // Multi-select
        onView(withId(R.id.circle_shape))
            .perform(TestViewActions.ctrlClick())

        // Group selected layers
        onView(withId(R.id.btn_group_layers))
            .check(matches(isDisplayed()))
            .perform(click())

        // Verify group created
        onView(withId(R.id.layer_group))
            .check(matches(isDisplayed()))

        // Test group manipulation
        onView(withId(R.id.layer_group))
            .perform(TestViewActions.dragTo(
                GeneralLocation.CENTER,
                GeneralLocation.TOP_RIGHT
            ))

        // Verify all grouped elements moved together
        activityRule.scenario.onActivity { activity ->
            val group = activity.findViewById<android.view.ViewGroup>(R.id.layer_group)
            assertTrue("Group should have moved") {
                group.translationX > 50 && group.translationY > 50
            }
        }
    }

    // MARK: - Helper Methods

    private fun setupCanvasWithDevice(deviceName: String) {
        onView(withId(R.id.btn_create_design))
            .check(matches(isDisplayed()))
            .perform(click())

        onView(withId(R.id.btn_device_selector))
            .check(matches(isDisplayed()))
            .perform(click())

        onView(withText(deviceName))
            .check(matches(isDisplayed()))
            .perform(click())

        onView(withId(R.id.canvas_view))
            .check(matches(isDisplayed()))
    }

    private fun addTextLayer(text: String) {
        onView(withId(R.id.btn_add_text))
            .check(matches(isDisplayed()))
            .perform(click())

        onView(withId(R.id.et_text_input))
            .perform(typeText(text), closeSoftKeyboard())

        onView(withId(R.id.btn_confirm_text))
            .perform(click())

        onView(withText(text))
            .check(matches(isDisplayed()))
    }

    private fun addShapeLayer(shape: String) {
        onView(withId(R.id.btn_add_shape))
            .check(matches(isDisplayed()))
            .perform(click())

        onView(withText(shape))
            .check(matches(isDisplayed()))
            .perform(click())

        onView(withId(R.id.btn_confirm_shape))
            .perform(click())

        onView(withId(R.id.${shape.lowercase()}_shape))
            .check(matches(isDisplayed()))
    }
}
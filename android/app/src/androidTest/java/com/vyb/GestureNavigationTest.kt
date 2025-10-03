package com.vyb

import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.*
import androidx.test.espresso.assertion.ViewAssertions.*
import androidx.test.espresso.matcher.ViewMatchers.*
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import org.hamcrest.Matchers.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.test.assertTrue

@RunWith(AndroidJUnit4::class)
@LargeTest
class GestureNavigationTest {

    @get:Rule
    val activityRule = ActivityScenarioRule(MainActivity::class.java)

    @Before
    fun setUp() {
        Thread.sleep(1000) // Wait for activity to fully load
    }

    @Test
    fun testCreateBaseDesignAndGenerateAIVariations() {
        setupCanvasWithDevice("Pixel 8 Pro")

        // Create base design elements
        addTextLayer("Social Media Post", fontSize = 24)
        addImageLayer("sample-photo.jpg")
        addGradientBackground("#FF6B6B", "#4ECDC4")

        // Save as initial variation
        onView(withId(R.id.btn_save_variation))
            .check(matches(isDisplayed()))
            .perform(click())

        onView(withId(R.id.et_variation_name))
            .perform(typeText("Initial Design"), closeSoftKeyboard())

        onView(withId(R.id.btn_save_confirm))
            .perform(click())

        // Trigger AI analysis
        onView(withId(R.id.btn_generate_ai))
            .check(matches(isDisplayed()))
            .perform(click())

        // Wait for AI processing to complete
        onView(withId(R.id.ai_loading_indicator))
            .check(matches(isDisplayed()))

        onView(withId(R.id.ai_suggestions_ready))
            .check(matches(withEffectiveVisibility(Visibility.VISIBLE)))

        // Verify AI suggestions generated
        onView(withId(R.id.ai_suggestions_container))
            .check(matches(hasMinimumChildCount(3)))

        // Verify confidence scores are displayed
        onView(allOf(
            withId(R.id.confidence_score),
            isDescendantOfA(withId(R.id.ai_suggestions_container))
        ))
        .check(matches(isDisplayed()))
        .check(matches(withText(matchesPattern("\\d{1,3}%"))))
    }

    @Test
    fun testGestureNavigationBetweenVariations() {
        setupBaseDesignWithAI()

        val canvasView = onView(withId(R.id.canvas_interaction_area))

        // Get initial variation ID
        var currentVariationId: String = ""
        activityRule.scenario.onActivity { activity ->
            currentVariationId = activity.getCurrentVariationId()
        }

        // Test scroll down (next variation)
        canvasView.perform(TestViewActions.scrollDown())
        Thread.sleep(300) // Wait for navigation animation

        // Verify we moved to next variation
        activityRule.scenario.onActivity { activity ->
            val newVariationId = activity.getCurrentVariationId()
            assertTrue("Should navigate to next variation") {
                newVariationId != currentVariationId
            }
            currentVariationId = newVariationId
        }

        // Test scroll up (previous variation)
        canvasView.perform(TestViewActions.scrollUp())
        Thread.sleep(300) // Wait for navigation animation

        // Verify we returned to previous variation
        activityRule.scenario.onActivity { activity ->
            val returnedVariationId = activity.getCurrentVariationId()
            assertTrue("Should return to previous variation") {
                returnedVariationId != currentVariationId
            }
        }
    }

    @Test
    fun testScrollPerformanceAt60FPS() {
        setupBaseDesignWithAI()

        val canvasView = onView(withId(R.id.canvas_interaction_area))

        // Enable frame rate monitoring
        activityRule.scenario.onActivity { activity ->
            activity.enableFrameRateMonitoring()
        }

        // Perform rapid scrolling to test frame rates
        for (i in 1..10) {
            canvasView.perform(TestViewActions.fastScrollDown())
            Thread.sleep(100)
            canvasView.perform(TestViewActions.fastScrollUp())
            Thread.sleep(100)
        }

        // Check frame rate performance
        activityRule.scenario.onActivity { activity ->
            val frameStats = activity.getFrameRateStats()
            val avgFrameTime = frameStats.averageFrameTimeMs
            val slowFrameCount = frameStats.slowFrameCount

            assertTrue("Average frame time should be under 16.67ms (60fps)") {
                avgFrameTime < 16.67
            }

            assertTrue("Less than 5% frames should be slow") {
                slowFrameCount < frameStats.totalFrames * 0.05
            }
        }
    }

    @Test
    fun testMomentumPhysicsCorrectly() {
        setupBaseDesignWithAI()

        val canvasView = onView(withId(R.id.canvas_interaction_area))

        // Start gesture monitoring
        activityRule.scenario.onActivity { activity ->
            activity.startGestureMonitoring()
        }

        // Simulate momentum scroll gesture
        canvasView.perform(TestViewActions.momentumScroll(
            startVelocity = 2000f,
            direction = TestViewActions.ScrollDirection.DOWN
        ))

        // Verify momentum continues after gesture ends
        var isAnimating = true
        var animationFrames = 0
        val maxFrames = 100

        while (isAnimating && animationFrames < maxFrames) {
            Thread.sleep(16) // ~60fps
            
            activityRule.scenario.onActivity { activity ->
                isAnimating = activity.isGestureAnimating()
            }
            animationFrames++
        }

        assertTrue("Should animate for several frames") { animationFrames > 5 }
        assertTrue("Should eventually stop animating") { animationFrames < maxFrames }
    }

    @Test
    fun testEdgeCasesInNavigation() {
        setupBaseDesignWithAI()

        val canvasView = onView(withId(R.id.canvas_interaction_area))

        // Test scrolling at beginning of history
        var initialVariationId: String = ""
        activityRule.scenario.onActivity { activity ->
            initialVariationId = activity.getCurrentVariationId()
        }

        // Large scroll up at beginning should not break
        canvasView.perform(TestViewActions.largeScrollUp())
        Thread.sleep(300)

        // Should remain at first variation
        activityRule.scenario.onActivity { activity ->
            val afterScrollId = activity.getCurrentVariationId()
            assertTrue("Should remain at first variation") {
                afterScrollId == initialVariationId
            }
        }

        // Navigate to last variation
        var currentId = initialVariationId
        for (attempts in 1..10) {
            canvasView.perform(TestViewActions.scrollDown())
            Thread.sleep(200)

            activityRule.scenario.onActivity { activity ->
                val newId = activity.getCurrentVariationId()
                if (newId == currentId) {
                    // Reached end of variations
                    return@onActivity
                }
                currentId = newId
            }
        }

        // Test scrolling at end of history
        val endVariationId = currentId
        canvasView.perform(TestViewActions.largeScrollDown())
        Thread.sleep(300)

        // Should remain at last variation
        activityRule.scenario.onActivity { activity ->
            val afterScrollId = activity.getCurrentVariationId()
            assertTrue("Should remain at last variation") {
                afterScrollId == endVariationId
            }
        }
    }

    @Test
    fun testImmediateVisualFeedbackDuringGestures() {
        setupBaseDesignWithAI()

        val canvasView = onView(withId(R.id.canvas_interaction_area))

        // Start gesture and check for immediate feedback
        canvasView.perform(TestViewActions.startGesture())

        // Check for immediate visual feedback (within 1 frame)
        Thread.sleep(16) // 1 frame at 60fps

        onView(withId(R.id.gesture_feedback_indicator))
            .check(matches(isDisplayed()))

        // Continue gesture
        canvasView.perform(TestViewActions.continueGesture(100f, 0f))

        // Verify feedback updates with gesture
        activityRule.scenario.onActivity { activity ->
            val feedbackView = activity.findViewById<android.view.View>(R.id.gesture_feedback_indicator)
            assertTrue("Feedback should be visible during gesture") {
                feedbackView.alpha > 0.5f
            }
        }

        // End gesture
        canvasView.perform(TestViewActions.endGesture())

        // Verify feedback disappears after gesture ends
        Thread.sleep(500)
        
        activityRule.scenario.onActivity { activity ->
            val feedbackView = activity.findViewById<android.view.View>(R.id.gesture_feedback_indicator)
            assertTrue("Feedback should fade after gesture ends") {
                feedbackView.alpha < 0.1f
            }
        }
    }

    @Test
    fun testGestureVelocityCalculation() {
        setupBaseDesignWithAI()

        val canvasView = onView(withId(R.id.canvas_interaction_area))

        // Perform slow gesture
        canvasView.perform(TestViewActions.slowScroll(
            direction = TestViewActions.ScrollDirection.DOWN,
            velocity = 100f
        ))

        activityRule.scenario.onActivity { activity ->
            val velocity = activity.getLastGestureVelocity()
            assertTrue("Slow gesture should have low velocity") {
                velocity < 500f
            }
            assertTrue("Should not trigger navigation") {
                !activity.shouldTriggerNavigation()
            }
        }

        // Perform fast gesture
        canvasView.perform(TestViewActions.fastScroll(
            direction = TestViewActions.ScrollDirection.DOWN,
            velocity = 1500f
        ))

        activityRule.scenario.onActivity { activity ->
            val velocity = activity.getLastGestureVelocity()
            assertTrue("Fast gesture should have high velocity") {
                velocity > 1000f
            }
            assertTrue("Should trigger navigation") {
                activity.shouldTriggerNavigation()
            }
        }
    }

    @Test
    fun testScrollDirectionRecognition() {
        setupBaseDesignWithAI()

        val canvasView = onView(withId(R.id.canvas_interaction_area))

        // Test scroll up recognition (previous variation intent)
        canvasView.perform(TestViewActions.scrollUp())

        activityRule.scenario.onActivity { activity ->
            val navigationIntent = activity.getNavigationIntent()
            assertTrue("Scroll up should indicate previous variation intent") {
                navigationIntent == "previous"
            }
        }

        // Test scroll down recognition (next variation intent)
        canvasView.perform(TestViewActions.scrollDown())

        activityRule.scenario.onActivity { activity ->
            val navigationIntent = activity.getNavigationIntent()
            assertTrue("Scroll down should indicate next variation intent") {
                navigationIntent == "next"
            }
        }
    }

    @Test
    fun testGestureCancellation() {
        setupBaseDesignWithAI()

        val canvasView = onView(withId(R.id.canvas_interaction_area))

        // Start gesture
        canvasView.perform(TestViewActions.startGesture())
        
        // Begin scroll
        canvasView.perform(TestViewActions.continueGesture(0f, 150f))

        // Verify gesture is in progress
        activityRule.scenario.onActivity { activity ->
            assertTrue("Gesture should be in progress") {
                activity.isGestureInProgress()
            }
        }

        // Cancel gesture mid-scroll
        canvasView.perform(TestViewActions.cancelGesture())

        // Verify gesture state is reset
        activityRule.scenario.onActivity { activity ->
            assertFalse("Gesture should be cancelled") {
                activity.isGestureInProgress()
            }
            assertTrue("Velocity should be reset") {
                activity.getCurrentScrollVelocity() == 0f
            }
            assertTrue("Direction should be idle") {
                activity.getScrollDirection() == "idle"
            }
        }
    }

    @Test
    fun testNavigationHistoryManagement() {
        setupBaseDesignWithAI()

        val canvasView = onView(withId(R.id.canvas_interaction_area))

        // Navigate through several variations
        val visitedVariations = mutableListOf<String>()
        
        activityRule.scenario.onActivity { activity ->
            visitedVariations.add(activity.getCurrentVariationId())
        }

        // Navigate forward through variations
        for (i in 1..5) {
            canvasView.perform(TestViewActions.scrollDown())
            Thread.sleep(200)
            
            activityRule.scenario.onActivity { activity ->
                val currentId = activity.getCurrentVariationId()
                if (!visitedVariations.contains(currentId)) {
                    visitedVariations.add(currentId)
                }
            }
        }

        // Verify navigation history maintained
        activityRule.scenario.onActivity { activity ->
            val navigationHistory = activity.getNavigationHistory()
            assertTrue("Navigation history should contain visited variations") {
                navigationHistory.size >= visitedVariations.size - 1
            }
            
            // Verify history stack is limited to prevent memory issues
            assertTrue("History should be limited to reasonable size") {
                navigationHistory.size <= 10
            }
        }

        // Test backward navigation
        for (i in 1..3) {
            canvasView.perform(TestViewActions.scrollUp())
            Thread.sleep(200)
        }

        // Verify we can navigate back through history
        activityRule.scenario.onActivity { activity ->
            val currentId = activity.getCurrentVariationId()
            assertTrue("Should be able to navigate back through history") {
                visitedVariations.contains(currentId)
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

    private fun addTextLayer(text: String, fontSize: Int = 16) {
        onView(withId(R.id.btn_add_text))
            .perform(click())

        onView(withId(R.id.et_text_input))
            .perform(typeText(text), closeSoftKeyboard())

        if (fontSize != 16) {
            onView(withId(R.id.font_size_slider))
                .perform(TestViewActions.setSliderValue(fontSize.toFloat()))
        }

        onView(withId(R.id.btn_confirm_text))
            .perform(click())
    }

    private fun addImageLayer(imageName: String) {
        onView(withId(R.id.btn_add_image))
            .perform(click())

        onView(withId(R.id.btn_test_image))
            .perform(click())

        onView(withId(R.id.btn_select_image))
            .perform(click())
    }

    private fun addGradientBackground(color1: String, color2: String) {
        onView(withId(R.id.btn_add_background))
            .perform(click())

        onView(withId(R.id.btn_gradient_background))
            .perform(click())

        onView(withId(R.id.et_gradient_color_1))
            .perform(typeText(color1), closeSoftKeyboard())

        onView(withId(R.id.et_gradient_color_2))
            .perform(typeText(color2), closeSoftKeyboard())

        onView(withId(R.id.btn_confirm_background))
            .perform(click())
    }

    private fun setupBaseDesignWithAI() {
        setupCanvasWithDevice("Pixel 8 Pro")
        addTextLayer("Test Design")
        addGradientBackground("#4ECDC4", "#FF6B6B")

        // Generate AI suggestions
        onView(withId(R.id.btn_generate_ai))
            .perform(click())

        onView(withId(R.id.ai_suggestions_ready))
            .check(matches(withEffectiveVisibility(Visibility.VISIBLE)))
    }
}
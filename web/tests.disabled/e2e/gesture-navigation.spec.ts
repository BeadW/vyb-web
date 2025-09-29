import { test, expect, Page } from '@playwright/test'

test.describe('Gesture-Based AI Navigation', () => {
  let page: Page

  test.beforeEach(async ({ page: testPage }) => {
    page = testPage
    await page.goto('/')
    await page.waitForLoadState('networkidle')
    
    // Set up initial design for AI processing
    await page.click('[data-testid="device-selector"]')
    await page.click('[data-testid="device-iphone-15-pro"]')
  })

  test('should create base design and generate AI variations', async () => {
    // Create base design elements
    await page.click('[data-testid="add-text-layer"]')
    await page.fill('[data-testid="text-input"]', 'Social Media Post')
    await page.selectOption('[data-testid="font-size"]', '24')
    await page.click('[data-testid="confirm-text"]')
    
    // Add image layer
    await page.click('[data-testid="add-image-layer"]')
    await page.setInputFiles('[data-testid="image-upload"]', 'tests/fixtures/sample-photo.jpg')
    await page.waitForSelector('[data-testid="image-layer"]')
    
    // Add gradient background
    await page.click('[data-testid="add-background-layer"]')
    await page.selectOption('[data-testid="background-type"]', 'gradient')
    await page.fill('[data-testid="gradient-color-1"]', '#FF6B6B')
    await page.fill('[data-testid="gradient-color-2"]', '#4ECDC4')
    await page.click('[data-testid="confirm-background"]')
    
    // Save as initial variation
    await page.click('[data-testid="save-variation"]')
    await page.waitForSelector('[data-testid="variation-saved"]')
    
    // Trigger AI analysis
    await page.click('[data-testid="generate-ai-suggestions"]')
    
    // Wait for AI processing to complete (with timeout)
    await page.waitForSelector('[data-testid="ai-suggestions-ready"]', { timeout: 10000 })
    
    // Verify AI suggestions generated
    const suggestionCount = await page.locator('[data-testid="ai-suggestion"]').count()
    expect(suggestionCount).toBeGreaterThanOrEqual(3)
    
    // Verify each suggestion has confidence scores
    const suggestions = page.locator('[data-testid="ai-suggestion"]')
    for (let i = 0; i < await suggestions.count(); i++) {
      const suggestion = suggestions.nth(i)
      const confidenceScore = await suggestion.locator('[data-testid="confidence-score"]').textContent()
      expect(parseFloat(confidenceScore!)).toBeGreaterThan(0)
      expect(parseFloat(confidenceScore!)).toBeLessThanOrEqual(1)
    }
  })

  test('should handle gesture navigation between variations', async () => {
    // Set up base design and AI suggestions (abbreviated setup)
    await setupBaseDesignWithAI(page)
    
    const canvasArea = page.locator('[data-testid="canvas-interaction-area"]')
    
    // Test scroll down (next variation)
    await canvasArea.hover()
    await page.mouse.wheel(0, 100) // Scroll down
    
    // Wait for navigation animation
    await page.waitForTimeout(300)
    
    // Verify we moved to next variation
    const currentVariationId = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    expect(currentVariationId).not.toBe('root')
    
    // Test scroll up (previous variation)
    await canvasArea.hover()
    await page.mouse.wheel(0, -100) // Scroll up
    await page.waitForTimeout(300)
    
    // Verify we returned to previous variation
    const newVariationId = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    expect(newVariationId).toBe('root')
  })

  test('should maintain 60fps during scroll transitions', async () => {
    await setupBaseDesignWithAI(page)
    
    const canvasArea = page.locator('[data-testid="canvas-interaction-area"]')
    
    // Start performance monitoring
    await page.evaluate(() => {
      (window as any).performanceFrames = []
      const startTime = performance.now()
      
      function measureFrame() {
        const currentTime = performance.now()
        ;(window as any).performanceFrames.push(currentTime - startTime)
        requestAnimationFrame(measureFrame)
      }
      
      requestAnimationFrame(measureFrame)
    })
    
    // Perform rapid scrolling to test frame rates
    for (let i = 0; i < 5; i++) {
      await canvasArea.hover()
      await page.mouse.wheel(0, 200) // Fast scroll down
      await page.waitForTimeout(100)
      await page.mouse.wheel(0, -200) // Fast scroll up
      await page.waitForTimeout(100)
    }
    
    // Measure frame times
    const frameTimes = await page.evaluate(() => {
      const frames = (window as any).performanceFrames
      const deltas = []
      for (let i = 1; i < frames.length; i++) {
        deltas.push(frames[i] - frames[i-1])
      }
      return deltas
    })
    
    // Verify frame times are under 16ms (60fps target)
    const avgFrameTime = frameTimes.reduce((a, b) => a + b, 0) / frameTimes.length
    expect(avgFrameTime).toBeLessThan(16.67) // 16.67ms = 60fps
    
    // Verify no frames exceeded 33ms (30fps minimum)
    const slowFrames = frameTimes.filter(time => time > 33.33)
    expect(slowFrames.length).toBeLessThan(frameTimes.length * 0.05) // Less than 5% slow frames
  })

  test('should handle momentum physics correctly', async () => {
    await setupBaseDesignWithAI(page)
    
    const canvasArea = page.locator('[data-testid="canvas-interaction-area"]')
    
    // Simulate momentum scroll gesture
    await canvasArea.hover()
    
    // Fast scroll to build momentum
    await page.mouse.down()
    for (let i = 0; i < 10; i++) {
      await page.mouse.move(200, 100 + i * 20)
      await page.waitForTimeout(10)
    }
    await page.mouse.up()
    
    // Verify momentum continues after gesture ends
    let isAnimating = true
    let animationFrames = 0
    
    while (isAnimating && animationFrames < 100) { // Max 100 frames to prevent infinite loop
      const animationState = await page.getAttribute('[data-testid="canvas-interaction-area"]', 'data-animation-state')
      isAnimating = animationState === 'animating'
      animationFrames++
      await page.waitForTimeout(16) // ~60fps
    }
    
    expect(animationFrames).toBeGreaterThan(5) // Should animate for several frames
    expect(animationFrames).toBeLessThan(100) // Should eventually stop
  })

  test('should handle edge cases in navigation', async () => {
    await setupBaseDesignWithAI(page)
    
    const canvasArea = page.locator('[data-testid="canvas-interaction-area"]')
    
    // Test scrolling at beginning of history (should not break)
    const initialVariationId = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    
    await canvasArea.hover()
    await page.mouse.wheel(0, -500) // Large scroll up at beginning
    await page.waitForTimeout(300)
    
    // Should remain at first variation
    const afterUpScrollId = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    expect(afterUpScrollId).toBe(initialVariationId)
    
    // Navigate to last variation
    let currentId = initialVariationId
    for (let attempts = 0; attempts < 10; attempts++) {
      await canvasArea.hover()
      await page.mouse.wheel(0, 300) // Scroll down
      await page.waitForTimeout(200)
      
      const newId = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
      if (newId === currentId) {
        // Reached end of variations
        break
      }
      currentId = newId
    }
    
    // Test scrolling at end of history
    const endVariationId = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    
    await canvasArea.hover()
    await page.mouse.wheel(0, 500) // Large scroll down at end
    await page.waitForTimeout(300)
    
    // Should remain at last variation
    const afterDownScrollId = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    expect(afterDownScrollId).toBe(endVariationId)
  })

  test('should provide immediate visual feedback during gestures', async () => {
    await setupBaseDesignWithAI(page)
    
    const canvasArea = page.locator('[data-testid="canvas-interaction-area"]')
    
    // Start gesture and immediately check for visual feedback
    await canvasArea.hover()
    await page.mouse.down()
    
    // Check for immediate visual feedback (within 1 frame)
    await page.waitForTimeout(16)
    const feedbackElement = page.locator('[data-testid="gesture-feedback"]')
    expect(await feedbackElement.isVisible()).toBe(true)
    
    // Move mouse to simulate dragging
    await page.mouse.move(200, 150)
    
    // Verify feedback updates with gesture
    const feedbackOpacity = await feedbackElement.evaluate(el => 
      window.getComputedStyle(el).opacity
    )
    expect(parseFloat(feedbackOpacity)).toBeGreaterThan(0.5)
    
    // End gesture
    await page.mouse.up()
    
    // Verify feedback disappears after gesture ends
    await page.waitForTimeout(500)
    const finalOpacity = await feedbackElement.evaluate(el => 
      window.getComputedStyle(el).opacity
    )
    expect(parseFloat(finalOpacity)).toBeLessThan(0.1)
  })
})

// Helper function to set up base design with AI suggestions
async function setupBaseDesignWithAI(page: Page) {
  // Add text layer
  await page.click('[data-testid="add-text-layer"]')
  await page.fill('[data-testid="text-input"]', 'Test Design')
  await page.click('[data-testid="confirm-text"]')
  
  // Add background
  await page.click('[data-testid="add-background-layer"]')
  await page.fill('[data-testid="background-color"]', '#4ECDC4')
  await page.click('[data-testid="confirm-background"]')
  
  // Generate AI suggestions
  await page.click('[data-testid="generate-ai-suggestions"]')
  await page.waitForSelector('[data-testid="ai-suggestions-ready"]', { timeout: 10000 })
}
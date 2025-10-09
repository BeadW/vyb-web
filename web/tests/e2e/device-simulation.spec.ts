import { test, expect, Page } from '@playwright/test'

test.describe('Device Simulation Accuracy', () => {
  let page: Page

  test.beforeEach(async ({ page: testPage }) => {
    page = testPage
    await page.goto('/')
    await page.waitForLoadState('networkidle')
  })

  test('should provide pixel-perfect iPhone 15 Pro simulation', async () => {
    // Select iPhone 15 Pro device simulation
    await page.click('[data-testid="device-selector"]')
    await page.click('[data-testid="device-iphone-15-pro"]')
    
    // Wait for device simulation to load
    await page.waitForSelector('[data-testid="device-canvas"]')
    
    // Get canvas dimensions
    const canvasElement = page.locator('[data-testid="device-canvas"]')
    const canvasBox = await canvasElement.boundingBox()
    
    // iPhone 15 Pro specifications: 393x852 points @ 3x pixel density
    expect(canvasBox?.width).toBe(393)
    expect(canvasBox?.height).toBe(852)
    
    // Create test pattern with grid, text, and images
    await page.click('[data-testid="add-text-layer"]')
    await page.fill('[data-testid="text-input"]', 'Test Pattern Text')
    await page.click('[data-testid="confirm-text"]')
    
    await page.click('[data-testid="add-image-layer"]')
    await page.setInputFiles('[data-testid="image-upload"]', 'tests/fixtures/test-image.jpg')
    
    // Verify content is positioned correctly within safe areas
    const safeAreaTop = page.locator('[data-testid="safe-area-top"]')
    const safeAreaTopHeight = await safeAreaTop.evaluate(el => el.getBoundingClientRect().height)
    expect(safeAreaTopHeight).toBe(59) // iPhone 15 Pro notch height
    
    const safeAreaBottom = page.locator('[data-testid="safe-area-bottom"]')
    const safeAreaBottomHeight = await safeAreaBottom.evaluate(el => el.getBoundingClientRect().height)
    expect(safeAreaBottomHeight).toBe(34) // Home indicator height
  })

  test('should handle device switching with content preservation', async () => {
    // Start with iPhone 15 Pro
    await page.click('[data-testid="device-selector"]')
    await page.click('[data-testid="device-iphone-15-pro"]')
    
    // Add content
    await page.click('[data-testid="add-text-layer"]')
    await page.fill('[data-testid="text-input"]', 'Device Switch Test')
    await page.click('[data-testid="confirm-text"]')
    
    const textLayer = page.locator('[data-testid="text-layer"]')
    const initialTextContent = await textLayer.textContent()
    
    // Switch to iPad Pro 12.9
    await page.click('[data-testid="device-selector"]')
    await page.click('[data-testid="device-ipad-pro-12.9"]')
    
    // Wait for device simulation to update
    await page.waitForTimeout(500)
    
    // Verify canvas dimensions changed to iPad specifications
    const canvasElement = page.locator('[data-testid="device-canvas"]')
    const newCanvasBox = await canvasElement.boundingBox()
    
    expect(newCanvasBox?.width).toBe(1024)
    expect(newCanvasBox?.height).toBe(1366)
    
    // Verify content preserved and scaled appropriately
    const scaledTextLayer = page.locator('[data-testid="text-layer"]')
    const scaledTextContent = await scaledTextLayer.textContent()
    expect(scaledTextContent).toBe(initialTextContent)
    
    // Check aspect ratio maintained
    const aspectRatio = (newCanvasBox?.width || 1) / (newCanvasBox?.height || 1)
    expect(aspectRatio).toBeCloseTo(1024 / 1366, 2) // iPad Pro aspect ratio
  })

  test('should maintain safe area accuracy across device types', async () => {
    const deviceTests = [
      {
        device: 'device-iphone-15-pro',
        expectedDimensions: { width: 393, height: 852 },
        expectedSafeAreas: { top: 59, bottom: 34, left: 0, right: 0 }
      },
      {
        device: 'device-pixel-8-pro', 
        expectedDimensions: { width: 448, height: 998 },
        expectedSafeAreas: { top: 24, bottom: 0, left: 0, right: 0 }
      },
      {
        device: 'device-ipad-pro-12.9',
        expectedDimensions: { width: 1024, height: 1366 },
        expectedSafeAreas: { top: 24, bottom: 24, left: 0, right: 0 }
      }
    ]

    for (const deviceTest of deviceTests) {
      await page.click('[data-testid="device-selector"]')
      await page.click(`[data-testid="${deviceTest.device}"]`)
      
      await page.waitForSelector('[data-testid="device-canvas"]')
      
      // Verify dimensions
      const canvasElement = page.locator('[data-testid="device-canvas"]')
      const canvasBox = await canvasElement.boundingBox()
      
      expect(canvasBox?.width).toBe(deviceTest.expectedDimensions.width)
      expect(canvasBox?.height).toBe(deviceTest.expectedDimensions.height)
      
      // Verify safe areas
      if (deviceTest.expectedSafeAreas.top > 0) {
        const safeAreaTop = page.locator('[data-testid="safe-area-top"]')
        const topHeight = await safeAreaTop.evaluate(el => el.getBoundingClientRect().height)
        expect(topHeight).toBe(deviceTest.expectedSafeAreas.top)
      }
      
      if (deviceTest.expectedSafeAreas.bottom > 0) {
        const safeAreaBottom = page.locator('[data-testid="safe-area-bottom"]')
        const bottomHeight = await safeAreaBottom.evaluate(el => el.getBoundingClientRect().height)
        expect(bottomHeight).toBe(deviceTest.expectedSafeAreas.bottom)
      }
    }
  })

  test('should handle device rotation and responsive behavior', async () => {
    // Set up initial portrait orientation
    await page.setViewportSize({ width: 393, height: 852 })
    
    await page.click('[data-testid="device-selector"]')
    await page.click('[data-testid="device-iphone-15-pro"]')
    
    // Add content to test rotation behavior
    await page.click('[data-testid="add-text-layer"]')
    await page.fill('[data-testid="text-input"]', 'Rotation Test')
    await page.click('[data-testid="confirm-text"]')
    
    // Capture initial state
    const portraitScreenshot = await page.screenshot({ path: 'tests/screenshots/portrait-before.png' })
    
    // Rotate to landscape
    await page.click('[data-testid="rotate-device"]')
    await page.waitForTimeout(300) // Animation time
    
    // Verify landscape dimensions
    const canvasElement = page.locator('[data-testid="device-canvas"]')
    const landscapeBox = await canvasElement.boundingBox()
    
    expect(landscapeBox?.width).toBe(852) // Swapped dimensions
    expect(landscapeBox?.height).toBe(393)
    
    // Verify content adapted to new orientation
    const textLayer = page.locator('[data-testid="text-layer"]')
    expect(await textLayer.textContent()).toBe('Rotation Test')
    
    // Take landscape screenshot for comparison
    const landscapeScreenshot = await page.screenshot({ path: 'tests/screenshots/landscape-after.png' })
    
    // Verify screenshots are different (orientation changed)
    expect(portraitScreenshot).not.toEqual(landscapeScreenshot)
  })

  test('should validate cross-platform visual consistency', async () => {
    // This test would ideally run against multiple browser engines
    // For now, we test within single browser but verify consistency markers
    
    await page.click('[data-testid="device-selector"]')
    await page.click('[data-testid="device-iphone-15-pro"]')
    
    // Create standardized test design
    await page.click('[data-testid="add-text-layer"]')
    await page.fill('[data-testid="text-input"]', 'Cross-Platform Test')
    await page.selectOption('[data-testid="font-size"]', '16')
    await page.selectOption('[data-testid="font-family"]', 'Arial')
    await page.click('[data-testid="confirm-text"]')
    
    // Add background with specific color
    await page.click('[data-testid="add-background-layer"]')
    await page.fill('[data-testid="background-color"]', '#FF5733')
    await page.click('[data-testid="confirm-background"]')
    
    // Export design state for cross-platform testing
    await page.click('[data-testid="export-design"]')
    const exportedData = await page.evaluate(() => {
      return window.localStorage.getItem('exported-design-state')
    })
    
    expect(exportedData).toBeDefined()
    const designState = JSON.parse(exportedData!)
    
    // Verify design state contains all necessary information for cross-platform rendering
    expect(designState.deviceType).toBe('iphone-15-pro')
    expect(designState.layers).toHaveLength(2) // text + background
    expect(designState.dimensions).toEqual({ width: 393, height: 852, pixelDensity: 3 })
    
    // Verify layer properties are serializable and complete
    const textLayer = designState.layers.find((layer: any) => layer.type === 'text')
    expect(textLayer.content.text).toBe('Cross-Platform Test')
    expect(textLayer.style.fontSize).toBe(16)
    expect(textLayer.style.fontFamily).toBe('Arial')
    
    const backgroundLayer = designState.layers.find((layer: any) => layer.type === 'background')
    expect(backgroundLayer.style.backgroundColor).toBe('#FF5733')
  })
})
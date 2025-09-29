import { test, expect, Page } from '@playwright/test'

test.describe('Branching History Preservation', () => {
  let page: Page

  test.beforeEach(async ({ page: testPage }) => {
    page = testPage
    await page.goto('/')
    await page.waitForLoadState('networkidle')
    
    // Set up device simulation
    await page.click('[data-testid="device-selector"]')
    await page.click('[data-testid="device-iphone-15-pro"]')
  })

  test('should create and preserve linear history', async () => {
    // Step 1: Start with blank canvas (Root)
    const rootVariationId = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    expect(rootVariationId).toBe('root')
    
    // Step 2: Make user edit - Add text → User Edit 1
    await page.click('[data-testid="add-text-layer"]')
    await page.fill('[data-testid="text-input"]', 'Initial Text')
    await page.click('[data-testid="confirm-text"]')
    
    await page.click('[data-testid="save-variation"]')
    await page.fill('[data-testid="variation-name"]', 'User Edit 1')
    await page.click('[data-testid="save-confirm"]')
    
    const userEdit1Id = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    expect(userEdit1Id).not.toBe(rootVariationId)
    
    // Step 3: Make another edit - Change color → User Edit 2
    await page.click('[data-testid="text-layer"]')
    await page.click('[data-testid="text-color-picker"]')
    await page.fill('[data-testid="color-input"]', '#FF5733')
    await page.click('[data-testid="apply-color"]')
    
    await page.click('[data-testid="save-variation"]')
    await page.fill('[data-testid="variation-name"]', 'User Edit 2')
    await page.click('[data-testid="save-confirm"]')
    
    const userEdit2Id = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    expect(userEdit2Id).not.toBe(userEdit1Id)
    
    // Step 4: Generate AI suggestion → AI Suggestion 1
    await page.click('[data-testid="generate-ai-suggestions"]')
    await page.waitForSelector('[data-testid="ai-suggestions-ready"]', { timeout: 10000 })
    
    // Accept first AI suggestion
    await page.click('[data-testid="ai-suggestion"]:first-child [data-testid="accept-suggestion"]')
    
    const aiSuggestion1Id = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    expect(aiSuggestion1Id).not.toBe(userEdit2Id)
    
    // Verify linear history chain
    const historyChain = await page.evaluate(() => {
      return (window as any).vyb?.historyManager?.getLinearHistory() || []
    })
    
    expect(historyChain).toHaveLength(4) // root → user1 → user2 → ai1
    expect(historyChain[0]).toBe(rootVariationId)
    expect(historyChain[1]).toBe(userEdit1Id)
    expect(historyChain[2]).toBe(userEdit2Id)
    expect(historyChain[3]).toBe(aiSuggestion1Id)
  })

  test('should create and manage branching history', async () => {
    // First create a linear history to branch from
    await createLinearHistory(page)
    
    // Get User Edit 1 ID for branching
    const historyData = await page.evaluate(() => {
      return (window as any).vyb?.historyManager?.getAllVariations() || {}
    })
    
    const userEdit1Id = Object.keys(historyData).find(id => 
      historyData[id].name === 'User Edit 1'
    )
    
    // Navigate back to User Edit 1
    await page.click('[data-testid="history-navigator"]')
    await page.click(`[data-testid="variation-${userEdit1Id}"]`)
    
    // Verify we're at User Edit 1
    const currentId = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    expect(currentId).toBe(userEdit1Id)
    
    // Create Branch 1: Add image → User Edit 3
    await page.click('[data-testid="add-image-layer"]')
    await page.setInputFiles('[data-testid="image-upload"]', 'tests/fixtures/branch-image.jpg')
    await page.waitForSelector('[data-testid="image-layer"]')
    
    await page.click('[data-testid="save-variation"]')
    await page.fill('[data-testid="variation-name"]', 'User Edit 3 - Branch 1')
    await page.click('[data-testid="save-confirm"]')
    
    const userEdit3Id = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    
    // Generate AI suggestion from this branch → AI Suggestion 2
    await page.click('[data-testid="generate-ai-suggestions"]')
    await page.waitForSelector('[data-testid="ai-suggestions-ready"]', { timeout: 10000 })
    await page.click('[data-testid="ai-suggestion"]:first-child [data-testid="accept-suggestion"]')
    
    const aiSuggestion2Id = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    
    // Navigate back to root for third branch
    await page.click('[data-testid="history-navigator"]')
    await page.click('[data-testid="variation-root"]')
    
    // Create Branch 2: Add shape → User Edit 4
    await page.click('[data-testid="add-shape-layer"]')
    await page.click('[data-testid="shape-circle"]')
    await page.click('[data-testid="confirm-shape"]')
    
    await page.click('[data-testid="save-variation"]')
    await page.fill('[data-testid="variation-name"]', 'User Edit 4 - Branch 2')
    await page.click('[data-testid="save-confirm"]')
    
    const userEdit4Id = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
    
    // Verify DAG structure
    const dagStructure = await page.evaluate(() => {
      return (window as any).vyb?.historyManager?.getDAGStructure() || {}
    })
    
    // Verify branching relationships
    expect(dagStructure[userEdit3Id].parentId).toBe(userEdit1Id) // Branch from User Edit 1
    expect(dagStructure[aiSuggestion2Id].parentId).toBe(userEdit3Id) // AI from Branch 1
    expect(dagStructure[userEdit4Id].parentId).toBe('root') // Branch from root
    
    // Verify no circular references
    const hasCircularRef = await page.evaluate(() => {
      return (window as any).vyb?.historyManager?.detectCircularReferences() || false
    })
    expect(hasCircularRef).toBe(false)
  })

  test('should navigate history tree without data loss', async () => {
    // Create complex branching structure
    await createComplexBranchingHistory(page)
    
    // Test navigation to each branch and verify content preservation
    const allVariations = await page.evaluate(() => {
      return (window as any).vyb?.historyManager?.getAllVariations() || {}
    })
    
    for (const [variationId, variationData] of Object.entries(allVariations)) {
      // Navigate to variation
      await page.click('[data-testid="history-navigator"]')
      await page.click(`[data-testid="variation-${variationId}"]`)
      
      // Verify we're at the correct variation
      const currentId = await page.getAttribute('[data-testid="current-variation"]', 'data-variation-id')
      expect(currentId).toBe(variationId)
      
      // Verify canvas state matches stored data
      const currentCanvasState = await page.evaluate(() => {
        return (window as any).vyb?.canvasManager?.exportState() || {}
      })
      
      const storedCanvasState = (variationData as any).canvasState
      
      // Verify key canvas properties preserved
      expect(currentCanvasState.layers?.length).toBe(storedCanvasState.layers?.length)
      expect(currentCanvasState.deviceType).toBe(storedCanvasState.deviceType)
      
      // Verify layer content preserved
      if (currentCanvasState.layers && storedCanvasState.layers) {
        for (let i = 0; i < currentCanvasState.layers.length; i++) {
          const currentLayer = currentCanvasState.layers[i]
          const storedLayer = storedCanvasState.layers[i]
          
          expect(currentLayer.type).toBe(storedLayer.type)
          expect(currentLayer.id).toBe(storedLayer.id)
          
          // Verify content based on layer type
          if (currentLayer.type === 'text') {
            expect(currentLayer.content.text).toBe(storedLayer.content.text)
          } else if (currentLayer.type === 'image') {
            expect(currentLayer.content.src).toBe(storedLayer.content.src)
          }
        }
      }
    }
  })

  test('should maintain DAG acyclic property', async () => {
    await createComplexBranchingHistory(page)
    
    // Verify DAG is acyclic
    const isAcyclic = await page.evaluate(() => {
      return (window as any).vyb?.historyManager?.verifyAcyclicProperty() !== false
    })
    expect(isAcyclic).toBe(true)
    
    // Test topological sorting
    const topologicalOrder = await page.evaluate(() => {
      return (window as any).vyb?.historyManager?.getTopologicalSort() || []
    })
    
    expect(topologicalOrder).toBeDefined()
    expect(topologicalOrder.length).toBeGreaterThan(0)
    expect(topologicalOrder[0]).toBe('root') // Root should be first
    
    // Verify each variation appears after its parent
    const allVariations = await page.evaluate(() => {
      return (window as any).vyb?.historyManager?.getAllVariations() || {}
    })
    
    for (const [variationId, variationData] of Object.entries(allVariations)) {
      const parentId = (variationData as any).parentId
      if (parentId && parentId !== 'root') {
        const parentIndex = topologicalOrder.indexOf(parentId)
        const childIndex = topologicalOrder.indexOf(variationId)
        expect(parentIndex).toBeLessThan(childIndex)
      }
    }
  })

  test('should handle memory usage with deep history', async () => {
    // Monitor initial memory usage
    const initialMemory = await page.evaluate(() => {
      return (performance as any).memory?.usedJSHeapSize || 0
    })
    
    // Create deep branching history (50+ variations)
    for (let i = 0; i < 50; i++) {
      await page.click('[data-testid="add-text-layer"]')
      await page.fill('[data-testid="text-input"]', `Deep History Text ${i}`)
      await page.click('[data-testid="confirm-text"]')
      
      await page.click('[data-testid="save-variation"]')
      await page.fill('[data-testid="variation-name"]', `Deep Variation ${i}`)
      await page.click('[data-testid="save-confirm"]')
      
      // Every 10 variations, create a branch
      if (i % 10 === 9) {
        const parentIndex = Math.floor(Math.random() * i)
        const variations = await page.evaluate(() => {
          const mgr = (window as any).vyb?.historyManager
          return mgr ? Object.keys(mgr.getAllVariations()) : []
        })
        
        if (variations.length > parentIndex) {
          await page.click('[data-testid="history-navigator"]')
          await page.click(`[data-testid="variation-${variations[parentIndex]}"]`)
        }
      }
    }
    
    // Check final memory usage
    const finalMemory = await page.evaluate(() => {
      return (performance as any).memory?.usedJSHeapSize || 0
    })
    
    const memoryIncrease = finalMemory - initialMemory
    const mbIncrease = memoryIncrease / (1024 * 1024)
    
    // Should not exceed 100MB for 50+ variations
    expect(mbIncrease).toBeLessThan(100)
    
    // Verify history navigation still works efficiently
    const navigationStartTime = Date.now()
    
    // Navigate through 10 random variations
    const variations = await page.evaluate(() => {
      const mgr = (window as any).vyb?.historyManager
      return mgr ? Object.keys(mgr.getAllVariations()).slice(0, 10) : []
    })
    
    for (const variationId of variations) {
      await page.click('[data-testid="history-navigator"]')
      await page.click(`[data-testid="variation-${variationId}"]`)
      await page.waitForTimeout(50) // Small delay for navigation
    }
    
    const navigationEndTime = Date.now()
    const averageNavigationTime = (navigationEndTime - navigationStartTime) / variations.length
    
    // Navigation should remain fast even with deep history
    expect(averageNavigationTime).toBeLessThan(200) // <200ms per navigation
  })

  test('should export and import complete history tree', async () => {
    await createComplexBranchingHistory(page)
    
    // Export complete history
    await page.click('[data-testid="export-history"]')
    const exportedHistory = await page.evaluate(() => {
      return window.localStorage.getItem('exported-history-data')
    })
    
    expect(exportedHistory).toBeDefined()
    const historyData = JSON.parse(exportedHistory!)
    
    // Verify export contains all necessary data
    expect(historyData.variations).toBeDefined()
    expect(historyData.dagStructure).toBeDefined()
    expect(historyData.metadata).toBeDefined()
    
    // Clear current history
    await page.evaluate(() => {
      (window as any).vyb?.historyManager?.clearAllHistory()
    })
    
    // Verify history is cleared
    const clearedVariations = await page.evaluate(() => {
      const mgr = (window as any).vyb?.historyManager
      return mgr ? Object.keys(mgr.getAllVariations()).length : 0
    })
    expect(clearedVariations).toBe(1) // Only root should remain
    
    // Import history
    await page.click('[data-testid="import-history"]')
    await page.setInputFiles('[data-testid="history-file-input"]', {
      name: 'test-history.json',
      mimeType: 'application/json',
      buffer: Buffer.from(exportedHistory)
    })
    
    await page.waitForSelector('[data-testid="import-complete"]')
    
    // Verify import restored all variations
    const restoredVariations = await page.evaluate(() => {
      const mgr = (window as any).vyb?.historyManager
      return mgr ? mgr.getAllVariations() : {}
    })
    
    expect(Object.keys(restoredVariations)).toHaveLength(Object.keys(historyData.variations).length)
    
    // Verify DAG structure maintained
    const restoredDAG = await page.evaluate(() => {
      return (window as any).vyb?.historyManager?.getDAGStructure() || {}
    })
    
    expect(Object.keys(restoredDAG)).toHaveLength(Object.keys(historyData.dagStructure).length)
  })
})

// Helper functions
async function createLinearHistory(page: Page) {
  // Root → User Edit 1 → User Edit 2 → AI Suggestion 1
  await page.click('[data-testid="add-text-layer"]')
  await page.fill('[data-testid="text-input"]', 'Initial Text')
  await page.click('[data-testid="confirm-text"]')
  await page.click('[data-testid="save-variation"]')
  await page.fill('[data-testid="variation-name"]', 'User Edit 1')
  await page.click('[data-testid="save-confirm"]')
  
  await page.click('[data-testid="text-layer"]')
  await page.fill('[data-testid="color-input"]', '#FF5733')
  await page.click('[data-testid="apply-color"]')
  await page.click('[data-testid="save-variation"]')
  await page.fill('[data-testid="variation-name"]', 'User Edit 2')
  await page.click('[data-testid="save-confirm"]')
  
  await page.click('[data-testid="generate-ai-suggestions"]')
  await page.waitForSelector('[data-testid="ai-suggestions-ready"]', { timeout: 10000 })
  await page.click('[data-testid="ai-suggestion"]:first-child [data-testid="accept-suggestion"]')
}

async function createComplexBranchingHistory(page: Page) {
  // Create a more complex branching structure for comprehensive testing
  await createLinearHistory(page)
  
  // Add additional branches and variations
  const historyData = await page.evaluate(() => {
    return (window as any).vyb?.historyManager?.getAllVariations() || {}
  })
  
  // Create 2 more branches from different points
  const variationIds = Object.keys(historyData).filter(id => id !== 'root')
  
  for (let i = 0; i < Math.min(2, variationIds.length); i++) {
    const branchPointId = variationIds[i]
    
    await page.click('[data-testid="history-navigator"]')
    await page.click(`[data-testid="variation-${branchPointId}"]`)
    
    await page.click('[data-testid="add-shape-layer"]')
    await page.click('[data-testid="shape-rectangle"]')
    await page.click('[data-testid="confirm-shape"]')
    
    await page.click('[data-testid="save-variation"]')
    await page.fill('[data-testid="variation-name"]', `Branch ${i + 2}`)
    await page.click('[data-testid="save-confirm"]')
  }
}
import { describe, it, expect } from 'vitest'
import { GestureNavigation } from '../../../src/entities/GestureNavigation'
import { ScrollDirection, TransitionState } from '../../../src/types'

describe('GestureNavigation Entity', () => {
  describe('Creation and State Management', () => {
    it('should create GestureNavigation with initial state', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'variation-123',
        navigationHistory: ['variation-root', 'variation-123'],
        scrollVelocity: 0,
        direction: ScrollDirection.IDLE,
        transitionState: TransitionState.IDLE
      })

      expect(navigation.currentVariationId).toBe('variation-123')
      expect(navigation.navigationHistory).toHaveLength(2)
      expect(navigation.scrollVelocity).toBe(0)
      expect(navigation.direction).toBe(ScrollDirection.IDLE)
      expect(navigation.transitionState).toBe(TransitionState.IDLE)
    })

    it('should validate current variation ID exists', () => {
      expect(() => {
        new GestureNavigation({
          currentVariationId: '', // Invalid empty variation ID
          navigationHistory: [],
          scrollVelocity: 0,
          direction: ScrollDirection.IDLE,
          transitionState: TransitionState.IDLE
        })
      }).toThrow('Current variation ID must be valid')
    })

    it('should maintain navigation history stack', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'variation-current',
        navigationHistory: ['var-1', 'var-2', 'var-3'],
        scrollVelocity: 0,
        direction: ScrollDirection.IDLE,
        transitionState: TransitionState.IDLE
      })

      // Test history navigation
      navigation.navigateBack()
      expect(navigation.currentVariationId).toBe('var-3')
      expect(navigation.navigationHistory).toHaveLength(2)
    })
  })

  describe('State Transitions', () => {
    it('should handle idle → scrolling transition', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'test-variation',
        navigationHistory: ['test-variation'],
        scrollVelocity: 0,
        direction: ScrollDirection.IDLE,
        transitionState: TransitionState.IDLE
      })

      // Start scrolling gesture
      navigation.startScrolling(ScrollDirection.UP, 150)
      
      expect(navigation.transitionState).toBe(TransitionState.SCROLLING)
      expect(navigation.direction).toBe(ScrollDirection.UP)
      expect(navigation.scrollVelocity).toBe(150)
    })

    it('should handle scrolling → animating transition', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'test-variation',
        navigationHistory: ['test-variation'],
        scrollVelocity: 200,
        direction: ScrollDirection.DOWN,
        transitionState: TransitionState.SCROLLING
      })

      // End gesture with momentum
      navigation.endScrolling()
      
      expect(navigation.transitionState).toBe(TransitionState.ANIMATING)
      expect(navigation.scrollVelocity).toBeGreaterThan(0) // Should preserve momentum
    })

    it('should handle animating → idle transition', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'test-variation',
        navigationHistory: ['test-variation'],
        scrollVelocity: 50,
        direction: ScrollDirection.DOWN,
        transitionState: TransitionState.ANIMATING
      })

      // Complete animation
      navigation.completeAnimation()
      
      expect(navigation.transitionState).toBe(TransitionState.IDLE)
      expect(navigation.scrollVelocity).toBe(0)
      expect(navigation.direction).toBe(ScrollDirection.IDLE)
    })

    it('should prevent invalid state transitions', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'test-variation',
        navigationHistory: ['test-variation'],
        scrollVelocity: 0,
        direction: ScrollDirection.IDLE,
        transitionState: TransitionState.IDLE
      })

      // Cannot go directly from idle to animating
      expect(() => {
        navigation.transitionToAnimating()
      }).toThrow('Invalid state transition from IDLE to ANIMATING')
    })
  })

  describe('Scroll Physics', () => {
    it('should calculate velocity with proper damping', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'physics-test',
        navigationHistory: ['physics-test'],
        scrollVelocity: 300, // High initial velocity
        direction: ScrollDirection.UP,
        transitionState: TransitionState.ANIMATING
      })

      // Apply physics damping over time
      navigation.updatePhysics(16) // 16ms frame (60fps)
      
      expect(navigation.scrollVelocity).toBeLessThan(300)
      expect(navigation.scrollVelocity).toBeGreaterThan(0)
    })

    it('should handle velocity thresholds for navigation triggers', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'threshold-test',
        navigationHistory: ['var-1', 'threshold-test'],
        scrollVelocity: 0,
        direction: ScrollDirection.IDLE,
        transitionState: TransitionState.IDLE
      })

      // High velocity should trigger navigation
      navigation.startScrolling(ScrollDirection.UP, 500)
      
      expect(navigation.shouldTriggerNavigation()).toBe(true)
      
      // Low velocity should not trigger navigation
      navigation.startScrolling(ScrollDirection.UP, 50)
      
      expect(navigation.shouldTriggerNavigation()).toBe(false)
    })

    it('should respect momentum conservation during transitions', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'momentum-test',
        navigationHistory: ['momentum-test'],
        scrollVelocity: 250,
        direction: ScrollDirection.DOWN,
        transitionState: TransitionState.SCROLLING
      })

      const initialMomentum = navigation.calculateMomentum()
      
      // End scrolling - momentum should be preserved initially
      navigation.endScrolling()
      const postTransitionMomentum = navigation.calculateMomentum()
      
      expect(postTransitionMomentum).toBeCloseTo(initialMomentum, 1)
    })
  })

  describe('Navigation History Management', () => {
    it('should maintain history stack with proper limits', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'history-test',
        navigationHistory: [],
        scrollVelocity: 0,
        direction: ScrollDirection.IDLE,
        transitionState: TransitionState.IDLE
      })

      // Add many items to history
      for (let i = 0; i < 15; i++) {
        navigation.navigateToVariation(`var-${i}`)
      }
      
      // History should be limited to prevent memory issues
      expect(navigation.navigationHistory.length).toBeLessThanOrEqual(10)
      expect(navigation.currentVariationId).toBe('var-14')
    })

    it('should support forward and backward navigation', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'nav-3',
        navigationHistory: ['nav-1', 'nav-2', 'nav-3'],
        scrollVelocity: 0,
        direction: ScrollDirection.IDLE,
        transitionState: TransitionState.IDLE
      })

      // Navigate backward
      navigation.navigateBack()
      expect(navigation.currentVariationId).toBe('nav-2')
      
      // Navigate forward (if implementation supports it)
      if (navigation.canNavigateForward()) {
        navigation.navigateForward()
        expect(navigation.currentVariationId).toBe('nav-3')
      }
    })
  })

  describe('Gesture Recognition', () => {
    it('should recognize scroll up as previous variation intent', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'gesture-test',
        navigationHistory: ['prev-var', 'gesture-test'],
        scrollVelocity: 0,
        direction: ScrollDirection.IDLE,
        transitionState: TransitionState.IDLE
      })

      navigation.startScrolling(ScrollDirection.UP, 200)
      
      expect(navigation.getNavigationIntent()).toBe('previous')
      expect(navigation.direction).toBe(ScrollDirection.UP)
    })

    it('should recognize scroll down as next variation intent', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'gesture-test',
        navigationHistory: ['gesture-test'],
        scrollVelocity: 0,
        direction: ScrollDirection.IDLE,
        transitionState: TransitionState.IDLE
      })

      navigation.startScrolling(ScrollDirection.DOWN, 200)
      
      expect(navigation.getNavigationIntent()).toBe('next')
      expect(navigation.direction).toBe(ScrollDirection.DOWN)
    })

    it('should handle gesture cancellation', () => {
      const navigation = new GestureNavigation({
        currentVariationId: 'cancel-test',
        navigationHistory: ['cancel-test'],
        scrollVelocity: 150,
        direction: ScrollDirection.UP,
        transitionState: TransitionState.SCROLLING
      })

      // Cancel gesture mid-scroll
      navigation.cancelGesture()
      
      expect(navigation.transitionState).toBe(TransitionState.IDLE)
      expect(navigation.scrollVelocity).toBe(0)
      expect(navigation.direction).toBe(ScrollDirection.IDLE)
    })
  })
})
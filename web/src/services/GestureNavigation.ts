/**
 * GestureNavigation - State machine for gesture-based AI variation browsing
 * Implements T053: Web Gesture Navigation
 * Provides scroll physics, momentum tracking, and social media-like navigation
 */

import React, { useState, useEffect, useCallback, useRef } from 'react';
import { HistoryManager, HistoryNode } from './HistoryManager';

// MARK: - Navigation State Types

export enum NavigationState {
  IDLE = 'idle',
  SCROLLING = 'scrolling',
  MOMENTUM = 'momentum', 
  SNAPPING = 'snapping',
  TRANSITIONING = 'transitioning'
}

export enum ScrollDirection {
  NONE = 'none',
  UP = 'up',
  DOWN = 'down',
  LEFT = 'left',
  RIGHT = 'right'
}

export interface GestureState {
  currentState: NavigationState;
  scrollDirection: ScrollDirection;
  velocity: Vector2D;
  position: Vector2D;
  targetPosition: Vector2D;
  momentum: number;
  isDragging: boolean;
  startPosition: Vector2D;
  deltaPosition: Vector2D;
  timestamp: number;
}

export interface Vector2D {
  x: number;
  y: number;
}

export interface ScrollPhysics {
  friction: number;
  snapThreshold: number;
  momentumThreshold: number;
  maxVelocity: number;
  bounceBack: boolean;
  snapForce: number;
}

export interface NavigationEvent {
  type: 'variation_change' | 'branch_switch' | 'momentum_start' | 'momentum_end' | 'snap_complete' | 'gesture_start' | 'gesture_end' | 'variation_scroll';
  data: any;
  timestamp: number;
}

export interface VariationCard {
  node: HistoryNode;
  position: Vector2D;
  scale: number;
  opacity: number;
  zIndex: number;
  isActive: boolean;
  transitionState: 'entering' | 'active' | 'exiting' | 'idle';
}

// MARK: - Navigation Configuration

export const DEFAULT_PHYSICS: ScrollPhysics = {
  friction: 0.92,
  snapThreshold: 50,
  momentumThreshold: 0.1,
  maxVelocity: 2000,
  bounceBack: true,
  snapForce: 0.15
};

export const ANIMATION_CONFIG = {
  duration: 300,
  easing: 'cubic-bezier(0.4, 0, 0.2, 1)',
  staggerDelay: 50
};

// MARK: - Gesture Navigation Manager

export class GestureNavigationManager {
  private state: GestureState;
  private physics: ScrollPhysics;
  private historyManager: HistoryManager;
  private listeners: Set<(event: NavigationEvent) => void> = new Set();
  private animationFrame: number | null = null;
  private variations: VariationCard[] = [];
  private activeIndex: number = 0;

  constructor(historyManager: HistoryManager, physics: ScrollPhysics = DEFAULT_PHYSICS) {
    this.historyManager = historyManager;
    this.physics = physics;
    this.state = this.createInitialState();
    
    // Listen to history changes
    this.historyManager.addListener((historyState) => {
      this.updateVariations(historyState);
    });
  }

  // MARK: - Public API

  /**
   * Initialize gesture navigation with current history
   */
  initialize(): void {
    this.updateVariations(this.historyManager.getState());
    this.setState(NavigationState.IDLE);
  }

  /**
   * Handle touch/mouse start
   */
  handleStart(position: Vector2D): void {
    this.cancelMomentum();
    
    this.state = {
      ...this.state,
      currentState: NavigationState.SCROLLING,
      isDragging: true,
      startPosition: position,
      position: position,
      deltaPosition: { x: 0, y: 0 },
      velocity: { x: 0, y: 0 },
      timestamp: Date.now()
    };

    this.emit('gesture_start', { position });
  }

  /**
   * Handle touch/mouse move
   */
  handleMove(position: Vector2D): void {
    if (!this.state.isDragging) return;

    const deltaX = position.x - this.state.position.x;
    const deltaY = position.y - this.state.position.y;
    const now = Date.now();
    const deltaTime = Math.max(1, now - this.state.timestamp);

    // Calculate velocity
    const velocityX = (deltaX / deltaTime) * 1000; // pixels per second
    const velocityY = (deltaY / deltaTime) * 1000;

    // Determine scroll direction
    const direction = this.getScrollDirection(deltaX, deltaY);

    this.state = {
      ...this.state,
      position,
      deltaPosition: {
        x: position.x - this.state.startPosition.x,
        y: position.y - this.state.startPosition.y
      },
      velocity: { x: velocityX, y: velocityY },
      scrollDirection: direction,
      timestamp: now
    };

    // Update variation positions based on scroll
    this.updateVariationPositions();
    this.emit('variation_scroll', { position, delta: { x: deltaX, y: deltaY } });
  }

  /**
   * Handle touch/mouse end
   */
  handleEnd(): void {
    if (!this.state.isDragging) return;

    const { velocity } = this.state;
    const speed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);

    this.state = {
      ...this.state,
      isDragging: false
    };

    if (speed > this.physics.momentumThreshold) {
      this.startMomentum();
    } else {
      this.startSnapping();
    }

    this.emit('gesture_end', { velocity, speed });
  }

  /**
   * Navigate to next variation (programmatically)
   */
  navigateNext(): void {
    if (this.activeIndex < this.variations.length - 1) {
      this.navigateToIndex(this.activeIndex + 1);
    }
  }

  /**
   * Navigate to previous variation (programmatically)
   */
  navigatePrevious(): void {
    if (this.activeIndex > 0) {
      this.navigateToIndex(this.activeIndex - 1);
    }
  }

  /**
   * Navigate to specific variation index
   */
  navigateToIndex(index: number): void {
    if (index < 0 || index >= this.variations.length) return;

    const targetVariation = this.variations[index];
    if (!targetVariation) return;

    // Navigate history manager
    const result = this.historyManager.navigateToNode(targetVariation.node.id);
    
    if (result.success) {
      this.activeIndex = index;
      this.animateToVariation(targetVariation);
      this.emit('variation_change', { 
        from: this.variations[this.activeIndex]?.node, 
        to: targetVariation.node,
        index 
      });
    }
  }

  /**
   * Get current navigation state
   */
  getState(): Readonly<GestureState> {
    return { ...this.state };
  }

  /**
   * Get current variations layout
   */
  getVariations(): ReadonlyArray<VariationCard> {
    return [...this.variations];
  }

  /**
   * Get active variation
   */
  getActiveVariation(): VariationCard | null {
    return this.variations[this.activeIndex] || null;
  }

  // MARK: - Event Handling

  addEventListener(listener: (event: NavigationEvent) => void): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  // MARK: - Private Methods

  private createInitialState(): GestureState {
    return {
      currentState: NavigationState.IDLE,
      scrollDirection: ScrollDirection.NONE,
      velocity: { x: 0, y: 0 },
      position: { x: 0, y: 0 },
      targetPosition: { x: 0, y: 0 },
      momentum: 0,
      isDragging: false,
      startPosition: { x: 0, y: 0 },
      deltaPosition: { x: 0, y: 0 },
      timestamp: Date.now()
    };
  }

  private setState(newState: NavigationState): void {
    this.state = {
      ...this.state,
      currentState: newState
    };
  }

  private getScrollDirection(deltaX: number, deltaY: number): ScrollDirection {
    const threshold = 5;
    
    if (Math.abs(deltaX) > Math.abs(deltaY)) {
      return deltaX > threshold ? ScrollDirection.RIGHT : 
             deltaX < -threshold ? ScrollDirection.LEFT : ScrollDirection.NONE;
    } else {
      return deltaY > threshold ? ScrollDirection.DOWN : 
             deltaY < -threshold ? ScrollDirection.UP : ScrollDirection.NONE;
    }
  }

  private updateVariations(historyState: any): void {
    // Get all nodes and create variation cards
    const nodes = Array.from(historyState.nodes.values()) as HistoryNode[];
    const currentNodeId = historyState.currentNodeId;
    
    this.variations = nodes.map((node, index) => ({
      node,
      position: { x: index * 300, y: 0 }, // Horizontal layout
      scale: node.id === currentNodeId ? 1.0 : 0.8,
      opacity: node.id === currentNodeId ? 1.0 : 0.6,
      zIndex: node.id === currentNodeId ? 10 : 1,
      isActive: node.id === currentNodeId,
      transitionState: 'idle' as const
    }));

    // Find active index
    this.activeIndex = this.variations.findIndex(v => v.isActive);
    if (this.activeIndex === -1) this.activeIndex = 0;
  }

  private updateVariationPositions(): void {
    const { deltaPosition } = this.state;
    
    this.variations.forEach((variation, index) => {
      const baseX = index * 300;
      variation.position = {
        x: baseX + deltaPosition.x,
        y: deltaPosition.y * 0.1 // Subtle vertical movement
      };
      
      // Update scale and opacity based on distance from center
      const distanceFromCenter = Math.abs(variation.position.x);
      const normalizedDistance = Math.min(distanceFromCenter / 300, 1);
      
      variation.scale = 1.0 - (normalizedDistance * 0.3);
      variation.opacity = 1.0 - (normalizedDistance * 0.5);
    });
  }

  private startMomentum(): void {
    this.setState(NavigationState.MOMENTUM);
    this.animateMomentum();
    this.emit('momentum_start', { velocity: this.state.velocity });
  }

  private animateMomentum(): void {
    const animate = () => {
      if (this.state.currentState !== NavigationState.MOMENTUM) return;

      // Apply friction to velocity
      this.state.velocity.x *= this.physics.friction;
      this.state.velocity.y *= this.physics.friction;

      // Update position
      this.state.position.x += this.state.velocity.x * 0.016; // 60fps assumption
      this.state.position.y += this.state.velocity.y * 0.016;

      // Update delta position
      this.state.deltaPosition.x = this.state.position.x - this.state.startPosition.x;
      this.state.deltaPosition.y = this.state.position.y - this.state.startPosition.y;

      // Update variation positions
      this.updateVariationPositions();

      // Check if momentum should stop
      const speed = Math.sqrt(
        this.state.velocity.x * this.state.velocity.x + 
        this.state.velocity.y * this.state.velocity.y
      );

      if (speed < this.physics.momentumThreshold) {
        this.setState(NavigationState.SNAPPING);
        this.startSnapping();
        this.emit('momentum_end', { finalVelocity: this.state.velocity });
        return;
      }

      this.animationFrame = requestAnimationFrame(animate);
    };

    this.animationFrame = requestAnimationFrame(animate);
  }

  private startSnapping(): void {
    this.setState(NavigationState.SNAPPING);
    
    // Find nearest variation to snap to
    const targetIndex = this.findNearestVariation();
    
    if (targetIndex !== this.activeIndex) {
      this.navigateToIndex(targetIndex);
    } else {
      // Snap back to current position
      this.snapToCurrent();
    }
  }

  private findNearestVariation(): number {
    const { deltaPosition } = this.state;
    const displacement = -deltaPosition.x; // Invert for natural scrolling
    const threshold = this.physics.snapThreshold;
    
    if (displacement > threshold && this.activeIndex > 0) {
      return this.activeIndex - 1; // Scroll right shows previous
    } else if (displacement < -threshold && this.activeIndex < this.variations.length - 1) {
      return this.activeIndex + 1; // Scroll left shows next
    }
    
    return this.activeIndex;
  }

  private snapToCurrent(): void {
    const currentVariation = this.variations[this.activeIndex];
    if (!currentVariation) return;

    this.animateToVariation(currentVariation);
  }

  private animateToVariation(targetVariation: VariationCard): void {
    this.setState(NavigationState.TRANSITIONING);
    
    const startTime = Date.now();
    const startDelta = { ...this.state.deltaPosition };
    const targetDelta = { x: 0, y: 0 }; // Snap back to center
    
    const animate = () => {
      const elapsed = Date.now() - startTime;
      const progress = Math.min(elapsed / ANIMATION_CONFIG.duration, 1);
      
      // Easing function (ease-out)
      const eased = 1 - Math.pow(1 - progress, 3);
      
      // Interpolate position
      this.state.deltaPosition.x = startDelta.x + (targetDelta.x - startDelta.x) * eased;
      this.state.deltaPosition.y = startDelta.y + (targetDelta.y - startDelta.y) * eased;
      
      // Update variation positions
      this.updateVariationPositions();
      
      if (progress < 1) {
        this.animationFrame = requestAnimationFrame(animate);
      } else {
        this.setState(NavigationState.IDLE);
        this.emit('snap_complete', { targetVariation });
      }
    };
    
    this.animationFrame = requestAnimationFrame(animate);
  }

  private cancelMomentum(): void {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
      this.animationFrame = null;
    }
  }

  private emit(type: NavigationEvent['type'], data: any): void {
    const event: NavigationEvent = {
      type,
      data,
      timestamp: Date.now()
    };

    this.listeners.forEach(listener => {
      try {
        listener(event);
      } catch (error) {
        console.error('Error in navigation event listener:', error);
      }
    });
  }
}

// MARK: - React Hook Integration

export interface UseGestureNavigationOptions {
  physics?: Partial<ScrollPhysics>;
  autoInitialize?: boolean;
}

export function useGestureNavigation(
  historyManager: HistoryManager,
  options: UseGestureNavigationOptions = {}
) {
  const [manager] = useState(() => {
    const physics = { ...DEFAULT_PHYSICS, ...options.physics };
    return new GestureNavigationManager(historyManager, physics);
  });

  const [navigationState, setNavigationState] = useState<GestureState>(manager.getState());
  const [variations, setVariations] = useState<VariationCard[]>([...manager.getVariations()]);
  const [activeVariation, setActiveVariation] = useState<VariationCard | null>(manager.getActiveVariation());

  const eventListeners = useRef<Set<(event: NavigationEvent) => void>>(new Set());

  // Initialize on mount
  useEffect(() => {
    if (options.autoInitialize !== false) {
      manager.initialize();
    }
  }, [manager, options.autoInitialize]);

  // Subscribe to navigation events
  useEffect(() => {
    const handleNavigationEvent = (event: NavigationEvent) => {
      // Update local state based on events
      switch (event.type) {
        case 'variation_change':
          setVariations([...manager.getVariations()]);
          setActiveVariation(manager.getActiveVariation());
          break;
        case 'momentum_start':
        case 'momentum_end':
        case 'snap_complete':
          setNavigationState(manager.getState());
          break;
      }

      // Notify external listeners
      eventListeners.current.forEach(listener => listener(event));
    };

    const unsubscribe = manager.addEventListener(handleNavigationEvent);
    return unsubscribe;
  }, [manager]);

  // Gesture handlers
  const handleTouchStart = useCallback((event: React.TouchEvent) => {
    if (event.touches.length === 1) {
      const touch = event.touches[0];
      manager.handleStart({ x: touch.clientX, y: touch.clientY });
    }
  }, [manager]);

  const handleTouchMove = useCallback((event: React.TouchEvent) => {
    if (event.touches.length === 1) {
      const touch = event.touches[0];
      manager.handleMove({ x: touch.clientX, y: touch.clientY });
      event.preventDefault(); // Prevent scrolling
    }
  }, [manager]);

  const handleTouchEnd = useCallback(() => {
    manager.handleEnd();
  }, [manager]);

  // Mouse handlers for desktop
  const handleMouseDown = useCallback((event: React.MouseEvent) => {
    manager.handleStart({ x: event.clientX, y: event.clientY });
    event.preventDefault();
  }, [manager]);

  const handleMouseMove = useCallback((event: React.MouseEvent) => {
    if (navigationState.isDragging) {
      manager.handleMove({ x: event.clientX, y: event.clientY });
    }
  }, [manager, navigationState.isDragging]);

  const handleMouseUp = useCallback(() => {
    manager.handleEnd();
  }, [manager]);

  // Navigation actions
  const navigateNext = useCallback(() => {
    manager.navigateNext();
  }, [manager]);

  const navigatePrevious = useCallback(() => {
    manager.navigatePrevious();
  }, [manager]);

  const navigateToIndex = useCallback((index: number) => {
    manager.navigateToIndex(index);
  }, [manager]);

  // Event listener management
  const addEventListener = useCallback((listener: (event: NavigationEvent) => void) => {
    eventListeners.current.add(listener);
    return () => eventListeners.current.delete(listener);
  }, []);

  return {
    // State
    navigationState,
    variations,
    activeVariation,
    
    // Gesture handlers
    gestureHandlers: {
      onTouchStart: handleTouchStart,
      onTouchMove: handleTouchMove,
      onTouchEnd: handleTouchEnd,
      onMouseDown: handleMouseDown,
      onMouseMove: handleMouseMove,
      onMouseUp: handleMouseUp,
    },
    
    // Actions
    navigateNext,
    navigatePrevious,
    navigateToIndex,
    initialize: manager.initialize.bind(manager),
    
    // Utils
    addEventListener,
    manager
  };
}

// MARK: - Gesture Navigation Component

export interface GestureNavigationProps {
  historyManager: HistoryManager;
  children: (props: {
    variations: VariationCard[];
    activeVariation: VariationCard | null;
    navigationState: GestureState;
    gestureHandlers: any;
  }) => React.ReactNode;
  physics?: Partial<ScrollPhysics>;
  className?: string;
}

export const GestureNavigation: React.FC<GestureNavigationProps> = ({
  historyManager,
  children,
  physics,
  className = ''
}) => {
  const navigation = useGestureNavigation(historyManager, { physics });

  return React.createElement('div', {
    className: `gesture-navigation ${className}`,
    ...navigation.gestureHandlers,
    style: {
      touchAction: 'none',
      userSelect: 'none'
    }
  }, children({
    variations: navigation.variations,
    activeVariation: navigation.activeVariation,
    navigationState: navigation.navigationState,
    gestureHandlers: navigation.gestureHandlers
  }));
};
/**
 * HistoryManager - DAG-based history management for design variations
 * Implements T052: Web DAG History Manager
 * Provides immutable state management, branching operations, and version control
 */

import { DesignCanvas } from '../models/DesignCanvas';

// MARK: - History Node Types

export interface HistoryNode {
  id: string;
  parentId: string | null;
  canvasState: DesignCanvas;
  timestamp: Date;
  metadata: HistoryMetadata;
  children: string[];
  branchName?: string;
}

export interface HistoryMetadata {
  source: 'user' | 'ai' | 'import' | 'fork';
  description?: string;
  tags?: string[];
  author?: string;
  confidence?: number;
  aiPrompt?: string;
}

export interface HistoryBranch {
  id: string;
  name: string;
  baseNodeId: string;
  nodes: string[];
  isActive: boolean;
  metadata: BranchMetadata;
}

export interface BranchMetadata {
  createdAt: Date;
  description?: string;
  color?: string;
  isProtected?: boolean;
}

export interface HistoryState {
  nodes: Map<string, HistoryNode>;
  branches: Map<string, HistoryBranch>;
  currentNodeId: string | null;
  currentBranchId: string | null;
  rootNodeId: string | null;
}

export interface HistoryStats {
  totalNodes: number;
  totalBranches: number;
  maxDepth: number;
  aiGeneratedNodes: number;
  userModifiedNodes: number;
}

// MARK: - Navigation Types

export interface NavigationResult {
  success: boolean;
  previousNode: HistoryNode | null;
  currentNode: HistoryNode | null;
  error?: string;
}

export interface ComparisonResult {
  nodeA: HistoryNode;
  nodeB: HistoryNode;
  changes: ChangeDetail[];
  similarity: number;
}

export interface ChangeDetail {
  type: 'layer_added' | 'layer_removed' | 'layer_modified' | 'canvas_resized' | 'metadata_changed';
  path: string;
  oldValue?: any;
  newValue?: any;
  layerId?: string;
}

// MARK: - Error Types

export class HistoryError extends Error {
  constructor(message: string, public code: string) {
    super(message);
    this.name = 'HistoryError';
  }
}

// MARK: - History Manager Class

export class HistoryManager {
  private state: HistoryState;
  private maxHistorySize: number;
  private listeners: Set<(state: HistoryState) => void> = new Set();

  constructor(maxHistorySize: number = 1000) {
    this.maxHistorySize = maxHistorySize;
    this.state = this.createEmptyState();
  }

  // MARK: - Public API

  /**
   * Initialize history with a root canvas
   */
  initialize(canvas: DesignCanvas, metadata?: Partial<HistoryMetadata>): HistoryNode {
    const rootNode: HistoryNode = {
      id: this.generateId(),
      parentId: null,
      canvasState: this.deepClone(canvas),
      timestamp: new Date(),
      metadata: {
        source: 'user',
        description: 'Initial canvas',
        ...metadata
      },
      children: [],
      branchName: 'main'
    };

    // Create main branch
    const mainBranch: HistoryBranch = {
      id: this.generateId(),
      name: 'main',
      baseNodeId: rootNode.id,
      nodes: [rootNode.id],
      isActive: true,
      metadata: {
        createdAt: new Date(),
        description: 'Main design branch',
        color: '#3B82F6',
        isProtected: false
      }
    };

    this.state = {
      nodes: new Map([[rootNode.id, rootNode]]),
      branches: new Map([[mainBranch.id, mainBranch]]),
      currentNodeId: rootNode.id,
      currentBranchId: mainBranch.id,
      rootNodeId: rootNode.id
    };

    this.notifyListeners();
    return rootNode;
  }

  /**
   * Add a new node to the history
   */
  addNode(
    canvas: DesignCanvas,
    parentId?: string,
    metadata?: Partial<HistoryMetadata>
  ): HistoryNode {
    const actualParentId = parentId || this.state.currentNodeId;
    
    if (!actualParentId) {
      throw new HistoryError('No parent node available. Initialize history first.', 'NO_PARENT');
    }

    const parent = this.state.nodes.get(actualParentId);
    if (!parent) {
      throw new HistoryError(`Parent node ${actualParentId} not found`, 'PARENT_NOT_FOUND');
    }

    // Check history size limit
    if (this.state.nodes.size >= this.maxHistorySize) {
      this.pruneOldestNodes();
    }

    const newNode: HistoryNode = {
      id: this.generateId(),
      parentId: actualParentId,
      canvasState: this.deepClone(canvas),
      timestamp: new Date(),
      metadata: {
        source: 'user',
        ...metadata
      },
      children: [],
      branchName: parent.branchName
    };

    // Update parent's children
    const updatedParent = { ...parent };
    updatedParent.children.push(newNode.id);
    
    // Update state
    this.state.nodes.set(actualParentId, updatedParent);
    this.state.nodes.set(newNode.id, newNode);
    this.state.currentNodeId = newNode.id;

    // Update current branch
    if (this.state.currentBranchId) {
      const currentBranch = this.state.branches.get(this.state.currentBranchId);
      if (currentBranch) {
        const updatedBranch = { ...currentBranch };
        updatedBranch.nodes.push(newNode.id);
        this.state.branches.set(this.state.currentBranchId, updatedBranch);
      }
    }

    this.notifyListeners();
    return newNode;
  }

  /**
   * Create a new branch from the current node
   */
  createBranch(
    name: string,
    baseNodeId?: string,
    metadata?: Partial<BranchMetadata>
  ): HistoryBranch {
    const actualBaseNodeId = baseNodeId || this.state.currentNodeId;
    
    if (!actualBaseNodeId) {
      throw new HistoryError('No base node available for branching', 'NO_BASE_NODE');
    }

    const baseNode = this.state.nodes.get(actualBaseNodeId);
    if (!baseNode) {
      throw new HistoryError(`Base node ${actualBaseNodeId} not found`, 'BASE_NODE_NOT_FOUND');
    }

    // Check if branch name already exists
    const existingBranch = Array.from(this.state.branches.values())
      .find(branch => branch.name === name);
    
    if (existingBranch) {
      throw new HistoryError(`Branch '${name}' already exists`, 'BRANCH_EXISTS');
    }

    const newBranch: HistoryBranch = {
      id: this.generateId(),
      name,
      baseNodeId: actualBaseNodeId,
      nodes: [actualBaseNodeId],
      isActive: false,
      metadata: {
        createdAt: new Date(),
        color: this.generateBranchColor(),
        isProtected: false,
        ...metadata
      }
    };

    this.state.branches.set(newBranch.id, newBranch);
    this.notifyListeners();
    
    return newBranch;
  }

  /**
   * Switch to a different branch
   */
  switchBranch(branchId: string): NavigationResult {
    const branch = this.state.branches.get(branchId);
    if (!branch) {
      return {
        success: false,
        previousNode: this.getCurrentNode(),
        currentNode: null,
        error: `Branch ${branchId} not found`
      };
    }

    const previousNode = this.getCurrentNode();

    // Deactivate current branch
    if (this.state.currentBranchId) {
      const currentBranch = this.state.branches.get(this.state.currentBranchId);
      if (currentBranch) {
        this.state.branches.set(this.state.currentBranchId, { ...currentBranch, isActive: false });
      }
    }

    // Activate new branch and move to its latest node
    const updatedBranch = { ...branch, isActive: true };
    this.state.branches.set(branchId, updatedBranch);
    this.state.currentBranchId = branchId;
    
    // Move to the latest node in the branch
    const latestNodeId = branch.nodes[branch.nodes.length - 1];
    this.state.currentNodeId = latestNodeId;

    const currentNode = this.getCurrentNode();
    this.notifyListeners();

    return {
      success: true,
      previousNode,
      currentNode,
    };
  }

  /**
   * Navigate to a specific node
   */
  navigateToNode(nodeId: string): NavigationResult {
    const previousNode = this.getCurrentNode();
    const targetNode = this.state.nodes.get(nodeId);
    
    if (!targetNode) {
      return {
        success: false,
        previousNode,
        currentNode: previousNode,
        error: `Node ${nodeId} not found`
      };
    }

    this.state.currentNodeId = nodeId;

    // Update current branch to match the node's branch
    const nodeBranchId = this.findNodeBranch(nodeId);
    if (nodeBranchId && nodeBranchId !== this.state.currentBranchId) {
      this.switchBranch(nodeBranchId);
    }

    this.notifyListeners();

    return {
      success: true,
      previousNode,
      currentNode: targetNode,
    };
  }

  /**
   * Undo - navigate to parent node
   */
  undo(): NavigationResult {
    const currentNode = this.getCurrentNode();
    if (!currentNode || !currentNode.parentId) {
      return {
        success: false,
        previousNode: currentNode,
        currentNode,
        error: 'No parent node to undo to'
      };
    }

    return this.navigateToNode(currentNode.parentId);
  }

  /**
   * Redo - navigate to the first child node
   */
  redo(): NavigationResult {
    const currentNode = this.getCurrentNode();
    if (!currentNode || currentNode.children.length === 0) {
      return {
        success: false,
        previousNode: currentNode,
        currentNode,
        error: 'No child nodes to redo to'
      };
    }

    // Navigate to the first child (could be enhanced to remember the last path taken)
    return this.navigateToNode(currentNode.children[0]);
  }

  /**
   * Get path from root to a specific node
   */
  getPathToNode(nodeId: string): HistoryNode[] {
    const path: HistoryNode[] = [];
    let currentId: string | null = nodeId;

    while (currentId) {
      const node = this.state.nodes.get(currentId);
      if (!node) break;
      
      path.unshift(node);
      currentId = node.parentId;
    }

    return path;
  }

  /**
   * Compare two nodes and get detailed changes
   */
  compareNodes(nodeAId: string, nodeBId: string): ComparisonResult {
    const nodeA = this.state.nodes.get(nodeAId);
    const nodeB = this.state.nodes.get(nodeBId);

    if (!nodeA || !nodeB) {
      throw new HistoryError('One or both nodes not found for comparison', 'NODES_NOT_FOUND');
    }

    const changes = this.calculateChanges(nodeA.canvasState, nodeB.canvasState);
    const similarity = this.calculateSimilarity(changes);

    return {
      nodeA,
      nodeB,
      changes,
      similarity
    };
  }

  /**
   * Get all nodes that are descendants of a given node
   */
  getDescendants(nodeId: string): HistoryNode[] {
    const descendants: HistoryNode[] = [];
    const visited = new Set<string>();
    
    const traverse = (id: string) => {
      if (visited.has(id)) return;
      visited.add(id);
      
      const node = this.state.nodes.get(id);
      if (!node) return;
      
      node.children.forEach(childId => {
        const child = this.state.nodes.get(childId);
        if (child) {
          descendants.push(child);
          traverse(childId);
        }
      });
    };

    traverse(nodeId);
    return descendants;
  }

  /**
   * Get history statistics
   */
  getStats(): HistoryStats {
    const nodes = Array.from(this.state.nodes.values());
    
    return {
      totalNodes: nodes.length,
      totalBranches: this.state.branches.size,
      maxDepth: this.calculateMaxDepth(),
      aiGeneratedNodes: nodes.filter(n => n.metadata.source === 'ai').length,
      userModifiedNodes: nodes.filter(n => n.metadata.source === 'user').length
    };
  }

  // MARK: - Getters

  getCurrentNode(): HistoryNode | null {
    return this.state.currentNodeId ? this.state.nodes.get(this.state.currentNodeId) || null : null;
  }

  getCurrentBranch(): HistoryBranch | null {
    return this.state.currentBranchId ? this.state.branches.get(this.state.currentBranchId) || null : null;
  }

  getAllNodes(): HistoryNode[] {
    return Array.from(this.state.nodes.values());
  }

  getAllBranches(): HistoryBranch[] {
    return Array.from(this.state.branches.values());
  }

  getState(): Readonly<HistoryState> {
    return { ...this.state };
  }

  // MARK: - Event Handling

  addListener(listener: (state: HistoryState) => void): () => void {
    this.listeners.add(listener);
    
    // Return unsubscribe function
    return () => {
      this.listeners.delete(listener);
    };
  }

  // MARK: - Serialization

  /**
   * Export history to JSON
   */
  exportHistory(): string {
    const exportData = {
      nodes: Array.from(this.state.nodes.entries()),
      branches: Array.from(this.state.branches.entries()),
      currentNodeId: this.state.currentNodeId,
      currentBranchId: this.state.currentBranchId,
      rootNodeId: this.state.rootNodeId,
      version: '1.0',
      exportedAt: new Date().toISOString()
    };

    return JSON.stringify(exportData, null, 2);
  }

  /**
   * Import history from JSON
   */
  importHistory(jsonData: string): void {
    try {
      const data = JSON.parse(jsonData);
      
      if (data.version !== '1.0') {
        throw new HistoryError('Unsupported history version', 'VERSION_MISMATCH');
      }

      this.state = {
        nodes: new Map(data.nodes),
        branches: new Map(data.branches),
        currentNodeId: data.currentNodeId,
        currentBranchId: data.currentBranchId,
        rootNodeId: data.rootNodeId
      };

      this.notifyListeners();
    } catch (error) {
      throw new HistoryError('Failed to import history: ' + (error as Error).message, 'IMPORT_FAILED');
    }
  }

  // MARK: - Private Methods

  private createEmptyState(): HistoryState {
    return {
      nodes: new Map(),
      branches: new Map(),
      currentNodeId: null,
      currentBranchId: null,
      rootNodeId: null
    };
  }

  private generateId(): string {
    return crypto.randomUUID();
  }

  private deepClone<T>(obj: T): T {
    return JSON.parse(JSON.stringify(obj));
  }

  private notifyListeners(): void {
    this.listeners.forEach(listener => {
      try {
        listener({ ...this.state });
      } catch (error) {
        console.error('Error in history listener:', error);
      }
    });
  }

  private findNodeBranch(nodeId: string): string | null {
    for (const [branchId, branch] of this.state.branches) {
      if (branch.nodes.includes(nodeId)) {
        return branchId;
      }
    }
    return null;
  }

  private calculateMaxDepth(): number {
    if (!this.state.rootNodeId) return 0;
    
    const calculateDepth = (nodeId: string): number => {
      const node = this.state.nodes.get(nodeId);
      if (!node || node.children.length === 0) return 1;
      
      const childDepths = node.children.map(childId => calculateDepth(childId));
      return 1 + Math.max(...childDepths);
    };

    return calculateDepth(this.state.rootNodeId);
  }

  private calculateChanges(canvasA: DesignCanvas, canvasB: DesignCanvas): ChangeDetail[] {
    const changes: ChangeDetail[] = [];

    // Check canvas dimensions
    if (canvasA.dimensions.width !== canvasB.dimensions.width ||
        canvasA.dimensions.height !== canvasB.dimensions.height) {
      changes.push({
        type: 'canvas_resized',
        path: 'dimensions',
        oldValue: canvasA.dimensions,
        newValue: canvasB.dimensions
      });
    }

    // Check layers - simplified comparison
    const layersA = canvasA.layers;
    const layersB = canvasB.layers;

    // Find added/removed layers
    const layerIdsA = new Set(layersA.map(l => l.id));
    const layerIdsB = new Set(layersB.map(l => l.id));

    layerIdsB.forEach(id => {
      if (!layerIdsA.has(id)) {
        changes.push({
          type: 'layer_added',
          path: `layers.${id}`,
          newValue: layersB.find(l => l.id === id),
          layerId: id
        });
      }
    });

    layerIdsA.forEach(id => {
      if (!layerIdsB.has(id)) {
        changes.push({
          type: 'layer_removed',
          path: `layers.${id}`,
          oldValue: layersA.find(l => l.id === id),
          layerId: id
        });
      }
    });

    return changes;
  }

  private calculateSimilarity(changes: ChangeDetail[]): number {
    if (changes.length === 0) return 1.0;
    
    // Simple similarity calculation based on change count
    // Could be enhanced with more sophisticated comparison
    const maxChanges = 20; // Arbitrary max for normalization
    return Math.max(0, 1 - (changes.length / maxChanges));
  }

  private generateBranchColor(): string {
    const colors = [
      '#EF4444', '#F97316', '#F59E0B', '#EAB308',
      '#84CC16', '#22C55E', '#10B981', '#14B8A6',
      '#06B6D4', '#0EA5E9', '#3B82F6', '#6366F1',
      '#8B5CF6', '#A855F7', '#D946EF', '#EC4899'
    ];
    
    return colors[Math.floor(Math.random() * colors.length)];
  }

  private pruneOldestNodes(): void {
    // Simple pruning strategy - remove oldest non-branch nodes
    // In a production implementation, this would be more sophisticated
    const nodes = Array.from(this.state.nodes.values())
      .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
    
    const nodesToRemove = Math.floor(this.maxHistorySize * 0.1); // Remove 10%
    
    for (let i = 0; i < nodesToRemove && nodes.length > i; i++) {
      const node = nodes[i];
      
      // Don't remove root node or nodes that are branch bases
      if (node.id === this.state.rootNodeId) continue;
      
      const isBranchBase = Array.from(this.state.branches.values())
        .some(branch => branch.baseNodeId === node.id);
      
      if (isBranchBase) continue;
      
      this.state.nodes.delete(node.id);
    }
  }
}

// MARK: - React Hook Integration

import { useState, useEffect, useCallback } from 'react';

export interface UseHistoryManagerOptions {
  maxHistorySize?: number;
  autoSave?: boolean;
}

export function useHistoryManager(options: UseHistoryManagerOptions = {}) {
  const [manager] = useState(() => new HistoryManager(options.maxHistorySize));
  const [state, setState] = useState<HistoryState>(manager.getState());
  const [isInitialized, setIsInitialized] = useState(false);

  useEffect(() => {
    const unsubscribe = manager.addListener(setState);
    return unsubscribe;
  }, [manager]);

  const initialize = useCallback((canvas: DesignCanvas, metadata?: Partial<HistoryMetadata>) => {
    const rootNode = manager.initialize(canvas, metadata);
    setIsInitialized(true);
    return rootNode;
  }, [manager]);

  const addNode = useCallback((
    canvas: DesignCanvas,
    parentId?: string,
    metadata?: Partial<HistoryMetadata>
  ) => {
    return manager.addNode(canvas, parentId, metadata);
  }, [manager]);

  const createBranch = useCallback((
    name: string,
    baseNodeId?: string,
    metadata?: Partial<BranchMetadata>
  ) => {
    return manager.createBranch(name, baseNodeId, metadata);
  }, [manager]);

  const switchBranch = useCallback((branchId: string) => {
    return manager.switchBranch(branchId);
  }, [manager]);

  const navigateToNode = useCallback((nodeId: string) => {
    return manager.navigateToNode(nodeId);
  }, [manager]);

  const undo = useCallback(() => {
    return manager.undo();
  }, [manager]);

  const redo = useCallback(() => {
    return manager.redo();
  }, [manager]);

  return {
    manager,
    state,
    isInitialized,
    currentNode: manager.getCurrentNode(),
    currentBranch: manager.getCurrentBranch(),
    stats: manager.getStats(),
    // Actions
    initialize,
    addNode,
    createBranch,
    switchBranch,
    navigateToNode,
    undo,
    redo,
    // Utilities
    getPathToNode: manager.getPathToNode.bind(manager),
    compareNodes: manager.compareNodes.bind(manager),
    getDescendants: manager.getDescendants.bind(manager),
    exportHistory: manager.exportHistory.bind(manager),
    importHistory: manager.importHistory.bind(manager)
  };
}

// MARK: - Singleton Instance

export const historyManager = new HistoryManager();
import { fabric } from 'fabric';

// Interface for layer transform operations
export interface LayerTransform {
  x: number;
  y: number;
  rotation: number;
  scaleX: number;
  scaleY: number;
  opacity: number;
}

// Interface for manipulation constraints
export interface ManipulationConstraints {
  lockMovement?: boolean;
  lockRotation?: boolean;
  lockScaling?: boolean;
  lockSkewing?: boolean;
  maintainAspectRatio?: boolean;
  minScale?: number;
  maxScale?: number;
  snapToGrid?: boolean;
  gridSize?: number;
  snapToObjects?: boolean;
  snapDistance?: number;
}

// Interface for manipulation events
export interface ManipulationEvent {
  type: 'move' | 'scale' | 'rotate' | 'modified';
  target: fabric.Object;
  layerId: string;
  transform: LayerTransform;
  originalTransform?: LayerTransform;
}

// Interface for batch manipulation operations
export interface BatchOperation {
  type: 'move' | 'scale' | 'rotate' | 'duplicate' | 'delete';
  objects: fabric.Object[];
  parameters: Record<string, any>;
}

/**
 * CanvasManipulation service provides advanced object manipulation capabilities
 * Handles move, scale, rotate operations with constraints and snapping
 */
export class CanvasManipulation {
  private canvas: fabric.Canvas;
  private constraints: ManipulationConstraints = {};
  private snapLines: fabric.Line[] = [];
  private onManipulationCallback?: (event: ManipulationEvent) => void;

  constructor(canvas: fabric.Canvas) {
    this.canvas = canvas;
    this.setupEventHandlers();
    this.setupKeyboardHandlers();
  }

  /**
   * Set manipulation constraints for objects
   */
  setConstraints(constraints: ManipulationConstraints) {
    this.constraints = { ...this.constraints, ...constraints };
  }

  /**
   * Set callback for manipulation events
   */
  onManipulation(callback: (event: ManipulationEvent) => void) {
    this.onManipulationCallback = callback;
  }

  /**
   * Move object to specific position
   */
  moveObject(object: fabric.Object, x: number, y: number, animate = true) {
    if (this.constraints.lockMovement) return;

    const targetPosition = this.applySnapConstraints({ x, y }, object);
    
    if (animate) {
      object.animate({
        left: targetPosition.x,
        top: targetPosition.y
      }, {
        duration: 200,
        onChange: () => this.canvas.renderAll(),
        onComplete: () => this.emitManipulationEvent('move', object)
      });
    } else {
      object.set({
        left: targetPosition.x,
        top: targetPosition.y
      });
      this.canvas.renderAll();
      this.emitManipulationEvent('move', object);
    }
  }

  /**
   * Scale object with optional aspect ratio locking
   */
  scaleObject(object: fabric.Object, scaleX: number, scaleY?: number, animate = true) {
    if (this.constraints.lockScaling) return;

    // Maintain aspect ratio if specified or if only scaleX provided
    if (this.constraints.maintainAspectRatio || scaleY === undefined) {
      scaleY = scaleX;
    }

    // Apply scale constraints
    const constrainedScale = this.applyScaleConstraints({
      scaleX: scaleX!,
      scaleY: scaleY!
    });

    if (animate) {
      object.animate({
        scaleX: constrainedScale.scaleX,
        scaleY: constrainedScale.scaleY
      }, {
        duration: 200,
        onChange: () => this.canvas.renderAll(),
        onComplete: () => this.emitManipulationEvent('scale', object)
      });
    } else {
      object.set({
        scaleX: constrainedScale.scaleX,
        scaleY: constrainedScale.scaleY
      });
      this.canvas.renderAll();
      this.emitManipulationEvent('scale', object);
    }
  }

  /**
   * Rotate object to specific angle
   */
  rotateObject(object: fabric.Object, angle: number, animate = true) {
    if (this.constraints.lockRotation) return;

    // Normalize angle to 0-360 range
    const normalizedAngle = ((angle % 360) + 360) % 360;

    if (animate) {
      object.animate('angle', normalizedAngle, {
        duration: 200,
        onChange: () => this.canvas.renderAll(),
        onComplete: () => this.emitManipulationEvent('rotate', object)
      });
    } else {
      object.set('angle', normalizedAngle);
      this.canvas.renderAll();
      this.emitManipulationEvent('rotate', object);
    }
  }

  /**
   * Duplicate selected object(s)
   */
  duplicateObjects(objects?: fabric.Object[]) {
    const targetObjects = objects || [this.canvas.getActiveObject()].filter(Boolean);
    const duplicates: fabric.Object[] = [];

    targetObjects.forEach(obj => {
      if (obj) {
        obj.clone((cloned: fabric.Object) => {
          cloned.set({
            left: cloned.left! + 20,
            top: cloned.top! + 20,
            evented: true,
          });
          
          // Copy layer ID for tracking
          if ((obj as any).layerId) {
            (cloned as any).layerId = this.generateLayerId();
          }

          this.canvas.add(cloned);
          duplicates.push(cloned);

          if (duplicates.length === targetObjects.length) {
            // Select duplicated objects
            if (duplicates.length === 1) {
              this.canvas.setActiveObject(duplicates[0]);
            } else {
              const selection = new fabric.ActiveSelection(duplicates, {
                canvas: this.canvas
              });
              this.canvas.setActiveObject(selection);
            }
            this.canvas.renderAll();
          }
        });
      }
    });

    return duplicates;
  }

  /**
   * Delete selected object(s)
   */
  deleteObjects(objects?: fabric.Object[]) {
    const targetObjects = objects || [this.canvas.getActiveObject()].filter(Boolean);
    
    targetObjects.forEach(obj => {
      if (obj) {
        this.canvas.remove(obj);
      }
    });

    this.canvas.discardActiveObject();
    this.canvas.renderAll();
  }

  /**
   * Group selected objects
   */
  groupObjects(objects?: fabric.Object[]) {
    const targetObjects = objects || this.canvas.getActiveObjects();
    
    if (targetObjects.length < 2) {
      console.warn('Need at least 2 objects to create a group');
      return null;
    }

    const group = new fabric.Group(targetObjects, {
      canvas: this.canvas
    });

    // Remove individual objects and add group
    targetObjects.forEach(obj => this.canvas.remove(obj));
    this.canvas.add(group);
    this.canvas.setActiveObject(group);
    this.canvas.renderAll();

    return group;
  }

  /**
   * Ungroup selected group
   */
  ungroupObjects(group?: fabric.Group) {
    const targetGroup = group || this.canvas.getActiveObject() as fabric.Group;
    
    if (!targetGroup || targetGroup.type !== 'group') {
      console.warn('No group selected to ungroup');
      return [];
    }

    const objects = (targetGroup as fabric.Group).getObjects();
    (targetGroup as fabric.Group).destroy();
    this.canvas.remove(targetGroup);

    objects.forEach(obj => {
      this.canvas.add(obj);
    });

    // Select ungrouped objects
    if (objects.length > 1) {
      const selection = new fabric.ActiveSelection(objects, {
        canvas: this.canvas
      });
      this.canvas.setActiveObject(selection);
    } else if (objects.length === 1) {
      this.canvas.setActiveObject(objects[0]);
    }

    this.canvas.renderAll();
    return objects;
  }

  /**
   * Align objects relative to canvas or selection
   */
  alignObjects(alignment: 'left' | 'center' | 'right' | 'top' | 'middle' | 'bottom', objects?: fabric.Object[]) {
    const targetObjects = objects || this.canvas.getActiveObjects();
    if (targetObjects.length === 0) return;

    const canvasCenter = {
      x: this.canvas.width! / 2,
      y: this.canvas.height! / 2
    };

    // Calculate bounds for multiple objects
    let bounds: { left: number; top: number; width: number; height: number } | null = null;
    if (targetObjects.length > 1) {
      const group = new fabric.Group(targetObjects, { canvas: this.canvas });
      bounds = group.getBoundingRect();
      group.destroy();
    }

    targetObjects.forEach(obj => {
      const objBounds = obj.getBoundingRect();
      
      switch (alignment) {
        case 'left':
          obj.set('left', bounds ? bounds.left : 0);
          break;
        case 'center':
          obj.set('left', canvasCenter.x - objBounds.width / 2);
          break;
        case 'right':
          obj.set('left', (bounds ? bounds.left + bounds.width : this.canvas.width!) - objBounds.width);
          break;
        case 'top':
          obj.set('top', bounds ? bounds.top : 0);
          break;
        case 'middle':
          obj.set('top', canvasCenter.y - objBounds.height / 2);
          break;
        case 'bottom':
          obj.set('top', (bounds ? bounds.top + bounds.height : this.canvas.height!) - objBounds.height);
          break;
      }
    });

    this.canvas.renderAll();
  }

  /**
   * Distribute objects evenly
   */
  distributeObjects(direction: 'horizontal' | 'vertical', objects?: fabric.Object[]) {
    const targetObjects = objects || this.canvas.getActiveObjects();
    if (targetObjects.length < 3) {
      console.warn('Need at least 3 objects to distribute');
      return;
    }

    // Sort objects by position
    const sortedObjects = targetObjects.slice().sort((a, b) => {
      if (direction === 'horizontal') {
        return a.left! - b.left!;
      } else {
        return a.top! - b.top!;
      }
    });

    const first = sortedObjects[0];
    const last = sortedObjects[sortedObjects.length - 1];
    
    const totalSpace = direction === 'horizontal' 
      ? last.left! - first.left!
      : last.top! - first.top!;
    
    const spacing = totalSpace / (sortedObjects.length - 1);

    sortedObjects.forEach((obj, index) => {
      if (index > 0 && index < sortedObjects.length - 1) {
        if (direction === 'horizontal') {
          obj.set('left', first.left! + (spacing * index));
        } else {
          obj.set('top', first.top! + (spacing * index));
        }
      }
    });

    this.canvas.renderAll();
  }

  /**
   * Perform batch operations on multiple objects
   */
  performBatchOperation(operation: BatchOperation) {
    const { type, objects, parameters } = operation;

    switch (type) {
      case 'move':
        const { deltaX = 0, deltaY = 0 } = parameters;
        objects.forEach(obj => {
          obj.set({
            left: obj.left! + deltaX,
            top: obj.top! + deltaY
          });
        });
        break;

      case 'scale':
        const { scaleX = 1, scaleY = 1 } = parameters;
        objects.forEach(obj => {
          obj.set({
            scaleX: obj.scaleX! * scaleX,
            scaleY: obj.scaleY! * scaleY
          });
        });
        break;

      case 'rotate':
        const { angle = 0 } = parameters;
        objects.forEach(obj => {
          obj.set('angle', (obj.angle || 0) + angle);
        });
        break;

      case 'duplicate':
        return this.duplicateObjects(objects);

      case 'delete':
        this.deleteObjects(objects);
        break;

      default:
        console.warn(`Unknown batch operation: ${type}`);
    }

    this.canvas.renderAll();
  }

  /**
   * Enable/disable object snapping
   */
  setSnapping(enabled: boolean, gridSize = 10, snapDistance = 5) {
    this.constraints.snapToGrid = enabled;
    this.constraints.gridSize = gridSize;
    this.constraints.snapDistance = snapDistance;
  }

  // Private methods
  private setupEventHandlers() {
    this.canvas.on('object:moving', this.handleObjectMoving.bind(this));
    this.canvas.on('object:scaling', this.handleObjectScaling.bind(this));
    this.canvas.on('object:rotating', this.handleObjectRotating.bind(this));
    this.canvas.on('object:modified', this.handleObjectModified.bind(this));
  }

  private setupKeyboardHandlers() {
    document.addEventListener('keydown', (e) => {
      const activeObject = this.canvas.getActiveObject();
      if (!activeObject) return;

      // Arrow keys for precise movement
      if (e.key.startsWith('Arrow')) {
        e.preventDefault();
        const step = e.shiftKey ? 10 : 1;
        
        switch (e.key) {
          case 'ArrowLeft':
            this.moveObject(activeObject, activeObject.left! - step, activeObject.top!, false);
            break;
          case 'ArrowRight':
            this.moveObject(activeObject, activeObject.left! + step, activeObject.top!, false);
            break;
          case 'ArrowUp':
            this.moveObject(activeObject, activeObject.left!, activeObject.top! - step, false);
            break;
          case 'ArrowDown':
            this.moveObject(activeObject, activeObject.left!, activeObject.top! + step, false);
            break;
        }
      }

      // Delete key
      if (e.key === 'Delete' || e.key === 'Backspace') {
        e.preventDefault();
        this.deleteObjects();
      }

      // Duplicate (Ctrl/Cmd + D)
      if ((e.ctrlKey || e.metaKey) && e.key === 'd') {
        e.preventDefault();
        this.duplicateObjects();
      }

      // Group (Ctrl/Cmd + G)
      if ((e.ctrlKey || e.metaKey) && e.key === 'g') {
        e.preventDefault();
        this.groupObjects();
      }

      // Ungroup (Ctrl/Cmd + Shift + G)
      if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'g') {
        e.preventDefault();
        this.ungroupObjects();
      }
    });
  }

  private handleObjectMoving(event: fabric.IEvent) {
    const object = event.target!;
    if (this.constraints.snapToGrid || this.constraints.snapToObjects) {
      const snappedPosition = this.applySnapConstraints({
        x: object.left!,
        y: object.top!
      }, object);
      
      object.set({
        left: snappedPosition.x,
        top: snappedPosition.y
      });
    }
  }

  private handleObjectScaling(event: fabric.IEvent) {
    const object = event.target!;
    const constrainedScale = this.applyScaleConstraints({
      scaleX: object.scaleX!,
      scaleY: object.scaleY!
    });

    object.set({
      scaleX: constrainedScale.scaleX,
      scaleY: constrainedScale.scaleY
    });
  }

  private handleObjectRotating(_event: fabric.IEvent) {
    // Could add rotation snapping here (e.g., 15-degree increments)
    // const object = _event.target!;
  }

  private handleObjectModified(event: fabric.IEvent) {
    const object = event.target!;
    this.emitManipulationEvent('modified', object);
    this.clearSnapLines();
  }

  private applySnapConstraints(position: { x: number; y: number }, object: fabric.Object) {
    let { x, y } = position;

    if (this.constraints.snapToGrid && this.constraints.gridSize) {
      const gridSize = this.constraints.gridSize;
      x = Math.round(x / gridSize) * gridSize;
      y = Math.round(y / gridSize) * gridSize;
    }

    if (this.constraints.snapToObjects) {
      const snapResult = this.findSnapTargets(x, y, object);
      x = snapResult.x;
      y = snapResult.y;
      this.showSnapLines(snapResult.lines);
    }

    return { x, y };
  }

  private applyScaleConstraints(scale: { scaleX: number; scaleY: number }) {
    let { scaleX, scaleY } = scale;

    if (this.constraints.minScale) {
      scaleX = Math.max(scaleX, this.constraints.minScale);
      scaleY = Math.max(scaleY, this.constraints.minScale);
    }

    if (this.constraints.maxScale) {
      scaleX = Math.min(scaleX, this.constraints.maxScale);
      scaleY = Math.min(scaleY, this.constraints.maxScale);
    }

    return { scaleX, scaleY };
  }

  private findSnapTargets(x: number, y: number, movingObject: fabric.Object) {
    const snapDistance = this.constraints.snapDistance || 5;
    const objects = this.canvas.getObjects().filter(obj => obj !== movingObject);
    const lines: fabric.Line[] = [];

    let snapX = x;
    let snapY = y;

    // Find horizontal and vertical alignment targets
    objects.forEach(obj => {
      const objBounds = obj.getBoundingRect();
      const movingBounds = movingObject.getBoundingRect();

      // Vertical alignment (snap X)
      const centerXDiff = Math.abs((objBounds.left + objBounds.width / 2) - (x + movingBounds.width / 2));
      const leftXDiff = Math.abs(objBounds.left - x);
      const rightXDiff = Math.abs((objBounds.left + objBounds.width) - (x + movingBounds.width));

      if (centerXDiff < snapDistance) {
        snapX = objBounds.left + objBounds.width / 2 - movingBounds.width / 2;
        lines.push(this.createSnapLine(snapX + movingBounds.width / 2, 0, snapX + movingBounds.width / 2, this.canvas.height!));
      } else if (leftXDiff < snapDistance) {
        snapX = objBounds.left;
        lines.push(this.createSnapLine(snapX, 0, snapX, this.canvas.height!));
      } else if (rightXDiff < snapDistance) {
        snapX = objBounds.left + objBounds.width - movingBounds.width;
        lines.push(this.createSnapLine(snapX + movingBounds.width, 0, snapX + movingBounds.width, this.canvas.height!));
      }

      // Horizontal alignment (snap Y)
      const centerYDiff = Math.abs((objBounds.top + objBounds.height / 2) - (y + movingBounds.height / 2));
      const topYDiff = Math.abs(objBounds.top - y);
      const bottomYDiff = Math.abs((objBounds.top + objBounds.height) - (y + movingBounds.height));

      if (centerYDiff < snapDistance) {
        snapY = objBounds.top + objBounds.height / 2 - movingBounds.height / 2;
        lines.push(this.createSnapLine(0, snapY + movingBounds.height / 2, this.canvas.width!, snapY + movingBounds.height / 2));
      } else if (topYDiff < snapDistance) {
        snapY = objBounds.top;
        lines.push(this.createSnapLine(0, snapY, this.canvas.width!, snapY));
      } else if (bottomYDiff < snapDistance) {
        snapY = objBounds.top + objBounds.height - movingBounds.height;
        lines.push(this.createSnapLine(0, snapY + movingBounds.height, this.canvas.width!, snapY + movingBounds.height));
      }
    });

    return { x: snapX, y: snapY, lines };
  }

  private createSnapLine(x1: number, y1: number, x2: number, y2: number): fabric.Line {
    return new fabric.Line([x1, y1, x2, y2], {
      stroke: '#ff0000',
      strokeWidth: 1,
      strokeDashArray: [5, 5],
      selectable: false,
      evented: false,
      excludeFromExport: true
    });
  }

  private showSnapLines(lines: fabric.Line[]) {
    this.clearSnapLines();
    this.snapLines = lines;
    lines.forEach(line => this.canvas.add(line));
    this.canvas.renderAll();
  }

  private clearSnapLines() {
    this.snapLines.forEach(line => this.canvas.remove(line));
    this.snapLines = [];
  }

  private generateLayerId(): string {
    return `layer_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private emitManipulationEvent(type: ManipulationEvent['type'], object: fabric.Object) {
    if (!this.onManipulationCallback) return;

    const layerId = (object as any).layerId;
    if (!layerId) return;

    const transform: LayerTransform = {
      x: object.left || 0,
      y: object.top || 0,
      rotation: object.angle || 0,
      scaleX: object.scaleX || 1,
      scaleY: object.scaleY || 1,
      opacity: object.opacity || 1
    };

    const event: ManipulationEvent = {
      type,
      target: object,
      layerId,
      transform
    };

    this.onManipulationCallback(event);
  }

  /**
   * Cleanup method
   */
  dispose() {
    this.clearSnapLines();
    // Remove event listeners if needed
  }
}

export default CanvasManipulation;
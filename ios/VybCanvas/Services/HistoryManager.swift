/**
 * HistoryManager - iOS DAG-based history management system
 * Implements T054: iOS History Manager
 * Provides Core Data persistence and SwiftUI integration
 */

import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - History Node Types

public struct HistoryNodeID: Hashable, Codable {
    public let value: UUID
    
    public init() {
        self.value = UUID()
    }
    
    public init(value: UUID) {
        self.value = value
    }
}

public protocol HistoryNodeData: Codable {
    var timestamp: Date { get }
    var metadata: [String: String] { get } // Changed from [String: Any] for Codable conformance
}

public struct DesignCanvasData: HistoryNodeData {
    public let canvasId: String
    public let elements: [CanvasElement]
    public let viewport: ViewportState
    public let timestamp: Date
    public let metadata: [String: String]
    
    public init(canvasId: String, elements: [CanvasElement], viewport: ViewportState, metadata: [String: String] = [:]) {
        self.canvasId = canvasId
        self.elements = elements
        self.viewport = viewport
        self.timestamp = Date()
        self.metadata = metadata
    }
}

public struct CanvasElement: Codable {
    public let id: String
    public let type: String
    public let position: CodablePoint
    public let size: CodableSize
    public let properties: [String: String] // Simplified for Codable
    
    public init(id: String, type: String, position: CGPoint, size: CGSize, properties: [String: String] = [:]) {
        self.id = id
        self.type = type
        self.position = CodablePoint(x: position.x, y: position.y)
        self.size = CodableSize(width: size.width, height: size.height)
        self.properties = properties
    }
}

public struct CodablePoint: Codable, Equatable {
    public let x: Double
    public let y: Double
    
    public var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
}

public struct CodableSize: Codable, Equatable {
    public let width: Double
    public let height: Double
    
    public var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
}

public struct ViewportState: Codable {
    public let center: CGPoint
    public let zoom: Double
    public let rotation: Double
    
    public init(center: CGPoint = .zero, zoom: Double = 1.0, rotation: Double = 0.0) {
        self.center = center
        self.zoom = zoom
        self.rotation = rotation
    }
}

// MARK: - History Node

public class HistoryNode: ObservableObject, Identifiable {
    public let id: HistoryNodeID
    public let data: DesignCanvasData
    public let parentIds: Set<HistoryNodeID>
    public let branchName: String?
    
    @Published public var children: Set<HistoryNodeID> = []
    @Published public var isBookmarked: Bool = false
    @Published public var tags: Set<String> = []
    @Published public var description: String = ""
    
    public init(
        id: HistoryNodeID? = nil,
        data: DesignCanvasData,
        parentIds: Set<HistoryNodeID> = [],
        branchName: String? = nil
    ) {
        self.id = id ?? HistoryNodeID()
        self.data = data
        self.parentIds = parentIds
        self.branchName = branchName
    }
    
    // MARK: - Node Operations
    
    public func addChild(_ childId: HistoryNodeID) {
        children.insert(childId)
    }
    
    public func removeChild(_ childId: HistoryNodeID) {
        children.remove(childId)
    }
    
    public func addTag(_ tag: String) {
        tags.insert(tag)
    }
    
    public func removeTag(_ tag: String) {
        tags.remove(tag)
    }
    
    // MARK: - Comparison
    
    public func compare(to other: HistoryNode) -> HistoryNodeComparison {
        let elementChanges = compareElements(self.data.elements, other.data.elements)
        let viewportChanges = compareViewport(self.data.viewport, other.data.viewport)
        
        return HistoryNodeComparison(
            fromNode: self.id,
            toNode: other.id,
            elementChanges: elementChanges,
            viewportChanges: viewportChanges,
            timestamp: Date()
        )
    }
    
    private func compareElements(_ elements1: [CanvasElement], _ elements2: [CanvasElement]) -> [ElementChange] {
        var changes: [ElementChange] = []
        let elements1Dict = Dictionary(uniqueKeysWithValues: elements1.map { ($0.id, $0) })
        let elements2Dict = Dictionary(uniqueKeysWithValues: elements2.map { ($0.id, $0) })
        
        // Find added elements
        for element in elements2 {
            if elements1Dict[element.id] == nil {
                changes.append(ElementChange(type: .added, elementId: element.id, element: element))
            }
        }
        
        // Find removed elements
        for element in elements1 {
            if elements2Dict[element.id] == nil {
                changes.append(ElementChange(type: .removed, elementId: element.id, element: element))
            }
        }
        
        // Find modified elements
        for element1 in elements1 {
            if let element2 = elements2Dict[element1.id] {
                if !areElementsEqual(element1, element2) {
                    changes.append(ElementChange(type: .modified, elementId: element1.id, element: element2, previousElement: element1))
                }
            }
        }
        
        return changes
    }
    
    private func compareViewport(_ viewport1: ViewportState, _ viewport2: ViewportState) -> ViewportChange? {
        if viewport1.center != viewport2.center || 
           viewport1.zoom != viewport2.zoom || 
           viewport1.rotation != viewport2.rotation {
            return ViewportChange(from: viewport1, to: viewport2)
        }
        return nil
    }
    
    private func areElementsEqual(_ element1: CanvasElement, _ element2: CanvasElement) -> Bool {
        return element1.position == element2.position &&
               element1.size == element2.size &&
               element1.properties == element2.properties
    }
}

// MARK: - History Branch

public class HistoryBranch: ObservableObject, Identifiable {
    public let id: UUID = UUID()
    public let name: String
    public let startNodeId: HistoryNodeID
    public let color: Color
    
    @Published public var isActive: Bool = false
    @Published public var description: String = ""
    @Published public var nodeIds: [HistoryNodeID] = []
    
    public init(name: String, startNodeId: HistoryNodeID, color: Color = .blue) {
        self.name = name
        self.startNodeId = startNodeId
        self.color = color
        self.nodeIds = [startNodeId]
    }
    
    public func addNode(_ nodeId: HistoryNodeID) {
        nodeIds.append(nodeId)
    }
    
    public func removeNode(_ nodeId: HistoryNodeID) {
        nodeIds.removeAll { $0 == nodeId }
    }
}

// MARK: - Comparison Types

public struct HistoryNodeComparison {
    public let fromNode: HistoryNodeID
    public let toNode: HistoryNodeID
    public let elementChanges: [ElementChange]
    public let viewportChanges: ViewportChange?
    public let timestamp: Date
    
    public var hasChanges: Bool {
        return !elementChanges.isEmpty || viewportChanges != nil
    }
}

public struct ElementChange {
    public enum ChangeType {
        case added, removed, modified
    }
    
    public let type: ChangeType
    public let elementId: String
    public let element: CanvasElement
    public let previousElement: CanvasElement?
    
    public init(type: ChangeType, elementId: String, element: CanvasElement, previousElement: CanvasElement? = nil) {
        self.type = type
        self.elementId = elementId
        self.element = element
        self.previousElement = previousElement
    }
}

public struct ViewportChange {
    public let from: ViewportState
    public let to: ViewportState
}

// MARK: - History State

public struct HistoryState {
    public let nodes: [HistoryNodeID: HistoryNode]
    public let branches: [UUID: HistoryBranch]
    public let currentNodeId: HistoryNodeID?
    public let activeBranchId: UUID?
    public let canUndo: Bool
    public let canRedo: Bool
    
    public init(
        nodes: [HistoryNodeID: HistoryNode] = [:],
        branches: [UUID: HistoryBranch] = [:],
        currentNodeId: HistoryNodeID? = nil,
        activeBranchId: UUID? = nil,
        canUndo: Bool = false,
        canRedo: Bool = false
    ) {
        self.nodes = nodes
        self.branches = branches
        self.currentNodeId = currentNodeId
        self.activeBranchId = activeBranchId
        self.canUndo = canUndo
        self.canRedo = canRedo
    }
}

public enum HistoryNavigationResult {
    case success(DesignCanvasData)
    case failure(String)
    case noChange
}

// MARK: - iOS History Manager

@MainActor
public class HistoryManager: ObservableObject {
    @Published public private(set) var state = HistoryState()
    
    private let persistentContainer: NSPersistentContainer
    private let maxHistorySize: Int
    private var undoStack: [HistoryNodeID] = []
    private var redoStack: [HistoryNodeID] = []
    
    public init(maxHistorySize: Int = 1000) {
        self.maxHistorySize = maxHistorySize
        
        // Initialize Core Data stack
        self.persistentContainer = NSPersistentContainer(name: "HistoryModel")
        self.persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        
        // Load existing state from Core Data
        loadFromPersistence()
    }
    
    // MARK: - Public API
    
    public func createSnapshot(data: DesignCanvasData, branchName: String? = nil) -> HistoryNavigationResult {
        let parentIds: Set<HistoryNodeID> = state.currentNodeId.map { [$0] } ?? []
        let newNode = HistoryNode(data: data, parentIds: parentIds, branchName: branchName)
        
        // Add to nodes
        var newNodes = state.nodes
        newNodes[newNode.id] = newNode
        
        // Update parent-child relationships
        if let parentId = state.currentNodeId {
            newNodes[parentId]?.addChild(newNode.id)
        }
        
        // Handle branching
        var newBranches = state.branches
        var newActiveBranchId = state.activeBranchId
        
        if let branchName = branchName {
            let branch = HistoryBranch(name: branchName, startNodeId: newNode.id)
            newBranches[branch.id] = branch
            newActiveBranchId = branch.id
        } else if let activeBranchId = state.activeBranchId {
            newBranches[activeBranchId]?.addNode(newNode.id)
        }
        
        // Update undo/redo stacks
        undoStack.append(newNode.id)
        redoStack.removeAll()
        
        // Enforce size limits
        enforceHistorySize(&newNodes)
        
        // Update state
        state = HistoryState(
            nodes: newNodes,
            branches: newBranches,
            currentNodeId: newNode.id,
            activeBranchId: newActiveBranchId,
            canUndo: undoStack.count > 1,
            canRedo: false
        )
        
        // Persist changes
        persistState()
        
        return .success(data)
    }
    
    public func undo() -> HistoryNavigationResult {
        guard undoStack.count > 1 else {
            return .failure("Cannot undo: no previous state")
        }
        
        let currentId = undoStack.removeLast()
        redoStack.append(currentId)
        
        guard let targetId = undoStack.last,
              let targetNode = state.nodes[targetId] else {
            return .failure("Target node not found")
        }
        
        state = HistoryState(
            nodes: state.nodes,
            branches: state.branches,
            currentNodeId: targetId,
            activeBranchId: state.activeBranchId,
            canUndo: undoStack.count > 1,
            canRedo: !redoStack.isEmpty
        )
        
        persistState()
        return .success(targetNode.data)
    }
    
    public func redo() -> HistoryNavigationResult {
        guard !redoStack.isEmpty else {
            return .failure("Cannot redo: no forward state")
        }
        
        let targetId = redoStack.removeLast()
        undoStack.append(targetId)
        
        guard let targetNode = state.nodes[targetId] else {
            return .failure("Target node not found")
        }
        
        state = HistoryState(
            nodes: state.nodes,
            branches: state.branches,
            currentNodeId: targetId,
            activeBranchId: state.activeBranchId,
            canUndo: undoStack.count > 1,
            canRedo: !redoStack.isEmpty
        )
        
        persistState()
        return .success(targetNode.data)
    }
    
    public func navigateToNode(_ nodeId: HistoryNodeID) -> HistoryNavigationResult {
        guard let targetNode = state.nodes[nodeId] else {
            return .failure("Node not found: \(nodeId)")
        }
        
        // Update navigation stacks
        if state.currentNodeId != nil {
            if !undoStack.contains(nodeId) {
                // Clear redo stack when jumping to a different branch
                redoStack.removeAll()
            }
        }
        
        // Rebuild path to target node
        rebuildNavigationPath(to: nodeId)
        
        state = HistoryState(
            nodes: state.nodes,
            branches: state.branches,
            currentNodeId: nodeId,
            activeBranchId: findBranchForNode(nodeId),
            canUndo: undoStack.count > 1,
            canRedo: !redoStack.isEmpty
        )
        
        persistState()
        return .success(targetNode.data)
    }
    
    public func createBranch(name: String, fromNode: HistoryNodeID? = nil) -> UUID? {
        let startNodeId = fromNode ?? state.currentNodeId ?? HistoryNodeID()
        let branch = HistoryBranch(name: name, startNodeId: startNodeId)
        
        var newBranches = state.branches
        newBranches[branch.id] = branch
        
        state = HistoryState(
            nodes: state.nodes,
            branches: newBranches,
            currentNodeId: state.currentNodeId,
            activeBranchId: branch.id,
            canUndo: state.canUndo,
            canRedo: state.canRedo
        )
        
        persistState()
        return branch.id
    }
    
    public func switchToBranch(_ branchId: UUID) -> HistoryNavigationResult {
        guard let branch = state.branches[branchId] else {
            return .failure("Branch not found: \(branchId)")
        }
        
        // Navigate to the latest node in the branch
        let latestNodeId = branch.nodeIds.last ?? branch.startNodeId
        return navigateToNode(latestNodeId)
    }
    
    public func deleteBranch(_ branchId: UUID) -> Bool {
        guard state.branches[branchId] != nil,
              state.activeBranchId != branchId else {
            return false
        }
        
        var newBranches = state.branches
        newBranches.removeValue(forKey: branchId)
        
        state = HistoryState(
            nodes: state.nodes,
            branches: newBranches,
            currentNodeId: state.currentNodeId,
            activeBranchId: state.activeBranchId,
            canUndo: state.canUndo,
            canRedo: state.canRedo
        )
        
        persistState()
        return true
    }
    
    public func compareNodes(_ nodeId1: HistoryNodeID, _ nodeId2: HistoryNodeID) -> HistoryNodeComparison? {
        guard let node1 = state.nodes[nodeId1],
              let node2 = state.nodes[nodeId2] else {
            return nil
        }
        
        return node1.compare(to: node2)
    }
    
    public func getPath(from: HistoryNodeID, to: HistoryNodeID) -> [HistoryNodeID] {
        // Simple implementation - could be optimized with proper graph algorithms
        var visited: Set<HistoryNodeID> = []
        var path: [HistoryNodeID] = []
        
        func dfs(current: HistoryNodeID, target: HistoryNodeID, currentPath: [HistoryNodeID]) -> Bool {
            if current == target {
                path = currentPath + [current]
                return true
            }
            
            if visited.contains(current) {
                return false
            }
            
            visited.insert(current)
            
            guard let node = state.nodes[current] else {
                return false
            }
            
            for childId in node.children {
                if dfs(current: childId, target: target, currentPath: currentPath + [current]) {
                    return true
                }
            }
            
            return false
        }
        
        _ = dfs(current: from, target: to, currentPath: [])
        return path
    }
    
    // MARK: - Export/Import
    
    public func exportHistory() -> Data? {
        let exportData = HistoryExportData(
            nodes: Array(state.nodes.values),
            branches: Array(state.branches.values),
            currentNodeId: state.currentNodeId,
            activeBranchId: state.activeBranchId
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    public func importHistory(from data: Data) -> Bool {
        guard let importData = try? JSONDecoder().decode(HistoryExportData.self, from: data) else {
            return false
        }
        
        var newNodes: [HistoryNodeID: HistoryNode] = [:]
        for nodeData in importData.nodes {
            let node = HistoryNode(
                id: nodeData.id,
                data: nodeData.data,
                parentIds: nodeData.parentIds,
                branchName: nodeData.branchName
            )
            node.isBookmarked = nodeData.isBookmarked
            node.tags = nodeData.tags
            node.description = nodeData.description
            newNodes[node.id] = node
        }
        
        var newBranches: [UUID: HistoryBranch] = [:]
        for branchData in importData.branches {
            let branch = HistoryBranch(
                name: branchData.name,
                startNodeId: branchData.startNodeId,
                color: branchData.color.swiftUIColor
            )
            branch.isActive = branchData.isActive
            branch.description = branchData.description
            branch.nodeIds = branchData.nodeIds
            newBranches[branch.id] = branch
        }
        
        state = HistoryState(
            nodes: newNodes,
            branches: newBranches,
            currentNodeId: importData.currentNodeId,
            activeBranchId: importData.activeBranchId,
            canUndo: true,
            canRedo: false
        )
        
        // Rebuild navigation stacks
        rebuildNavigationStacks()
        persistState()
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func enforceHistorySize(_ nodes: inout [HistoryNodeID: HistoryNode]) {
        guard nodes.count > maxHistorySize else { return }
        
        // Remove oldest nodes (simple FIFO strategy)
        let sortedNodes = nodes.values.sorted { $0.data.timestamp < $1.data.timestamp }
        let nodesToRemove = sortedNodes.prefix(nodes.count - maxHistorySize)
        
        for node in nodesToRemove {
            nodes.removeValue(forKey: node.id)
            
            // Update parent-child relationships
            for parentId in node.parentIds {
                nodes[parentId]?.removeChild(node.id)
            }
            
            // Remove from navigation stacks
            undoStack.removeAll { $0 == node.id }
            redoStack.removeAll { $0 == node.id }
        }
    }
    
    private func rebuildNavigationPath(to targetId: HistoryNodeID) {
        // Simple linear path reconstruction
        guard state.currentNodeId != nil else { return }
        
        let path = getPath(from: findRootNode(), to: targetId)
        undoStack = path
    }
    
    private func rebuildNavigationStacks() {
        guard state.currentNodeId != nil else { return }
        
        let path = getPath(from: findRootNode(), to: state.currentNodeId!)
        undoStack = path
        redoStack.removeAll()
    }
    
    private func findRootNode() -> HistoryNodeID {
        // Find a node with no parents
        for (nodeId, node) in state.nodes {
            if node.parentIds.isEmpty {
                return nodeId
            }
        }
        // Fallback to first node
        return state.nodes.keys.first ?? HistoryNodeID()
    }
    
    private func findBranchForNode(_ nodeId: HistoryNodeID) -> UUID? {
        for (branchId, branch) in state.branches {
            if branch.nodeIds.contains(nodeId) {
                return branchId
            }
        }
        return nil
    }
    
    // MARK: - Core Data Persistence
    
    private func persistState() {
        let context = persistentContainer.viewContext
        
        // Clear existing data
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PersistedHistoryNode")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            
            // Save nodes
            for node in state.nodes.values {
                let entity = NSEntityDescription.entity(forEntityName: "PersistedHistoryNode", in: context)!
                let persistedNode = NSManagedObject(entity: entity, insertInto: context)
                
                persistedNode.setValue(node.id.value.uuidString, forKey: "id")
                persistedNode.setValue(try? JSONEncoder().encode(node.data), forKey: "data")
                persistedNode.setValue(node.parentIds.map { $0.value.uuidString }, forKey: "parentIds")
                persistedNode.setValue(node.branchName, forKey: "branchName")
                persistedNode.setValue(node.isBookmarked, forKey: "isBookmarked")
                persistedNode.setValue(Array(node.tags), forKey: "tags")
                persistedNode.setValue(node.description, forKey: "nodeDescription")
            }
            
            // Save current state
            if let currentId = state.currentNodeId {
                UserDefaults.standard.set(currentId.value.uuidString, forKey: "currentNodeId")
            }
            
            if let activeBranchId = state.activeBranchId {
                UserDefaults.standard.set(activeBranchId.uuidString, forKey: "activeBranchId")
            }
            
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }
    
    private func loadFromPersistence() {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "PersistedHistoryNode")
        
        do {
            let results = try context.fetch(fetchRequest)
            var loadedNodes: [HistoryNodeID: HistoryNode] = [:]
            
            for result in results {
                guard let idString = result.value(forKey: "id") as? String,
                      let id = UUID(uuidString: idString),
                      let dataData = result.value(forKey: "data") as? Data,
                      let data = try? JSONDecoder().decode(DesignCanvasData.self, from: dataData),
                      let parentIdStrings = result.value(forKey: "parentIds") as? [String] else {
                    continue
                }
                
                let nodeId = HistoryNodeID(value: id)
                let parentIds = Set(parentIdStrings.compactMap { UUID(uuidString: $0) }.map { HistoryNodeID(value: $0) })
                let branchName = result.value(forKey: "branchName") as? String
                
                let node = HistoryNode(id: nodeId, data: data, parentIds: parentIds, branchName: branchName)
                node.isBookmarked = result.value(forKey: "isBookmarked") as? Bool ?? false
                node.tags = Set(result.value(forKey: "tags") as? [String] ?? [])
                node.description = result.value(forKey: "nodeDescription") as? String ?? ""
                
                loadedNodes[nodeId] = node
            }
            
            // Load current state
            var currentNodeId: HistoryNodeID?
            if let currentIdString = UserDefaults.standard.string(forKey: "currentNodeId"),
               let currentId = UUID(uuidString: currentIdString) {
                currentNodeId = HistoryNodeID(value: currentId)
            }
            
            var activeBranchId: UUID?
            if let activeBranchIdString = UserDefaults.standard.string(forKey: "activeBranchId") {
                activeBranchId = UUID(uuidString: activeBranchIdString)
            }
            
            state = HistoryState(
                nodes: loadedNodes,
                branches: [:], // Branches would need separate persistence
                currentNodeId: currentNodeId,
                activeBranchId: activeBranchId,
                canUndo: !loadedNodes.isEmpty,
                canRedo: false
            )
            
            // Rebuild parent-child relationships
            for node in loadedNodes.values {
                for parentId in node.parentIds {
                    loadedNodes[parentId]?.addChild(node.id)
                }
            }
            
            rebuildNavigationStacks()
            
        } catch {
            print("Core Data load error: \(error)")
        }
    }
}

// MARK: - Export Data Types

private struct HistoryExportData: Codable {
    let nodes: [SerializableHistoryNode]
    let branches: [SerializableHistoryBranch]
    let currentNodeId: HistoryNodeID?
    let activeBranchId: UUID?
    
    init(nodes: [HistoryNode], branches: [HistoryBranch], currentNodeId: HistoryNodeID?, activeBranchId: UUID?) {
        self.nodes = nodes.map { SerializableHistoryNode(from: $0) }
        self.branches = branches.map { SerializableHistoryBranch(from: $0) }
        self.currentNodeId = currentNodeId
        self.activeBranchId = activeBranchId
    }
}

private struct SerializableHistoryNode: Codable {
    let id: HistoryNodeID
    let data: DesignCanvasData
    let parentIds: Set<HistoryNodeID>
    let branchName: String?
    let isBookmarked: Bool
    let tags: Set<String>
    let description: String
    
    init(from node: HistoryNode) {
        self.id = node.id
        self.data = node.data
        self.parentIds = node.parentIds
        self.branchName = node.branchName
        self.isBookmarked = node.isBookmarked
        self.tags = node.tags
        self.description = node.description
    }
}

private struct SerializableHistoryBranch: Codable {
    let id: UUID
    let name: String
    let startNodeId: HistoryNodeID
    let color: CodableColor
    let isActive: Bool
    let description: String
    let nodeIds: [HistoryNodeID]
    
    init(from branch: HistoryBranch) {
        self.id = branch.id
        self.name = branch.name
        self.startNodeId = branch.startNodeId
        self.color = CodableColor(from: branch.color)
        self.isActive = branch.isActive
        self.description = branch.description
        self.nodeIds = branch.nodeIds
    }
}

private struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(from color: Color) {
        // Convert SwiftUI Color to components (simplified)
        // In a real implementation, you'd extract actual color components
        self.red = 0.5
        self.green = 0.5
        self.blue = 1.0
        self.alpha = 1.0
    }
    
    var swiftUIColor: Color {
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
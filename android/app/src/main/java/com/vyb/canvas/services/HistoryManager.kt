/**
 * HistoryManager - Android DAG-based history management system
 * Implements T055: Android History Manager
 * Provides Room database persistence and Compose integration
 */

package com.vyb.canvas.services

import androidx.room.*
import androidx.compose.runtime.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.*
import kotlinx.serialization.*
import kotlinx.serialization.json.*
import java.util.*
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope

// MARK: - History Node Types

@Serializable
data class HistoryNodeID(val value: String = UUID.randomUUID().toString()) {
    companion object {
        fun generate() = HistoryNodeID()
    }
}

interface HistoryNodeData {
    val timestamp: Long
    val metadata: Map<String, String>
}

@Serializable
data class DesignCanvasData(
    val canvasId: String,
    val elements: List<CanvasElement>,
    val viewport: ViewportState,
    override val timestamp: Long = System.currentTimeMillis(),
    override val metadata: Map<String, String> = emptyMap()
) : HistoryNodeData

@Serializable
data class CanvasElement(
    val id: String,
    val type: String,
    val position: SerializablePoint,
    val size: SerializableSize,
    val properties: Map<String, String> = emptyMap()
)

@Serializable
data class SerializablePoint(val x: Float, val y: Float)

@Serializable
data class SerializableSize(val width: Float, val height: Float)

@Serializable
data class ViewportState(
    val center: SerializablePoint = SerializablePoint(0f, 0f),
    val zoom: Double = 1.0,
    val rotation: Double = 0.0
)

// MARK: - Room Database Entities

@Entity(tableName = "history_nodes")
data class HistoryNodeEntity(
    @PrimaryKey val id: String,
    val dataJson: String,
    val parentIds: List<String>,
    val branchName: String?,
    val isBookmarked: Boolean = false,
    val tags: List<String> = emptyList(),
    val description: String = ""
)

@Entity(tableName = "history_branches")
data class HistoryBranchEntity(
    @PrimaryKey val id: String,
    val name: String,
    val startNodeId: String,
    val colorHex: String,
    val isActive: Boolean = false,
    val description: String = "",
    val nodeIds: List<String> = emptyList()
)

@Entity(tableName = "history_state")
data class HistoryStateEntity(
    @PrimaryKey val id: Int = 0,
    val currentNodeId: String?,
    val activeBranchId: String?
)

// MARK: - Type Converters

class Converters {
    @TypeConverter
    fun fromStringList(value: List<String>): String {
        return Json.encodeToString(value)
    }

    @TypeConverter
    fun toStringList(value: String): List<String> {
        return try {
            Json.decodeFromString(value)
        } catch (e: Exception) {
            emptyList()
        }
    }
}

// MARK: - DAOs

@Dao
interface HistoryNodeDao {
    @Query("SELECT * FROM history_nodes")
    fun getAllNodes(): Flow<List<HistoryNodeEntity>>

    @Query("SELECT * FROM history_nodes WHERE id = :id")
    suspend fun getNodeById(id: String): HistoryNodeEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNode(node: HistoryNodeEntity)

    @Delete
    suspend fun deleteNode(node: HistoryNodeEntity)

    @Query("DELETE FROM history_nodes")
    suspend fun deleteAllNodes()

    @Query("SELECT COUNT(*) FROM history_nodes")
    suspend fun getNodeCount(): Int
}

@Dao
interface HistoryBranchDao {
    @Query("SELECT * FROM history_branches")
    fun getAllBranches(): Flow<List<HistoryBranchEntity>>

    @Query("SELECT * FROM history_branches WHERE id = :id")
    suspend fun getBranchById(id: String): HistoryBranchEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBranch(branch: HistoryBranchEntity)

    @Delete
    suspend fun deleteBranch(branch: HistoryBranchEntity)

    @Query("DELETE FROM history_branches")
    suspend fun deleteAllBranches()
}

@Dao
interface HistoryStateDao {
    @Query("SELECT * FROM history_state WHERE id = 0")
    suspend fun getHistoryState(): HistoryStateEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertHistoryState(state: HistoryStateEntity)
}

// MARK: - Room Database

@Database(
    entities = [HistoryNodeEntity::class, HistoryBranchEntity::class, HistoryStateEntity::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class HistoryDatabase : RoomDatabase() {
    abstract fun historyNodeDao(): HistoryNodeDao
    abstract fun historyBranchDao(): HistoryBranchDao
    abstract fun historyStateDao(): HistoryStateDao

    companion object {
        @Volatile
        private var INSTANCE: HistoryDatabase? = null

        fun getDatabase(context: android.content.Context): HistoryDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    HistoryDatabase::class.java,
                    "history_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}

// MARK: - History Node

data class HistoryNode(
    val id: HistoryNodeID,
    val data: DesignCanvasData,
    val parentIds: Set<HistoryNodeID>,
    val branchName: String? = null,
    val children: MutableSet<HistoryNodeID> = mutableSetOf(),
    var isBookmarked: Boolean = false,
    val tags: MutableSet<String> = mutableSetOf(),
    var description: String = ""
) {
    fun addChild(childId: HistoryNodeID) {
        children.add(childId)
    }

    fun removeChild(childId: HistoryNodeID) {
        children.remove(childId)
    }

    fun addTag(tag: String) {
        tags.add(tag)
    }

    fun removeTag(tag: String) {
        tags.remove(tag)
    }

    fun compare(to: HistoryNode): HistoryNodeComparison {
        val elementChanges = compareElements(this.data.elements, to.data.elements)
        val viewportChanges = compareViewport(this.data.viewport, to.data.viewport)
        
        return HistoryNodeComparison(
            fromNode = this.id,
            toNode = to.id,
            elementChanges = elementChanges,
            viewportChanges = viewportChanges,
            timestamp = System.currentTimeMillis()
        )
    }

    private fun compareElements(elements1: List<CanvasElement>, elements2: List<CanvasElement>): List<ElementChange> {
        val changes = mutableListOf<ElementChange>()
        val elements1Map = elements1.associateBy { it.id }
        val elements2Map = elements2.associateBy { it.id }

        // Find added elements
        elements2.forEach { element ->
            if (elements1Map[element.id] == null) {
                changes.add(ElementChange(ElementChangeType.ADDED, element.id, element))
            }
        }

        // Find removed elements
        elements1.forEach { element ->
            if (elements2Map[element.id] == null) {
                changes.add(ElementChange(ElementChangeType.REMOVED, element.id, element))
            }
        }

        // Find modified elements
        elements1.forEach { element1 ->
            val element2 = elements2Map[element1.id]
            if (element2 != null && !areElementsEqual(element1, element2)) {
                changes.add(ElementChange(ElementChangeType.MODIFIED, element1.id, element2, element1))
            }
        }

        return changes
    }

    private fun compareViewport(viewport1: ViewportState, viewport2: ViewportState): ViewportChange? {
        return if (viewport1.center != viewport2.center || 
                   viewport1.zoom != viewport2.zoom || 
                   viewport1.rotation != viewport2.rotation) {
            ViewportChange(viewport1, viewport2)
        } else null
    }

    private fun areElementsEqual(element1: CanvasElement, element2: CanvasElement): Boolean {
        return element1.position == element2.position &&
               element1.size == element2.size &&
               element1.properties == element2.properties
    }
}

// MARK: - History Branch

data class HistoryBranch(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val startNodeId: HistoryNodeID,
    val color: androidx.compose.ui.graphics.Color,
    var isActive: Boolean = false,
    var description: String = "",
    val nodeIds: MutableList<HistoryNodeID> = mutableListOf()
) {
    init {
        nodeIds.add(startNodeId)
    }

    fun addNode(nodeId: HistoryNodeID) {
        nodeIds.add(nodeId)
    }

    fun removeNode(nodeId: HistoryNodeID) {
        nodeIds.remove(nodeId)
    }
}

// MARK: - Comparison Types

enum class ElementChangeType {
    ADDED, REMOVED, MODIFIED
}

data class ElementChange(
    val type: ElementChangeType,
    val elementId: String,
    val element: CanvasElement,
    val previousElement: CanvasElement? = null
)

data class ViewportChange(
    val from: ViewportState,
    val to: ViewportState
)

data class HistoryNodeComparison(
    val fromNode: HistoryNodeID,
    val toNode: HistoryNodeID,
    val elementChanges: List<ElementChange>,
    val viewportChanges: ViewportChange?,
    val timestamp: Long
) {
    val hasChanges: Boolean
        get() = elementChanges.isNotEmpty() || viewportChanges != null
}

// MARK: - History State

data class HistoryState(
    val nodes: Map<HistoryNodeID, HistoryNode> = emptyMap(),
    val branches: Map<String, HistoryBranch> = emptyMap(),
    val currentNodeId: HistoryNodeID? = null,
    val activeBranchId: String? = null,
    val canUndo: Boolean = false,
    val canRedo: Boolean = false
)

sealed class HistoryNavigationResult {
    data class Success(val data: DesignCanvasData) : HistoryNavigationResult()
    data class Failure(val message: String) : HistoryNavigationResult()
    object NoChange : HistoryNavigationResult()
}

// MARK: - Android History Manager

class HistoryManager(
    private val database: HistoryDatabase,
    private val maxHistorySize: Int = 1000
) : ViewModel() {

    private val _state = MutableStateFlow(HistoryState())
    val state: StateFlow<HistoryState> = _state.asStateFlow()

    private val undoStack = mutableListOf<HistoryNodeID>()
    private val redoStack = mutableListOf<HistoryNodeID>()

    private val json = Json { 
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    init {
        viewModelScope.launch {
            loadFromDatabase()
        }
    }

    // MARK: - Public API

    fun createSnapshot(
        data: DesignCanvasData, 
        branchName: String? = null
    ): Flow<HistoryNavigationResult> = flow {
        try {
            val parentIds = _state.value.currentNodeId?.let { setOf(it) } ?: emptySet()
            val newNode = HistoryNode(
                id = HistoryNodeID.generate(),
                data = data,
                parentIds = parentIds,
                branchName = branchName
            )

            val currentNodes = _state.value.nodes.toMutableMap()
            currentNodes[newNode.id] = newNode

            // Update parent-child relationships
            _state.value.currentNodeId?.let { parentId ->
                currentNodes[parentId]?.addChild(newNode.id)
            }

            // Handle branching
            var newBranches = _state.value.branches
            var newActiveBranchId = _state.value.activeBranchId

            if (branchName != null) {
                val branch = HistoryBranch(
                    name = branchName,
                    startNodeId = newNode.id,
                    color = androidx.compose.ui.graphics.Color.Blue
                )
                newBranches = newBranches + (branch.id to branch)
                newActiveBranchId = branch.id
            } else if (_state.value.activeBranchId != null) {
                val activeBranch = newBranches[_state.value.activeBranchId!!]
                activeBranch?.addNode(newNode.id)
            }

            // Update undo/redo stacks
            undoStack.add(newNode.id)
            redoStack.clear()

            // Enforce size limits
            enforceHistorySize(currentNodes)

            // Update state
            val newState = HistoryState(
                nodes = currentNodes,
                branches = newBranches,
                currentNodeId = newNode.id,
                activeBranchId = newActiveBranchId,
                canUndo = undoStack.size > 1,
                canRedo = false
            )
            _state.value = newState

            // Persist to database
            persistToDatabase()

            emit(HistoryNavigationResult.Success(data))
        } catch (e: Exception) {
            emit(HistoryNavigationResult.Failure("Failed to create snapshot: ${e.message}"))
        }
    }

    fun undo(): Flow<HistoryNavigationResult> = flow {
        try {
            if (undoStack.size <= 1) {
                emit(HistoryNavigationResult.Failure("Cannot undo: no previous state"))
                return@flow
            }

            val currentId = undoStack.removeLastOrNull()
            currentId?.let { redoStack.add(it) }

            val targetId = undoStack.lastOrNull()
            if (targetId == null) {
                emit(HistoryNavigationResult.Failure("Target node not found"))
                return@flow
            }

            val targetNode = _state.value.nodes[targetId]
            if (targetNode == null) {
                emit(HistoryNavigationResult.Failure("Target node not found"))
                return@flow
            }

            val newState = _state.value.copy(
                currentNodeId = targetId,
                canUndo = undoStack.size > 1,
                canRedo = redoStack.isNotEmpty()
            )
            _state.value = newState

            persistToDatabase()
            emit(HistoryNavigationResult.Success(targetNode.data))
        } catch (e: Exception) {
            emit(HistoryNavigationResult.Failure("Undo failed: ${e.message}"))
        }
    }

    fun redo(): Flow<HistoryNavigationResult> = flow {
        try {
            if (redoStack.isEmpty()) {
                emit(HistoryNavigationResult.Failure("Cannot redo: no forward state"))
                return@flow
            }

            val targetId = redoStack.removeLastOrNull()
            if (targetId == null) {
                emit(HistoryNavigationResult.Failure("Target node not found"))
                return@flow
            }

            undoStack.add(targetId)

            val targetNode = _state.value.nodes[targetId]
            if (targetNode == null) {
                emit(HistoryNavigationResult.Failure("Target node not found"))
                return@flow
            }

            val newState = _state.value.copy(
                currentNodeId = targetId,
                canUndo = undoStack.size > 1,
                canRedo = redoStack.isNotEmpty()
            )
            _state.value = newState

            persistToDatabase()
            emit(HistoryNavigationResult.Success(targetNode.data))
        } catch (e: Exception) {
            emit(HistoryNavigationResult.Failure("Redo failed: ${e.message}"))
        }
    }

    fun navigateToNode(nodeId: HistoryNodeID): Flow<HistoryNavigationResult> = flow {
        try {
            val targetNode = _state.value.nodes[nodeId]
            if (targetNode == null) {
                emit(HistoryNavigationResult.Failure("Node not found: $nodeId"))
                return@flow
            }

            // Update navigation stacks
            if (_state.value.currentNodeId != null) {
                if (!undoStack.contains(nodeId)) {
                    // Clear redo stack when jumping to a different branch
                    redoStack.clear()
                }
            }

            // Rebuild path to target node
            rebuildNavigationPath(nodeId)

            val newState = _state.value.copy(
                currentNodeId = nodeId,
                activeBranchId = findBranchForNode(nodeId),
                canUndo = undoStack.size > 1,
                canRedo = redoStack.isNotEmpty()
            )
            _state.value = newState

            persistToDatabase()
            emit(HistoryNavigationResult.Success(targetNode.data))
        } catch (e: Exception) {
            emit(HistoryNavigationResult.Failure("Navigation failed: ${e.message}"))
        }
    }

    fun createBranch(name: String, fromNode: HistoryNodeID? = null): String? {
        return try {
            val startNodeId = fromNode ?: _state.value.currentNodeId ?: HistoryNodeID.generate()
            val branch = HistoryBranch(
                name = name,
                startNodeId = startNodeId,
                color = androidx.compose.ui.graphics.Color.Blue
            )

            val newBranches = _state.value.branches + (branch.id to branch)
            val newState = _state.value.copy(
                branches = newBranches,
                activeBranchId = branch.id
            )
            _state.value = newState

            viewModelScope.launch { persistToDatabase() }
            branch.id
        } catch (e: Exception) {
            null
        }
    }

    fun switchToBranch(branchId: String): Flow<HistoryNavigationResult> = flow {
        try {
            val branch = _state.value.branches[branchId]
            if (branch == null) {
                emit(HistoryNavigationResult.Failure("Branch not found: $branchId"))
                return@flow
            }

            // Navigate to the latest node in the branch
            val latestNodeId = branch.nodeIds.lastOrNull() ?: branch.startNodeId
            navigateToNode(latestNodeId).collect { emit(it) }
        } catch (e: Exception) {
            emit(HistoryNavigationResult.Failure("Branch switch failed: ${e.message}"))
        }
    }

    fun deleteBranch(branchId: String): Boolean {
        return try {
            if (_state.value.branches[branchId] == null || _state.value.activeBranchId == branchId) {
                false
            } else {
                val newBranches = _state.value.branches - branchId
                val newState = _state.value.copy(branches = newBranches)
                _state.value = newState

                viewModelScope.launch { persistToDatabase() }
                true
            }
        } catch (e: Exception) {
            false
        }
    }

    fun compareNodes(nodeId1: HistoryNodeID, nodeId2: HistoryNodeID): HistoryNodeComparison? {
        val node1 = _state.value.nodes[nodeId1] ?: return null
        val node2 = _state.value.nodes[nodeId2] ?: return null
        return node1.compare(node2)
    }

    fun getPath(from: HistoryNodeID, to: HistoryNodeID): List<HistoryNodeID> {
        val visited = mutableSetOf<HistoryNodeID>()
        var path: List<HistoryNodeID> = emptyList()

        fun dfs(current: HistoryNodeID, target: HistoryNodeID, currentPath: List<HistoryNodeID>): Boolean {
            if (current == target) {
                path = currentPath + current
                return true
            }

            if (visited.contains(current)) {
                return false
            }

            visited.add(current)

            val node = _state.value.nodes[current] ?: return false
            for (childId in node.children) {
                if (dfs(childId, target, currentPath + current)) {
                    return true
                }
            }

            return false
        }

        dfs(from, to, emptyList())
        return path
    }

    // MARK: - Export/Import

    fun exportHistory(): String? {
        return try {
            val exportData = HistoryExportData(
                nodes = _state.value.nodes.values.toList(),
                branches = _state.value.branches.values.toList(),
                currentNodeId = _state.value.currentNodeId,
                activeBranchId = _state.value.activeBranchId
            )
            json.encodeToString(exportData)
        } catch (e: Exception) {
            null
        }
    }

    fun importHistory(jsonData: String): Boolean {
        return try {
            val importData = json.decodeFromString<HistoryExportData>(jsonData)
            
            val newNodes = importData.nodes.associateBy { it.id }
            val newBranches = importData.branches.associateBy { it.id }

            val newState = HistoryState(
                nodes = newNodes,
                branches = newBranches,
                currentNodeId = importData.currentNodeId,
                activeBranchId = importData.activeBranchId,
                canUndo = true,
                canRedo = false
            )
            _state.value = newState

            // Rebuild navigation stacks
            rebuildNavigationStacks()
            viewModelScope.launch { persistToDatabase() }

            true
        } catch (e: Exception) {
            false
        }
    }

    // MARK: - Private Methods

    private fun enforceHistorySize(nodes: MutableMap<HistoryNodeID, HistoryNode>) {
        if (nodes.size <= maxHistorySize) return

        // Remove oldest nodes (simple FIFO strategy)
        val sortedNodes = nodes.values.sortedBy { it.data.timestamp }
        val nodesToRemove = sortedNodes.take(nodes.size - maxHistorySize)

        nodesToRemove.forEach { node ->
            nodes.remove(node.id)

            // Update parent-child relationships
            node.parentIds.forEach { parentId ->
                nodes[parentId]?.removeChild(node.id)
            }

            // Remove from navigation stacks
            undoStack.remove(node.id)
            redoStack.remove(node.id)
        }
    }

    private fun rebuildNavigationPath(targetId: HistoryNodeID) {
        if (_state.value.currentNodeId == null) return

        val path = getPath(findRootNode(), targetId)
        undoStack.clear()
        undoStack.addAll(path)
    }

    private fun rebuildNavigationStacks() {
        val currentId = _state.value.currentNodeId ?: return
        val path = getPath(findRootNode(), currentId)
        undoStack.clear()
        undoStack.addAll(path)
        redoStack.clear()
    }

    private fun findRootNode(): HistoryNodeID {
        // Find a node with no parents
        _state.value.nodes.values.forEach { node ->
            if (node.parentIds.isEmpty()) {
                return node.id
            }
        }
        // Fallback to first node
        return _state.value.nodes.keys.firstOrNull() ?: HistoryNodeID.generate()
    }

    private fun findBranchForNode(nodeId: HistoryNodeID): String? {
        _state.value.branches.values.forEach { branch ->
            if (branch.nodeIds.contains(nodeId)) {
                return branch.id
            }
        }
        return null
    }

    // MARK: - Database Operations

    private suspend fun persistToDatabase() {
        try {
            // Save nodes
            _state.value.nodes.values.forEach { node ->
                val entity = HistoryNodeEntity(
                    id = node.id.value,
                    dataJson = json.encodeToString(node.data),
                    parentIds = node.parentIds.map { it.value },
                    branchName = node.branchName,
                    isBookmarked = node.isBookmarked,
                    tags = node.tags.toList(),
                    description = node.description
                )
                database.historyNodeDao().insertNode(entity)
            }

            // Save branches
            _state.value.branches.values.forEach { branch ->
                val entity = HistoryBranchEntity(
                    id = branch.id,
                    name = branch.name,
                    startNodeId = branch.startNodeId.value,
                    colorHex = "#0000FF", // Simple color serialization
                    isActive = branch.isActive,
                    description = branch.description,
                    nodeIds = branch.nodeIds.map { it.value }
                )
                database.historyBranchDao().insertBranch(entity)
            }

            // Save current state
            val stateEntity = HistoryStateEntity(
                currentNodeId = _state.value.currentNodeId?.value,
                activeBranchId = _state.value.activeBranchId
            )
            database.historyStateDao().insertHistoryState(stateEntity)

        } catch (e: Exception) {
            // Handle persistence errors
            println("Database persistence error: ${e.message}")
        }
    }

    private suspend fun loadFromDatabase() {
        try {
            val nodeEntities = database.historyNodeDao().getAllNodes().first()
            val branchEntities = database.historyBranchDao().getAllBranches().first()
            val stateEntity = database.historyStateDao().getHistoryState()

            val loadedNodes = mutableMapOf<HistoryNodeID, HistoryNode>()
            
            nodeEntities.forEach { entity ->
                val data = json.decodeFromString<DesignCanvasData>(entity.dataJson)
                val nodeId = HistoryNodeID(entity.id)
                val parentIds = entity.parentIds.map { HistoryNodeID(it) }.toSet()
                
                val node = HistoryNode(
                    id = nodeId,
                    data = data,
                    parentIds = parentIds,
                    branchName = entity.branchName
                )
                node.isBookmarked = entity.isBookmarked
                node.tags.addAll(entity.tags)
                node.description = entity.description
                
                loadedNodes[nodeId] = node
            }

            val loadedBranches = mutableMapOf<String, HistoryBranch>()
            branchEntities.forEach { entity ->
                val branch = HistoryBranch(
                    id = entity.id,
                    name = entity.name,
                    startNodeId = HistoryNodeID(entity.startNodeId),
                    color = androidx.compose.ui.graphics.Color.Blue // Simple color deserialization
                )
                branch.isActive = entity.isActive
                branch.description = entity.description
                branch.nodeIds.addAll(entity.nodeIds.map { HistoryNodeID(it) })
                
                loadedBranches[entity.id] = branch
            }

            val newState = HistoryState(
                nodes = loadedNodes,
                branches = loadedBranches,
                currentNodeId = stateEntity?.currentNodeId?.let { HistoryNodeID(it) },
                activeBranchId = stateEntity?.activeBranchId,
                canUndo = loadedNodes.isNotEmpty(),
                canRedo = false
            )
            _state.value = newState

            // Rebuild parent-child relationships
            loadedNodes.values.forEach { node ->
                node.parentIds.forEach { parentId ->
                    loadedNodes[parentId]?.addChild(node.id)
                }
            }

            rebuildNavigationStacks()

        } catch (e: Exception) {
            println("Database load error: ${e.message}")
        }
    }

    override fun onCleared() {
        super.onCleared()
        // Clean up any resources if needed
    }
}

// MARK: - Export Data Types

@Serializable
private data class HistoryExportData(
    val nodes: List<HistoryNode>,
    val branches: List<HistoryBranch>,
    val currentNodeId: HistoryNodeID?,
    val activeBranchId: String?
)

// MARK: - Compose Integration

@Composable
fun rememberHistoryManager(database: HistoryDatabase): HistoryManager {
    return remember { HistoryManager(database) }
}

@Composable
fun collectHistoryState(historyManager: HistoryManager): State<HistoryState> {
    return historyManager.state.collectAsState()
}
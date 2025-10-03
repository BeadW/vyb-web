import Foundation
import CoreData
import SwiftUI

// MARK: - Device Type Enum
enum DeviceType: String, CaseIterable, Codable {
    case iPhone15Pro = "iPhone 15 Pro"
    case iPhone15Plus = "iPhone 15 Plus"
    case iPadPro11 = "iPad Pro 11\""
    case iPadPro129 = "iPad Pro 12.9\""
    case pixel8Pro = "Pixel 8 Pro"
    case galaxyS24Ultra = "Galaxy S24 Ultra"
    case macBookPro14 = "MacBook Pro 14\""
    case desktop1920x1080 = "Desktop 1920x1080"
}

// MARK: - Canvas State Enum
enum CanvasState: String, CaseIterable, Codable {
    case editing = "editing"
    case aiProcessing = "ai-processing"
    case viewing = "viewing"
    case loading = "loading"
}

// MARK: - Canvas Dimensions
struct CanvasDimensions: Codable {
    let width: Double
    let height: Double
    let pixelDensity: Double
}

// MARK: - Canvas Metadata
struct CanvasMetadata: Codable {
    var createdAt: Date
    var modifiedAt: Date
    var tags: [String]
    var description: String?
    var author: String?
}

// MARK: - Core Data Entity
@objc(DesignCanvas)
public class DesignCanvas: NSManagedObject {
    
    // MARK: - Core Data Properties
    @NSManaged public var id: String
    @NSManaged public var deviceTypeRaw: String
    @NSManaged public var dimensionsData: Data
    @NSManaged public var metadataData: Data
    @NSManaged public var stateRaw: String
    @NSManaged public var layers: NSSet?
    
    // MARK: - Computed Properties
    public var deviceType: DeviceType {
        get {
            return DeviceType(rawValue: deviceTypeRaw) ?? .iPhone15Pro
        }
        set {
            deviceTypeRaw = newValue.rawValue
        }
    }
    
    public var dimensions: CanvasDimensions {
        get {
            do {
                return try JSONDecoder().decode(CanvasDimensions.self, from: dimensionsData)
            } catch {
                return CanvasDimensions(width: 393, height: 852, pixelDensity: 3) // Default iPhone 15 Pro
            }
        }
        set {
            do {
                dimensionsData = try JSONEncoder().encode(newValue)
            } catch {
                print("Failed to encode dimensions: \(error)")
            }
        }
    }
    
    public var metadata: CanvasMetadata {
        get {
            do {
                return try JSONDecoder().decode(CanvasMetadata.self, from: metadataData)
            } catch {
                return CanvasMetadata(createdAt: Date(), modifiedAt: Date(), tags: [])
            }
        }
        set {
            do {
                metadataData = try JSONEncoder().encode(newValue)
            } catch {
                print("Failed to encode metadata: \(error)")
            }
        }
    }
    
    public var state: CanvasState {
        get {
            return CanvasState(rawValue: stateRaw) ?? .editing
        }
        set {
            stateRaw = newValue.rawValue
        }
    }
    
    public var layersArray: [Layer] {
        let layersSet = layers as? Set<Layer> ?? []
        return layersSet.sorted { $0.zIndex < $1.zIndex }
    }
}

// MARK: - Validation Methods
extension DesignCanvas {
    
    public func validateCanvasData() throws {
        // Validate Canvas ID
        guard !id.isEmpty else {
            throw ValidationError.invalidCanvasID("Canvas ID must be a valid non-empty string")
        }
        
        // Validate Device Type
        guard DeviceType(rawValue: deviceTypeRaw) != nil else {
            throw ValidationError.invalidDeviceType("Device type must be a supported device specification")
        }
        
        // Validate Dimensions
        guard dimensions.width > 0 && dimensions.height > 0 && dimensions.pixelDensity > 0 else {
            throw ValidationError.invalidDimensions("Canvas dimensions must have positive width, height, and pixelDensity")
        }
        
        // Validate aspect ratio against device specifications
        try validateDeviceAspectRatio()
        
        // Validate layers
        guard let layersSet = layers, layersSet.count > 0 else {
            throw ValidationError.noLayers("Canvas must contain at least one layer to be considered valid")
        }
        
        // Validate z-index ordering
        try validateZIndexOrdering()
    }
    
    private func validateDeviceAspectRatio() throws {
        let expectedRatios: [DeviceType: Double] = [
            .iPhone15Pro: 393.0 / 852.0,
            .iPhone15Plus: 428.0 / 926.0,
            .iPadPro11: 834.0 / 1194.0,
            .iPadPro129: 1024.0 / 1366.0,
            .pixel8Pro: 448.0 / 998.0,
            .galaxyS24Ultra: 440.0 / 956.0,
            .macBookPro14: 1512.0 / 982.0,
            .desktop1920x1080: 1920.0 / 1080.0
        ]
        
        let actualRatio = dimensions.width / dimensions.height
        let expectedRatio = expectedRatios[deviceType] ?? (393.0 / 852.0)
        let tolerance = 0.01
        
        if abs(actualRatio - expectedRatio) > tolerance {
            throw ValidationError.aspectRatioMismatch("Dimensions must maintain accurate aspect ratios for target device")
        }
    }
    
    private func validateZIndexOrdering() throws {
        let layersArray = self.layersArray
        
        for i in 1..<layersArray.count {
            if layersArray[i].zIndex < layersArray[i-1].zIndex {
                throw ValidationError.invalidZIndex("Layers must be ordered with valid z-index values")
            }
        }
    }
}

// MARK: - Convenience Methods
extension DesignCanvas {
    
    @discardableResult
    public func setState(_ newState: CanvasState) -> DesignCanvas {
        state = newState
        var currentMetadata = metadata
        currentMetadata.modifiedAt = Date()
        metadata = currentMetadata
        return self
    }
    
    public func addLayer(_ layer: Layer) throws {
        // Validate layer doesn't already exist
        if layersArray.contains(where: { $0.id == layer.id }) {
            throw ValidationError.duplicateLayer("Layer with ID \(layer.id) already exists")
        }
        
        // Set appropriate z-index
        let maxZIndex = layersArray.map { $0.zIndex }.max() ?? -1
        layer.zIndex = Int32(maxZIndex + 1)
        layer.canvas = self
        
        // Update modified date
        var currentMetadata = metadata
        currentMetadata.modifiedAt = Date()
        metadata = currentMetadata
    }
    
    public func removeLayer(withId layerId: String) throws {
        guard let layer = layersArray.first(where: { $0.id == layerId }) else {
            throw ValidationError.layerNotFound("Layer with ID \(layerId) not found")
        }
        
        // Ensure we don't remove the last layer
        if layersArray.count <= 1 {
            throw ValidationError.noLayers("Canvas must contain at least one layer to be considered valid")
        }
        
        managedObjectContext?.delete(layer)
        
        // Update modified date
        var currentMetadata = metadata
        currentMetadata.modifiedAt = Date()
        metadata = currentMetadata
    }
    
    public func getLayer(withId layerId: String) -> Layer? {
        return layersArray.first { $0.id == layerId }
    }
}

// MARK: - Device Specifications
extension DesignCanvas {
    
    public struct DeviceSpec {
        let name: String
        let category: String
        let os: String
    }
    
    public func getDeviceSpec() -> DeviceSpec {
        let deviceSpecs: [DeviceType: DeviceSpec] = [
            .iPhone15Pro: DeviceSpec(name: "iPhone 15 Pro", category: "phone", os: "ios"),
            .iPhone15Plus: DeviceSpec(name: "iPhone 15 Plus", category: "phone", os: "ios"),
            .iPadPro11: DeviceSpec(name: "iPad Pro 11\"", category: "tablet", os: "ios"),
            .iPadPro129: DeviceSpec(name: "iPad Pro 12.9\"", category: "tablet", os: "ios"),
            .pixel8Pro: DeviceSpec(name: "Pixel 8 Pro", category: "phone", os: "android"),
            .galaxyS24Ultra: DeviceSpec(name: "Galaxy S24 Ultra", category: "phone", os: "android"),
            .macBookPro14: DeviceSpec(name: "MacBook Pro 14\"", category: "desktop", os: "web"),
            .desktop1920x1080: DeviceSpec(name: "Desktop 1920x1080", category: "desktop", os: "web")
        ]
        
        return deviceSpecs[deviceType] ?? DeviceSpec(name: "iPhone 15 Pro", category: "phone", os: "ios")
    }
}

// MARK: - JSON Serialization
extension DesignCanvas {
    
    public func toJSON() -> [String: Any] {
        return [
            "id": id,
            "deviceType": deviceType.rawValue,
            "dimensions": [
                "width": dimensions.width,
                "height": dimensions.height,
                "pixelDensity": dimensions.pixelDensity
            ],
            "layers": layersArray.map { $0.toJSON() },
            "metadata": [
                "createdAt": ISO8601DateFormatter().string(from: metadata.createdAt),
                "modifiedAt": ISO8601DateFormatter().string(from: metadata.modifiedAt),
                "tags": metadata.tags,
                "description": metadata.description as Any,
                "author": metadata.author as Any
            ],
            "state": state.rawValue
        ]
    }
    
    public static func fromJSON(_ json: [String: Any], in context: NSManagedObjectContext) throws -> DesignCanvas {
        guard let id = json["id"] as? String,
              let deviceTypeString = json["deviceType"] as? String,
              let deviceType = DeviceType(rawValue: deviceTypeString),
              let dimensionsDict = json["dimensions"] as? [String: Any],
              let width = dimensionsDict["width"] as? Double,
              let height = dimensionsDict["height"] as? Double,
              let pixelDensity = dimensionsDict["pixelDensity"] as? Double,
              let stateString = json["state"] as? String,
              let state = CanvasState(rawValue: stateString),
              let metadataDict = json["metadata"] as? [String: Any],
              let createdAtString = metadataDict["createdAt"] as? String,
              let modifiedAtString = metadataDict["modifiedAt"] as? String,
              let tags = metadataDict["tags"] as? [String] else {
            throw ValidationError.invalidJSONData("Invalid JSON data for DesignCanvas")
        }
        
        let canvas = DesignCanvas(context: context)
        canvas.id = id
        canvas.deviceType = deviceType
        canvas.dimensions = CanvasDimensions(width: width, height: height, pixelDensity: pixelDensity)
        canvas.state = state
        
        let formatter = ISO8601DateFormatter()
        let createdAt = formatter.date(from: createdAtString) ?? Date()
        let modifiedAt = formatter.date(from: modifiedAtString) ?? Date()
        
        canvas.metadata = CanvasMetadata(
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            tags: tags,
            description: metadataDict["description"] as? String,
            author: metadataDict["author"] as? String
        )
        
        return canvas
    }
}

// MARK: - Validation Errors
enum ValidationError: LocalizedError {
    case invalidCanvasID(String)
    case invalidDeviceType(String)
    case invalidDimensions(String)
    case aspectRatioMismatch(String)
    case invalidZIndex(String)
    case noLayers(String)
    case duplicateLayer(String)
    case layerNotFound(String)
    case invalidJSONData(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCanvasID(let message),
             .invalidDeviceType(let message),
             .invalidDimensions(let message),
             .aspectRatioMismatch(let message),
             .invalidZIndex(let message),
             .noLayers(let message),
             .duplicateLayer(let message),
             .layerNotFound(let message),
             .invalidJSONData(let message):
            return message
        }
    }
}

// MARK: - Core Data Generated Accessors
extension DesignCanvas {

    @objc(addLayersObject:)
    @NSManaged public func addToLayers(_ value: Layer)

    @objc(removeLayersObject:)
    @NSManaged public func removeFromLayers(_ value: Layer)

    @objc(addLayers:)
    @NSManaged public func addToLayers(_ values: NSSet)

    @objc(removeLayers:)
    @NSManaged public func removeFromLayers(_ values: NSSet)
}
import Foundation
import SwiftUI

/// Device simulation models and types
/// Contains all necessary types for device simulation functionality

/// Enumeration of supported device types for device simulation
public enum SimulationDeviceType: String, CaseIterable, Identifiable {
    case mobile = "mobile"
    case tablet = "tablet"
    case desktop = "desktop"
    case watch = "watch"
    case tv = "tv"
    
    public var id: String { rawValue }
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .mobile: return "Mobile"
        case .tablet: return "Tablet"
        case .desktop: return "Desktop"
        case .watch: return "Watch"
        case .tv: return "TV"
        }
    }
}

/// Device specifications for accurate device simulation
public struct DeviceSpecifications {
    
    /// Individual device specification
    public struct DeviceSpec {
        public let minWidth: CGFloat
        public let minHeight: CGFloat
        public let pixelRatio: CGFloat
        public let aspectRatios: [AspectRatio]
        
        public init(minWidth: CGFloat, minHeight: CGFloat, pixelRatio: CGFloat = 1.0, aspectRatios: [AspectRatio]) {
            self.minWidth = minWidth
            self.minHeight = minHeight
            self.pixelRatio = pixelRatio
            self.aspectRatios = aspectRatios
        }
    }
    
    /// Aspect ratio specification
    public struct AspectRatio {
        public let name: String
        public let ratio: CGFloat
        public let width: CGFloat
        public let height: CGFloat
        
        public init(name: String, ratio: CGFloat, width: CGFloat, height: CGFloat) {
            self.name = name
            self.ratio = ratio
            self.width = width
            self.height = height
        }
    }
    
    /// Comprehensive device specifications database
    public static let DEVICE_SPECS: [SimulationDeviceType: DeviceSpec] = [
        .mobile: DeviceSpec(
            minWidth: 375,
            minHeight: 812,
            pixelRatio: 3.0,
            aspectRatios: [
                AspectRatio(name: "iPhone 14", ratio: 19.5/9, width: 390, height: 844),
                AspectRatio(name: "iPhone SE", ratio: 16/9, width: 375, height: 667)
            ]
        ),
        .tablet: DeviceSpec(
            minWidth: 768,
            minHeight: 1024,
            pixelRatio: 2.0,
            aspectRatios: [
                AspectRatio(name: "iPad Pro", ratio: 4/3, width: 1024, height: 1366),
                AspectRatio(name: "iPad Air", ratio: 4/3, width: 820, height: 1180)
            ]
        ),
        .desktop: DeviceSpec(
            minWidth: 1280,
            minHeight: 720,
            pixelRatio: 1.0,
            aspectRatios: [
                AspectRatio(name: "1080p HD", ratio: 16/9, width: 1920, height: 1080),
                AspectRatio(name: "4K UHD", ratio: 16/9, width: 3840, height: 2160)
            ]
        ),
        .watch: DeviceSpec(
            minWidth: 184,
            minHeight: 224,
            pixelRatio: 2.0,
            aspectRatios: [
                AspectRatio(name: "Apple Watch", ratio: 1.22, width: 198, height: 242)
            ]
        ),
        .tv: DeviceSpec(
            minWidth: 1920,
            minHeight: 1080,
            pixelRatio: 1.0,
            aspectRatios: [
                AspectRatio(name: "Apple TV 4K", ratio: 16/9, width: 1920, height: 1080)
            ]
        )
    ]
}

/// Device Simulation SwiftUI View for iOS
struct DeviceSimulationView: View {
    
    let deviceType: SimulationDeviceType
    @State private var currentScale: Double = 1.0
    @State private var isLandscape: Bool = false
    
    private var deviceSpec: DeviceSpecifications.DeviceSpec {
        return DeviceSpecifications.DEVICE_SPECS[deviceType] ?? DeviceSpecifications.DEVICE_SPECS[SimulationDeviceType.mobile]!
    }
    
    private var displayDimensions: CGSize {
        let baseWidth = deviceSpec.minWidth
        let baseHeight = deviceSpec.minHeight
        
        return isLandscape 
            ? CGSize(width: baseHeight, height: baseWidth)
            : CGSize(width: baseWidth, height: baseHeight)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Device Controls
            deviceControlsView
            
            // Device Simulation Area
            ScrollView([.horizontal, .vertical]) {
                deviceSimulationContent
                    .padding(40)
            }
            .background(Color.gray.opacity(0.1))
        }
        .navigationTitle("Device Simulation")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var deviceControlsView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(deviceSpec.aspectRatios.first?.name ?? "Custom")
                    .font(.headline)
                Text("\(Int(displayDimensions.width))×\(Int(displayDimensions.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Text("Scale:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: $currentScale, in: 0.25...2.0, step: 0.25)
                    .frame(width: 100)
                
                Text("\(Int(currentScale * 100))%")
                    .font(.caption)
                    .frame(width: 35, alignment: .trailing)
            }
            
            Button(action: { isLandscape.toggle() }) {
                Image(systemName: isLandscape ? "rotate.left" : "rotate.right")
                    .font(.title2)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.white)
    }
    
    private var deviceSimulationContent: some View {
        deviceFrameView
            .scaleEffect(currentScale)
            .animation(.easeInOut(duration: 0.3), value: currentScale)
            .animation(.easeInOut(duration: 0.3), value: isLandscape)
    }
    
    private var deviceFrameView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black)
                .frame(width: displayDimensions.width, height: displayDimensions.height)
                .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
            
            screenContentView
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(12)
        }
    }
    
    private var screenContentView: some View {
        Rectangle()
            .fill(Color.white)
            .overlay(
                VStack {
                    Spacer()
                    Image(systemName: "photo")
                        .font(.system(size: 64))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("Canvas content will appear here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            )
    }
}

struct DeviceSimulationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeviceSimulationView(deviceType: SimulationDeviceType.mobile)
        }
    }
}
import SwiftUI
import CoreData

// MARK: - UI Components

struct FontStyleButton: View {
    enum Style {
        case bold, italic, underline
        
        var iconName: String {
            switch self {
            case .bold: return "bold"
            case .italic: return "italic"
            case .underline: return "underline"
            }
        }
    }
    
    let style: Style
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: style.iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isActive ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? Color.blue : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FontFamilyButton: View {
    let font: FontFamily
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Aa")
                .font(.custom(font.systemName, size: 18))
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 50, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TextAlignmentButton: View {
    let alignment: CustomTextAlignment
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: alignment.iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 40, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MediaSourceButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ImageAdjustmentSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            
            Slider(value: $value, in: range)
            
            Text(String(format: "%.1f", value))
                .font(.caption)
                .frame(width: 30)
        }
    }
}

struct ShapeButton: View {
    let shape: ShapeType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                shape.icon
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                
                Text(shape.displayName)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
        }
    }
}

struct ShadowSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Slider(value: $value, in: range)
            
            Text(String(format: "%.0f", value))
                .font(.caption)
                .frame(width: 25)
        }
    }
}

// MARK: - Supporting Enums and Types

enum FontFamily: String, CaseIterable {
    case systemDefault = "System"
    case helvetica = "Helvetica"
    case times = "Times"
    case courier = "Courier"
    case georgia = "Georgia"
    case verdana = "Verdana"
    
    var displayName: String {
        return rawValue
    }
    
    var systemName: String {
        switch self {
        case .systemDefault:
            return ".SF UI Text"
        case .helvetica:
            return "Helvetica"
        case .times:
            return "Times New Roman"
        case .courier:
            return "Courier New"
        case .georgia:
            return "Georgia"
        case .verdana:
            return "Verdana"
        }
    }
}

enum CustomTextAlignment: String, CaseIterable {
    case left, center, right, justify
    
    var iconName: String {
        switch self {
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        case .justify: return "text.justify"
        }
    }
}

enum ShapeType: String, CaseIterable {
    case rectangle, circle, triangle, star, arrow, heart
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    @ViewBuilder
    var icon: some View {
        switch self {
        case .rectangle:
            Image(systemName: "rectangle")
        case .circle:
            Image(systemName: "circle")
        case .triangle:
            Image(systemName: "triangle")
        case .star:
            Image(systemName: "star")
        case .arrow:
            Image(systemName: "arrow.right")
        case .heart:
            Image(systemName: "heart")
        }
    }
}

// MARK: - Extensions

extension Color {
    // Color extension methods already defined in LayerCanvas.swift
    
    func toHex() -> String {
        // For now, return a placeholder - this would need platform-specific implementation
        return "#000000"
    }
}

// MARK: - Layer Style Extensions

// Extensions would be added here based on LayerStyle structure
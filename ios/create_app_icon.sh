#!/bin/bash

# Simple script to create app icon images using macOS built-in tools

# Create the directory for our icon images
mkdir -p icon_temp

# Create a simple VYB icon using native macOS tools
# We'll create different sizes for the app icon

echo "Creating VYB app icon..."

# Use built-in textutil and other commands to create a basic icon
# Create a base image using Swift/SwiftUI rendering

cat > create_icon.swift << 'EOF'
import SwiftUI
import AppKit

struct VYBIcon: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 4) {
                HStack(spacing: 1) {
                    Text("V").font(.system(size: 40, weight: .black)).foregroundColor(.white)
                    Text("Y").font(.system(size: 40, weight: .black)).foregroundColor(.yellow)
                    Text("B").font(.system(size: 40, weight: .black)).foregroundColor(.white)
                }
                .shadow(radius: 2)
            }
        }
        .frame(width: 120, height: 120)
        .cornerRadius(26)
    }
}

@main
struct IconGenerator {
    static func main() {
        let view = VYBIcon()
        let hosting = NSHostingView(rootView: view)
        hosting.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
        
        let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds)!
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        
        let image = NSImage(size: hosting.bounds.size)
        image.addRepresentation(rep)
        
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try! pngData.write(to: URL(fileURLWithPath: "icon_temp/vyb-icon-120.png"))
        }
    }
}
EOF

# Try to compile and run the Swift script
echo "Attempting to create icon with Swift..."
if swift create_icon.swift 2>/dev/null; then
    echo "Icon created successfully!"
else
    echo "Swift compilation failed, creating simple placeholder..."
    # Create a simple colored square as fallback
    python3 << 'EOF'
from PIL import Image, ImageDraw, ImageFont
import os

def create_icon():
    # Create a simple icon
    size = 1024
    image = Image.new('RGB', (size, size), '#4A90E2')
    draw = ImageDraw.Draw(image)
    
    # Try to use a system font
    try:
        font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', size//6)
    except:
        font = ImageFont.load_default()
    
    # Draw VYB text
    text = "VYB"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0] 
    text_height = bbox[3] - bbox[1]
    
    x = (size - text_width) // 2
    y = (size - text_height) // 2
    
    draw.text((x, y), text, fill='white', font=font)
    
    # Save in different sizes
    os.makedirs('icon_temp', exist_ok=True)
    image.save('icon_temp/vyb-icon-1024.png')
    
    # Create smaller versions
    for s in [512, 256, 128, 64, 32, 16]:
        small = image.resize((s, s), Image.Resampling.LANCZOS)
        small.save(f'icon_temp/vyb-icon-{s}.png')

create_icon()
print("Icon created with Python!")
EOF
fi

# Copy the icon to the Assets catalog if we have one
if [ -f "icon_temp/vyb-icon-1024.png" ]; then
    echo "Copying icon to Assets.xcassets..."
    cp icon_temp/vyb-icon-1024.png VYB/Assets.xcassets/AppIcon.appiconset/
    echo "Icon installation complete!"
    ls -la VYB/Assets.xcassets/AppIcon.appiconset/
else
    echo "Failed to create icon"
fi

# Clean up
rm -f create_icon.swift
echo "Done!"
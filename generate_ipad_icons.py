#!/usr/bin/env python3
"""
Generate missing iPad app icons from the 1024x1024 source
Run this script from the StepPet directory:
    python3 generate_ipad_icons.py
"""

from PIL import Image
import os

# Source icon (1024x1024)
source_path = "Assets.xcassets/AppIcon.appiconset/Virtupet1024.png"
output_dir = "Assets.xcassets/AppIcon.appiconset"

# iPad icon sizes needed
ipad_icons = [
    ("Virtupet-ipad-20.png", 20),
    ("Virtupet-ipad-29.png", 29),
    ("Virtupet-ipad-76.png", 76),
    ("Virtupet-ipad-152.png", 152),
    ("Virtupet-ipad-167.png", 167),
]

def generate_icons():
    # Check if PIL/Pillow is available
    try:
        from PIL import Image
    except ImportError:
        print("❌ Pillow is not installed. Install it with:")
        print("   pip3 install Pillow")
        return False
    
    # Check if source exists
    if not os.path.exists(source_path):
        print(f"❌ Source icon not found: {source_path}")
        return False
    
    # Open source image
    print(f"📂 Opening source: {source_path}")
    source = Image.open(source_path)
    
    # Generate each icon
    for filename, size in ipad_icons:
        output_path = os.path.join(output_dir, filename)
        print(f"🔄 Generating {filename} ({size}x{size})...")
        
        # Resize with high quality
        resized = source.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(output_path, "PNG")
        print(f"✅ Saved: {output_path}")
    
    print("\n🎉 All iPad icons generated successfully!")
    print("📱 Now try archiving and uploading again in Xcode.")
    return True

if __name__ == "__main__":
    generate_icons()

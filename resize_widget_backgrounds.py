#!/usr/bin/env python3
"""
Resize widget background images to appropriate sizes for iOS widgets.
Creates @1x, @2x, @3x versions for each widget size.
Also creates a separate optimized small widget image.
"""

from PIL import Image
import os
import json
import shutil

WIDGET_ASSETS_PATH = 'StepPetWidget/Assets.xcassets'

# iOS Widget sizes (in points, need @1x/@2x/@3x)
# Small widget: 169x169 pt (square)
# Medium widget: 360x169 pt (wide)  
# Large widget: 360x376 pt (tall rectangle)

def resize_widget_background(imageset_name, target_width, target_height, source_imageset=None):
    """Resize a widget background image to target size with @1x/@2x/@3x."""
    imageset_path = os.path.join(WIDGET_ASSETS_PATH, f'{imageset_name}.imageset')
    
    # If source_imageset is specified, copy from there first
    if source_imageset:
        source_path = os.path.join(WIDGET_ASSETS_PATH, f'{source_imageset}.imageset')
        if not os.path.exists(source_path):
            print(f"⚠️  Source {source_imageset} not found")
            return False
        
        # Create new imageset folder if it doesn't exist
        if not os.path.exists(imageset_path):
            os.makedirs(imageset_path)
        
        # Find and copy source image
        for filename in os.listdir(source_path):
            if filename.endswith('.png') and not '@' in filename:
                source_file = os.path.join(source_path, filename)
                dest_file = os.path.join(imageset_path, f'{imageset_name}_source.png')
                shutil.copy2(source_file, dest_file)
                break
    
    if not os.path.exists(imageset_path):
        print(f"⚠️  Skipping {imageset_name} - folder not found")
        return False
    
    # Find source image
    source_image = None
    for filename in os.listdir(imageset_path):
        if filename.endswith('.png') and not '@' in filename:
            source_image = os.path.join(imageset_path, filename)
            break
    
    if not source_image:
        print(f"⚠️  Skipping {imageset_name} - no source PNG found")
        return False
    
    print(f"\nProcessing {imageset_name}...")
    
    try:
        img = Image.open(source_image)
        print(f"  Original size: {img.size}")
        
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Create @1x, @2x, @3x versions
        sizes = {
            '': (target_width, target_height),           # @1x
            '@2x': (target_width * 2, target_height * 2), # @2x
            '@3x': (target_width * 3, target_height * 3), # @3x
        }
        
        image_entries = []
        
        for suffix, (w, h) in sizes.items():
            output_filename = f'{imageset_name}{suffix}.png'
            output_path = os.path.join(imageset_path, output_filename)
            
            # Resize with high quality
            resized = img.resize((w, h), Image.Resampling.LANCZOS)
            resized.save(output_path, 'PNG', optimize=True)
            
            if suffix == '@2x':
                scale = '2x'
            elif suffix == '@3x':
                scale = '3x'
            else:
                scale = '1x'
            
            image_entries.append({
                'filename': output_filename,
                'idiom': 'universal',
                'scale': scale
            })
            
            print(f"  ✓ Created {output_filename} ({w}x{h})")
        
        # Remove temporary source file if we created one
        temp_source = os.path.join(imageset_path, f'{imageset_name}_source.png')
        if os.path.exists(temp_source):
            os.remove(temp_source)
        
        # Update Contents.json
        contents_path = os.path.join(imageset_path, 'Contents.json')
        contents = {
            'images': image_entries,
            'info': {
                'author': 'xcode',
                'version': 1
            }
        }
        
        with open(contents_path, 'w') as f:
            json.dump(contents, f, indent=2)
        
        print(f"  ✓ Updated Contents.json")
        return True
        
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False

def main():
    print("=" * 60)
    print("Resizing widget background images for iOS")
    print("=" * 60)
    
    # Create SmallWidget - optimized for small widget (169x169 pt)
    # Copy from Virtupetwidget as source
    print("\n📱 Creating SmallWidget (169x169 pt) - NEW optimized for small widgets:")
    resize_widget_background('SmallWidget', 169, 169, source_imageset='Virtupetwidget')
    
    # Medium widget background (MiddleWidget) - 360x169 pt
    print("\n📱 Medium Widget Background (360x169 pt):")
    resize_widget_background('MiddleWidget', 360, 169)
    
    # Large widget keeps Virtupetwidget at a good size for large (360x376 pt)
    print("\n📱 Large Widget Background (360x376 pt):")
    resize_widget_background('Virtupetwidget', 360, 376)
    
    print("\n" + "=" * 60)
    print("Done!")
    print("=" * 60)
    print("\nNext: Update StepPetWidget.swift to use 'SmallWidget' for small widgets")

if __name__ == '__main__':
    main()

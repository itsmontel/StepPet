#!/usr/bin/env python3
"""
Resize pet images for Live Activity widget to appropriate sizes.
Creates @1x, @2x, @3x versions for better display on all devices.
"""

from PIL import Image
import os
import json

# Widget asset catalog path
WIDGET_ASSETS_PATH = 'StepPetWidget/Assets.xcassets'

# Pet image sets to process
PET_IMAGESETS = [
    'dogfullhealth', 'doghappy', 'dogcontent', 'dogsad', 'dogsick',
    'catfullhealth', 'cathappy', 'catcontent', 'catsad', 'catsick',
    'bunnyfullhealth', 'bunnyhappy', 'bunnycontent', 'bunnysad', 'bunnysick',
    'hamsterfullhealth', 'hamsterhappy', 'hamstercontent', 'hamstersad', 'hamstersick',
    'horsefullhealth', 'horsehappy', 'horsecontent', 'horsesad', 'horsesick',
]

# Target size for widget (logical pixels) - will create @1x, @2x, @3x
TARGET_SIZE = 80  # 80px logical = 80, 160, 240 physical pixels

def resize_imageset(imageset_name):
    """Resize a single imageset to widget-appropriate sizes."""
    imageset_path = os.path.join(WIDGET_ASSETS_PATH, f'{imageset_name}.imageset')
    
    if not os.path.exists(imageset_path):
        print(f"⚠️  Skipping {imageset_name} - folder not found")
        return False
    
    # Find the source image
    source_image = None
    for filename in os.listdir(imageset_path):
        if filename.endswith('.png') and not filename.endswith('@2x.png') and not filename.endswith('@3x.png'):
            source_image = os.path.join(imageset_path, filename)
            break
    
    if not source_image:
        print(f"⚠️  Skipping {imageset_name} - no source PNG found")
        return False
    
    print(f"Processing {imageset_name}...")
    
    try:
        # Open source image
        img = Image.open(source_image)
        original_size = img.size
        print(f"  Original size: {original_size}")
        
        # Ensure RGBA mode for transparency
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Create resized versions
        sizes = {
            '': TARGET_SIZE,           # @1x
            '@2x': TARGET_SIZE * 2,    # @2x
            '@3x': TARGET_SIZE * 3,    # @3x
        }
        
        image_entries = []
        
        for suffix, size in sizes.items():
            output_filename = f'{imageset_name}{suffix}.png'
            output_path = os.path.join(imageset_path, output_filename)
            
            # Resize with high quality
            resized = img.resize((size, size), Image.Resampling.LANCZOS)
            resized.save(output_path, 'PNG', optimize=True)
            
            # Determine scale for Contents.json
            if suffix == '':
                scale = '1x'
            elif suffix == '@2x':
                scale = '2x'
            else:
                scale = '3x'
            
            image_entries.append({
                'filename': output_filename,
                'idiom': 'universal',
                'scale': scale
            })
            
            print(f"  ✓ Created {output_filename} ({size}x{size})")
        
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
    print("=" * 50)
    print("Resizing pet images for Live Activity widget")
    print(f"Target size: {TARGET_SIZE}px (@1x), {TARGET_SIZE*2}px (@2x), {TARGET_SIZE*3}px (@3x)")
    print("=" * 50)
    print()
    
    success_count = 0
    fail_count = 0
    
    for imageset in PET_IMAGESETS:
        if resize_imageset(imageset):
            success_count += 1
        else:
            fail_count += 1
        print()
    
    print("=" * 50)
    print(f"Done! Resized {success_count} imagesets, {fail_count} failed/skipped")
    print("=" * 50)
    print()
    print("Next steps:")
    print("1. Open Xcode")
    print("2. Clean build folder (Shift+Cmd+K)")
    print("3. Rebuild and run the app")

if __name__ == '__main__':
    main()

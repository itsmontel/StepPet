from PIL import Image
import os

# Input and output configuration
input_file = 'Virtupet1024.png'
sizes = [40, 58, 60, 80, 87, 120, 180]

# Open the original image
print(f"Opening {input_file}...")
img = Image.open(input_file)
print(f"Original size: {img.size}")

# Resize to each target size
for size in sizes:
    output_file = f'Virtupet{size}x{size}.png'
    print(f"Resizing to {size}x{size}...")
    
    # Use LANCZOS resampling for high quality
    resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
    resized_img.save(output_file)
    
    print(f"✓ Saved {output_file}")

print("\nAll images resized successfully!")
print(f"Created {len(sizes)} new images.")





#!/usr/bin/env python3
"""
Image to Text Converter for Sobel Edge Detection
Converts images to/from text format for ModelSim simulation
"""

from PIL import Image
import numpy as np
import sys
import os

def image_to_text(input_path, output_path, width=None, height=None):
    """Convert image to text format for simulation"""
    try:
        # Load and convert to grayscale
        img = Image.open(input_path)
        print(f"Loaded: {input_path}")
        print(f"Original size: {img.size[0]}x{img.size[1]}, Mode: {img.mode}")
        
        if img.mode != 'L':
            img = img.convert('L')
            print("Converted to grayscale")
        
        # Resize if specified
        if width and height:
            img = img.resize((width, height), Image.LANCZOS)
            print(f"Resized to: {width}x{height}")
        
        # Convert to numpy array
        img_array = np.array(img)
        h, w = img_array.shape
        
        # Write to text file
        with open(output_path, 'w') as f:
            # Write dimensions as header
            f.write(f"{h} {w}\n")
            
            # Write pixel values (space-separated)
            for row in img_array:
                f.write(' '.join(str(int(pixel)) for pixel in row))
                f.write('\n')
        
        print(f"\n✓ Created: {output_path}")
        print(f"Dimensions: {h}x{w} pixels")
        print(f"Pixel range: [{img_array.min()}, {img_array.max()}]")
        print(f"Mean: {img_array.mean():.1f}")
        
        return True
        
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


def text_to_image(input_path, output_path):
    """Convert text format back to image"""
    try:
        with open(input_path, 'r') as f:
            lines = f.readlines()
        
        # Parse dimensions from header
        h, w = map(int, lines[0].strip().split())
        print(f"Reading {h}x{w} image from: {input_path}")
        
        # Parse pixel data
        img_array = np.zeros((h, w), dtype=np.uint8)
        for i, line in enumerate(lines[1:h+1]):
            pixels = list(map(int, line.strip().split()))
            img_array[i, :len(pixels)] = pixels[:w]
        
        # Create and save image
        img = Image.fromarray(img_array, mode='L')
        img.save(output_path)
        
        print(f"✓ Created: {output_path}")
        return True
        
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


def create_test_images():

    print("Creating sample test images...\n")
    
    # Sample 1: Simple shapes (128x128)
    size = 128
    img1 = np.zeros((size, size), dtype=np.uint8)
    
    # White rectangle
    img1[32:96, 32:96] = 255
    
    # Circle overlay
    y, x = np.ogrid[:size, :size]
    mask = (x - size//2)**2 + (y - size//2)**2 <= (size//4)**2
    img1[mask] = 180
    
    Image.fromarray(img1).save('sample_shapes.png')
    print("✓ Created: sample_shapes.png (128x128)")
    
    # Sample 2: Letter 'E'
    img2 = np.zeros((64, 64), dtype=np.uint8)
    img2[10:54, 10:15] = 255  # Vertical bar
    img2[10:15, 10:45] = 255  # Top horizontal
    img2[30:34, 10:40] = 255  # Middle horizontal
    img2[49:54, 10:45] = 255  # Bottom horizontal
    
    Image.fromarray(img2).save('sample_letter.png')
    print("✓ Created: sample_letter.png (64x64)")
    
    # Sample 3: Gradient
    img3 = np.linspace(0, 255, 64*64).reshape(64, 64).astype(np.uint8)
    Image.fromarray(img3).save('sample_gradient.png')
    print("✓ Created: sample_gradient.png (64x64)")
    
    print("\nUse these commands to convert:")
    print("  python image_converter.py to_text sample_shapes.png")
    print("  python image_converter.py to_text sample_letter.png")


def compare_images(original_path, edges_path, output_path='comparison.png'):
    """Create side-by-side comparison"""
    try:
        # Load images
        if original_path.endswith('.txt'):
            text_to_image(original_path, 'temp_orig.png')
            orig = Image.open('temp_orig.png')
        else:
            orig = Image.open(original_path).convert('L')
        
        if edges_path.endswith('.txt'):
            text_to_image(edges_path, 'temp_edges.png')
            edges = Image.open('temp_edges.png')
        else:
            edges = Image.open(edges_path).convert('L')
        
        # Create comparison
        width = orig.size[0] + edges.size[0] + 20
        height = max(orig.size[1], edges.size[1])
        
        comp = Image.new('L', (width, height), color=128)
        comp.paste(orig, (0, 0))
        comp.paste(edges, (orig.size[0] + 20, 0))
        comp.save(output_path)
        
        print(f"✓ Created comparison: {output_path}")
        
        # Cleanup
        for f in ['temp_orig.png', 'temp_edges.png']:
            if os.path.exists(f):
                os.remove(f)
        
        return True
        
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


def main():
    if len(sys.argv) < 2:
        print("=" * 60)
        print("Image Converter for Sobel Edge Detection Simulation")
        print("=" * 60)
        print("\nUsage:")
        print("  python image_converter.py to_text <image> [width height]")
        print("  python image_converter.py from_text <txtfile> <output>")
        print("  python image_converter.py compare <orig> <edges> [output]")
        print("  python image_converter.py samples")
        print("\nExamples:")
        print("  # Convert to text (original size)")
        print("  python image_converter.py to_text photo.jpg")
        print()
        print("  # Convert to text (resize to 128x128)")
        print("  python image_converter.py to_text photo.jpg 128 128")
        print()
        print("  # Convert simulation output to image")
        print("  python image_converter.py from_text output_edges.txt result.png")
        print()
        print("  # Create comparison")
        print("  python image_converter.py compare input.txt output_edges.txt")
        print()
        print("  # Generate sample images")
        print("  python image_converter.py samples")
        return
    
    cmd = sys.argv[1]
    
    if cmd == 'to_text':
        if len(sys.argv) < 3:
            print("✗ Error: Specify input image")
            return
        
        input_img = sys.argv[2]
        base_name = os.path.splitext(os.path.basename(input_img))[0]
        output_txt = f"{base_name}_input.txt"
        
        width = int(sys.argv[3]) if len(sys.argv) > 3 else None
        height = int(sys.argv[4]) if len(sys.argv) > 4 else None
        
        if image_to_text(input_img, output_txt, width, height):
            print("\n Next steps:")
            print(f"1. Copy {output_txt} to your ModelSim project directory")
            print(f"2. Update testbench parameters to match image size")
            print(f"3. Run: vsim -c -do 'do run.do'")
    
    elif cmd == 'from_text':
        if len(sys.argv) < 4:
            print("✗ Error: Specify input text and output image")
            return
        
        input_txt = sys.argv[2]
        output_img = sys.argv[3]
        text_to_image(input_txt, output_img)
    
    elif cmd == 'compare':
        if len(sys.argv) < 4:
            print("✗ Error: Specify original and edges files")
            return
        
        orig = sys.argv[2]
        edges = sys.argv[3]
        output = sys.argv[4] if len(sys.argv) > 4 else 'comparison.png'
        
        compare_images(orig, edges, output)
    
    elif cmd == 'samples':
        create_test_images()
    
    else:
        print(f"✗ Unknown command: {cmd}")


if __name__ == '__main__':
    main()
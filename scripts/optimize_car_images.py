#!/usr/bin/env python3
"""
Optimize generated car images for app bundling.

Pipeline:
1. Read raw 1024x1024 PNGs from CarImages/
2. Resize to 800x800 max dimension (Lanczos resampling)
3. Convert to JPEG quality 82
4. Output to CarImages/optimized/

Dependency: pip3 install Pillow

Usage:
    python3 scripts/optimize_car_images.py
"""

from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is required. Install with:")
    print("  pip3 install Pillow")
    exit(1)

# Configuration
INPUT_DIR = Path("/Users/sohail/AutoLedger/CarImages")
OUTPUT_DIR = INPUT_DIR / "optimized"
MAX_WIDTH = 1200
MAX_HEIGHT = 800
JPEG_QUALITY = 82


def optimize_image(src: Path, dst: Path) -> tuple[int, int]:
    """Resize and convert a PNG to optimized JPEG. Returns (original_size, new_size)."""
    original_size = src.stat().st_size

    with Image.open(src) as img:
        # Convert RGBA to RGB (JPEG doesn't support alpha)
        if img.mode in ("RGBA", "P"):
            # Use dark background to match the generated image style
            background = Image.new("RGB", img.size, (40, 40, 40))
            if img.mode == "P":
                img = img.convert("RGBA")
            background.paste(img, mask=img.split()[3])
            img = background
        elif img.mode != "RGB":
            img = img.convert("RGB")

        # Flip horizontally so all cars face left
        img = img.transpose(Image.FLIP_LEFT_RIGHT)

        # Resize if larger than max dimensions (landscape-aware)
        if img.width > MAX_WIDTH or img.height > MAX_HEIGHT:
            img.thumbnail((MAX_WIDTH, MAX_HEIGHT), Image.LANCZOS)

        # Save as JPEG
        img.save(dst, "JPEG", quality=JPEG_QUALITY, optimize=True)

    new_size = dst.stat().st_size
    return original_size, new_size


def main():
    if not INPUT_DIR.exists():
        print(f"Error: Input directory not found: {INPUT_DIR}")
        print("Run generate_car_images.py first.")
        return

    OUTPUT_DIR.mkdir(exist_ok=True)

    # Find all PNGs (exclude optimized/ subdirectory)
    png_files = sorted(INPUT_DIR.glob("*.png"))

    if not png_files:
        print(f"No PNG files found in {INPUT_DIR}")
        return

    print(f"Found {len(png_files)} images to optimize")
    print(f"Settings: max {MAX_WIDTH}x{MAX_HEIGHT}px, JPEG quality {JPEG_QUALITY}")
    print(f"Output: {OUTPUT_DIR}")
    print("-" * 50)

    total_original = 0
    total_optimized = 0
    processed = 0

    for png in png_files:
        # Output as JPEG with same base name
        jpg_name = png.stem + ".jpg"
        dst = OUTPUT_DIR / jpg_name

        try:
            orig_size, new_size = optimize_image(png, dst)
            savings = (1 - new_size / orig_size) * 100
            print(f"  {png.name} -> {jpg_name}  "
                  f"{orig_size // 1024}KB -> {new_size // 1024}KB  "
                  f"({savings:.0f}% smaller)")

            total_original += orig_size
            total_optimized += new_size
            processed += 1

        except Exception as e:
            print(f"  FAILED: {png.name}: {e}")

    # Summary
    print()
    print("-" * 50)
    print(f"Processed: {processed}/{len(png_files)} images")
    print(f"Total original:  {total_original / (1024 * 1024):.1f} MB")
    print(f"Total optimized: {total_optimized / (1024 * 1024):.1f} MB")
    if total_original > 0:
        savings = (1 - total_optimized / total_original) * 100
        print(f"Total savings:   {savings:.0f}%")
    print(f"\nOptimized images saved to: {OUTPUT_DIR}")
    print("\nNext step:")
    print("  python3 scripts/setup_car_images.py")


if __name__ == "__main__":
    main()

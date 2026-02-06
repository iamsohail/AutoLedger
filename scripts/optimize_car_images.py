#!/usr/bin/env python3
"""
Optimize generated car images for app bundling.

Pipeline:
1. Read raw PNGs from CarImages/
2. Detect car facing direction using GPT-4o vision
3. Flip only right-facing cars so all face left
4. Resize to max 1200x800 (Lanczos resampling)
5. Convert to JPEG quality 82
6. Output to CarImages/optimized/

Dependencies: pip3 install Pillow
Requires: OPENAI_API_KEY environment variable

Usage:
    export OPENAI_API_KEY="your-key"
    python3 scripts/optimize_car_images.py
"""

import os
import json
import base64
import urllib.request
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
DIRECTION_CACHE = INPUT_DIR / "direction_cache.json"
MAX_WIDTH = 1200
MAX_HEIGHT = 800
JPEG_QUALITY = 82
API_KEY = os.environ.get("OPENAI_API_KEY")


def detect_direction_batch(image_paths: list[Path], batch_size: int = 5) -> dict[str, str]:
    """Detect car facing direction for a batch of images using GPT-4o vision.
    Returns dict mapping filename to 'left' or 'right'."""
    results = {}

    for i in range(0, len(image_paths), batch_size):
        batch = image_paths[i:i + batch_size]
        content = [
            {
                "type": "text",
                "text": (
                    "For each car image, tell me which direction the car's FRONT/NOSE is pointing: "
                    "'left' or 'right'. A car facing left has its hood/bonnet pointing toward the "
                    "left side of the image. Respond ONLY with a JSON object mapping each filename "
                    "to 'left' or 'right'. Example: {\"audi_a3.png\": \"left\", \"bmw_x5.png\": \"right\"}"
                ),
            }
        ]

        for img_path in batch:
            # Create a small thumbnail for vision (saves tokens)
            with Image.open(img_path) as img:
                if img.mode in ("RGBA", "P"):
                    bg = Image.new("RGB", img.size, (40, 40, 40))
                    if img.mode == "P":
                        img = img.convert("RGBA")
                    bg.paste(img, mask=img.split()[3])
                    img = bg
                elif img.mode != "RGB":
                    img = img.convert("RGB")
                img.thumbnail((512, 340), Image.LANCZOS)
                import io
                buf = io.BytesIO()
                img.save(buf, "JPEG", quality=60)
                b64 = base64.b64encode(buf.getvalue()).decode()

            content.append({
                "type": "text",
                "text": f"Image: {img_path.name}"
            })
            content.append({
                "type": "image_url",
                "image_url": {"url": f"data:image/jpeg;base64,{b64}", "detail": "low"},
            })

        payload = json.dumps({
            "model": "gpt-4o",
            "messages": [{"role": "user", "content": content}],
            "max_tokens": 300,
        }).encode()

        req = urllib.request.Request(
            "https://api.openai.com/v1/chat/completions",
            data=payload,
            headers={
                "Authorization": f"Bearer {API_KEY}",
                "Content-Type": "application/json",
            },
        )

        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                result = json.loads(resp.read())
                text = result["choices"][0]["message"]["content"]
                # Extract JSON from response
                start = text.find("{")
                end = text.rfind("}") + 1
                if start >= 0 and end > start:
                    parsed = json.loads(text[start:end])
                    results.update(parsed)
                    names = list(parsed.keys())
                    dirs = list(parsed.values())
                    print(f"  Batch {i // batch_size + 1}: {len(parsed)} detected — "
                          f"{dirs.count('left')} left, {dirs.count('right')} right")
                else:
                    print(f"  Batch {i // batch_size + 1}: Failed to parse response")
                    # Default to no-flip for unparseable results
                    for p in batch:
                        results[p.name] = "left"
        except Exception as e:
            print(f"  Batch {i // batch_size + 1}: API error: {e}")
            # Default to no-flip on error
            for p in batch:
                results[p.name] = "left"

    return results


def load_direction_cache() -> dict:
    """Load cached direction results."""
    if DIRECTION_CACHE.exists():
        with open(DIRECTION_CACHE) as f:
            return json.load(f)
    return {}


def save_direction_cache(cache: dict):
    """Save direction cache."""
    with open(DIRECTION_CACHE, "w") as f:
        json.dump(cache, f, indent=2)


def optimize_image(src: Path, dst: Path, should_flip: bool) -> tuple[int, int]:
    """Resize and convert a PNG to optimized JPEG. Returns (original_size, new_size)."""
    original_size = src.stat().st_size

    with Image.open(src) as img:
        # Convert RGBA to RGB (JPEG doesn't support alpha)
        if img.mode in ("RGBA", "P"):
            background = Image.new("RGB", img.size, (40, 40, 40))
            if img.mode == "P":
                img = img.convert("RGBA")
            background.paste(img, mask=img.split()[3])
            img = background
        elif img.mode != "RGB":
            img = img.convert("RGB")

        # Only flip if car is facing right
        if should_flip:
            img = img.transpose(Image.FLIP_LEFT_RIGHT)

        # Resize if larger than max dimensions
        if img.width > MAX_WIDTH or img.height > MAX_HEIGHT:
            img.thumbnail((MAX_WIDTH, MAX_HEIGHT), Image.LANCZOS)

        img.save(dst, "JPEG", quality=JPEG_QUALITY, optimize=True)

    new_size = dst.stat().st_size
    return original_size, new_size


def main():
    if not INPUT_DIR.exists():
        print(f"Error: Input directory not found: {INPUT_DIR}")
        return

    if not API_KEY:
        print("Error: Set OPENAI_API_KEY environment variable")
        print("  export OPENAI_API_KEY='your-key-here'")
        return

    OUTPUT_DIR.mkdir(exist_ok=True)

    png_files = sorted(INPUT_DIR.glob("*.png"))
    if not png_files:
        print(f"No PNG files found in {INPUT_DIR}")
        return

    print(f"Found {len(png_files)} images to optimize")
    print(f"Settings: max {MAX_WIDTH}x{MAX_HEIGHT}px, JPEG quality {JPEG_QUALITY}")
    print(f"Output: {OUTPUT_DIR}")

    # Step 1: Detect car directions
    print("\n--- Detecting car facing directions (GPT-4o vision) ---")
    cache = load_direction_cache()
    uncached = [p for p in png_files if p.name not in cache]

    if uncached:
        print(f"  {len(uncached)} images need direction detection ({len(cache)} cached)")
        new_directions = detect_direction_batch(uncached)
        cache.update(new_directions)
        save_direction_cache(cache)
    else:
        print(f"  All {len(png_files)} directions cached")

    right_count = sum(1 for p in png_files if cache.get(p.name) == "right")
    left_count = sum(1 for p in png_files if cache.get(p.name) == "left")
    print(f"\n  Summary: {left_count} facing left, {right_count} facing right (will be flipped)")

    # Step 2: Optimize images
    print(f"\n--- Optimizing images ---")
    print("-" * 50)

    total_original = 0
    total_optimized = 0
    processed = 0
    flipped = 0

    for png in png_files:
        jpg_name = png.stem + ".jpg"
        dst = OUTPUT_DIR / jpg_name
        direction = cache.get(png.name, "left")
        should_flip = direction == "right"

        try:
            orig_size, new_size = optimize_image(png, dst, should_flip)
            savings = (1 - new_size / orig_size) * 100
            flip_tag = " [FLIPPED]" if should_flip else ""
            print(f"  {png.name} -> {jpg_name}  "
                  f"{orig_size // 1024}KB -> {new_size // 1024}KB  "
                  f"({savings:.0f}% smaller){flip_tag}")

            total_original += orig_size
            total_optimized += new_size
            processed += 1
            if should_flip:
                flipped += 1

        except Exception as e:
            print(f"  FAILED: {png.name}: {e}")

    print()
    print("-" * 50)
    print(f"Processed: {processed}/{len(png_files)} images")
    print(f"Flipped:   {flipped} (were facing right, now face left)")
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

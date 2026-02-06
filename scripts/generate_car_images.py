#!/usr/bin/env python3
"""
Generate car images for all active models using OpenAI DALL-E 3.

Features:
- Dark charcoal studio background (matches app's dark theme)
- Retry with exponential backoff for rate limiting
- Progress manifest (manifest.json) for resuming after interruptions
- Error logging to errors.log

Usage:
    export OPENAI_API_KEY="your-key-here"
    python3 scripts/generate_car_images.py

Output: /Users/sohail/AutoLedger/CarImages/
"""

import os
import json
import time
import base64
import urllib.request
import urllib.error
from pathlib import Path
from datetime import datetime

# Configuration
API_KEY = os.environ.get("OPENAI_API_KEY")
OUTPUT_DIR = Path("/Users/sohail/AutoLedger/CarImages")
DATA_FILE = Path("/Users/sohail/AutoLedger/AutoLedger/Resources/IndianVehicleData.json")
MANIFEST_FILE = OUTPUT_DIR / "manifest.json"
ERROR_LOG = OUTPUT_DIR / "errors.log"

# Rate limiting: 15s between requests (safe for standard tier ~5 req/min)
REQUEST_DELAY = 15
MAX_RETRIES = 3


def generate_image(make: str, model: str, year: int = 2026) -> bytes:
    """Generate a car image using OpenAI DALL-E 3."""

    prompt = (
        f"Professional studio photograph of a {year} {make} {model}, "
        f"front three-quarter view, dark charcoal studio background with subtle gradient, "
        f"rim light highlights on body panels, professional automotive photography, "
        f"high resolution, photorealistic, the actual real {make} {model} car model. "
        f"No text, no watermarks, no logos, no labels."
    )

    url = "https://api.openai.com/v1/images/generations"

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
    }

    data = json.dumps({
        "model": "dall-e-3",
        "prompt": prompt,
        "n": 1,
        "size": "1024x1024",
        "quality": "hd",
        "response_format": "b64_json",
    }).encode()

    req = urllib.request.Request(url, data=data, headers=headers)

    with urllib.request.urlopen(req, timeout=120) as response:
        result = json.loads(response.read())
        b64_data = result["data"][0]["b64_json"]
        return base64.b64decode(b64_data)


def generate_with_retry(make: str, model: str) -> bytes:
    """Generate image with exponential backoff retry."""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            return generate_image(make, model)
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < MAX_RETRIES:
                wait = REQUEST_DELAY * (2 ** (attempt - 1))
                print(f"  Rate limited, waiting {wait}s (attempt {attempt}/{MAX_RETRIES})...")
                time.sleep(wait)
            elif attempt < MAX_RETRIES:
                wait = 5 * attempt
                print(f"  HTTP {e.code}, retrying in {wait}s (attempt {attempt}/{MAX_RETRIES})...")
                time.sleep(wait)
            else:
                raise
        except Exception:
            if attempt < MAX_RETRIES:
                wait = 5 * attempt
                print(f"  Error, retrying in {wait}s (attempt {attempt}/{MAX_RETRIES})...")
                time.sleep(wait)
            else:
                raise


def safe_name(make: str, model: str) -> str:
    """Generate filename-safe asset name matching CarImageService.assetName()."""
    safe_make = make.lower().strip().replace(" ", "_").replace("-", "_")
    safe_model = model.lower().strip().replace(" ", "_").replace("-", "_")
    return f"{safe_make}_{safe_model}"


def load_manifest() -> dict:
    """Load progress manifest or create a new one."""
    if MANIFEST_FILE.exists():
        with open(MANIFEST_FILE) as f:
            return json.load(f)
    return {"generated": [], "failed": [], "started_at": datetime.now().isoformat()}


def save_manifest(manifest: dict):
    """Save progress manifest."""
    with open(MANIFEST_FILE, "w") as f:
        json.dump(manifest, f, indent=2)


def log_error(make: str, model: str, error: str):
    """Append error to errors.log."""
    with open(ERROR_LOG, "a") as f:
        timestamp = datetime.now().isoformat()
        f.write(f"[{timestamp}] {make} {model}: {error}\n")


def main():
    if not API_KEY:
        print("Error: Set OPENAI_API_KEY environment variable")
        print("  export OPENAI_API_KEY='your-key-here'")
        return

    OUTPUT_DIR.mkdir(exist_ok=True)

    # Load vehicle data
    with open(DATA_FILE) as f:
        data = json.load(f)

    # Collect active models
    models_to_generate = []
    for make in data["makes"]:
        make_name = make["name"]
        for model in make["models"]:
            if not model.get("discontinued"):
                models_to_generate.append((make_name, model["name"]))

    total = len(models_to_generate)
    print(f"Total active models: {total}")
    print(f"Estimated cost: ${total * 0.04:.2f} (DALL-E 3 HD @ $0.04/image)")
    print(f"Estimated time: ~{total * REQUEST_DELAY // 60} minutes")
    print(f"Output directory: {OUTPUT_DIR}")
    print("-" * 50)

    # Load manifest for resume support
    manifest = load_manifest()
    already_done = set(manifest.get("generated", []))

    # Count how many we can skip
    skip_count = 0
    for make_name, model_name in models_to_generate:
        name = safe_name(make_name, model_name)
        filepath = OUTPUT_DIR / f"{name}.png"
        if filepath.exists() or name in already_done:
            skip_count += 1

    if skip_count > 0:
        print(f"Resuming: {skip_count} already generated, {total - skip_count} remaining")
        remaining_cost = (total - skip_count) * 0.04
        print(f"Remaining cost: ${remaining_cost:.2f}")

    print()
    confirm = input("Continue? (yes/no): ")
    if confirm.lower() != "yes":
        print("Cancelled.")
        return

    generated = 0
    skipped = 0
    failed = 0

    for i, (make_name, model_name) in enumerate(models_to_generate, 1):
        name = safe_name(make_name, model_name)
        filepath = OUTPUT_DIR / f"{name}.png"

        # Skip if already exists
        if filepath.exists() or name in already_done:
            skipped += 1
            continue

        progress = f"[{i}/{total}]"
        print(f"{progress} {make_name} {model_name}...", end=" ", flush=True)

        try:
            image_data = generate_with_retry(make_name, model_name)
            filepath.write_bytes(image_data)
            print("OK")
            generated += 1

            # Update manifest
            manifest.setdefault("generated", []).append(name)
            save_manifest(manifest)

            # Rate limiting
            time.sleep(REQUEST_DELAY)

        except Exception as e:
            error_msg = str(e)
            print(f"FAILED: {error_msg}")
            failed += 1

            # Log error
            log_error(make_name, model_name, error_msg)
            manifest.setdefault("failed", []).append(name)
            save_manifest(manifest)

    # Final summary
    manifest["completed_at"] = datetime.now().isoformat()
    manifest["summary"] = {
        "generated": generated,
        "skipped": skipped,
        "failed": failed,
    }
    save_manifest(manifest)

    print()
    print("-" * 50)
    print(f"Generated: {generated}")
    print(f"Skipped:   {skipped}")
    print(f"Failed:    {failed}")
    print(f"\nImages saved to: {OUTPUT_DIR}")

    if failed > 0:
        print(f"Errors logged to: {ERROR_LOG}")
        print("\nTo retry failed images, just run this script again.")

    print("\nNext steps:")
    print("1. Spot-check ~10 images visually")
    print("2. Run: python3 scripts/optimize_car_images.py")
    print("3. Run: python3 scripts/setup_car_images.py")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Generate car images for all active models using reference photos + GPT-4o restyle.

Pipeline per model:
1. Fetch reference photo from CarWale (og:image — front three-quarter view)
2. Send reference to gpt-image-1 /v1/images/edits to restyle on dark studio background
3. Fallback: text-only generation if reference unavailable

Features:
- Reference-based generation for accurate car designs
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
import uuid
import re
import html as htmlmod
import urllib.request
import urllib.error
from pathlib import Path
from datetime import datetime

# Configuration
API_KEY = os.environ.get("OPENAI_API_KEY")
OUTPUT_DIR = Path("/Users/sohail/AutoLedger/CarImages")
REF_DIR = OUTPUT_DIR / "references"
DATA_FILE = Path("/Users/sohail/AutoLedger/AutoLedger/Resources/IndianVehicleData.json")
MANIFEST_FILE = OUTPUT_DIR / "manifest.json"
ERROR_LOG = OUTPUT_DIR / "errors.log"

# Rate limiting: 15s between requests (safe for standard tier)
REQUEST_DELAY = 15
MAX_RETRIES = 3

RESTYLE_PROMPT = (
    "Recreate this exact car model accurately, front three-quarter view. "
    "The car must be painted in glossy black color. "
    "Place it in a dark gray studio with a subtle gradient background. "
    "Show the ENTIRE car fully visible from bumper to bumper with generous space around it — "
    "do NOT crop any part of the car. "
    "Use strong key lighting from the front-left to illuminate the bumper, grille, and side panels clearly. "
    "Add soft rim light highlights along the edges. "
    "All car details — grille, headlights, bumper, wheels, rear — must be clearly visible. "
    "The brand logo and badge on the grille must match the reference as closely as possible — "
    "copy the exact shape, proportions, and placement of the emblem from the reference image. "
    "Professional automotive photography, photorealistic. "
    "Keep the car design exactly as shown in the reference. "
    "No text, no watermarks, no labels."
)

FALLBACK_PROMPT_TEMPLATE = (
    "Professional studio photograph of a {year} {make} {model} in glossy black color, "
    "facing left, front-left three-quarter view, "
    "in a dark gray studio with a subtle gradient background. "
    "Show the ENTIRE car fully visible from bumper to bumper with generous space around it. "
    "Use strong key lighting from the front-left to illuminate all details clearly. "
    "Add soft rim light highlights along the edges. "
    "Professional automotive photography, photorealistic, the actual real {make} {model} car model. "
    "No text, no watermarks, no labels."
)


# ---------------------------------------------------------------------------
# Reference image fetching
# ---------------------------------------------------------------------------

def carwale_slug(make: str, model: str) -> str:
    """Generate CarWale URL slug from make/model names."""
    make_s = make.lower().replace(" ", "-")
    model_s = model.lower().replace(" ", "-")
    return f"{make_s}-cars/{model_s}"


def fetch_reference_image(make: str, model: str) -> bytes | None:
    """Download a reference photo from CarWale's og:image tag."""
    slug = carwale_slug(make, model)
    page_url = f"https://www.carwale.com/{slug}/"
    headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                       "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120"
    }

    try:
        req = urllib.request.Request(page_url, headers=headers)
        with urllib.request.urlopen(req, timeout=15) as resp:
            page_html = resp.read().decode("utf-8", errors="ignore")

        # Extract og:image URL
        match = re.search(r'og:image.*?content="([^"]+)"', page_html)
        if not match:
            return None

        img_url = htmlmod.unescape(match.group(1))

        # Download the image — request a higher resolution version
        img_url = img_url.replace("642x336", "1056x594")
        req = urllib.request.Request(img_url, headers=headers)
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.read()

    except Exception:
        return None


# ---------------------------------------------------------------------------
# Image generation via OpenAI
# ---------------------------------------------------------------------------

def build_multipart(fields: dict, files: dict) -> tuple[bytes, str]:
    """Build multipart/form-data body. Returns (body, boundary)."""
    boundary = uuid.uuid4().hex
    lines = []
    for key, val in fields.items():
        lines.append(f"--{boundary}".encode())
        lines.append(f'Content-Disposition: form-data; name="{key}"'.encode())
        lines.append(b"")
        lines.append(val.encode() if isinstance(val, str) else val)
    for key, (filename, data, content_type) in files.items():
        lines.append(f"--{boundary}".encode())
        lines.append(
            f'Content-Disposition: form-data; name="{key}"; filename="{filename}"'.encode()
        )
        lines.append(f"Content-Type: {content_type}".encode())
        lines.append(b"")
        lines.append(data)
    lines.append(f"--{boundary}--".encode())
    lines.append(b"")
    return b"\r\n".join(lines), boundary


def generate_with_reference(ref_data: bytes) -> bytes:
    """Restyle a reference image via gpt-image-1 /v1/images/edits."""
    body, boundary = build_multipart(
        fields={
            "model": "gpt-image-1",
            "prompt": RESTYLE_PROMPT,
            "n": "1",
            "size": "1536x1024",
        },
        files={
            "image": ("reference.png", ref_data, "image/png"),
        },
    )

    req = urllib.request.Request(
        "https://api.openai.com/v1/images/edits",
        data=body,
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": f"multipart/form-data; boundary={boundary}",
        },
    )

    with urllib.request.urlopen(req, timeout=300) as response:
        result = json.loads(response.read())
        b64_data = result["data"][0]["b64_json"]
        return base64.b64decode(b64_data)


def generate_text_only(make: str, model: str, year: int = 2026) -> bytes:
    """Fallback: text-only generation via gpt-image-1 /v1/images/generations."""
    prompt = FALLBACK_PROMPT_TEMPLATE.format(year=year, make=make, model=model)

    data = json.dumps({
        "model": "gpt-image-1",
        "prompt": prompt,
        "n": 1,
        "size": "1536x1024",
    }).encode()

    req = urllib.request.Request(
        "https://api.openai.com/v1/images/generations",
        data=data,
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        },
    )

    with urllib.request.urlopen(req, timeout=300) as response:
        result = json.loads(response.read())
        b64_data = result["data"][0]["b64_json"]
        return base64.b64decode(b64_data)


def generate_image(make: str, model: str) -> tuple[bytes, str]:
    """Generate car image. Returns (image_bytes, method_used)."""
    # Try reference-based first
    ref_data = fetch_reference_image(make, model)
    if ref_data:
        # Save reference for debugging
        ref_name = safe_name(make, model)
        REF_DIR.mkdir(exist_ok=True)
        (REF_DIR / f"{ref_name}.png").write_bytes(ref_data)

        image_data = generate_with_reference(ref_data)
        return image_data, "ref"

    # Fallback to text-only
    image_data = generate_text_only(make, model)
    return image_data, "text"


def generate_with_retry(make: str, model: str) -> tuple[bytes, str]:
    """Generate image with exponential backoff retry."""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            return generate_image(make, model)
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < MAX_RETRIES:
                wait = REQUEST_DELAY * (2 ** (attempt - 1))
                print(f"\n  Rate limited, waiting {wait}s (attempt {attempt}/{MAX_RETRIES})...",
                      end=" ", flush=True)
                time.sleep(wait)
            elif attempt < MAX_RETRIES:
                wait = 5 * attempt
                print(f"\n  HTTP {e.code}, retrying in {wait}s (attempt {attempt}/{MAX_RETRIES})...",
                      end=" ", flush=True)
                time.sleep(wait)
            else:
                raise
        except Exception:
            if attempt < MAX_RETRIES:
                wait = 5 * attempt
                print(f"\n  Error, retrying in {wait}s (attempt {attempt}/{MAX_RETRIES})...",
                      end=" ", flush=True)
                time.sleep(wait)
            else:
                raise


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

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
    print(f"Estimated cost: ${total * 0.04:.2f} (gpt-image-1 @ ~$0.04/image)")
    print(f"Estimated time: ~{total * REQUEST_DELAY // 60} minutes")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Method: Reference from CarWale + gpt-image-1 restyle (text-only fallback)")
    print("-" * 60)

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
    ref_count = 0
    text_count = 0

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
            image_data, method = generate_with_retry(make_name, model_name)
            filepath.write_bytes(image_data)

            if method == "ref":
                ref_count += 1
                print(f"OK (ref)")
            else:
                text_count += 1
                print(f"OK (text-only)")

            generated += 1

            # Update manifest
            manifest.setdefault("generated", []).append(name)
            manifest.setdefault("methods", {})[name] = method
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
        "ref_based": ref_count,
        "text_only": text_count,
    }
    save_manifest(manifest)

    print()
    print("-" * 60)
    print(f"Generated:  {generated} ({ref_count} ref-based, {text_count} text-only)")
    print(f"Skipped:    {skipped}")
    print(f"Failed:     {failed}")
    print(f"\nImages saved to: {OUTPUT_DIR}")
    print(f"References saved to: {REF_DIR}")

    if failed > 0:
        print(f"Errors logged to: {ERROR_LOG}")
        print("\nTo retry failed images, just run this script again.")

    print("\nNext steps:")
    print("1. Spot-check ~10 images visually")
    print("2. Run: python3 scripts/optimize_car_images.py")
    print("3. Run: python3 scripts/setup_car_images.py")


if __name__ == "__main__":
    main()

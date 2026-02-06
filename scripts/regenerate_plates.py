#!/usr/bin/env python3
"""
Re-generate only images that have visible number plates.
Reads filenames from CarImages/has_plates/, deletes the originals,
and regenerates them using the same pipeline as generate_car_images.py.
"""

import os
import sys
import json
import time
import base64
import uuid
import re
import html as htmlmod
import urllib.request
import urllib.error
from pathlib import Path

# Configuration
API_KEY = os.environ.get("OPENAI_API_KEY")
OUTPUT_DIR = Path("/Users/sohail/AutoLedger/CarImages")
REF_DIR = OUTPUT_DIR / "references"
HAS_PLATES_DIR = OUTPUT_DIR / "has_plates"
DATA_FILE = Path("/Users/sohail/AutoLedger/AutoLedger/Resources/IndianVehicleData.json")

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
    "IMPORTANT: The car must have NO license plates, NO number plates at all — "
    "the front and rear plate areas must be completely blank, smooth, body-colored. "
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
    "IMPORTANT: The car must have NO license plates, NO number plates at all — "
    "the front and rear plate areas must be completely blank, smooth, body-colored. "
    "No text, no watermarks, no labels."
)


def safe_name(make: str, model: str) -> str:
    safe_make = make.lower().strip().replace(" ", "_").replace("-", "_")
    safe_model = model.lower().strip().replace(" ", "_").replace("-", "_")
    return f"{safe_make}_{safe_model}"


def carwale_slug(make: str, model: str) -> str:
    make_s = make.lower().replace(" ", "-")
    model_s = model.lower().replace(" ", "-")
    return f"{make_s}-cars/{model_s}"


def fetch_reference_image(make: str, model: str) -> bytes | None:
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
        match = re.search(r'og:image.*?content="([^"]+)"', page_html)
        if not match:
            return None
        img_url = htmlmod.unescape(match.group(1))
        img_url = img_url.replace("642x336", "1056x594")
        req = urllib.request.Request(img_url, headers=headers)
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.read()
    except Exception:
        return None


def build_multipart(fields: dict, files: dict) -> tuple[bytes, str]:
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


def generate_with_retry(make: str, model: str) -> tuple[bytes, str]:
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            ref_data = fetch_reference_image(make, model)
            if ref_data:
                REF_DIR.mkdir(exist_ok=True)
                name = safe_name(make, model)
                (REF_DIR / f"{name}.png").write_bytes(ref_data)
                image_data = generate_with_reference(ref_data)
                return image_data, "ref"
            else:
                image_data = generate_text_only(make, model)
                return image_data, "text"
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < MAX_RETRIES:
                wait = REQUEST_DELAY * (2 ** (attempt - 1))
                print(f"\n  Rate limited, waiting {wait}s...", end=" ", flush=True)
                time.sleep(wait)
            elif attempt < MAX_RETRIES:
                wait = 5 * attempt
                print(f"\n  HTTP {e.code}, retrying in {wait}s...", end=" ", flush=True)
                time.sleep(wait)
            else:
                raise
        except Exception:
            if attempt < MAX_RETRIES:
                wait = 5 * attempt
                print(f"\n  Error, retrying in {wait}s...", end=" ", flush=True)
                time.sleep(wait)
            else:
                raise


def main():
    if not API_KEY:
        print("Error: Set OPENAI_API_KEY environment variable")
        return

    # Load vehicle data to map filenames back to make/model
    with open(DATA_FILE) as f:
        data = json.load(f)

    name_to_make_model = {}
    for make in data["makes"]:
        for model in make["models"]:
            name = safe_name(make["name"], model["name"])
            name_to_make_model[name] = (make["name"], model["name"])

    # Get list of images to regenerate
    plate_files = sorted(f for f in os.listdir(HAS_PLATES_DIR) if f.endswith(".png"))
    if not plate_files:
        print("No images found in has_plates/ folder")
        return

    print(f"Found {len(plate_files)} images with number plates to regenerate")
    print(f"Estimated cost: ${len(plate_files) * 0.04:.2f}")
    print(f"Estimated time: ~{len(plate_files) * REQUEST_DELAY // 60} minutes")
    print()

    generated = 0
    failed = 0

    for i, filename in enumerate(plate_files, 1):
        name = filename.replace(".png", "")
        if name not in name_to_make_model:
            print(f"[{i}/{len(plate_files)}] {filename} — SKIPPED (not in vehicle data)")
            continue

        make_name, model_name = name_to_make_model[name]

        # Delete old original so it gets replaced
        old_path = OUTPUT_DIR / filename
        if old_path.exists():
            old_path.unlink()

        print(f"[{i}/{len(plate_files)}] {make_name} {model_name}...", end=" ", flush=True)

        try:
            image_data, method = generate_with_retry(make_name, model_name)
            (OUTPUT_DIR / filename).write_bytes(image_data)
            print(f"OK ({method})")
            generated += 1
            time.sleep(REQUEST_DELAY)
        except Exception as e:
            print(f"FAILED: {e}")
            failed += 1
            # Restore old image from has_plates
            old_backup = HAS_PLATES_DIR / filename
            if old_backup.exists():
                import shutil
                shutil.copy2(old_backup, OUTPUT_DIR / filename)

    print()
    print("-" * 50)
    print(f"Regenerated: {generated}/{len(plate_files)}")
    print(f"Failed: {failed}")
    print()
    print("Next steps:")
    print("1. Review the regenerated images")
    print("2. Run: python3 scripts/optimize_car_images.py")
    print("3. Run: python3 scripts/setup_car_images.py")


if __name__ == "__main__":
    main()

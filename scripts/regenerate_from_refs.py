#!/usr/bin/env python3
"""
Regenerate car images using user-provided reference images.
Reads references from CarImages/regenerate_refs/, converts to PNG,
and uses gpt-image-1 to restyle each one.

Special case: Range Rover Velar — remove text from bonnet using existing image.
"""

import os
import json
import time
import base64
import uuid
import urllib.request
import urllib.error
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow required. pip3 install Pillow")
    exit(1)

API_KEY = os.environ.get("OPENAI_API_KEY")
OUTPUT_DIR = Path("/Users/sohail/AutoLedger/CarImages")
REF_DIR = OUTPUT_DIR / "regenerate_refs"

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

VELAR_PROMPT = (
    "Recreate this exact car model accurately, front three-quarter view. "
    "The car must be painted in glossy black color. "
    "Place it in a dark gray studio with a subtle gradient background. "
    "Show the ENTIRE car fully visible from bumper to bumper with generous space around it. "
    "Use strong key lighting from the front-left. "
    "IMPORTANT: Remove ALL text from the car's bonnet/hood — the hood must be completely clean, "
    "smooth glossy black with no text, no lettering, no decals whatsoever. "
    "No license plates, no number plates, no text, no watermarks, no labels. "
    "Professional automotive photography, photorealistic."
)

# Map reference filenames to output asset names
FILENAME_MAP = {
    "BMW 6 Series": "bmw_6_series",
    "BMW X5": "bmw_x5",
    "Honda Accord Hybrid": "honda_accord_hybrid",
    "Honda WR-V": "honda_wr_v",
    "Hyundai Santa Fe": "hyundai_santa_fe",
    "Jaguar XJ": "jaguar_xj",
    "Kia Seltos": "kia_seltos",
    "Kia Syros": "kia_syros",
    "Mahindra Armada": "mahindra_armada",
    "Mahindra CL 500": "mahindra_cl_500",
    "Mahindra CL 550": "mahindra_cl_550",
    "Mahindra Logan": "mahindra_logan",
    "Mahindra Thar Roxx": "mahindra_thar_roxx",
    "Mahindra XUV300": "mahindra_xuv300",
    "Maruti Baleno RS": "maruti_suzuki_baleno_rs",
    "Maruti Suzuki Grand Vitara": "maruti_suzuki_grand_vitara",
    "Maruti Suzuki S Cross": "maruti_suzuki_s_cross",
    "Mitsubishi Pajero": "mitsubishi_pajero",
    "Mitsubishi Pajero Sport": "mitsubishi_pajero_sport",
    "Polo GT": "volkswagen_polo_gt",
    "Skoda Fabia": "škoda_fabia",
    "Skoda Laura": "škoda_laura",
    "Skoda Rapid": "škoda_rapid",
    "Tata Sierra": "tata_sierra",
    "Tesla Model Y": "tesla_model_y",
    "Toyota Corolla": "toyota_corolla",
}


def convert_to_png(src: Path) -> bytes:
    """Convert any image format (avif, webp, jpg, png) to PNG bytes."""
    with Image.open(src) as img:
        if img.mode in ("RGBA", "P"):
            bg = Image.new("RGB", img.size, (255, 255, 255))
            if img.mode == "P":
                img = img.convert("RGBA")
            bg.paste(img, mask=img.split()[3])
            img = bg
        elif img.mode != "RGB":
            img = img.convert("RGB")

        import io
        buf = io.BytesIO()
        img.save(buf, "PNG")
        return buf.getvalue()


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


def generate_with_reference(ref_data: bytes, prompt: str) -> bytes:
    body, boundary = build_multipart(
        fields={
            "model": "gpt-image-1",
            "prompt": prompt,
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


def generate_with_retry(ref_data: bytes, prompt: str) -> bytes:
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            return generate_with_reference(ref_data, prompt)
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

    ref_files = sorted([f for f in REF_DIR.iterdir() if f.is_file() and not f.name.startswith(".")])
    if not ref_files:
        print("No reference images found in regenerate_refs/")
        return

    # Also handle Velar special case
    velar_src = OUTPUT_DIR / "land_rover_range_rover_velar.png"
    has_velar = velar_src.exists()

    total = len(ref_files) + (1 if has_velar else 0)
    print(f"Found {len(ref_files)} reference images + {'1 Velar fix' if has_velar else 'no Velar'}")
    print(f"Total to regenerate: {total}")
    print(f"Estimated cost: ${total * 0.04:.2f}")
    print(f"Estimated time: ~{total * REQUEST_DELAY // 60} minutes")
    print()

    generated = 0
    failed = 0
    idx = 0

    for ref_file in ref_files:
        idx += 1
        stem = ref_file.stem  # e.g. "BMW 6 Series"

        asset_name = FILENAME_MAP.get(stem)
        if not asset_name:
            print(f"[{idx}/{total}] {stem} — SKIPPED (no mapping found)")
            failed += 1
            continue

        output_path = OUTPUT_DIR / f"{asset_name}.png"
        print(f"[{idx}/{total}] {stem} -> {asset_name}.png...", end=" ", flush=True)

        try:
            ref_data = convert_to_png(ref_file)
            image_data = generate_with_retry(ref_data, RESTYLE_PROMPT)
            output_path.write_bytes(image_data)
            print("OK")
            generated += 1
            time.sleep(REQUEST_DELAY)
        except Exception as e:
            print(f"FAILED: {e}")
            failed += 1

    # Special case: Velar text removal
    if has_velar:
        idx += 1
        print(f"[{idx}/{total}] Range Rover Velar (remove bonnet text)...", end=" ", flush=True)
        try:
            ref_data = velar_src.read_bytes()
            image_data = generate_with_retry(ref_data, VELAR_PROMPT)
            velar_src.write_bytes(image_data)
            print("OK")
            generated += 1
        except Exception as e:
            print(f"FAILED: {e}")
            failed += 1

    print()
    print("-" * 50)
    print(f"Regenerated: {generated}/{total}")
    print(f"Failed: {failed}")
    print()
    print("Next steps:")
    print("1. Review the regenerated images")
    print("2. Run: python3 scripts/optimize_car_images.py")
    print("3. Run: python3 scripts/setup_car_images.py")


if __name__ == "__main__":
    main()

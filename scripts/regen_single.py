#!/usr/bin/env python3
"""Generate a single car image from a reference."""

import os, sys, json, base64, uuid, io, urllib.request
from pathlib import Path
from PIL import Image

API_KEY = os.environ.get("OPENAI_API_KEY")

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

def generate(ref_path, out_path):
    with Image.open(ref_path) as img:
        if img.mode != "RGB":
            img = img.convert("RGB")
        buf = io.BytesIO()
        img.save(buf, "PNG")
        ref_data = buf.getvalue()

    boundary = uuid.uuid4().hex
    lines = []
    for key, val in {"model": "gpt-image-1", "prompt": RESTYLE_PROMPT, "n": "1", "size": "1536x1024"}.items():
        lines.append(f"--{boundary}".encode())
        lines.append(f'Content-Disposition: form-data; name="{key}"'.encode())
        lines.append(b"")
        lines.append(val.encode())
    lines.append(f"--{boundary}".encode())
    lines.append(b'Content-Disposition: form-data; name="image"; filename="reference.png"')
    lines.append(b"Content-Type: image/png")
    lines.append(b"")
    lines.append(ref_data)
    lines.append(f"--{boundary}--".encode())
    lines.append(b"")
    body = b"\r\n".join(lines)

    req = urllib.request.Request(
        "https://api.openai.com/v1/images/edits",
        data=body,
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": f"multipart/form-data; boundary={boundary}",
        },
    )

    print(f"Generating {out_path.name}...", end=" ", flush=True)
    with urllib.request.urlopen(req, timeout=300) as resp:
        result = json.loads(resp.read())
        img_data = base64.b64decode(result["data"][0]["b64_json"])
        out_path.write_bytes(img_data)
        print("OK")

if __name__ == "__main__":
    ref = Path(sys.argv[1])
    out = Path(sys.argv[2])
    generate(ref, out)

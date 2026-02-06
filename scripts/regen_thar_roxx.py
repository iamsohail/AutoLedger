#!/usr/bin/env python3
"""Regenerate Mahindra Thar ROXX (5-door) with specific prompt."""

import os, json, base64, uuid, io, urllib.request
from pathlib import Path
from PIL import Image

API_KEY = os.environ.get("OPENAI_API_KEY")
ref_path = Path("/Users/sohail/AutoLedger/CarImages/regenerate_refs/Mahindra Thar Roxx.webp")
out_path = Path("/Users/sohail/AutoLedger/CarImages/mahindra_thar_roxx.png")

# Convert ref to PNG
with Image.open(ref_path) as img:
    if img.mode != "RGB":
        img = img.convert("RGB")
    buf = io.BytesIO()
    img.save(buf, "PNG")
    ref_data = buf.getvalue()

prompt = (
    "Recreate this exact Mahindra Thar ROXX (not the regular Thar) accurately, front three-quarter view. "
    "The Thar ROXX is a 5-door SUV with a longer wheelbase than the regular 3-door Thar. "
    "It has a distinctive front grille with vertical slats, round LED headlamps, and a more premium look. "
    "The car must be painted in glossy black color. "
    "Place it in a dark gray studio with a subtle gradient background. "
    "Show the ENTIRE car fully visible from bumper to bumper with generous space around it. "
    "Use strong key lighting from the front-left. Add soft rim light highlights along the edges. "
    "Keep the car design exactly as shown in the reference — this is the 5-door ROXX variant NOT the 3-door Thar. "
    "IMPORTANT: NO license plates, NO number plates — plate areas must be blank/body-colored. "
    "No text, no watermarks, no labels. Professional automotive photography, photorealistic."
)

boundary = uuid.uuid4().hex
lines = []
for key, val in {"model": "gpt-image-1", "prompt": prompt, "n": "1", "size": "1536x1024"}.items():
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

print("Generating Mahindra Thar ROXX (5-door)...", end=" ", flush=True)
with urllib.request.urlopen(req, timeout=300) as resp:
    result = json.loads(resp.read())
    img_data = base64.b64decode(result["data"][0]["b64_json"])
    out_path.write_bytes(img_data)
    print("OK")

#!/usr/bin/env python3
"""
Setup car logos in Assets.xcassets from CarLogos folder.
"""

import os
import json
import shutil
from pathlib import Path

LOGOS_SOURCE = Path("/Users/sohail/AutoLedger/CarLogos")
ASSETS_DIR = Path("/Users/sohail/AutoLedger/AutoLedger/Resources/Assets.xcassets/CarLogos")

# Mapping of brand names to their logo files (will find PNGs in subfolders)
BRANDS = [
    "Aston Martin", "Audi", "BMW", "BYD", "Bentley", "Bugatti", "Chevrolet",
    "Citroen", "Datsun", "Ferrari", "Fiat", "Ford", "Honda", "Hyundai",
    "Isuzu", "Jaguar", "Jeep", "Kia", "Lamborghini", "Land Rover", "Lexus",
    "MG", "Mahindra", "Maruti Suzuki", "Maserati", "McLaren", "Mercedes-Benz",
    "Mini", "Mitsubishi", "Nissan", "Porsche", "Premier", "Renault",
    "Rolls-Royce", "Skoda", "Tata", "Toyota", "Volkswagen", "Volvo"
]

def find_png(brand_name):
    """Find PNG file for a brand."""
    brand_dir = LOGOS_SOURCE / brand_name

    # Check direct PNG file
    direct_png = LOGOS_SOURCE / f"{brand_name}.png"
    if direct_png.exists():
        return direct_png

    # Special case for Toyota
    if brand_name == "Toyota":
        toyota_png = LOGOS_SOURCE / "Toyota.svg.png"
        if toyota_png.exists():
            return toyota_png

    # Search in subdirectories
    if brand_dir.exists():
        for root, dirs, files in os.walk(brand_dir):
            for f in files:
                if f.endswith('.png'):
                    return Path(root) / f

    return None

def create_imageset(brand_name, png_path):
    """Create an imageset for a brand."""
    # Normalize brand name for asset name (replace spaces with underscores)
    asset_name = brand_name.replace(" ", "_").replace("-", "_")
    imageset_dir = ASSETS_DIR / f"{asset_name}.imageset"

    # Create directory
    imageset_dir.mkdir(parents=True, exist_ok=True)

    # Copy PNG file
    dest_png = imageset_dir / f"{asset_name}.png"
    shutil.copy2(png_path, dest_png)

    # Create Contents.json
    contents = {
        "images": [
            {
                "filename": f"{asset_name}.png",
                "idiom": "universal",
                "scale": "1x"
            },
            {
                "idiom": "universal",
                "scale": "2x"
            },
            {
                "idiom": "universal",
                "scale": "3x"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    with open(imageset_dir / "Contents.json", 'w') as f:
        json.dump(contents, f, indent=2)

    return True

def main():
    # Ensure assets directory exists
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    found = 0
    missing = []

    for brand in BRANDS:
        png_path = find_png(brand)
        if png_path:
            create_imageset(brand, png_path)
            print(f"✓ {brand}")
            found += 1
        else:
            print(f"✗ {brand} - PNG not found")
            missing.append(brand)

    print(f"\n{found}/{len(BRANDS)} logos added")
    if missing:
        print(f"\nMissing logos ({len(missing)}):")
        for m in missing:
            print(f"  - {m}")

if __name__ == "__main__":
    main()

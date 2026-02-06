#!/usr/bin/env python3
"""
Import optimized car images into Xcode Assets.xcassets catalog.

Reads optimized JPEGs from CarImages/optimized/ and creates proper
imageset directories in Assets.xcassets/CarImages/.

Naming convention matches CarImageService.assetName() exactly:
  "Maruti Suzuki" + "Baleno" -> "maruti_suzuki_baleno"

Usage:
    python3 scripts/setup_car_images.py
"""

import json
import shutil
from pathlib import Path

# Configuration
IMAGES_DIR = Path("/Users/sohail/AutoLedger/CarImages/optimized")
ASSETS_DIR = Path("/Users/sohail/AutoLedger/AutoLedger/Resources/Assets.xcassets/CarImages")
DATA_FILE = Path("/Users/sohail/AutoLedger/AutoLedger/Resources/IndianVehicleData.json")


def create_imageset(asset_name: str, jpg_path: Path):
    """Create an imageset directory with Contents.json for a JPEG image."""
    imageset_dir = ASSETS_DIR / f"{asset_name}.imageset"
    imageset_dir.mkdir(parents=True, exist_ok=True)

    # Copy JPEG file
    dest_file = imageset_dir / f"{asset_name}.jpg"
    shutil.copy2(jpg_path, dest_file)

    # Create Contents.json — universal, no scale specifier (800px raster)
    contents = {
        "images": [
            {
                "filename": f"{asset_name}.jpg",
                "idiom": "universal",
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1,
        },
    }

    with open(imageset_dir / "Contents.json", "w") as f:
        json.dump(contents, f, indent=2)


def main():
    if not IMAGES_DIR.exists():
        print(f"Error: Optimized images directory not found: {IMAGES_DIR}")
        print("Run optimize_car_images.py first.")
        return

    # Create CarImages folder in asset catalog
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    # Create folder Contents.json (required by Xcode for asset catalog groups)
    folder_contents = {
        "info": {
            "author": "xcode",
            "version": 1,
        },
    }
    with open(ASSETS_DIR / "Contents.json", "w") as f:
        json.dump(folder_contents, f, indent=2)

    # Find all optimized JPEGs
    jpg_files = {p.stem: p for p in sorted(IMAGES_DIR.glob("*.jpg"))}

    if not jpg_files:
        print(f"No JPEG files found in {IMAGES_DIR}")
        return

    print(f"Found {len(jpg_files)} optimized images")

    # Load vehicle data for coverage report
    with open(DATA_FILE) as f:
        data = json.load(f)

    # Build expected asset names from active models
    expected_names = []
    for make in data["makes"]:
        make_name = make["name"]
        for model in make["models"]:
            if not model.get("discontinued"):
                safe_make = make_name.lower().strip().replace(" ", "_").replace("-", "_")
                safe_model = model["name"].lower().strip().replace(" ", "_").replace("-", "_")
                expected_names.append(f"{safe_make}_{safe_model}")

    # Import images
    imported = 0
    missing = []

    for name in expected_names:
        if name in jpg_files:
            create_imageset(name, jpg_files[name])
            imported += 1
        else:
            missing.append(name)

    # Also import any extra images not in expected list (manual additions)
    extras = 0
    for name, path in jpg_files.items():
        if name not in expected_names:
            create_imageset(name, path)
            extras += 1

    # Summary
    print()
    print("-" * 50)
    print(f"Imported: {imported}/{len(expected_names)} active models")
    if extras > 0:
        print(f"Extras:   {extras} (images not matching active models)")
    coverage = (imported / len(expected_names) * 100) if expected_names else 0
    print(f"Coverage: {coverage:.1f}%")

    if missing:
        print(f"\nMissing images ({len(missing)}):")
        for m in missing[:20]:
            print(f"  - {m}")
        if len(missing) > 20:
            print(f"  ... and {len(missing) - 20} more")

    print(f"\nAsset catalog updated: {ASSETS_DIR}")
    print(f"Total imagesets: {imported + extras}")
    print("\nNext steps:")
    print("1. Build Xcode project — verify no asset catalog errors")
    print("2. Launch in simulator — check VehicleHeroCard displays images")


if __name__ == "__main__":
    main()

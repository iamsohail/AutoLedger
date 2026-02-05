#!/usr/bin/env python3
"""
Setup car logos using SVG (vector) where available, PNG as fallback.
iOS 13+ supports SVG in asset catalogs.
"""

import os
import json
import shutil
from pathlib import Path

LOGOS_SOURCE = Path("/Users/sohail/AutoLedger/CarLogos")
ASSETS_DIR = Path("/Users/sohail/AutoLedger/AutoLedger/Resources/Assets.xcassets/CarLogos")

# Brand name to SVG file mapping
BRANDS = {
    "Aston Martin": "Aston Martin/Aston Martin_idQog5cFWh_0.svg",
    "Audi": "Audi/Audi/Audi_Logo_0.svg",
    "BMW": "BMW/BMW/BMW_id5loysbiT_0.svg",
    "BYD": "BYD/BYD/BYD_Logo_0.svg",
    "Bentley": "Bentley/Bentley Newsroom/Bentley Newsroom_idzAm4Kdl6_1.svg",
    "Bugatti": "Bugatti/Bugatti/Bugatti_idI7eTIC8l_0.svg",
    "Chevrolet": "Chevrolet/Chevrolet/Chevrolet_Logo_0.svg",
    "Citroen": "Citroen.svg",
    "Datsun": "Datsun/Nissan Motor/Nissan Motor_id01HYBDJV_1.svg",
    "Ferrari": "Ferrari/Ferrari/Ferrari_Logo_0.svg",
    "Fiat": "Fiat/FIAT/FIAT_idGeGBWemT_0.svg",
    "Ford": "Ford/Ford Motor Company/Ford Motor Company_Logo_0.svg",
    "Honda": "Honda/Honda/Honda_Symbol_0.svg",
    "Hyundai": "Hyundai/Hyundai/Hyundai_Symbol_0.svg",
    "Isuzu": "Isuzu/Isuzu/Isuzu_idKEMCAeKw_0.svg",
    "Jaguar": "Jaguar/Jaguar USA/Jaguar USA_id2_cHt6YS_0.svg",
    "Jeep": "Jeep/Jeep/Jeep_idl_dDIsgg_0.svg",
    "Kia": "Kia/Kia/Kia_idQSySv2Et_0.svg",
    "Lamborghini": "Lamborghini/Lamborghini_Logo_0.svg",
    "Lexus": "Lexus/Lexus/Lexus_idh5DdXVTn_0.svg",
    "MG": "MG/MG Motor UK/MG Motor UK_idCpo57oQX_1.svg",
    "Mahindra": "Mahindra EV/Mahindra Electric Origin SUVs/Mahindra Electric Origin SUVs_id90qnE-X__1.svg",
    "Maruti Suzuki": "Maruti Suzuki/Suzuki/Suzuki_Logo_Alternative_0.svg",
    "Maserati": "Maserati/Maserati/Maserati_idls86yLKI_1.svg",
    "McLaren": "McLaren/McLaren/McLaren_id33vK7Ho6_0.svg",
    "Mercedes-Benz": "Mercedes-Benz/Mercedes-Benz/Mercedes-Benz_Symbol_0.svg",
    "Mini": "Mini/MINI/MINI_idcPfYcMuk_0.svg",
    "Mitsubishi": "Mitsubishi/Mitsubishi Motors/Mitsubishi Motors_idkJddI72X_0.svg",
    "Nissan": "Nissan/Nissan USA/Nissan USA_id7sE7ZsL-_0.svg",
    "Porsche": "Porsche/Porsche/Porsche_Symbol_0.svg",
    "Premier": "Premier.svg",
    "Renault": "Renault/Renault UK/Renault UK_idDaZMekG5_1.svg",
    "Rolls-Royce": "Rolls-Royce/Rolls-Royce Motor Cars/Rolls-Royce Motor Cars_idAl418hHj_0.svg",
    "Skoda": "Skoda/Škoda Auto/Škoda Auto_idUkmSurR1_0.svg",
    "Tata": "Tata/Tata Motors/Tata Motors_idhfHAmYXV_1.svg",
    "Toyota": None,  # No SVG
    "Land Rover": None,  # No SVG
    "Volkswagen": "Volkswagen/Volkswagen/Volkswagen_Logo_0.svg",
    "Volvo": "Volvo/Volvo/Volvo_Symbol_0.svg",
}

def find_png(brand_name):
    """Find PNG file for a brand."""
    # Direct PNG file
    direct_png = LOGOS_SOURCE / f"{brand_name}.png"
    if direct_png.exists():
        return direct_png

    # Toyota special case
    if brand_name == "Toyota":
        toyota_png = LOGOS_SOURCE / "Toyota.svg.png"
        if toyota_png.exists():
            return toyota_png

    # Search in subdirectories
    brand_dir = LOGOS_SOURCE / brand_name
    if brand_dir.exists():
        for f in brand_dir.rglob("*.png"):
            return f

    # Check unzipped folders
    for folder in LOGOS_SOURCE.iterdir():
        if folder.is_dir() and brand_name.lower() in folder.name.lower():
            for f in folder.rglob("*.png"):
                return f

    return None

def create_svg_imageset(brand_name, svg_path):
    """Create an imageset with SVG and vector preservation."""
    asset_name = brand_name.replace(" ", "_").replace("-", "_")
    imageset_dir = ASSETS_DIR / f"{asset_name}.imageset"

    # Remove existing imageset
    if imageset_dir.exists():
        shutil.rmtree(imageset_dir)

    imageset_dir.mkdir(parents=True, exist_ok=True)

    # Copy SVG file
    dest_svg = imageset_dir / f"{asset_name}.svg"
    shutil.copy2(svg_path, dest_svg)

    # Create Contents.json with vector preservation
    contents = {
        "images": [
            {
                "filename": f"{asset_name}.svg",
                "idiom": "universal"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        },
        "properties": {
            "preserves-vector-representation": True
        }
    }

    with open(imageset_dir / "Contents.json", 'w') as f:
        json.dump(contents, f, indent=2)

    return True

def create_png_imageset(brand_name, png_path):
    """Create an imageset with PNG."""
    asset_name = brand_name.replace(" ", "_").replace("-", "_")
    imageset_dir = ASSETS_DIR / f"{asset_name}.imageset"

    # Remove existing imageset
    if imageset_dir.exists():
        shutil.rmtree(imageset_dir)

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
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    svg_count = 0
    png_count = 0
    failed = []

    for brand, svg_rel_path in BRANDS.items():
        if svg_rel_path:
            svg_path = LOGOS_SOURCE / svg_rel_path
            if svg_path.exists():
                create_svg_imageset(brand, svg_path)
                svg_count += 1
                print(f"[SVG] {brand}")
                continue

        # Fallback to PNG
        png_path = find_png(brand)
        if png_path:
            create_png_imageset(brand, png_path)
            png_count += 1
            print(f"[PNG] {brand}")
        else:
            failed.append(brand)
            print(f"[FAIL] {brand}")

    print(f"\n{svg_count} SVG, {png_count} PNG, {len(failed)} failed")
    if failed:
        print(f"Failed: {', '.join(failed)}")

if __name__ == "__main__":
    main()

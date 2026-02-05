#!/usr/bin/env python3
"""
Convert SVG logos to PDF and create proper asset catalogs with vector preservation.
"""

import os
import json
import subprocess
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
    "Toyota": None,  # No SVG, use PNG
    "Land Rover": None,  # No SVG, use PNG
    "Volkswagen": "Volkswagen/Volkswagen/Volkswagen_Logo_0.svg",
    "Volvo": "Volvo/Volvo/Volvo_Symbol_0.svg",
}

def svg_to_pdf(svg_path, pdf_path):
    """Convert SVG to PDF using rsvg-convert or cairosvg."""
    try:
        # Try rsvg-convert first (from librsvg)
        result = subprocess.run(
            ["rsvg-convert", "-f", "pdf", "-o", str(pdf_path), str(svg_path)],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            return True
    except FileNotFoundError:
        pass

    try:
        # Try cairosvg Python library
        import cairosvg
        cairosvg.svg2pdf(url=str(svg_path), write_to=str(pdf_path))
        return True
    except ImportError:
        pass

    try:
        # Try Inkscape
        result = subprocess.run(
            ["inkscape", str(svg_path), "--export-filename=" + str(pdf_path)],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            return True
    except FileNotFoundError:
        pass

    # Fallback: use qlmanage to convert SVG to PNG, then use that
    return False

def create_pdf_imageset(brand_name, pdf_path):
    """Create an imageset with PDF and vector preservation."""
    asset_name = brand_name.replace(" ", "_").replace("-", "_")
    imageset_dir = ASSETS_DIR / f"{asset_name}.imageset"

    # Remove existing imageset
    if imageset_dir.exists():
        shutil.rmtree(imageset_dir)

    imageset_dir.mkdir(parents=True, exist_ok=True)

    # Copy PDF file
    dest_pdf = imageset_dir / f"{asset_name}.pdf"
    shutil.copy2(pdf_path, dest_pdf)

    # Create Contents.json with vector preservation
    contents = {
        "images": [
            {
                "filename": f"{asset_name}.pdf",
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
    """Create an imageset with PNG (for brands without SVG)."""
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
    # Create temp directory for PDFs
    temp_dir = Path("/tmp/car_logos_pdf")
    temp_dir.mkdir(exist_ok=True)

    converted = 0
    failed = []
    png_fallback = []

    for brand, svg_rel_path in BRANDS.items():
        if svg_rel_path is None:
            # No SVG available, try to find PNG
            png_candidates = [
                LOGOS_SOURCE / f"{brand}.png",
                LOGOS_SOURCE / f"{brand}/".glob("**/*.png") if (LOGOS_SOURCE / brand).exists() else []
            ]

            # Find PNG file
            png_path = None
            if (LOGOS_SOURCE / f"{brand}.png").exists():
                png_path = LOGOS_SOURCE / f"{brand}.png"
            elif (LOGOS_SOURCE / "Toyota.svg.png").exists() and brand == "Toyota":
                png_path = LOGOS_SOURCE / "Toyota.svg.png"
            else:
                # Search in subdirectories
                brand_dir = LOGOS_SOURCE / brand
                if brand_dir.exists():
                    for f in brand_dir.rglob("*.png"):
                        png_path = f
                        break

            if png_path and png_path.exists():
                create_png_imageset(brand, png_path)
                png_fallback.append(brand)
                print(f"[PNG] {brand}")
            else:
                failed.append(brand)
                print(f"[FAIL] {brand} - No SVG or PNG found")
            continue

        svg_path = LOGOS_SOURCE / svg_rel_path

        if not svg_path.exists():
            failed.append(brand)
            print(f"[FAIL] {brand} - SVG not found: {svg_path}")
            continue

        # Convert SVG to PDF
        pdf_path = temp_dir / f"{brand.replace(' ', '_')}.pdf"

        if svg_to_pdf(svg_path, pdf_path):
            create_pdf_imageset(brand, pdf_path)
            converted += 1
            print(f"[PDF] {brand}")
        else:
            # Fallback to PNG
            png_path = svg_path.with_suffix('.png')
            if not png_path.exists():
                # Find any PNG in same directory
                png_files = list(svg_path.parent.glob("*.png"))
                if png_files:
                    png_path = png_files[0]

            if png_path.exists():
                create_png_imageset(brand, png_path)
                png_fallback.append(brand)
                print(f"[PNG] {brand} (SVG conversion failed)")
            else:
                failed.append(brand)
                print(f"[FAIL] {brand} - Conversion failed, no PNG fallback")

    print(f"\n{converted} PDF, {len(png_fallback)} PNG, {len(failed)} failed")
    if failed:
        print(f"Failed: {', '.join(failed)}")

if __name__ == "__main__":
    main()

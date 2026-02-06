#!/usr/bin/env python3
"""
Download car brand logos from Wikimedia Commons.
These are high-quality SVG files with transparent backgrounds.

Usage: python3 download_car_logos.py
"""

import os
import urllib.request
import ssl

# Disable SSL verification for downloads (Wikimedia uses valid certs but sometimes causes issues)
ssl._create_default_https_context = ssl._create_unverified_context

# Output directory
OUTPUT_DIR = '/Users/sohail/AutoLedger/CarLogos'
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Car brand logos from Wikimedia Commons
# Format: (brand_name, wikimedia_file_url)
LOGO_URLS = {
    # Indian Brands
    'maruti': 'https://upload.wikimedia.org/wikipedia/commons/1/12/Suzuki_logo_2.svg',
    'tata': 'https://upload.wikimedia.org/wikipedia/commons/8/8e/Tata_logo.svg',
    'mahindra': 'https://upload.wikimedia.org/wikipedia/commons/1/1b/Mahindra_Rise_Logo.svg',

    # Japanese Brands
    'toyota': 'https://upload.wikimedia.org/wikipedia/commons/e/e7/Toyota.svg',
    'honda': 'https://upload.wikimedia.org/wikipedia/commons/3/38/Honda.svg',
    'suzuki': 'https://upload.wikimedia.org/wikipedia/commons/1/12/Suzuki_logo_2.svg',
    'nissan': 'https://upload.wikimedia.org/wikipedia/commons/8/8c/Nissan_2020_logo.svg',
    'mazda': 'https://upload.wikimedia.org/wikipedia/commons/f/f3/Mazda_logo_with_emblem.svg',
    'mitsubishi': 'https://upload.wikimedia.org/wikipedia/commons/5/5a/Mitsubishi_logo.svg',
    'subaru': 'https://upload.wikimedia.org/wikipedia/commons/6/6f/Subaru_logo.svg',
    'isuzu': 'https://upload.wikimedia.org/wikipedia/commons/d/d1/Isuzu_logo.svg',
    'lexus': 'https://upload.wikimedia.org/wikipedia/commons/d/d1/Lexus_division_emblem.svg',

    # Korean Brands
    'hyundai': 'https://upload.wikimedia.org/wikipedia/commons/4/44/Hyundai_Motor_Company_logo.svg',
    'kia': 'https://upload.wikimedia.org/wikipedia/commons/1/13/Kia-logo.svg',
    'genesis': 'https://upload.wikimedia.org/wikipedia/commons/b/b5/Genesis_Motor_LLC_Logo.svg',

    # German Brands
    'volkswagen': 'https://upload.wikimedia.org/wikipedia/commons/6/6d/Volkswagen_logo_2019.svg',
    'bmw': 'https://upload.wikimedia.org/wikipedia/commons/4/44/BMW.svg',
    'mercedes': 'https://upload.wikimedia.org/wikipedia/commons/9/90/Mercedes-Logo.svg',
    'audi': 'https://upload.wikimedia.org/wikipedia/commons/9/92/Audi-Logo_2016.svg',
    'porsche': 'https://upload.wikimedia.org/wikipedia/commons/f/fa/Porsche-Logo.svg',
    'skoda': 'https://upload.wikimedia.org/wikipedia/commons/5/54/Skoda_2022.svg',
    'mini': 'https://upload.wikimedia.org/wikipedia/commons/7/76/Mini_logo_2018.svg',

    # American Brands
    'ford': 'https://upload.wikimedia.org/wikipedia/commons/3/3e/Ford_logo_flat.svg',
    'chevrolet': 'https://upload.wikimedia.org/wikipedia/commons/1/1e/Chevrolet-logo.svg',
    'jeep': 'https://upload.wikimedia.org/wikipedia/commons/9/9e/Jeep_logo.svg',
    'tesla': 'https://upload.wikimedia.org/wikipedia/commons/b/bd/Tesla_Motors.svg',
    'cadillac': 'https://upload.wikimedia.org/wikipedia/commons/9/90/Cadillac-Logo_2014.svg',

    # British Brands
    'jaguar': 'https://upload.wikimedia.org/wikipedia/commons/a/a1/Jaguar_2012_logo.svg',
    'land_rover': 'https://upload.wikimedia.org/wikipedia/commons/9/9c/Land-Rover-Logo_2020.svg',
    'bentley': 'https://upload.wikimedia.org/wikipedia/commons/d/da/Bentley_logo_2.svg',
    'rolls_royce': 'https://upload.wikimedia.org/wikipedia/commons/5/5c/Rolls-Royce_Motor_Cars_logo.svg',
    'aston_martin': 'https://upload.wikimedia.org/wikipedia/commons/1/1d/Aston_Martin_Lagonda_brandance_logo.svg',
    'mg': 'https://upload.wikimedia.org/wikipedia/commons/e/e2/MG_Motor_logo.svg',

    # Italian Brands
    'ferrari': 'https://upload.wikimedia.org/wikipedia/commons/c/c9/Ferrari_Logo.svg',
    'lamborghini': 'https://upload.wikimedia.org/wikipedia/commons/2/2e/Lamborghini_Logo.svg',
    'maserati': 'https://upload.wikimedia.org/wikipedia/commons/e/e5/Maserati_Logo.svg',
    'alfa_romeo': 'https://upload.wikimedia.org/wikipedia/commons/2/2d/Alfa_Romeo_2015.svg',
    'fiat': 'https://upload.wikimedia.org/wikipedia/commons/1/12/Fiat_Automobiles_logo.svg',

    # French Brands
    'renault': 'https://upload.wikimedia.org/wikipedia/commons/4/49/Renault_2009_logo.svg',
    'peugeot': 'https://upload.wikimedia.org/wikipedia/commons/4/4b/Peugeot_Logo_2010.svg',
    'citroen': 'https://upload.wikimedia.org/wikipedia/commons/0/0b/Citro%C3%ABn_2022.svg',

    # Chinese Brands
    'byd': 'https://upload.wikimedia.org/wikipedia/commons/4/49/BYD_Auto_Logo.svg',

    # Swedish Brands
    'volvo': 'https://upload.wikimedia.org/wikipedia/commons/3/30/Volvo_iron_mark_2012.svg',
}

def download_logo(brand, url):
    """Download a single logo."""
    output_path = os.path.join(OUTPUT_DIR, f'logo_{brand}.svg')

    try:
        print(f'Downloading {brand}...', end=' ')

        # Create request with user agent
        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'}
        )

        with urllib.request.urlopen(req, timeout=30) as response:
            svg_content = response.read()

        with open(output_path, 'wb') as f:
            f.write(svg_content)

        print(f'OK ({len(svg_content)} bytes)')
        return True

    except Exception as e:
        print(f'FAILED: {e}')
        return False

def main():
    print(f'Downloading {len(LOGO_URLS)} car brand logos...')
    print(f'Output directory: {OUTPUT_DIR}')
    print('-' * 50)

    success = 0
    failed = 0

    for brand, url in LOGO_URLS.items():
        if download_logo(brand, url):
            success += 1
        else:
            failed += 1

    print('-' * 50)
    print(f'Downloaded: {success}/{len(LOGO_URLS)}')
    if failed > 0:
        print(f'Failed: {failed}')

    print(f'\nLogos saved to: {OUTPUT_DIR}')
    print('\nNext steps:')
    print('1. Review the SVG files in the CarLogos folder')
    print('2. Convert SVGs to PDF for iOS using:')
    print('   for f in *.svg; do rsvg-convert -f pdf -o "${f%.svg}.pdf" "$f"; done')
    print('3. Or use online converter: cloudconvert.com/svg-to-pdf')
    print('4. Add PDFs to Assets.xcassets as Image Sets')

if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
Import vehicle data from CSV to JSON format.

Usage: python3 import_csv_to_json.py

Input:  /Users/sohail/AutoLedger/vehicle_data.csv
Output: /Users/sohail/AutoLedger/AutoLedger/Resources/IndianVehicleData.json
"""

import csv
import json
from collections import defaultdict
from datetime import datetime

def import_csv():
    csv_path = '/Users/sohail/AutoLedger/vehicle_data.csv'
    json_path = '/Users/sohail/AutoLedger/AutoLedger/Resources/IndianVehicleData.json'

    # Read CSV
    makes_dict = defaultdict(list)

    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            make = row['Make'].strip()
            model_name = row['Model'].strip()
            fuel_types = [ft.strip() for ft in row['Fuel Types'].split(',') if ft.strip()]
            transmission = row['Transmission'].strip()
            tank_l = row['Tank (L)'].strip()
            battery_kwh = row['Battery (kWh)'].strip()
            discontinued = row['Discontinued'].strip().lower() == 'yes'

            model = {
                'name': model_name,
                'fuelTypes': fuel_types,
                'transmission': transmission
            }

            if tank_l:
                model['tankL'] = float(tank_l)
            if battery_kwh:
                model['batteryKWh'] = float(battery_kwh)
            if discontinued:
                model['discontinued'] = True

            makes_dict[make].append(model)

    # Build JSON structure
    data = {
        'version': '7.0',
        'lastUpdated': datetime.now().strftime('%Y-%m-%d'),
        'makes': []
    }

    for make_name in sorted(makes_dict.keys()):
        data['makes'].append({
            'name': make_name,
            'models': makes_dict[make_name]
        })

    # Write JSON
    with open(json_path, 'w') as f:
        json.dump(data, f, indent=2)

    print(f"Imported {sum(len(m['models']) for m in data['makes'])} models from {len(data['makes'])} makes")
    print(f"Saved to: {json_path}")

if __name__ == '__main__':
    import_csv()

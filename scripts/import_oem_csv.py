#!/usr/bin/env python3
"""
Convert OEM-named CSV to IndianVehicleData.json format.
"""

import csv
import json
from pathlib import Path
from collections import defaultdict

CSV_FILE = Path("/Users/sohail/Downloads/indian_car_models_oem_named.csv")
OUTPUT_FILE = Path("/Users/sohail/AutoLedger/AutoLedger/Resources/IndianVehicleData.json")

def parse_fuel_types(fuel_str: str) -> list:
    """Parse comma-separated fuel types."""
    if not fuel_str:
        return ["petrol"]

    fuels = []
    for f in fuel_str.split(","):
        f = f.strip().lower()
        # Normalize fuel type names
        if f == "cng":
            fuels.append("cng")
        elif f == "electric":
            fuels.append("electric")
        elif f == "diesel":
            fuels.append("diesel")
        elif f == "hybrid":
            fuels.append("hybrid")
        elif f == "plug-in hybrid" or f == "plugin hybrid":
            fuels.append("plugInHybrid")
        else:
            fuels.append("petrol")

    # Remove duplicates while preserving order
    seen = set()
    unique_fuels = []
    for f in fuels:
        if f not in seen:
            seen.add(f)
            unique_fuels.append(f)

    return unique_fuels

def main():
    makes_dict = defaultdict(list)

    with open(CSV_FILE, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)

        for row in reader:
            make = row['Make'].strip()
            model = row['Model'].strip()
            fuel_types = parse_fuel_types(row['Fuel Types'])
            transmission = row['Transmission'].strip() or "Manual"

            # Parse tank capacity
            tank_str = row['Tank (L)'].strip()
            tank_capacity = float(tank_str) if tank_str else None

            # Parse battery capacity
            battery_str = row['Battery (kWh)'].strip()
            battery_capacity = float(battery_str) if battery_str else None

            # Parse discontinued
            discontinued = row['Discontinued'].strip().lower() == 'yes'

            model_data = {
                "name": model,
                "fuelTypes": fuel_types,
                "transmission": transmission,
            }

            if tank_capacity:
                model_data["tankL"] = tank_capacity

            if battery_capacity:
                model_data["batteryKWh"] = battery_capacity

            if discontinued:
                model_data["discontinued"] = True

            makes_dict[make].append(model_data)

    # Build final structure
    makes_list = []
    for make_name, models in makes_dict.items():
        # Sort models alphabetically, with discontinued at the end
        models.sort(key=lambda m: (m.get("discontinued", False), m["name"]))

        makes_list.append({
            "name": make_name,
            "models": models
        })

    # Sort makes alphabetically
    makes_list.sort(key=lambda m: m["name"])

    from datetime import datetime
    output = {
        "version": "2.0",
        "lastUpdated": datetime.now().strftime("%Y-%m-%d"),
        "makes": makes_list
    }

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    # Print summary
    total_models = sum(len(m["models"]) for m in makes_list)
    active_models = sum(
        1 for m in makes_list
        for model in m["models"]
        if not model.get("discontinued", False)
    )

    print(f"Converted {total_models} models from {len(makes_list)} makes")
    print(f"Active models: {active_models}")
    print(f"Discontinued: {total_models - active_models}")
    print(f"Output: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()

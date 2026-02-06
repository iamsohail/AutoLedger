/**
 * Deduplicate models (case-insensitive)
 * Merge fuel types and prefer non-discontinued
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

let dupsRemoved = 0;

data.makes.forEach(make => {
    const seen = new Map();
    const deduped = [];

    make.models.forEach(model => {
        const key = model.name.toUpperCase();

        if (seen.has(key)) {
            dupsRemoved++;
            const existing = seen.get(key);

            // Merge fuel types
            const allFuels = new Set([...existing.fuelTypes, ...model.fuelTypes]);
            existing.fuelTypes = Array.from(allFuels);

            // Prefer non-discontinued
            if (!model.discontinued && existing.discontinued) {
                existing.discontinued = false;
            }

            // Keep tank/battery if missing
            if (!existing.tankL && model.tankL) {
                existing.tankL = model.tankL;
            }
            if (!existing.batteryKWh && model.batteryKWh) {
                existing.batteryKWh = model.batteryKWh;
            }

            // Upgrade transmission to Both if different
            if (existing.transmission !== model.transmission) {
                existing.transmission = 'Both';
            }
        } else {
            seen.set(key, model);
            deduped.push(model);
        }
    });

    make.models = deduped;
});

data.version = "6.1";
data.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

const totalModels = data.makes.reduce((sum, m) => sum + m.models.length, 0);

console.log('✅ Models deduplicated!\n');
console.log(`   Duplicates merged: ${dupsRemoved}`);
console.log(`   Final models: ${totalModels}`);

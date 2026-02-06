/**
 * Simplify data structure - Remove variants
 * New structure: Make → Model → Fuel Types + Tank/Battery + Transmission options
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

const simplified = {
    version: "6.0",
    lastUpdated: new Date().toISOString().split('T')[0],
    makes: []
};

let modelCount = 0;

data.makes.forEach(make => {
    const simplifiedMake = {
        name: make.name,
        models: []
    };

    make.models.forEach(model => {
        const fuelTypes = [];
        const transmissions = new Set();

        if (model.variants) {
            // Collect fuel types and transmissions
            Object.keys(model.variants).forEach(fuelType => {
                fuelTypes.push(fuelType);
                model.variants[fuelType].forEach(v => {
                    if (v.transmission) {
                        transmissions.add(v.transmission);
                    }
                });
            });
        }

        // Determine transmission options
        let transmission;
        if (transmissions.has('Manual') && transmissions.has('Automatic')) {
            transmission = 'Both';
        } else if (transmissions.has('Automatic')) {
            transmission = 'Automatic';
        } else {
            transmission = 'Manual';
        }

        const simplifiedModel = {
            name: model.name,
            fuelTypes: fuelTypes.length > 0 ? fuelTypes : ['petrol'],
            transmission: transmission
        };

        // Add tank capacity if available
        if (model.tankL) {
            simplifiedModel.tankL = model.tankL;
        }

        // Add battery capacity if available (for EVs)
        if (model.batteryKWh) {
            simplifiedModel.batteryKWh = model.batteryKWh;
        }

        // Add discontinued flag if true
        if (model.discontinued) {
            simplifiedModel.discontinued = true;
        }

        simplifiedMake.models.push(simplifiedModel);
        modelCount++;
    });

    simplified.makes.push(simplifiedMake);
});

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(simplified, null, 2)
);

console.log('✅ Data simplified!\n');
console.log(`   Makes: ${simplified.makes.length}`);
console.log(`   Models: ${modelCount}`);
console.log('\n   Structure: Make → Model → Fuel Types + Tank + Transmission');

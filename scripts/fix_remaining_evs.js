/**
 * Fix remaining EVs that have mixed fuel types
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

// Specific models to fix
const EV_MODELS = [
    'Nexon EV', 'Tigor EV', 'EV6', 'ZS EV', 'iX1'
];

let fixedCount = 0;

data.makes.forEach(make => {
    make.models.forEach(model => {
        // Fix specific models
        if (EV_MODELS.includes(model.name)) {
            if (model.fuelTypes.includes('petrol')) {
                model.fuelTypes = ['electric'];
                fixedCount++;
                console.log(`  Fixed: ${make.name} ${model.name}`);
            }
        }

        // Any model with "EV" in name should be electric only
        if (/\bEV\b/.test(model.name) && model.fuelTypes.includes('petrol')) {
            model.fuelTypes = ['electric'];
            fixedCount++;
            console.log(`  Fixed (EV pattern): ${make.name} ${model.name}`);
        }
    });
});

data.version = "6.3";
data.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log(`\n✅ Fixed ${fixedCount} remaining EVs`);

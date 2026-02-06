/**
 * Consolidate Vehicle Data
 *
 * Merges all 3 data files into one clean structure with:
 * - Tank capacity embedded in model
 * - Transmission embedded in variant
 * - Generic/placeholder model names removed
 */

const fs = require('fs');

const vehicleData = require('../AutoLedger/Resources/IndianVehicleDataV2.json');
const tankData = require('../AutoLedger/Resources/TankCapacityData.json');
const transmissionData = require('../AutoLedger/Resources/TransmissionData.json');

// Patterns to filter out generic/placeholder model names
const GENERIC_NAME_PATTERNS = [
    /\(Gen \d+-\d+\)/i,        // City (Gen 1-4)
    /\(Old\)$/i,               // Innova (Old), Jazz (Old)
    /\(Gen\s*\d+\)/i,          // Any (Gen X) suffix
    /Tour$/i,                  // Tour variants (commercial)
    /Tour\s+\w+$/i,            // Tour S, Tour H1
    /Cargo$/i,                 // Eeco Cargo (commercial)
    /Pickup$/i,                // Yodha Pickup
    /Pik-Up/i,                 // Bolero Pik-Up
    /Maxi Truck/i,             // Commercial vehicles
    /^Super Carry$/i,          // Commercial
    /-T$/i,                    // Xpres-T (fleet)
    /-T EV$/i,                 // Xpres-T EV (fleet)
    /Prime HB$/i,              // Hyundai Prime HB (taxi)
    /Prime SD$/i,              // Hyundai Prime SD (taxi)
    /Xcent Prime$/i,           // Taxi variant
    /Grand I10 Prime$/i,       // Taxi variant
];

// Models to explicitly remove (commercial/fleet/taxi only)
const MODELS_TO_REMOVE = [
    'Dzire Tour S',
    'Ertiga Tour',
    'WagonR Tour',
    'Swift Dzire Tour',
    'Alto 800 Tour',
    'Alto Tour H1',
    'Eeco Cargo',
    'Super Carry',
    'Xpres-T',
    'Xpres-T EV',
    'City (Gen 1-4)',
    'City VTEC',
    'Innova (Old)',
    'Jazz (Old)',
    'Prime HB',
    'Prime SD',
    'Bolero Pik-Up',
    'Bolero Pik-Up Extra Strong',
    'Bolero Maxi Truck Plus',
    'Bolero Camper',
    'Yodha Pickup',
    'S-Cab',
    'S-Cab Z',
    'HI-Lander',
    'Maxximo',
    'Supro',
    'Gio',
    'Major',
    'Commander',
    'MM',
    'Aveo U-VA',
    'Optra Magnum',
    'Optra SRV',
    'Sail U-VA',
    'Palio Adventure',
    'Palio Stile',
    'Grande Punto',
    '500 Abarth',
    'Avventura Urban Cross',
    'Ambassador Avigo',
    'Ambassador Classic',
    'Ambassador Grand',
    'Contessa Classic',
    'Premier 118NE',
    'Premier 137',
    'Getz Prime',
    'Santro Xing',
    'Sonata Embera',
    'Verna Transform',
    'Active i20',
    'Indica Vista',
    'Indigo eCS',
    'Indigo Marina',
    'Safari DiCOR',
    'Sumo Grande',
    'Fiesta Classic',
    'Focus',
    'Cooper Countryman',
    'John Cooper Works',
    'Gurkha',           // Duplicate with Force Motors
    'Gurkha 5 Door',
    'Urbania',
    'G-Class Electric',
    'Cayenne Electric',
    'Macan EV',
    '2 Series',
    'M8 Coupe Competition',
    'X6 M',
    'RS e-tron GT',
    'RS 6',
    'RS 7',
    'AMG A 45 S',
    'AMG C 63',
    'AMG C43',
    'AMG CLE 53',
    'AMG E 53 Cabriolet',
    'AMG GLC 43',
    'AMG GLE 53',
    'AMG GT Coupe',
    'AMG S 63',
    'AMG SL',
    'M-Class',
    'R-Class',
    'Land Cruiser Prado',  // Duplicate
    'Prado',
    'Compass Trailhawk',   // Duplicate of Compass
    'Trailhawk',
    'GT-R',                // Not sold in India anymore
    '812 Superfast',
    'GTC4Lusso',
    'SF90 Stradale',
    'Huracán EVO',
    'Bentayga EWB',
];

function shouldRemoveModel(modelName) {
    // Check explicit removal list
    if (MODELS_TO_REMOVE.includes(modelName)) {
        return true;
    }

    // Check patterns
    for (const pattern of GENERIC_NAME_PATTERNS) {
        if (pattern.test(modelName)) {
            return true;
        }
    }

    return false;
}

function getTankCapacity(makeName, modelName) {
    // Try exact match
    const key = `${makeName}|${modelName}`;
    if (tankData.data[key]) {
        return tankData.data[key];
    }

    // Try case variations
    for (const [k, v] of Object.entries(tankData.data)) {
        if (k.toLowerCase() === key.toLowerCase()) {
            return v;
        }
    }

    return null;
}

function getTransmission(makeName, modelName, fuelType, variantName) {
    // Clean variant name (remove [Disc.] and [Hist.] markers)
    const cleanVariant = variantName.replace(/\s*\[(Disc\.|Hist\.)\]\s*/gi, '').trim();

    const key = `${makeName}|${modelName}|${fuelType}|${cleanVariant}`;

    if (transmissionData.data[key]) {
        return transmissionData.data[key];
    }

    // Try without the markers in key
    for (const [k, v] of Object.entries(transmissionData.data)) {
        if (k.toLowerCase() === key.toLowerCase()) {
            return v;
        }
    }

    return 'manual'; // Default
}

// Build consolidated data
const consolidatedData = {
    version: "4.0",
    lastUpdated: new Date().toISOString().split('T')[0],
    sources: ["CarWale", "CarDekho", "Kaggle"],
    makes: []
};

let removedModels = [];
let totalModels = 0;
let totalVariants = 0;

for (const make of vehicleData.makes) {
    const cleanMake = {
        name: make.name,
        models: []
    };

    for (const model of make.models) {
        // Skip generic/unwanted models
        if (shouldRemoveModel(model.name)) {
            removedModels.push(`${make.name} ${model.name}`);
            continue;
        }

        // Skip models with no variants and marked discontinued
        if (model.discontinued && (!model.variants || Object.keys(model.variants).length === 0)) {
            removedModels.push(`${make.name} ${model.name} (no variants)`);
            continue;
        }

        const cleanModel = {
            name: model.name,
            discontinued: model.discontinued || false
        };

        // Add tank capacity
        const tank = getTankCapacity(make.name, model.name);
        if (tank) {
            if (tank.tankL) cleanModel.tankL = tank.tankL;
            if (tank.batteryKWh) cleanModel.batteryKWh = tank.batteryKWh;
        }

        // Add variants with transmission
        if (model.variants && Object.keys(model.variants).length > 0) {
            cleanModel.variants = {};

            for (const [fuelType, variants] of Object.entries(model.variants)) {
                cleanModel.variants[fuelType] = variants.map(variantName => {
                    // Clean the variant name
                    const isDiscontinued = /\[(Disc\.|Hist\.)\]/i.test(variantName);
                    const cleanName = variantName.replace(/\s*\[(Disc\.|Hist\.)\]\s*/gi, '').trim();

                    const variantObj = {
                        name: cleanName,
                        transmission: getTransmission(make.name, model.name, fuelType, variantName)
                    };

                    if (isDiscontinued) {
                        variantObj.discontinued = true;
                    }

                    totalVariants++;
                    return variantObj;
                });
            }
        }

        totalModels++;
        cleanMake.models.push(cleanModel);
    }

    // Only add make if it has models
    if (cleanMake.models.length > 0) {
        consolidatedData.makes.push(cleanMake);
    }
}

// Save consolidated data
fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(consolidatedData, null, 2)
);

console.log('✅ Consolidated data created!\n');
console.log(`   Makes: ${consolidatedData.makes.length}`);
console.log(`   Models: ${totalModels}`);
console.log(`   Variants: ${totalVariants}`);
console.log(`   Removed: ${removedModels.length} models\n`);
console.log('📁 Saved to: IndianVehicleData.json\n');

console.log('🗑️  Removed models:');
removedModels.slice(0, 30).forEach(m => console.log(`   - ${m}`));
if (removedModels.length > 30) {
    console.log(`   ... and ${removedModels.length - 30} more`);
}

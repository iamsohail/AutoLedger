/**
 * Merge Discontinued Variants
 *
 * Merges the discontinued variants data with the scraped active variants
 * to create a comprehensive vehicle database.
 *
 * Usage: node merge_variants.js
 */

const fs = require('fs');

// Load scraped data
const scrapedData = require('../AutoLedger/Resources/IndianVehicleDataV2.json');
const discontinuedData = require('./discontinued_variants.json');

console.log('🔄 Merging discontinued variants into vehicle data...\n');

let addedVariants = 0;
let modelsUpdated = 0;

// Process each make
for (const make of scrapedData.makes) {
    const makeName = make.name;
    const discontinuedMake = discontinuedData.data[makeName];

    if (!discontinuedMake) continue;

    // Process each model in this make
    for (const model of make.models) {
        const modelName = model.name;
        const discontinuedModel = discontinuedMake[modelName];

        if (!discontinuedModel) continue;

        let updated = false;

        // Add discontinued variants for each fuel type
        for (const [fuelKey, variants] of Object.entries(discontinuedModel)) {
            // Skip non-variant fields
            if (['discontinuedYear', 'note'].includes(fuelKey)) continue;

            // Normalize fuel type (petrol_old -> petrol, diesel_old -> diesel)
            let fuelType = fuelKey.replace('_old', '');

            // Initialize fuel type array if not exists
            if (!model.variants) model.variants = {};
            if (!model.variants[fuelType]) {
                model.variants[fuelType] = [];
            }

            // Add discontinued variants that don't exist
            for (const variant of variants) {
                // Mark as discontinued
                const variantName = `${variant} [Disc.]`;

                // Check if variant already exists (without discontinued marker)
                const exists = model.variants[fuelType].some(v =>
                    v.toLowerCase() === variant.toLowerCase() ||
                    v.toLowerCase() === variantName.toLowerCase()
                );

                if (!exists) {
                    model.variants[fuelType].push(variantName);
                    addedVariants++;
                    updated = true;
                }
            }

            // Update fuel types list
            if (!model.fuelTypes.includes(fuelType)) {
                model.fuelTypes.push(fuelType);
            }
        }

        // Add discontinuedYear if available
        if (discontinuedModel.discontinuedYear) {
            model.discontinuedYear = discontinuedModel.discontinuedYear;
        }

        if (updated) {
            modelsUpdated++;
            console.log(`   ✓ ${makeName} ${modelName}: added discontinued variants`);
        }
    }
}

// Update version and note
scrapedData.version = "3.0";
scrapedData.lastUpdated = new Date().toISOString().split('T')[0];
scrapedData.note = "Comprehensive data from CarWale + CarDekho + discontinued variants";

// Save merged data
fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleDataV2.json',
    JSON.stringify(scrapedData, null, 2)
);

console.log(`\n✅ Merge complete!`);
console.log(`   Models updated: ${modelsUpdated}`);
console.log(`   Discontinued variants added: ${addedVariants}`);
console.log(`\n📁 Saved to IndianVehicleDataV2.json`);

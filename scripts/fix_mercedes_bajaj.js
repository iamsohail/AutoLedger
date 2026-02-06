/**
 * Fix data issues:
 * 1. Remove Bajaj (commercial vehicles)
 * 2. Fix Mercedes fuel types based on variant naming:
 *    - "d" suffix = diesel (200d, 220d, 300d, 450d)
 *    - EQ prefix = electric (EQA, EQB, EQE, EQS)
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

// Remove Bajaj
const bajajIndex = data.makes.findIndex(m => m.name === 'Bajaj');
if (bajajIndex !== -1) {
    data.makes.splice(bajajIndex, 1);
    console.log('✓ Removed Bajaj (commercial)');
}

// Fix Mercedes fuel types
const mercedes = data.makes.find(m => m.name === 'Mercedes-Benz');
if (mercedes) {
    let dieselMoved = 0;
    let electricMoved = 0;

    mercedes.models.forEach(model => {
        if (!model.variants) return;

        // Check if model name contains EQ (electric)
        const isEQModel = /\bEQ[A-Z]?\b/.test(model.name) || model.name.includes('EQS') || model.name.includes('EQE') || model.name.includes('EQA') || model.name.includes('EQB');

        // Get all variants from petrol (incorrectly categorized)
        const petrolVariants = model.variants.petrol || [];
        const toMoveToElectric = [];
        const toMoveToDiesel = [];
        const stayPetrol = [];

        petrolVariants.forEach(variant => {
            if (isEQModel) {
                // EQ models are electric
                toMoveToElectric.push(variant);
            } else if (/\bd\b/i.test(variant.name) || /\d+d\b/i.test(variant.name)) {
                // Variants with "d" suffix (200d, 220d, 300d, 450d, G 450d)
                toMoveToDiesel.push(variant);
            } else {
                stayPetrol.push(variant);
            }
        });

        // Move to diesel
        if (toMoveToDiesel.length > 0) {
            if (!model.variants.diesel) model.variants.diesel = [];
            model.variants.diesel.push(...toMoveToDiesel);
            dieselMoved += toMoveToDiesel.length;
        }

        // Move to electric
        if (toMoveToElectric.length > 0) {
            if (!model.variants.electric) model.variants.electric = [];
            model.variants.electric.push(...toMoveToElectric);
            electricMoved += toMoveToElectric.length;
        }

        // Update petrol list
        if (stayPetrol.length > 0) {
            model.variants.petrol = stayPetrol;
        } else {
            delete model.variants.petrol;
        }

        // Clean up empty fuel types
        Object.keys(model.variants).forEach(fuel => {
            if (model.variants[fuel].length === 0) {
                delete model.variants[fuel];
            }
        });
    });

    console.log(`✓ Mercedes: ${dieselMoved} variants moved to diesel`);
    console.log(`✓ Mercedes: ${electricMoved} variants moved to electric`);
}

// Update version
data.version = "5.3";
data.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log('\n✅ Fixes applied!');
console.log(`   Makes: ${data.makes.length}`);

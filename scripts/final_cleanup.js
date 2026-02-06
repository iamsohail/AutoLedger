/**
 * Final Cleanup - Remove all transmission and fuel suffixes from variant names
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

// Patterns to remove (order matters - longer patterns first)
const REMOVE_PATTERNS = [
    // Transmission patterns
    /\s+AGS$/i,
    /\s+AMT$/i,
    /\s+AT$/i,
    /\s+MT$/i,
    /\s+CVT$/i,
    /\s+DCT$/i,
    /\s+IMT$/i,
    /\s+ECVT$/i,
    /\s+6AT$/i,
    /\s+7DCT$/i,
    /\s+E\s+CVT$/i,

    // Fuel type patterns
    /\s+CNG$/i,
    /\s+PETROL$/i,
    /\s+DIESEL$/i,

    // Optional markers
    /\s+O$/,         // Single O at end
    /\s+S$/,         // Single S at end (CNG marker)

    // Seater info
    /\s+\d+\s*STR$/i,
    /\s+\d+\s*SEATER$/i,
];

// Patterns with AT/MT in middle (before DUAL TONE etc)
const MIDDLE_PATTERNS = [
    /\s+AT\s+/i,
    /\s+MT\s+/i,
    /\s+AGS\s+/i,
    /\s+AMT\s+/i,
    /\s+CVT\s+/i,
];

function cleanVariantName(name) {
    let cleaned = name;

    // Remove middle patterns (AT DUAL TONE -> DUAL TONE)
    for (const pattern of MIDDLE_PATTERNS) {
        cleaned = cleaned.replace(pattern, ' ');
    }

    // Remove end patterns
    for (const pattern of REMOVE_PATTERNS) {
        cleaned = cleaned.replace(pattern, '');
    }

    // Clean up spaces
    cleaned = cleaned.replace(/\s+/g, ' ').trim();

    return cleaned;
}

let totalBefore = 0;
let totalAfter = 0;
let cleanedCount = 0;

data.makes.forEach(make => {
    make.models.forEach(model => {
        if (model.variants) {
            Object.keys(model.variants).forEach(fuelType => {
                const seen = new Map();
                const cleanedList = [];

                model.variants[fuelType].forEach(variant => {
                    totalBefore++;
                    const originalName = variant.name;
                    const cleanedName = cleanVariantName(originalName);

                    if (!cleanedName || cleanedName.length < 1) {
                        return;
                    }

                    if (originalName !== cleanedName) {
                        cleanedCount++;
                        // console.log(`  ${originalName} -> ${cleanedName}`);
                    }

                    // Deduplicate
                    const key = cleanedName.toUpperCase();
                    if (seen.has(key)) {
                        const existing = seen.get(key);
                        if (!variant.discontinued && existing.discontinued) {
                            existing.name = cleanedName;
                            existing.transmission = variant.transmission;
                            existing.discontinued = false;
                        }
                        return;
                    }

                    variant.name = cleanedName;
                    seen.set(key, variant);
                    cleanedList.push(variant);
                    totalAfter++;
                });

                model.variants[fuelType] = cleanedList;
            });

            // Remove empty fuel types
            Object.keys(model.variants).forEach(fuelType => {
                if (model.variants[fuelType].length === 0) {
                    delete model.variants[fuelType];
                }
            });
        }
    });
});

// Update version
data.version = "5.1";
data.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log('✅ Final cleanup complete!\n');
console.log(`   Before: ${totalBefore} variants`);
console.log(`   After: ${totalAfter} variants`);
console.log(`   Cleaned: ${cleanedCount} names`);
console.log(`   Removed: ${totalBefore - totalAfter} duplicates`);
console.log('\n📁 Saved to: IndianVehicleData.json');

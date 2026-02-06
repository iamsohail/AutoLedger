/**
 * Clean Variant Names
 * Removes transmission suffixes (AT, AGS, MT, CVT, DCT, AMT, IMT) from variant names
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

// Patterns to remove from variant names
const TRANSMISSION_SUFFIXES = [
    /\s+AGS$/i,
    /\s+AT$/i,
    /\s+MT$/i,
    /\s+CVT$/i,
    /\s+DCT$/i,
    /\s+AMT$/i,
    /\s+IMT$/i,
    /\s+6AT$/i,
    /\s+6at$/i,
    /\s+7DCT$/i,
    /\s+Ecvt$/i,
    /\s+E CVT$/i,
    /\s+Amt$/i,
    /\s+At$/i,
    /\s+Mt$/i,
    /\s+Cvt$/i,
    /\s+Automatic$/i,
    /\s+Manual$/i,
];

function cleanVariantName(name) {
    let cleaned = name;

    // Apply all suffix removals
    for (const pattern of TRANSMISSION_SUFFIXES) {
        cleaned = cleaned.replace(pattern, '');
    }

    // Clean up any double spaces and trim
    cleaned = cleaned.replace(/\s+/g, ' ').trim();

    return cleaned;
}

// Track unique variants per model+fuel to avoid duplicates after cleaning
let duplicatesRemoved = 0;
let totalVariants = 0;
let cleanedVariants = 0;

data.makes.forEach(make => {
    make.models.forEach(model => {
        if (model.variants) {
            Object.keys(model.variants).forEach(fuelType => {
                const seen = new Map(); // name -> variant object
                const cleanedList = [];

                model.variants[fuelType].forEach(variant => {
                    const originalName = variant.name;
                    const cleanedName = cleanVariantName(originalName);
                    totalVariants++;

                    // Check if we already have this cleaned name
                    if (seen.has(cleanedName)) {
                        // Keep the one that's not discontinued, or the first one
                        const existing = seen.get(cleanedName);
                        if (variant.discontinued && !existing.discontinued) {
                            // Keep existing (active), skip this one
                            duplicatesRemoved++;
                        } else if (!variant.discontinued && existing.discontinued) {
                            // Replace with active variant
                            existing.name = cleanedName;
                            existing.discontinued = false;
                            duplicatesRemoved++;
                        } else {
                            // Both same status, keep first
                            duplicatesRemoved++;
                        }
                    } else {
                        variant.name = cleanedName;
                        seen.set(cleanedName, variant);
                        cleanedList.push(variant);
                        if (originalName !== cleanedName) {
                            cleanedVariants++;
                        }
                    }
                });

                model.variants[fuelType] = cleanedList;
            });
        }
    });
});

// Update version
data.version = "4.1";
data.lastUpdated = new Date().toISOString().split('T')[0];

// Save cleaned data
fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log('✅ Variant names cleaned!\n');
console.log(`   Total variants processed: ${totalVariants}`);
console.log(`   Names cleaned: ${cleanedVariants}`);
console.log(`   Duplicates removed: ${duplicatesRemoved}`);
console.log(`   Final variants: ${totalVariants - duplicatesRemoved}`);
console.log('\n📁 Saved to: IndianVehicleData.json');

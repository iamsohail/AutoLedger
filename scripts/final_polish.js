/**
 * Final Polish - Remove remaining transmission/seater codes from variant names
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

// Patterns to remove
const REMOVE_PATTERNS = [
    // Transmission with numbers
    /\s+\d+MT\b/gi,           // 5MT, 6MT
    /\s+\d+DCT\b/gi,          // 6DCT, 7DCT
    /\s+\d+AT\b/gi,           // 6AT, 8AT
    /\s+\d+AMT\b/gi,          // 5AMT
    /\s+\d+CVT\b/gi,          // eCVT
    /\s+\d+dct\b/gi,          // 6dct lowercase
    // Seater patterns
    /\s+\d+str\b/gi,          // 6str, 7str
    /\s+\d+Str\b/gi,
    /\s+\d+STR\b/gi,
    /\s+\d+\s*Seater\b/gi,    // 7 Seater
    // Pure transmission at end
    /\s+MT$/i,
    /\s+AT$/i,
    /\s+AMT$/i,
    /\s+CVT$/i,
    /\s+DCT$/i,
    /\s+DSG$/i,
    /\s+IVT$/i,
    /\s+IMT$/i,
];

function cleanVariant(name) {
    let cleaned = name;

    for (const pattern of REMOVE_PATTERNS) {
        cleaned = cleaned.replace(pattern, '');
    }

    // Clean up spaces
    cleaned = cleaned.replace(/\s+/g, ' ').trim();

    return cleaned;
}

let changedCount = 0;
let totalAfter = 0;

data.makes.forEach(make => {
    make.models.forEach(model => {
        if (!model.variants) return;

        Object.keys(model.variants).forEach(fuelType => {
            const seen = new Map();
            const cleanedList = [];

            model.variants[fuelType].forEach(variant => {
                const original = variant.name;
                const cleaned = cleanVariant(original);

                if (!cleaned || cleaned.length < 1) return;

                if (original !== cleaned) {
                    changedCount++;
                    // console.log(`  ${original} -> ${cleaned}`);
                }

                // Deduplicate
                const key = cleaned.toUpperCase();
                if (seen.has(key)) {
                    const existing = seen.get(key);
                    if (!variant.discontinued && existing.discontinued) {
                        existing.name = cleaned;
                        existing.discontinued = false;
                    }
                    return;
                }

                variant.name = cleaned;
                seen.set(key, variant);
                cleanedList.push(variant);
                totalAfter++;
            });

            model.variants[fuelType] = cleanedList;
        });

        // Remove empty
        Object.keys(model.variants).forEach(fuelType => {
            if (model.variants[fuelType].length === 0) {
                delete model.variants[fuelType];
            }
        });
    });
});

data.version = "5.6";
data.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log('✅ Final polish complete!\n');
console.log(`   Changed: ${changedCount} names`);
console.log(`   Final: ${totalAfter} variants`);

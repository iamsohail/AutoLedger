/**
 * Fix remaining issues:
 * - Remove "L " prefix (leftover from engine capacity)
 * - Remove "S " prefix/suffix (CNG marker)
 * - Clean other edge cases
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

const FIXES = [
    // L prefix from engine capacity
    [/^L\s+/i, ''],
    // S markers
    [/\s+S\s+/i, ' '],    // S in middle
    [/\s+S$/i, ''],       // S at end
    // Trailing O
    [/\s+O$/i, ''],
    // Stray numbers at start
    [/^\d+\s+/, ''],
    // "PLUS O" -> "PLUS"
    [/\s+PLUS\s+O\b/i, ' PLUS'],
    // Multiple spaces
    [/\s+/g, ' '],
];

function fixVariantName(name) {
    let fixed = name;
    for (const [pattern, replacement] of FIXES) {
        fixed = fixed.replace(pattern, replacement);
    }
    return fixed.trim();
}

let fixedCount = 0;
let dupsRemoved = 0;
let totalBefore = 0;
let totalAfter = 0;

data.makes.forEach(make => {
    make.models.forEach(model => {
        if (model.variants) {
            Object.keys(model.variants).forEach(fuelType => {
                const seen = new Map();
                const cleanedList = [];

                model.variants[fuelType].forEach(variant => {
                    totalBefore++;
                    const original = variant.name;
                    const fixed = fixVariantName(original);

                    if (original !== fixed) {
                        fixedCount++;
                    }

                    if (!fixed || fixed.length < 2) return;

                    // Dedupe
                    const key = fixed.toUpperCase();
                    if (seen.has(key)) {
                        dupsRemoved++;
                        const existing = seen.get(key);
                        if (!variant.discontinued && existing.discontinued) {
                            existing.name = fixed;
                            existing.transmission = variant.transmission;
                            existing.discontinued = false;
                        }
                        return;
                    }

                    variant.name = fixed;
                    seen.set(key, variant);
                    cleanedList.push(variant);
                    totalAfter++;
                });

                model.variants[fuelType] = cleanedList;
            });
        }
    });
});

data.version = "5.2";
data.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log('✅ Remaining fixes applied!\n');
console.log(`   Fixed: ${fixedCount} names`);
console.log(`   Duplicates removed: ${dupsRemoved}`);
console.log(`   Final: ${totalAfter} variants`);

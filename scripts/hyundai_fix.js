/**
 * Fix Hyundai-specific issues:
 * - "Asta O" -> "Asta(O)"
 * - "SX O" -> "SX(O)"
 * - Remove IVT from variant names
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

const FIXES = [
    // Hyundai (O) variants
    [/\bAsta O\b/gi, 'Asta(O)'],
    [/\bSX O\b/gi, 'SX(O)'],
    [/\bMagna O\b/gi, 'Magna(O)'],
    [/\bSportz O\b/gi, 'Sportz(O)'],
    // Remove transmission codes
    [/\s+IVT\b/gi, ''],
    [/\s+DCT\b/gi, ''],
    // Clean up spaces
    [/\s+/g, ' '],
];

let changedCount = 0;

data.makes.forEach(make => {
    make.models.forEach(model => {
        if (!model.variants) return;

        Object.keys(model.variants).forEach(fuelType => {
            model.variants[fuelType].forEach(variant => {
                const original = variant.name;
                let fixed = original;

                for (const [pattern, replacement] of FIXES) {
                    fixed = fixed.replace(pattern, replacement);
                }
                fixed = fixed.trim();

                if (original !== fixed) {
                    changedCount++;
                    // console.log(`  ${original} -> ${fixed}`);
                    variant.name = fixed;
                }
            });
        });
    });
});

data.version = "5.7";
data.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log('✅ Hyundai fixes applied!\n');
console.log(`   Changed: ${changedCount} names`);

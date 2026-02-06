/**
 * Deep Clean - Fix all remaining data issues:
 * 1. Remove fuel types from variant names (CNG, PETROL, DIESEL)
 * 2. Fix casing (Zdi -> ZDI, Vxi -> VXI)
 * 3. Remove parenthetical junk like "(cng +"
 * 4. Remove commercial/taxi variants
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

// All trim codes that should be uppercase
const UPPERCASE_TRIMS = [
    // Maruti - Petrol
    'LXI', 'VXI', 'ZXI', 'LX', 'VX', 'ZX',
    // Maruti - Diesel
    'LDI', 'VDI', 'ZDI', 'DDI',
    // Maruti - Greek
    'SIGMA', 'DELTA', 'ZETA', 'ALPHA', 'OMEGA',
    // Hyundai
    'ERA', 'MAGNA', 'SPORTZ', 'ASTA', 'SX', 'EX', 'S', 'E',
    // Tata
    'XE', 'XM', 'XT', 'XZ', 'XZA', 'XTA', 'XMA', 'XMS', 'XTS', 'XZS',
    'XZ+', 'XT+', 'XM+', 'XZ+ DT', 'XZA+',
    // Mahindra
    'MX', 'AX', 'W4', 'W6', 'W8', 'W10', 'W11', 'W12',
    // Honda
    'V', 'VX', 'ZX', 'SV', 'CV', 'E', 'S', 'EX',
    // VW/Skoda
    'HIGHLINE', 'COMFORTLINE', 'TRENDLINE', 'AMBITION', 'STYLE', 'ELEGANCE', 'LAURIN', 'KLEMENT',
    // Common
    'GT', 'GTI', 'GTS', 'GTX', 'RS', 'R',
    'PLUS', 'PRO', 'PRIME', 'MAX', 'LITE', 'BASE',
    'DLX', 'GLX', 'SLX', 'ELX', 'GL', 'GLS',
    'TITANIUM', 'TREND', 'AMBIENTE',
    'ALLGRIP', '4WD', '2WD', 'AWD', 'RWD',
    'DUAL', 'TONE', 'DT',
    'TURBO', 'HYBRID', 'EV',
    'CREATIVE', 'ACCOMPLISHED', 'FEARLESS', 'PURE', 'ADVENTURE',
    'PRESTIGE', 'ELITE', 'SPORT', 'SPORTS', 'LINE',
    'PHANTOM', 'BLAQ', 'EDITION', 'LIMITED',
    'AMG', 'M', 'SPORT', 'LUXURY',
    'STD', 'STR', 'SEATER',
];

// Build regex for case-insensitive replacement
const trimRegexMap = {};
UPPERCASE_TRIMS.forEach(trim => {
    // Match the trim as a whole word (with optional + suffix)
    trimRegexMap[trim] = new RegExp(`\\b${trim.replace('+', '\\+')}\\b`, 'gi');
});

// Patterns to remove from variant names
const REMOVE_PATTERNS = [
    /\s*\([^)]*$/,              // Unclosed parentheses "(cng +"
    /\s*\([^)]*\)/g,            // Closed parentheses "(O)", "(cng + petrol)"
    /\bCNG\b/gi,                // CNG word
    /\bPETROL\b/gi,             // PETROL word
    /\bDIESEL\b/gi,             // DIESEL word
    /\bHYBRID\b/gi,             // HYBRID word (fuel type is separate)
    /\bTaxi\b/gi,               // Commercial
    /\bBS6\b/gi,                // Emission standard
    /\bBSVI\b/gi,
    /\bBS-VI\b/gi,
    /\s+\+\s*$/,                // Trailing " +"
    /\s+\(\s*$/,                // Trailing " ("
];

function cleanVariantName(name) {
    let cleaned = name;

    // Remove junk patterns
    for (const pattern of REMOVE_PATTERNS) {
        cleaned = cleaned.replace(pattern, '');
    }

    // Fix casing - replace each trim with uppercase version
    for (const [trim, regex] of Object.entries(trimRegexMap)) {
        cleaned = cleaned.replace(regex, trim);
    }

    // Special case: fix patterns like "Zdi+" "Vxi+" that have + attached
    cleaned = cleaned.replace(/\b([LVZD])([xdXD])i\+/gi, (match, p1, p2) => {
        return p1.toUpperCase() + p2.toUpperCase() + 'I+';
    });

    // Fix standalone lowercase trim codes
    cleaned = cleaned.replace(/\b(lxi|vxi|zxi|ldi|vdi|zdi|lx|vx|zx)\b/gi, m => m.toUpperCase());

    // Clean up spaces
    cleaned = cleaned.replace(/\s+/g, ' ').trim();

    return cleaned;
}

let cleanedCount = 0;
let removedCount = 0;
let totalBefore = 0;
let totalAfter = 0;

data.makes.forEach(make => {
    make.models.forEach(model => {
        if (!model.variants) return;

        Object.keys(model.variants).forEach(fuelType => {
            const seen = new Map();
            const cleanedList = [];

            model.variants[fuelType].forEach(variant => {
                totalBefore++;
                const original = variant.name;
                const cleaned = cleanVariantName(original);

                // Skip invalid/commercial variants
                if (!cleaned || cleaned.length < 1) {
                    removedCount++;
                    return;
                }
                if (/taxi/i.test(original)) {
                    removedCount++;
                    return;
                }

                if (original !== cleaned) {
                    cleanedCount++;
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

        // Remove empty fuel types
        Object.keys(model.variants).forEach(fuelType => {
            if (model.variants[fuelType].length === 0) {
                delete model.variants[fuelType];
            }
        });
    });
});

data.version = "5.4";
data.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log('✅ Deep clean complete!\n');
console.log(`   Before: ${totalBefore} variants`);
console.log(`   Cleaned: ${cleanedCount} names`);
console.log(`   Removed: ${removedCount} invalid`);
console.log(`   Final: ${totalAfter} variants`);

/**
 * Standardize Variant Names
 * - Uppercase trim levels (LXI, VXI, ZXI, etc.)
 * - Remove engine capacity (1.2, 1.3, 1.5L, etc.)
 * - Clean redundant info
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

// Standard trim level mappings (lowercase -> proper case)
const TRIM_MAPPINGS = {
    // Maruti
    'lxi': 'LXI', 'lx': 'LX', 'vxi': 'VXI', 'vx': 'VX',
    'zxi': 'ZXI', 'zx': 'ZX', 'std': 'STD',
    'sigma': 'SIGMA', 'delta': 'DELTA', 'zeta': 'ZETA', 'alpha': 'ALPHA',
    'omega': 'OMEGA',

    // Hyundai
    'era': 'ERA', 'magna': 'MAGNA', 'sportz': 'SPORTZ', 'asta': 'ASTA',
    'sx': 'SX', 'sx(o)': 'SX(O)', 's': 'S', 'e': 'E',
    'elite': 'ELITE', 'prestige': 'PRESTIGE',

    // Tata
    'xe': 'XE', 'xm': 'XM', 'xt': 'XT', 'xz': 'XZ', 'xza': 'XZA',
    'xta': 'XTA', 'xma': 'XMA', 'xms': 'XMS', 'xts': 'XTS', 'xzs': 'XZS',
    'creative': 'CREATIVE', 'accomplished': 'ACCOMPLISHED',
    'fearless': 'FEARLESS', 'pure': 'PURE', 'adventure': 'ADVENTURE',

    // Mahindra
    'mx': 'MX', 'ax': 'AX', 'w4': 'W4', 'w6': 'W6', 'w8': 'W8', 'w10': 'W10',

    // Honda
    'v': 'V', 'vx': 'VX', 'zx': 'ZX', 's': 'S', 'sv': 'SV',

    // Common
    'base': 'BASE', 'plus': 'PLUS', 'pro': 'PRO', 'prime': 'PRIME',
    'style': 'STYLE', 'trend': 'TREND', 'titanium': 'TITANIUM',
    'highline': 'HIGHLINE', 'comfortline': 'COMFORTLINE', 'trendline': 'TRENDLINE',
    'gt': 'GT', 'gti': 'GTI', 'rs': 'RS', 'r': 'R',
    'sport': 'SPORT', 'sports': 'SPORTS',
    'turbo': 'TURBO', 'hybrid': 'HYBRID',
    'allgrip': 'ALLGRIP', '4wd': '4WD', '2wd': '2WD', 'awd': 'AWD', 'rwd': 'RWD',
    'petrol': 'PETROL', 'diesel': 'DIESEL', 'cng': 'CNG',
    'dual tone': 'DUAL TONE', 'dualjet': 'DUALJET',
    'intelligent': 'INTELLIGENT',
};

// Patterns to remove
const PATTERNS_TO_REMOVE = [
    // Engine capacity patterns
    /^1\.\d+\s*/i,           // 1.2, 1.3, 1.5 at start
    /^1\.\d+L?\s*/i,         // 1.2L, 1.5L at start
    /\s+1\.\d+L?$/i,         // 1.2L at end
    /\s+1\.\d+L?\s+/i,       // 1.2L in middle
    /\d+\.\d+L?\s*/i,        // Any X.XL pattern
    /\s+Petrol$/i,           // Redundant fuel type
    /\s+Diesel$/i,
    /\s+Smart Hybrid$/i,     // Redundant
    /\s+Dualjet$/i,          // Engine tech
    /\s+BSVI$/i,             // Emission standard
    /\s+BS6$/i,
    /\s+BS-VI$/i,
    /\s*\(O\)$/i,            // Optional variant marker
    /\s*\(Opt\)$/i,
    /\s+O$/,                 // O suffix (optional)
    /\s+S$/,                 // S suffix (CNG typically)
    /\s+Str$/i,              // Seater suffix
    /\s+7\s*Str$/i,
    /\s+8\s*Str$/i,
    /\s+6\s*Str$/i,
    /\s+5\s*Str$/i,
    /\s+Cng$/i,              // Redundant - fuel type is separate
    /\s+10l$/i,              // Engine spec
    /\s+12l$/i,
    /\s+15l$/i,
];

// Words to always uppercase
const UPPERCASE_WORDS = [
    'LXI', 'VXI', 'ZXI', 'LX', 'VX', 'ZX',
    'STD', 'SIGMA', 'DELTA', 'ZETA', 'ALPHA', 'OMEGA',
    'ERA', 'MAGNA', 'SPORTZ', 'ASTA', 'SX', 'EX',
    'XE', 'XM', 'XT', 'XZ', 'XZA', 'XTA', 'XMA',
    'MX', 'AX', 'W4', 'W6', 'W8', 'W10',
    'GT', 'GTI', 'RS', 'GTS', 'GTX',
    'PLUS', 'PRO', 'PRIME', 'MAX', 'LITE',
    'DLX', 'GLX', 'SLX', 'ELX',
    'TITANIUM', 'TREND', 'STYLE',
    'HIGHLINE', 'COMFORTLINE', 'TRENDLINE',
    'ALLGRIP', '4WD', '2WD', 'AWD', 'RWD',
    'DUAL', 'TONE', 'N', 'LINE',
    'TURBO', 'HYBRID', 'EV',
    'CREATIVE', 'ACCOMPLISHED', 'FEARLESS', 'PURE', 'ADVENTURE',
    'PRESTIGE', 'ELITE', 'SPORT', 'SPORTS',
    'PHANTOM', 'BLAQ', 'EDITION',
    'INTELLIGENT', 'CVT',
];

function standardizeVariantName(name) {
    let cleaned = name;

    // Remove patterns
    for (const pattern of PATTERNS_TO_REMOVE) {
        cleaned = cleaned.replace(pattern, ' ');
    }

    // Clean up spaces
    cleaned = cleaned.replace(/\s+/g, ' ').trim();

    // Split into words and standardize each
    const words = cleaned.split(' ');
    const standardized = words.map(word => {
        const upper = word.toUpperCase();
        // Check if it's a known trim level
        if (UPPERCASE_WORDS.includes(upper)) {
            return upper;
        }
        // Check mapping
        const lower = word.toLowerCase();
        if (TRIM_MAPPINGS[lower]) {
            return TRIM_MAPPINGS[lower];
        }
        // Default: Title case for unknown words, uppercase for short codes
        if (word.length <= 3 && /^[A-Za-z]+$/.test(word)) {
            return upper;
        }
        return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
    });

    cleaned = standardized.join(' ');

    // Final cleanup
    cleaned = cleaned.replace(/\s+/g, ' ').trim();

    // Remove empty or too short names
    if (cleaned.length < 2) {
        return null;
    }

    return cleaned;
}

// Process and deduplicate
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
                    const cleanedName = standardizeVariantName(originalName);

                    if (!cleanedName) {
                        return; // Skip invalid
                    }

                    if (originalName !== cleanedName) {
                        cleanedCount++;
                    }

                    // Deduplicate
                    const key = cleanedName.toUpperCase();
                    if (seen.has(key)) {
                        const existing = seen.get(key);
                        // Prefer non-discontinued
                        if (variant.discontinued && !existing.discontinued) {
                            return;
                        }
                        if (!variant.discontinued && existing.discontinued) {
                            existing.name = cleanedName;
                            existing.transmission = variant.transmission;
                            existing.discontinued = false;
                            return;
                        }
                        return; // Skip duplicate
                    }

                    variant.name = cleanedName;
                    seen.set(key, variant);
                    cleanedList.push(variant);
                    totalAfter++;
                });

                model.variants[fuelType] = cleanedList;
            });

            // Remove empty fuel type arrays
            Object.keys(model.variants).forEach(fuelType => {
                if (model.variants[fuelType].length === 0) {
                    delete model.variants[fuelType];
                }
            });
        }
    });
});

// Update version
data.version = "5.0";
data.lastUpdated = new Date().toISOString().split('T')[0];

// Save
fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log('✅ Variant names standardized!\n');
console.log(`   Before: ${totalBefore} variants`);
console.log(`   After: ${totalAfter} variants`);
console.log(`   Cleaned: ${cleanedCount} names`);
console.log(`   Removed duplicates: ${totalBefore - totalAfter}`);
console.log('\n📁 Saved to: IndianVehicleData.json');

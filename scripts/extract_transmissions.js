/**
 * Extract Transmission Types from Variant Names
 *
 * Analyzes variant names to determine transmission type.
 * Most variant names include transmission indicators like AMT, AT, MT, CVT, DCT.
 *
 * Usage: node extract_transmissions.js
 */

const fs = require('fs');

// Load scraped vehicle data
const vehicleData = require('../AutoLedger/Resources/IndianVehicleDataV2.json');

console.log('🔧 Extracting transmission types from variant names\n');

// Transmission patterns in variant names
const TRANSMISSION_PATTERNS = {
    // Automatic transmissions
    'amt': 'amt',           // Automated Manual Transmission
    'ags': 'amt',           // Auto Gear Shift (Maruti's AMT)
    'cvt': 'cvt',           // Continuously Variable Transmission
    'dct': 'dct',           // Dual Clutch Transmission
    'dsg': 'dct',           // Direct Shift Gearbox (VW's DCT)
    'imt': 'imt',           // Intelligent Manual Transmission
    'at': 'automatic',      // Automatic (torque converter)
    'automatic': 'automatic',

    // Manual transmissions
    'mt': 'manual',
    'manual': 'manual',

    // Specific patterns
    '6at': 'automatic',     // 6-speed automatic
    '7dct': 'dct',          // 7-speed DCT
    '6mt': 'manual',        // 6-speed manual
    '5mt': 'manual',        // 5-speed manual
};

// Words that indicate automatic variants even without explicit transmission code
const AUTO_INDICATORS = ['auto', 'automatic', 'smart', 'turbo dct'];

// Words that indicate manual variants
const MANUAL_INDICATORS = ['std', 'base'];

/**
 * Detect transmission type from variant name
 * @param {string} variantName - The variant name (e.g., "VXi AMT", "ZXi AT", "LXi")
 * @returns {string|null} - Transmission type or null if can't determine
 */
function detectTransmission(variantName) {
    if (!variantName) return null;

    const lower = variantName.toLowerCase();
    const words = lower.split(/[\s\-_()]+/);

    // Check each word for transmission patterns
    for (const word of words) {
        // Check exact matches first
        if (TRANSMISSION_PATTERNS[word]) {
            return TRANSMISSION_PATTERNS[word];
        }

        // Check if word ends with transmission code
        for (const [pattern, type] of Object.entries(TRANSMISSION_PATTERNS)) {
            if (word.endsWith(pattern) && word.length > pattern.length) {
                return type;
            }
        }
    }

    // Check for automatic indicators
    for (const indicator of AUTO_INDICATORS) {
        if (lower.includes(indicator)) {
            return 'automatic';
        }
    }

    // Check variant naming conventions
    // Many Indian car variants ending with 'A' are automatic versions
    // e.g., XTA = XT Automatic, XZA = XZ Automatic, XMA = XM Automatic
    const lastWord = words[words.length - 1];
    if (/^[a-z]{2,3}a$/.test(lastWord) && !['sigma', 'delta', 'zeta', 'alpha', 'omega'].includes(lastWord)) {
        // Check if it's a variant code + A (e.g., XTA, XZA, LXA, VXA)
        const withoutA = lastWord.slice(0, -1);
        if (['xt', 'xz', 'xm', 'xe', 'lx', 'vx', 'zx', 'gx', 'hx', 'mx', 'tx', 'sx'].includes(withoutA)) {
            return 'automatic';
        }
    }

    // If variant name has 'Plus' with A suffix, likely automatic
    if (lower.includes('plus') && lower.includes(' a ') || lower.endsWith(' a')) {
        return 'automatic';
    }

    // Cannot determine from name alone
    return null;
}

// Build transmission data
const transmissionData = {
    version: "1.0",
    lastUpdated: new Date().toISOString().split('T')[0],
    sources: ["CarWale", "CarDekho", "variant_name_analysis"],
    types: ["manual", "automatic", "amt", "cvt", "dct", "imt"],
    data: {}
};

let totalVariants = 0;
let detectedTransmissions = 0;
let undetected = [];

// Process each make -> model -> variant
for (const make of vehicleData.makes) {
    for (const model of make.models) {
        if (!model.variants) continue;

        for (const [fuelType, variants] of Object.entries(model.variants)) {
            for (const variant of variants) {
                totalVariants++;

                // Clean variant name (remove [Disc.] or [Hist.] markers)
                const cleanVariant = variant.replace(/\s*\[(Disc\.|Hist\.)\]\s*/gi, '').trim();

                const transmission = detectTransmission(cleanVariant);

                if (transmission) {
                    // Key format: Make|Model|fuelType|variant
                    const key = `${make.name}|${model.name}|${fuelType}|${cleanVariant}`;
                    transmissionData.data[key] = transmission;
                    detectedTransmissions++;
                } else {
                    // Track undetected for reporting
                    undetected.push(`${make.name} ${model.name} - ${cleanVariant} (${fuelType})`);
                }
            }
        }
    }
}

// Save transmission data
fs.writeFileSync(
    '../AutoLedger/Resources/TransmissionData.json',
    JSON.stringify(transmissionData, null, 2)
);

console.log(`✅ Transmission extraction complete!`);
console.log(`   Total variants: ${totalVariants}`);
console.log(`   Detected transmissions: ${detectedTransmissions}`);
console.log(`   Undetected: ${totalVariants - detectedTransmissions}`);
console.log(`\n📁 Saved to TransmissionData.json`);

// Show some undetected samples
if (undetected.length > 0) {
    console.log(`\n⚠️  Sample variants without detected transmission (first 20):`);
    undetected.slice(0, 20).forEach(v => console.log(`   - ${v}`));

    // These are likely manual by default in Indian market
    console.log(`\n💡 Note: Variants without explicit transmission codes are typically manual in the Indian market.`);
}

// Second pass: Set undetected variants to 'manual' (default in India)
console.log(`\n🔄 Setting undetected variants to 'manual' (default)...`);

for (const make of vehicleData.makes) {
    for (const model of make.models) {
        if (!model.variants) continue;

        for (const [fuelType, variants] of Object.entries(model.variants)) {
            for (const variant of variants) {
                const cleanVariant = variant.replace(/\s*\[(Disc\.|Hist\.)\]\s*/gi, '').trim();
                const key = `${make.name}|${model.name}|${fuelType}|${cleanVariant}`;

                if (!transmissionData.data[key]) {
                    transmissionData.data[key] = 'manual';
                }
            }
        }
    }
}

// Save updated transmission data
fs.writeFileSync(
    '../AutoLedger/Resources/TransmissionData.json',
    JSON.stringify(transmissionData, null, 2)
);

console.log(`\n✅ All variants now have transmission data!`);
console.log(`   Total entries: ${Object.keys(transmissionData.data).length}`);

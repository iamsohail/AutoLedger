/**
 * Proper Casing - Follow Indian OEM naming conventions
 * - Short codes: UPPERCASE (LXI, VXI, ZXI, XE, XM, HTE, HTK, etc.)
 * - Word trims: Title Case (Sigma, Delta, Era, Magna, Creative, etc.)
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

// Short codes - always UPPERCASE
const UPPERCASE_CODES = new Set([
    // Maruti
    'STD', 'LXI', 'VXI', 'ZXI', 'LX', 'VX', 'ZX',
    'LDI', 'VDI', 'ZDI', 'DDI',
    // Tata
    'XE', 'XM', 'XT', 'XZ', 'XZA', 'XTA', 'XMA', 'XMS', 'XTS', 'XZS',
    // Hyundai
    'SX', 'EX',
    // Mahindra
    'MX', 'AX', 'AX3', 'AX5', 'AX7', 'AX7L', 'LX',
    'W4', 'W6', 'W8', 'W10', 'W11', 'W12',
    // Kia
    'HTE', 'HTK', 'HTX', 'GT',
    // Toyota
    'E', 'G', 'V', 'VX', 'ZX', 'GR',
    // Honda
    'SV', 'CV',
    // Renault
    'RXE', 'RXL', 'RXT', 'RXZ',
    // Nissan
    'XE', 'XL', 'XV',
    // Common
    'DT', 'MT', 'AT', 'AMT', 'CVT', 'DCT', 'DSG', 'IVT', 'IMT',
    '4WD', '2WD', 'AWD', 'RWD', '4X4', '4X2',
    'EV', 'RS', 'GT', 'GTI', 'GTS', 'GTX',
    'DLX', 'GLX', 'SLX', 'ELX', 'GL', 'GLS',
    'AMG', 'M',
    // BMW/Audi
    'TFSI', 'TSI',
]);

// Word trims - Title Case
const TITLE_CASE_WORDS = new Set([
    // Maruti Greek
    'Sigma', 'Delta', 'Zeta', 'Alpha', 'Omega', 'Tour',
    // Hyundai
    'Era', 'Magna', 'Sportz', 'Asta', 'Elite', 'Prestige',
    // Tata
    'Creative', 'Fearless', 'Accomplished', 'Empowered', 'Pure', 'Adventure',
    // VW/Skoda
    'Comfortline', 'Highline', 'Trendline', 'Topline',
    'Active', 'Ambition', 'Style', 'Elegance', 'Sportline',
    // Kia
    'Line',
    // Toyota
    'Legender',
    // MG
    'Smart', 'Sharp', 'Savvy',
    // Jeep
    'Sport', 'Longitude', 'Limited', 'Trailhawk',
    // Mercedes
    'Progressive', 'Exclusive', 'Maybach',
    // BMW
    'Luxury',
    // Audi
    'Premium', 'Technology',
    // Common
    'Plus', 'Pro', 'Prime', 'Max', 'Lite', 'Base',
    'Dual', 'Tone', 'Dark', 'Edition', 'Limited',
    'Turbo', 'Hybrid', 'Smart',
    'Performance', 'Autobiography',
]);

// Special patterns that need specific formatting
const SPECIAL_PATTERNS = {
    // Hyundai (O) variants
    'SX(O)': 'SX(O)',
    'ASTA(O)': 'Asta(O)',
    // Kia
    'GT LINE': 'GT Line',
    'X-LINE': 'X-Line',
    'HTXPLUS': 'HTX Plus',
    'HTKPLUS': 'HTK Plus',
    // Toyota
    'GR-S': 'GR-S',
    'E-CVT': 'e-CVT',
    // Skoda
    'L&K': 'L&K',
    // Mercedes
    'AMG LINE': 'AMG Line',
    // BMW
    'M SPORT': 'M Sport',
    'M PERFORMANCE': 'M Performance',
    'LUXURY LINE': 'Luxury Line',
    // Common
    'DUAL TONE': 'Dual Tone',
    'DARK EDITION': 'Dark Edition',
};

function properCase(name) {
    let result = name;

    // First, check for special patterns (case-insensitive)
    for (const [pattern, replacement] of Object.entries(SPECIAL_PATTERNS)) {
        const regex = new RegExp(pattern.replace(/[()]/g, '\\$&'), 'gi');
        result = result.replace(regex, replacement);
    }

    // Split into words and process each
    const words = result.split(' ');
    const processed = words.map(word => {
        const upper = word.toUpperCase();
        const cleaned = upper.replace(/[^A-Z0-9]/g, '');

        // Check if it's a short code (all caps)
        if (UPPERCASE_CODES.has(cleaned) || UPPERCASE_CODES.has(upper)) {
            return upper;
        }

        // Check if word ends with + (like ZXI+, XZ+)
        if (word.endsWith('+')) {
            const base = word.slice(0, -1).toUpperCase();
            if (UPPERCASE_CODES.has(base)) {
                return base + '+';
            }
        }

        // Check for title case words
        const titleCheck = word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
        if (TITLE_CASE_WORDS.has(titleCheck)) {
            return titleCheck;
        }

        // Short alphanumeric codes (2-3 chars) -> uppercase
        if (/^[A-Za-z0-9]{1,3}$/.test(word)) {
            return upper;
        }

        // Numbers with letters (like 4x4, 200d) -> lowercase/as-is
        if (/^\d+[a-zA-Z]+$/.test(word) || /^[a-zA-Z]+\d+$/.test(word)) {
            return word.toLowerCase();
        }

        // Default: Title Case
        return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
    });

    result = processed.join(' ');

    // Fix specific patterns after processing
    result = result.replace(/Gt Line/g, 'GT Line');
    result = result.replace(/X-line/g, 'X-Line');
    result = result.replace(/Gr-s/g, 'GR-S');
    result = result.replace(/E-cvt/g, 'e-CVT');
    result = result.replace(/L&k/g, 'L&K');
    result = result.replace(/Amg Line/g, 'AMG Line');
    result = result.replace(/M Sport/gi, 'M Sport');
    result = result.replace(/Sx\(o\)/gi, 'SX(O)');
    result = result.replace(/Asta\(o\)/gi, 'Asta(O)');
    result = result.replace(/xdrive/gi, 'xDrive');
    result = result.replace(/quattro/gi, 'quattro');

    return result.trim();
}

let changedCount = 0;

data.makes.forEach(make => {
    make.models.forEach(model => {
        if (!model.variants) return;

        Object.keys(model.variants).forEach(fuelType => {
            model.variants[fuelType].forEach(variant => {
                const original = variant.name;
                const fixed = properCase(original);

                if (original !== fixed) {
                    changedCount++;
                    // console.log(`  ${original} -> ${fixed}`);
                }

                variant.name = fixed;
            });
        });
    });
});

data.version = "5.5";
data.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log('✅ Proper casing applied!\n');
console.log(`   Changed: ${changedCount} variant names`);

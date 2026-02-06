/**
 * Simplify transmission to just Manual or Automatic
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

// Map all transmission types
const TRANSMISSION_MAP = {
    // Manual types
    'manual': 'Manual',
    'mt': 'Manual',
    'imt': 'Manual',      // Intelligent Manual (clutchless but still manual)

    // Automatic types
    'automatic': 'Automatic',
    'at': 'Automatic',
    'amt': 'Automatic',   // Automated Manual
    'cvt': 'Automatic',   // Continuously Variable
    'dct': 'Automatic',   // Dual Clutch
    'dsg': 'Automatic',   // Direct Shift Gearbox
    'ivt': 'Automatic',   // Intelligent Variable
    'ecvt': 'Automatic',  // Electronic CVT
    'e-cvt': 'Automatic',
};

let changedCount = 0;

data.makes.forEach(make => {
    make.models.forEach(model => {
        if (!model.variants) return;

        Object.keys(model.variants).forEach(fuelType => {
            model.variants[fuelType].forEach(variant => {
                const original = variant.transmission;
                const lower = original?.toLowerCase();

                if (lower && TRANSMISSION_MAP[lower]) {
                    const mapped = TRANSMISSION_MAP[lower];
                    if (original !== mapped) {
                        changedCount++;
                        variant.transmission = mapped;
                    }
                }
            });
        });
    });
});

data.version = "5.8";
data.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log('✅ Transmission simplified!\n');
console.log(`   Changed: ${changedCount} entries`);
console.log('   Now only: Manual / Automatic');

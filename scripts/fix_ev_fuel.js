/**
 * Fix EV fuel types - EVs should have "electric" not "petrol"
 */

const fs = require('fs');
const data = require('../AutoLedger/Resources/IndianVehicleData.json');

// Patterns that indicate electric vehicles
const EV_PATTERNS = [
    /\bEV\b/i,
    /\bElectric\b/i,
    /\be-tron\b/i,
    /\bIONIQ\b/i,
    /\bEQ[A-Z]/,      // Mercedes EQA, EQB, EQS, etc.
    /\bComet\b/i,     // MG Comet EV
    /\bWindsor\b/i,   // MG Windsor EV
    /\bSpectre\b/i,   // Rolls-Royce Spectre
    /\bXEV\b/i,       // Mahindra XEV
    /\bBE 6\b/i,      // Mahindra BE 6
    /\bi4\b/,         // BMW i4
    /\bi5\b/,         // BMW i5
    /\bi7\b/,         // BMW i7
    /\biX\b/,         // BMW iX, iX1
    /\bEC40\b/i,      // Volvo EC40
    /\bEX30\b/i,      // Volvo EX30
    /\bEX40\b/i,      // Volvo EX40
    /\bAtto\b/i,      // BYD Atto 3
    /\bSeal\b/i,      // BYD Seal
    /\bEmax\b/i,      // BYD Emax
    /\bEC3\b/i,       // Citroen EC3
    /\bCooper SE\b/i, // Mini Cooper SE
    /\bTaycan\b/i,    // Porsche Taycan
];

let fixedCount = 0;

data.makes.forEach(make => {
    make.models.forEach(model => {
        const isEV = EV_PATTERNS.some(pattern => pattern.test(model.name));

        if (isEV) {
            // Check if already has electric
            if (!model.fuelTypes.includes('electric')) {
                // Replace petrol with electric, or add electric
                model.fuelTypes = ['electric'];
                fixedCount++;
                console.log(`  Fixed: ${make.name} ${model.name}`);
            }
        }

        // Also fix models with battery but no electric fuel type
        if (model.batteryKWh && !model.fuelTypes.includes('electric') && !model.fuelTypes.includes('hybrid')) {
            model.fuelTypes = ['electric'];
            fixedCount++;
            console.log(`  Fixed (has battery): ${make.name} ${model.name}`);
        }
    });
});

data.version = "6.2";
data.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(
    '../AutoLedger/Resources/IndianVehicleData.json',
    JSON.stringify(data, null, 2)
);

console.log(`\n✅ Fixed ${fixedCount} EV fuel types`);

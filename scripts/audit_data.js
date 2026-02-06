/**
 * AutoLedger Data Audit Script
 */

const vehicleData = require('../AutoLedger/Resources/IndianVehicleDataV2.json');
const tankData = require('../AutoLedger/Resources/TankCapacityData.json');
const transmissionData = require('../AutoLedger/Resources/TransmissionData.json');

console.log("=".repeat(60));
console.log("AUTOLEDGER DATA AUDIT REPORT");
console.log("Generated:", new Date().toISOString());
console.log("=".repeat(60));

console.log("\n📊 VEHICLE DATA (IndianVehicleDataV2.json)");
console.log("-".repeat(40));
console.log("Version:", vehicleData.version);
console.log("Last Updated:", vehicleData.lastUpdated);
console.log("Sources:", vehicleData.sources.join(", "));
console.log("Total Makes:", vehicleData.makes.length);

let totalModels = 0;
let totalVariants = 0;
let activeModels = 0;
let discontinuedModels = 0;
let fuelTypeStats = { petrol: 0, diesel: 0, cng: 0, electric: 0, hybrid: 0 };

vehicleData.makes.forEach(make => {
    make.models.forEach(model => {
        totalModels++;
        if (model.discontinued) discontinuedModels++;
        else activeModels++;

        if (model.variants) {
            Object.entries(model.variants).forEach(([fuel, variants]) => {
                totalVariants += variants.length;
                if (fuelTypeStats[fuel] !== undefined) fuelTypeStats[fuel] += variants.length;
            });
        }
    });
});

console.log("Total Models:", totalModels);
console.log("Active Models:", activeModels);
console.log("Discontinued Models:", discontinuedModels);
console.log("Total Variants:", totalVariants);
console.log("\nVariants by Fuel Type:");
Object.entries(fuelTypeStats).forEach(([fuel, count]) => {
    if (count > 0) console.log("  " + fuel + ":", count);
});

console.log("\n📦 MAKES BREAKDOWN");
console.log("-".repeat(40));
vehicleData.makes.forEach(make => {
    const models = make.models.length;
    const variants = make.models.reduce((sum, m) => {
        if (!m.variants) return sum;
        return sum + Object.values(m.variants).flat().length;
    }, 0);
    console.log(make.name.padEnd(20) + models + " models, " + variants + " variants");
});

console.log("\n⛽ TANK CAPACITY DATA (TankCapacityData.json)");
console.log("-".repeat(40));
console.log("Version:", tankData.version);
console.log("Total Entries:", Object.keys(tankData.data).length);

let tankCount = 0;
let batteryCount = 0;
let kaggleCount = 0;
Object.values(tankData.data).forEach(entry => {
    if (entry.tankL) tankCount++;
    if (entry.batteryKWh) batteryCount++;
    if (entry.source === "kaggle") kaggleCount++;
});
console.log("Fuel Tank entries:", tankCount);
console.log("Battery (EV) entries:", batteryCount);
console.log("From Kaggle source:", kaggleCount);

console.log("\n🔧 TRANSMISSION DATA (TransmissionData.json)");
console.log("-".repeat(40));
console.log("Version:", transmissionData.version);
console.log("Total Entries:", Object.keys(transmissionData.data).length);
console.log("Transmission Types:", transmissionData.types.join(", "));

let transStats = {};
Object.values(transmissionData.data).forEach(type => {
    transStats[type] = (transStats[type] || 0) + 1;
});
console.log("\nTransmission Distribution:");
Object.entries(transStats).sort((a,b) => b[1] - a[1]).forEach(([type, count]) => {
    const pct = (count / Object.keys(transmissionData.data).length * 100).toFixed(1);
    console.log("  " + type.padEnd(12) + count + " (" + pct + "%)");
});

console.log("\n" + "=".repeat(60));
console.log("DATA FILES LOCATION: ~/Desktop/AutoLedgerData/");
console.log("=".repeat(60));

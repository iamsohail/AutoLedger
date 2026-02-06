const fs = require("fs");
const data = require("../AutoLedger/Resources/IndianVehicleData.json");

let csv = "Make,Model,Fuel Types,Transmission,Tank (L),Battery (kWh),Discontinued\n";

let rowCount = 0;

data.makes.forEach(make => {
    make.models.forEach(model => {
        // Use "/" as separator for fuel types (not comma)
        const fuelTypes = model.fuelTypes ? model.fuelTypes.join("/") : "";
        const transmission = model.transmission || "";
        const tankL = model.tankL || "";
        const batteryKWh = model.batteryKWh || "";
        const discontinued = model.discontinued ? "Yes" : "No";

        // Escape commas in names
        const makeName = make.name.includes(",") ? `"${make.name}"` : make.name;
        const modelName = model.name.includes(",") ? `"${model.name}"` : model.name;

        csv += `${makeName},${modelName},${fuelTypes},${transmission},${tankL},${batteryKWh},${discontinued}\n`;
        rowCount++;
    });
});

fs.writeFileSync("/Users/sohail/Desktop/AutoLedgerData/IndianVehicleData.csv", csv);
console.log("✅ CSV exported successfully!");
console.log(`   Rows: ${rowCount}`);
console.log("   File: ~/Desktop/AutoLedgerData/IndianVehicleData.csv");

/**
 * Merge Kaggle Indian Cars Dataset
 *
 * Merges variant and tank capacity data from Kaggle dataset
 * with the scraped CarWale/CarDekho data.
 *
 * Usage: node merge_kaggle_data.js
 */

const fs = require('fs');
const path = require('path');

// Parse CSV line handling quoted fields
function parseCSVLine(line) {
    const values = [];
    let current = '';
    let inQuotes = false;

    for (const char of line) {
        if (char === '"') {
            inQuotes = !inQuotes;
        } else if (char === ',' && !inQuotes) {
            values.push(current.trim());
            current = '';
        } else {
            current += char;
        }
    }
    values.push(current.trim());
    return values;
}

// Parse CSV
function parseCSV(content) {
    const lines = content.split('\n');
    const headers = parseCSVLine(lines[0]);
    const records = [];

    for (let i = 1; i < lines.length; i++) {
        if (!lines[i].trim()) continue;

        const values = parseCSVLine(lines[i]);

        const record = {};
        headers.forEach((header, idx) => {
            record[header.trim()] = values[idx] || '';
        });
        records.push(record);
    }

    return records;
}

// Normalize make name
function normalizeMake(make) {
    const mappings = {
        'Maruti Suzuki R': 'Maruti Suzuki',
        'Land Rover Rover': 'Land Rover',
        'Bmw': 'BMW',
        'Mg': 'MG',
        'Icml': 'ICML'
    };
    return mappings[make] || make;
}

// Parse tank capacity
function parseTankCapacity(value) {
    if (!value) return null;
    const match = value.match(/(\d+(?:\.\d+)?)/);
    return match ? parseFloat(match[1]) : null;
}

// Parse fuel type
function normalizeFuelType(fuelType) {
    if (!fuelType) return 'petrol';
    const lower = fuelType.toLowerCase();
    if (lower.includes('diesel')) return 'diesel';
    if (lower.includes('cng')) return 'cng';
    if (lower.includes('electric')) return 'electric';
    if (lower.includes('hybrid')) return 'hybrid';
    return 'petrol';
}

// Normalize transmission type
function normalizeTransmission(transmission) {
    if (!transmission) return null;
    const lower = transmission.toLowerCase().trim();
    if (lower === 'manual') return 'manual';
    if (lower === 'automatic') return 'automatic';
    if (lower === 'amt') return 'amt';
    if (lower === 'cvt') return 'cvt';
    if (lower === 'dct') return 'dct';
    if (lower.includes('auto')) return 'automatic';
    return lower;
}

async function mergeData() {
    console.log('📊 Merging Kaggle Indian Cars Dataset\n');

    // Load Kaggle data
    const csvPath = path.join(__dirname, 'kaggle_data', 'cars_ds_final.csv');
    const csvContent = fs.readFileSync(csvPath, 'utf-8');
    const kaggleRecords = parseCSV(csvContent);

    console.log(`   Loaded ${kaggleRecords.length} records from Kaggle\n`);

    // Load scraped data
    let scrapedData;
    try {
        scrapedData = require('../AutoLedger/Resources/IndianVehicleDataV2.json');
    } catch (e) {
        console.log('   No scraped data found, creating new structure');
        scrapedData = { version: "3.0", makes: [] };
    }

    // Load tank capacity data
    let tankData;
    try {
        tankData = require('../AutoLedger/Resources/TankCapacityData.json');
    } catch (e) {
        tankData = { version: "3.0", data: {} };
    }

    // Load transmission data
    let transmissionData;
    try {
        transmissionData = require('../AutoLedger/Resources/TransmissionData.json');
    } catch (e) {
        transmissionData = { version: "1.0", data: {} };
    }

    // Group Kaggle data by Make -> Model -> Variants
    const kaggleByMake = {};
    for (const record of kaggleRecords) {
        const make = normalizeMake(record.Make);
        const model = record.Model;
        const variant = record.Variant;
        const fuelType = normalizeFuelType(record.Fuel_Type);
        const tankCapacity = parseTankCapacity(record.Fuel_Tank_Capacity);
        const transmission = normalizeTransmission(record.Type);

        if (!make || !model || !variant) continue;

        if (!kaggleByMake[make]) kaggleByMake[make] = {};
        if (!kaggleByMake[make][model]) {
            kaggleByMake[make][model] = {
                variants: {},
                variantTransmissions: {},  // Store transmission per variant
                tankCapacity: null
            };
        }

        // Add variant to fuel type
        if (!kaggleByMake[make][model].variants[fuelType]) {
            kaggleByMake[make][model].variants[fuelType] = [];
        }
        if (!kaggleByMake[make][model].variants[fuelType].includes(variant)) {
            kaggleByMake[make][model].variants[fuelType].push(variant);
        }

        // Store transmission type per variant
        if (transmission) {
            const variantKey = `${fuelType}|${variant}`;
            kaggleByMake[make][model].variantTransmissions[variantKey] = transmission;
        }

        // Store tank capacity (use first non-null value)
        if (tankCapacity && !kaggleByMake[make][model].tankCapacity) {
            kaggleByMake[make][model].tankCapacity = tankCapacity;
        }
    }

    let addedVariants = 0;
    let addedTankCapacities = 0;
    let addedTransmissions = 0;
    let newModels = 0;

    // Merge into scraped data
    for (const [makeName, models] of Object.entries(kaggleByMake)) {
        // Find or create make in scraped data
        let makeData = scrapedData.makes.find(m => m.name === makeName);
        if (!makeData) {
            makeData = { name: makeName, models: [] };
            scrapedData.makes.push(makeData);
            console.log(`   + Added make: ${makeName}`);
        }

        for (const [modelName, kaggleModel] of Object.entries(models)) {
            // Find or create model
            let modelData = makeData.models.find(m => m.name === modelName);
            if (!modelData) {
                modelData = {
                    name: modelName,
                    variants: {},
                    fuelTypes: [],
                    discontinued: true,  // Kaggle data is from 2021, likely discontinued
                    source: 'kaggle'
                };
                makeData.models.push(modelData);
                newModels++;
            }

            // Merge variants
            for (const [fuelType, variants] of Object.entries(kaggleModel.variants)) {
                if (!modelData.variants) modelData.variants = {};
                if (!modelData.variants[fuelType]) {
                    modelData.variants[fuelType] = [];
                }

                for (const variant of variants) {
                    // Check if variant exists (case insensitive)
                    const exists = modelData.variants[fuelType].some(v =>
                        v.toLowerCase().replace(/\s*\[disc\.\]\s*/i, '') === variant.toLowerCase()
                    );

                    if (!exists) {
                        // Mark as from Kaggle (historical)
                        const variantName = modelData.source === 'kaggle' ? variant : `${variant} [Hist.]`;
                        modelData.variants[fuelType].push(variantName);
                        addedVariants++;
                    }
                }

                // Update fuel types
                if (!modelData.fuelTypes.includes(fuelType)) {
                    modelData.fuelTypes.push(fuelType);
                }
            }

            // Add tank capacity if missing
            const tankKey = `${makeName}|${modelName}`;
            if (kaggleModel.tankCapacity && !tankData.data[tankKey]) {
                tankData.data[tankKey] = { tankL: kaggleModel.tankCapacity, source: 'kaggle' };
                addedTankCapacities++;
            }

            // Add transmission data for variants
            for (const [variantKey, transmission] of Object.entries(kaggleModel.variantTransmissions)) {
                const transKey = `${makeName}|${modelName}|${variantKey}`;
                if (!transmissionData.data[transKey]) {
                    transmissionData.data[transKey] = transmission;
                    addedTransmissions++;
                }
            }
        }
    }

    // Update metadata
    scrapedData.version = "3.1";
    scrapedData.lastUpdated = new Date().toISOString().split('T')[0];
    scrapedData.sources = ["CarWale", "CarDekho", "Kaggle"];

    tankData.version = "3.1";
    tankData.lastUpdated = new Date().toISOString().split('T')[0];
    tankData.sources = ["CarWale", "CarDekho", "Kaggle"];

    transmissionData.version = "1.0";
    transmissionData.lastUpdated = new Date().toISOString().split('T')[0];
    transmissionData.sources = ["Kaggle"];
    transmissionData.types = ["manual", "automatic", "amt", "cvt", "dct"];

    // Save merged data
    fs.writeFileSync(
        '../AutoLedger/Resources/IndianVehicleDataV2.json',
        JSON.stringify(scrapedData, null, 2)
    );

    fs.writeFileSync(
        '../AutoLedger/Resources/TankCapacityData.json',
        JSON.stringify(tankData, null, 2)
    );

    fs.writeFileSync(
        '../AutoLedger/Resources/TransmissionData.json',
        JSON.stringify(transmissionData, null, 2)
    );

    console.log(`\n✅ Merge complete!`);
    console.log(`   New models: ${newModels}`);
    console.log(`   Variants added: ${addedVariants}`);
    console.log(`   Tank capacities added: ${addedTankCapacities}`);
    console.log(`   Transmission types added: ${addedTransmissions}`);
    console.log(`\n📁 Saved to:`);
    console.log(`   - IndianVehicleDataV2.json`);
    console.log(`   - TankCapacityData.json`);
    console.log(`   - TransmissionData.json`);
}

mergeData().catch(console.error);

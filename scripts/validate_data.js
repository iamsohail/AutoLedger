#!/usr/bin/env node
/**
 * Vehicle Data Validator
 * Run this to check data quality before/after updates
 *
 * Usage: node validate_data.js [--verbose]
 */

const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, '../AutoLedger/Resources/IndianVehicleData.json');
const VERBOSE = process.argv.includes('--verbose');

// Valid values
const VALID_FUEL_TYPES = ['petrol', 'diesel', 'cng', 'electric', 'hybrid', 'lpg'];
const VALID_TRANSMISSIONS = ['Manual', 'Automatic', 'Both'];

// Known EV models (should have electric fuel type)
const KNOWN_EVS = [
    'Nexon EV', 'Tiago EV', 'Punch EV', 'Curvv EV', 'Tigor EV',
    'EQS', 'EQE', 'EQA', 'EQB', 'EQC',
    'iX', 'i4', 'i5', 'i7', 'iX1', 'iX3',
    'e-tron', 'Q8 e-tron', 'e-tron GT',
    'XC40 Recharge', 'C40 Recharge', 'EX90', 'EX30',
    'Taycan',
    'Kona Electric', 'Ioniq 5', 'Ioniq 6',
    'EV6', 'EV9',
    'ZS EV', 'Comet EV', 'Windsor EV',
    'Atto 3', 'Seal', 'e6',
    'Model 3', 'Model Y', 'Model S', 'Model X'
];

function validate() {
    console.log('🔍 Validating IndianVehicleData.json...\n');

    if (!fs.existsSync(DATA_FILE)) {
        console.error('❌ Data file not found:', DATA_FILE);
        process.exit(1);
    }

    const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
    const errors = [];
    const warnings = [];

    // Basic structure
    if (!data.version) warnings.push('Missing version field');
    if (!data.lastUpdated) warnings.push('Missing lastUpdated field');
    if (!data.makes || !Array.isArray(data.makes)) {
        errors.push('Missing or invalid makes array');
        console.error('❌ Critical: Invalid data structure');
        process.exit(1);
    }

    console.log(`📊 Data version: ${data.version}`);
    console.log(`📅 Last updated: ${data.lastUpdated}`);
    console.log(`🏭 Total makes: ${data.makes.length}\n`);

    let totalModels = 0;
    let evCount = 0;
    let cngCount = 0;
    let dieselCount = 0;
    const fuelTypeStats = {};
    const transmissionStats = { Manual: 0, Automatic: 0, Both: 0 };

    data.makes.forEach(make => {
        // Validate make
        if (!make.name) {
            errors.push('Make missing name');
            return;
        }

        if (!make.models || make.models.length === 0) {
            warnings.push(`${make.name} has no models`);
            return;
        }

        make.models.forEach(model => {
            totalModels++;

            // Validate model name
            if (!model.name) {
                errors.push(`Model in ${make.name} missing name`);
                return;
            }

            // Validate fuel types
            if (!model.fuelTypes || model.fuelTypes.length === 0) {
                errors.push(`${make.name} ${model.name}: missing fuelTypes`);
            } else {
                model.fuelTypes.forEach(ft => {
                    fuelTypeStats[ft] = (fuelTypeStats[ft] || 0) + 1;
                    if (!VALID_FUEL_TYPES.includes(ft.toLowerCase())) {
                        warnings.push(`${make.name} ${model.name}: unknown fuel type "${ft}"`);
                    }
                });

                if (model.fuelTypes.includes('electric')) evCount++;
                if (model.fuelTypes.includes('cng')) cngCount++;
                if (model.fuelTypes.includes('diesel')) dieselCount++;
            }

            // Validate transmission
            if (!model.transmission) {
                warnings.push(`${make.name} ${model.name}: missing transmission`);
            } else if (!VALID_TRANSMISSIONS.includes(model.transmission)) {
                warnings.push(`${make.name} ${model.name}: invalid transmission "${model.transmission}"`);
            } else {
                transmissionStats[model.transmission]++;
            }

            // Check for EVs that might be mislabeled
            const modelLower = model.name.toLowerCase();
            const isKnownEV = KNOWN_EVS.some(ev => modelLower.includes(ev.toLowerCase()));

            // Check for " EV" suffix (space before EV to avoid Evoque, Evo false positives)
            const hasEVSuffix = modelLower.endsWith(' ev') || modelLower.includes(' ev ');

            if ((isKnownEV || hasEVSuffix) && !model.fuelTypes?.includes('electric')) {
                warnings.push(`${make.name} ${model.name}: Looks like an EV but fuel type is [${model.fuelTypes?.join(', ')}]`);
            }

            // Check EV has battery capacity
            if (model.fuelTypes?.includes('electric') && !model.batteryKWh) {
                if (VERBOSE) warnings.push(`${make.name} ${model.name}: EV missing batteryKWh`);
            }

            // Check non-EV has tank capacity
            if (!model.fuelTypes?.includes('electric') && !model.tankL) {
                if (VERBOSE) warnings.push(`${make.name} ${model.name}: missing tankL`);
            }
        });

        if (VERBOSE) {
            console.log(`  ${make.name}: ${make.models.length} models`);
        }
    });

    console.log(`🚗 Total models: ${totalModels}`);
    console.log(`\n📈 Fuel Type Distribution:`);
    Object.entries(fuelTypeStats).sort((a, b) => b[1] - a[1]).forEach(([type, count]) => {
        console.log(`   ${type}: ${count}`);
    });

    console.log(`\n⚙️ Transmission Distribution:`);
    Object.entries(transmissionStats).forEach(([type, count]) => {
        console.log(`   ${type}: ${count}`);
    });

    console.log(`\n🔋 EVs: ${evCount}`);
    console.log(`⛽ CNG: ${cngCount}`);
    console.log(`🛢️ Diesel: ${dieselCount}`);

    // Report errors and warnings
    if (errors.length > 0) {
        console.log(`\n❌ ERRORS (${errors.length}):`);
        errors.forEach(e => console.log(`   - ${e}`));
    }

    if (warnings.length > 0) {
        console.log(`\n⚠️ WARNINGS (${warnings.length}):`);
        warnings.slice(0, 20).forEach(w => console.log(`   - ${w}`));
        if (warnings.length > 20) {
            console.log(`   ... and ${warnings.length - 20} more`);
        }
    }

    // Final status
    console.log('\n' + '='.repeat(50));
    if (errors.length === 0 && warnings.length === 0) {
        console.log('✅ Data validation PASSED - no issues found');
    } else if (errors.length === 0) {
        console.log(`✅ Data validation PASSED with ${warnings.length} warning(s)`);
    } else {
        console.log(`❌ Data validation FAILED - ${errors.length} error(s), ${warnings.length} warning(s)`);
        process.exit(1);
    }
}

validate();

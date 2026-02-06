/**
 * CarDekho Tank Capacity Scraper
 *
 * Scrapes fuel tank capacity for each model from cardekho.com
 * Tank capacity is usually same across variants of same fuel type.
 *
 * Usage:
 * 1. npm install puppeteer
 * 2. node scrape_tank_capacity.js
 * 3. Output: tank_capacity_data.json
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

const BASE_URL = 'https://www.cardekho.com';

// Load existing vehicle data
const vehicleData = require('../AutoLedger/Resources/IndianVehicleData.json');

// Delay helper
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Convert brand name to URL slug
function brandToSlug(brandName) {
    const slugMap = {
        'Maruti Suzuki': 'maruti-suzuki',
        'Mercedes-Benz': 'mercedes-benz',
        'Land Rover': 'land-rover',
        'Rolls-Royce': 'rolls-royce',
        'Aston Martin': 'aston-martin',
        'Force Motors': 'force',
        'Hindustan Motors': 'hindustan-motors'
    };
    return slugMap[brandName] || brandName.toLowerCase().replace(/\s+/g, '-');
}

// Convert model name to URL slug
function modelToSlug(modelName) {
    return modelName
        .toLowerCase()
        .replace(/\s+/g, '-')
        .replace(/[()]/g, '')
        .replace(/\./g, '-')
        .replace(/--+/g, '-')
        .replace(/-$/, '');
}

// Extract tank capacity from specifications page
async function scrapeTankCapacity(page, brandSlug, modelSlug) {
    const specsUrl = `${BASE_URL}/${brandSlug}/${modelSlug}/specifications`;

    try {
        await page.goto(specsUrl, { waitUntil: 'networkidle2', timeout: 30000 });
        await delay(500);

        // Extract tank capacity and fuel type from specs table
        const specs = await page.evaluate(() => {
            const result = {
                fuelTypes: [],
                tankCapacity: null,
                batteryCapacity: null
            };

            // Look for fuel tank capacity in specs tables
            const allText = document.body.innerText;

            // Find fuel tank capacity (various formats)
            const tankMatch = allText.match(/Fuel Tank Capacity\s*[:\-]?\s*(\d+(?:\.\d+)?)\s*(?:litres?|L|ltr)/i);
            if (tankMatch) {
                result.tankCapacity = parseFloat(tankMatch[1]);
            }

            // Alternative: look in table rows
            document.querySelectorAll('tr, .specificationTable tr, [class*="spec"] tr').forEach(row => {
                const text = row.innerText.toLowerCase();
                if (text.includes('fuel tank') && text.includes('capacity')) {
                    const match = text.match(/(\d+(?:\.\d+)?)\s*(?:litres?|l|ltr)/i);
                    if (match && !result.tankCapacity) {
                        result.tankCapacity = parseFloat(match[1]);
                    }
                }
                // Battery capacity for EVs
                if (text.includes('battery capacity') && !text.includes('auxiliary')) {
                    const match = text.match(/(\d+(?:\.\d+)?)\s*(?:kwh|kw)/i);
                    if (match) {
                        result.batteryCapacity = parseFloat(match[1]);
                    }
                }
            });

            // Look in div/span elements too
            document.querySelectorAll('div, span, td').forEach(el => {
                const text = el.innerText;
                if (text.match(/fuel tank capacity/i)) {
                    const parent = el.closest('tr, .row, [class*="spec"]');
                    if (parent) {
                        const match = parent.innerText.match(/(\d+(?:\.\d+)?)\s*(?:litres?|l|ltr)/i);
                        if (match && !result.tankCapacity) {
                            result.tankCapacity = parseFloat(match[1]);
                        }
                    }
                }
            });

            // Determine fuel type from page
            const fuelTypeMatch = allText.match(/Fuel Type\s*[:\-]?\s*(Petrol|Diesel|Electric|CNG|Hybrid|Plug-in Hybrid)/i);
            if (fuelTypeMatch) {
                result.fuelTypes.push(fuelTypeMatch[1].toLowerCase());
            }

            // Check for multiple fuel variants
            if (allText.toLowerCase().includes('petrol')) result.fuelTypes.push('petrol');
            if (allText.toLowerCase().includes('diesel')) result.fuelTypes.push('diesel');
            if (allText.toLowerCase().includes('electric') || allText.toLowerCase().includes('ev')) result.fuelTypes.push('electric');
            if (allText.toLowerCase().includes('cng')) result.fuelTypes.push('cng');

            result.fuelTypes = [...new Set(result.fuelTypes)];

            return result;
        });

        return specs;
    } catch (error) {
        return null;
    }
}

// Try alternative URL patterns
async function tryAlternativeUrls(page, brandSlug, modelName) {
    const variations = [
        modelToSlug(modelName),
        modelToSlug(modelName.replace(/\s*EV$/i, '-ev')),
        modelToSlug(modelName.replace(/\s*Electric$/i, '-electric')),
        modelToSlug(modelName.replace(/\s+/g, '')),
        modelToSlug(modelName.split(' ')[0]) // First word only
    ];

    for (const slug of [...new Set(variations)]) {
        const specs = await scrapeTankCapacity(page, brandSlug, slug);
        if (specs && (specs.tankCapacity || specs.batteryCapacity)) {
            return { ...specs, slug };
        }
    }
    return null;
}

async function scrapeAllTankCapacities() {
    console.log('🛢️  Starting Tank Capacity Scraper...\n');

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

    const tankData = {};
    let successCount = 0;
    let failCount = 0;

    for (const make of vehicleData.makes) {
        const brandSlug = brandToSlug(make.name);
        console.log(`\n📦 ${make.name} (${make.models.length} models)`);

        tankData[make.id] = {
            name: make.name,
            models: {}
        };

        for (const model of make.models) {
            process.stdout.write(`   ${model}... `);

            const specs = await tryAlternativeUrls(page, brandSlug, model);

            if (specs && (specs.tankCapacity || specs.batteryCapacity)) {
                tankData[make.id].models[model] = {
                    tankCapacity: specs.tankCapacity || null,
                    batteryCapacity: specs.batteryCapacity || null,
                    fuelTypes: specs.fuelTypes
                };
                console.log(`✓ ${specs.tankCapacity ? specs.tankCapacity + 'L' : specs.batteryCapacity + 'kWh'}`);
                successCount++;
            } else {
                console.log('✗ Not found');
                failCount++;
            }

            // Rate limiting
            await delay(300 + Math.random() * 200);
        }
    }

    await browser.close();

    // Save raw data
    fs.writeFileSync('./tank_capacity_raw.json', JSON.stringify(tankData, null, 2));
    console.log('\n✅ Raw data saved to tank_capacity_raw.json');

    // Create simplified format for the app
    const simplifiedData = {};
    for (const [brandId, brandData] of Object.entries(tankData)) {
        for (const [model, specs] of Object.entries(brandData.models)) {
            const key = `${brandData.name}|${model}`;
            simplifiedData[key] = {
                tankCapacity: specs.tankCapacity,
                batteryCapacity: specs.batteryCapacity
            };
        }
    }

    fs.writeFileSync('./tank_capacity_data.json', JSON.stringify(simplifiedData, null, 2));
    console.log('✅ Simplified data saved to tank_capacity_data.json');

    // Summary
    console.log('\n📊 Summary:');
    console.log(`   Success: ${successCount} models`);
    console.log(`   Failed: ${failCount} models`);
    console.log(`   Success rate: ${((successCount / (successCount + failCount)) * 100).toFixed(1)}%`);

    return tankData;
}

// Run
scrapeAllTankCapacities().catch(console.error);

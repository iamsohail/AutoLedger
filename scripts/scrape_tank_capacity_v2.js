/**
 * CarDekho Tank Capacity Scraper v2
 *
 * Uses the variant details pages which have more reliable data structure.
 * Falls back to embedded JSON-LD or structured data.
 *
 * Usage: node scrape_tank_capacity_v2.js
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

const BASE_URL = 'https://www.cardekho.com';

// Load existing vehicle data
const vehicleData = require('../AutoLedger/Resources/IndianVehicleData.json');

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Brand name to URL slug mapping
const BRAND_SLUGS = {
    'Maruti Suzuki': 'maruti-suzuki',
    'Mercedes-Benz': 'mercedes-benz',
    'Land Rover': 'land-rover',
    'Rolls-Royce': 'rolls-royce',
    'Aston Martin': 'aston-martin',
    'Force Motors': 'force',
    'Hindustan Motors': 'hindustan-motors'
};

function brandToSlug(brandName) {
    return BRAND_SLUGS[brandName] || brandName.toLowerCase().replace(/\s+/g, '-');
}

function modelToSlug(modelName) {
    return modelName
        .toLowerCase()
        .replace(/[()]/g, '')
        .replace(/\s+/g, '-')
        .replace(/\./g, '-')
        .replace(/--+/g, '-')
        .replace(/^-|-$/g, '');
}

async function scrapeTankFromVariantsPage(page, brandSlug, modelSlug) {
    // Try the main model page first (has variant links with specs)
    const modelUrl = `${BASE_URL}/${brandSlug}/${modelSlug}`;

    try {
        const response = await page.goto(modelUrl, {
            waitUntil: 'domcontentloaded',
            timeout: 20000
        });

        if (!response || response.status() === 404) {
            return null;
        }

        await delay(1000);

        // Extract data using multiple methods
        const data = await page.evaluate(() => {
            const result = {
                tankCapacity: null,
                batteryCapacity: null,
                fuelTypes: new Set()
            };

            // Method 1: Look for JSON-LD structured data
            document.querySelectorAll('script[type="application/ld+json"]').forEach(script => {
                try {
                    const json = JSON.parse(script.textContent);
                    if (json.fuelType) {
                        result.fuelTypes.add(json.fuelType.toLowerCase());
                    }
                    if (json.fuelCapacity) {
                        const cap = parseFloat(json.fuelCapacity);
                        if (cap > 0) result.tankCapacity = cap;
                    }
                } catch (e) {}
            });

            // Method 2: Look for spec items in the page
            const specPatterns = [
                /fuel\s*tank\s*(?:capacity)?\s*[:\-]?\s*(\d+(?:\.\d+)?)\s*(?:l(?:itres?)?|ltr)/gi,
                /tank\s*capacity\s*[:\-]?\s*(\d+(?:\.\d+)?)\s*(?:l(?:itres?)?|ltr)/gi,
                /(\d+(?:\.\d+)?)\s*(?:l(?:itres?)?|ltr)\s*(?:fuel)?\s*tank/gi
            ];

            const pageText = document.body.innerText;

            for (const pattern of specPatterns) {
                const matches = [...pageText.matchAll(pattern)];
                for (const match of matches) {
                    const val = parseFloat(match[1]);
                    if (val >= 20 && val <= 150) { // Reasonable tank size
                        result.tankCapacity = val;
                        break;
                    }
                }
                if (result.tankCapacity) break;
            }

            // Method 3: Battery capacity for EVs
            const batteryPattern = /battery\s*(?:capacity)?\s*[:\-]?\s*(\d+(?:\.\d+)?)\s*kwh/gi;
            const batteryMatches = [...pageText.matchAll(batteryPattern)];
            for (const match of batteryMatches) {
                const val = parseFloat(match[1]);
                if (val >= 10 && val <= 200) {
                    result.batteryCapacity = val;
                    break;
                }
            }

            // Method 4: Detect fuel types from page content
            const textLower = pageText.toLowerCase();
            if (textLower.includes('petrol')) result.fuelTypes.add('petrol');
            if (textLower.includes('diesel')) result.fuelTypes.add('diesel');
            if (textLower.includes('electric') && !textLower.includes('electric seats')) {
                result.fuelTypes.add('electric');
            }
            if (textLower.includes(' cng')) result.fuelTypes.add('cng');

            return {
                tankCapacity: result.tankCapacity,
                batteryCapacity: result.batteryCapacity,
                fuelTypes: Array.from(result.fuelTypes)
            };
        });

        // If no tank found on main page, try specs page
        if (!data.tankCapacity && !data.batteryCapacity) {
            const specsUrl = `${BASE_URL}/${brandSlug}/${modelSlug}/specs`;
            try {
                await page.goto(specsUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
                await delay(800);

                const specsData = await page.evaluate(() => {
                    const pageText = document.body.innerText;
                    let tank = null;
                    let battery = null;

                    const tankMatch = pageText.match(/fuel\s*tank[^0-9]*(\d+(?:\.\d+)?)\s*l/i);
                    if (tankMatch) tank = parseFloat(tankMatch[1]);

                    const battMatch = pageText.match(/battery[^0-9]*(\d+(?:\.\d+)?)\s*kwh/i);
                    if (battMatch) battery = parseFloat(battMatch[1]);

                    return { tankCapacity: tank, batteryCapacity: battery };
                });

                if (specsData.tankCapacity) data.tankCapacity = specsData.tankCapacity;
                if (specsData.batteryCapacity) data.batteryCapacity = specsData.batteryCapacity;
            } catch (e) {}
        }

        return data;
    } catch (error) {
        return null;
    }
}

async function scrapeAllTankCapacities() {
    console.log('🛢️  Tank Capacity Scraper v2\n');
    console.log('This will take ~15-20 minutes for 500+ models.\n');

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36');

    // Block images and unnecessary resources for speed
    await page.setRequestInterception(true);
    page.on('request', (req) => {
        if (['image', 'stylesheet', 'font', 'media'].includes(req.resourceType())) {
            req.abort();
        } else {
            req.continue();
        }
    });

    const results = {};
    let found = 0;
    let notFound = 0;

    // Process popular brands first
    const priorityBrands = [
        'Maruti Suzuki', 'Hyundai', 'Tata', 'Mahindra', 'Kia', 'Honda', 'Toyota',
        'MG', 'Volkswagen', 'Skoda', 'Renault', 'Nissan', 'Jeep', 'Citroen'
    ];

    const sortedMakes = [...vehicleData.makes].sort((a, b) => {
        const aIdx = priorityBrands.indexOf(a.name);
        const bIdx = priorityBrands.indexOf(b.name);
        if (aIdx === -1 && bIdx === -1) return 0;
        if (aIdx === -1) return 1;
        if (bIdx === -1) return -1;
        return aIdx - bIdx;
    });

    for (const make of sortedMakes) {
        const brandSlug = brandToSlug(make.name);
        console.log(`\n📦 ${make.name} (${make.models.length} models)`);

        results[make.id] = {
            name: make.name,
            models: {}
        };

        for (const model of make.models) {
            const modelSlug = modelToSlug(model);
            process.stdout.write(`   ${model}... `);

            const data = await scrapeTankFromVariantsPage(page, brandSlug, modelSlug);

            if (data && (data.tankCapacity || data.batteryCapacity)) {
                results[make.id].models[model] = {
                    tankCapacityL: data.tankCapacity,
                    batteryCapacityKWh: data.batteryCapacity,
                    fuelTypes: data.fuelTypes
                };

                const display = data.tankCapacity
                    ? `✓ ${data.tankCapacity}L`
                    : `✓ ${data.batteryCapacity}kWh (EV)`;
                console.log(display);
                found++;
            } else {
                console.log('✗');
                notFound++;
            }

            await delay(200 + Math.random() * 300);
        }
    }

    await browser.close();

    // Save detailed results
    fs.writeFileSync('./tank_capacity_detailed.json', JSON.stringify(results, null, 2));
    console.log('\n✅ Detailed data saved to tank_capacity_detailed.json');

    // Create flat lookup for the app
    const lookup = {};
    for (const [brandId, brandData] of Object.entries(results)) {
        for (const [model, specs] of Object.entries(brandData.models)) {
            const key = `${brandData.name}|${model}`;
            lookup[key] = {
                tankCapacityL: specs.tankCapacityL,
                batteryCapacityKWh: specs.batteryCapacityKWh
            };
        }
    }

    fs.writeFileSync('./tank_capacity_lookup.json', JSON.stringify(lookup, null, 2));
    console.log('✅ Lookup table saved to tank_capacity_lookup.json');

    // Summary
    const rate = ((found / (found + notFound)) * 100).toFixed(1);
    console.log(`\n📊 Summary:`);
    console.log(`   Found: ${found} models`);
    console.log(`   Not found: ${notFound} models`);
    console.log(`   Success rate: ${rate}%`);

    // Show sample data
    console.log('\n📋 Sample data:');
    let samples = 0;
    outer:
    for (const [brandId, brandData] of Object.entries(results)) {
        for (const [model, specs] of Object.entries(brandData.models)) {
            if (specs.tankCapacityL) {
                console.log(`   ${brandData.name} ${model}: ${specs.tankCapacityL}L`);
                samples++;
                if (samples >= 10) break outer;
            }
        }
    }

    return results;
}

scrapeAllTankCapacities().catch(console.error);

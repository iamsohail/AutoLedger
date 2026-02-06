/**
 * CarWale Full Data Scraper
 *
 * Scrapes models, variants (from price page), and tank capacity.
 * Uses price-in-delhi page which lists all variants.
 *
 * Usage: node scrape_carwale_full.js
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

const BASE_URL = 'https://www.carwale.com';

// Load existing vehicle data for the model list
const vehicleData = require('../AutoLedger/Resources/IndianVehicleData.json');

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Brand name to CarWale URL slug
const BRAND_SLUGS = {
    'Maruti Suzuki': 'maruti-suzuki',
    'Mercedes-Benz': 'mercedes-benz',
    'Land Rover': 'land-rover',
    'Rolls-Royce': 'rolls-royce',
    'Aston Martin': 'aston-martin',
    'Force Motors': 'force',
    'Hindustan Motors': 'hindustan-motors',
    'BMW': 'bmw',
    'MG': 'mg',
    'BYD': 'byd'
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

async function scrapeModelData(page, brandSlug, modelSlug, brandName, modelName) {
    const result = {
        variants: [],
        tankCapacity: null,
        batteryCapacity: null,
        fuelTypes: new Set()
    };

    // First get tank capacity from main page
    const modelUrl = `${BASE_URL}/${brandSlug}-cars/${modelSlug}/`;

    try {
        const response = await page.goto(modelUrl, {
            waitUntil: 'domcontentloaded',
            timeout: 20000
        });

        if (!response || response.status() === 404) {
            return null;
        }

        await delay(1000);

        // Get tank/battery capacity from JSON-LD
        const mainPageData = await page.evaluate(() => {
            let tankCapacity = null;
            let batteryCapacity = null;

            // Helper to find a key recursively in an object
            function findKey(obj, key) {
                if (!obj || typeof obj !== 'object') return null;
                if (obj[key] !== undefined) return obj[key];
                for (const k of Object.keys(obj)) {
                    const result = findKey(obj[k], key);
                    if (result) return result;
                }
                return null;
            }

            const scripts = document.querySelectorAll('script[type="application/ld+json"]');
            for (const script of scripts) {
                try {
                    const json = JSON.parse(script.textContent);
                    // Search recursively for fuelCapacity (it's nested in @graph)
                    const fuelCap = findKey(json, 'fuelCapacity');
                    if (fuelCap && fuelCap.value) {
                        tankCapacity = parseFloat(fuelCap.value);
                    }
                } catch (e) {}
            }

            // Check for battery capacity in page text (EVs)
            const pageText = document.body.innerText;
            const batteryMatch = pageText.match(/battery\s*(?:capacity)?[:\s]*(\d+(?:\.\d+)?)\s*kwh/i);
            if (batteryMatch) {
                batteryCapacity = parseFloat(batteryMatch[1]);
            }

            return { tankCapacity, batteryCapacity };
        });

        result.tankCapacity = mainPageData.tankCapacity;
        result.batteryCapacity = mainPageData.batteryCapacity;

    } catch (e) {
        // Main page failed
    }

    // Now get variants from price page
    const priceUrl = `${BASE_URL}/${brandSlug}-cars/${modelSlug}/price-in-delhi/`;

    try {
        await page.goto(priceUrl, {
            waitUntil: 'domcontentloaded',
            timeout: 20000
        });

        await delay(1500);

        const variantsData = await page.evaluate((modelName) => {
            const variants = [];
            const fuelTypes = [];

            // Method 1: Look for variant listings in the page
            // CarWale lists variants with format: "Model VariantName - Rs. X.XX Lakh"
            const pageText = document.body.innerText;
            const lines = pageText.split('\n');

            const modelNameLower = modelName.toLowerCase();

            for (const line of lines) {
                const lineLower = line.toLowerCase();

                // Skip lines that don't contain the model name
                if (!lineLower.includes(modelNameLower)) continue;

                // Pattern: "Swift LXi" or "Swift VXi CNG" etc.
                // Extract what comes after the model name
                const modelIdx = lineLower.indexOf(modelNameLower);
                if (modelIdx === -1) continue;

                const afterModel = line.substring(modelIdx + modelName.length).trim();

                // Clean up the variant name - stop at price or specs
                let variantName = afterModel
                    .split(/Rs\.|₹|\d+\.\d+\s*(?:Lakh|kmpl|bhp|cc)/i)[0]
                    .trim();

                // Clean up common suffixes
                variantName = variantName
                    .replace(/^[-–—\s]+/, '')
                    .replace(/[-–—\s]+$/, '')
                    .replace(/\s+/g, ' ')
                    .trim();

                // Skip if too short or too long
                if (variantName.length < 2 || variantName.length > 50) continue;

                // Skip if it's just numbers or common words
                if (/^[\d\s.]+$/.test(variantName)) continue;
                if (['price', 'ex-showroom', 'on road', 'starting', 'onwards'].some(w => variantName.toLowerCase().includes(w))) continue;

                // Detect fuel type
                let fuelType = 'petrol'; // default
                const variantLower = variantName.toLowerCase();
                if (variantLower.includes('diesel')) {
                    fuelType = 'diesel';
                    variantName = variantName.replace(/\s*diesel\s*/gi, ' ').trim();
                } else if (variantLower.includes('cng')) {
                    fuelType = 'cng';
                } else if (variantLower.includes('electric') || variantLower.includes(' ev') || variantLower.endsWith(' ev')) {
                    fuelType = 'electric';
                } else if (variantLower.includes('hybrid')) {
                    fuelType = 'hybrid';
                }

                if (!fuelTypes.includes(fuelType)) {
                    fuelTypes.push(fuelType);
                }

                // Only add if not duplicate
                const existing = variants.find(v => v.name.toLowerCase() === variantName.toLowerCase() && v.fuelType === fuelType);
                if (!existing && variantName.length > 0) {
                    variants.push({ name: variantName, fuelType });
                }
            }

            // Method 2: Also look for structured variant elements
            const variantElements = document.querySelectorAll('[class*="variant-name"], [class*="variantName"], a[href*="price-in-delhi"]');
            variantElements.forEach(el => {
                const text = el.textContent?.trim();
                if (text && text.length > 2 && text.length < 50) {
                    // Extract variant name (remove model name prefix if present)
                    let variantName = text;
                    if (text.toLowerCase().startsWith(modelNameLower)) {
                        variantName = text.substring(modelName.length).trim();
                    }

                    if (variantName.length > 1 && variantName.length < 40) {
                        // Detect fuel type
                        let fuelType = 'petrol';
                        const vl = variantName.toLowerCase();
                        if (vl.includes('diesel')) fuelType = 'diesel';
                        else if (vl.includes('cng')) fuelType = 'cng';
                        else if (vl.includes('electric') || vl.includes(' ev')) fuelType = 'electric';
                        else if (vl.includes('hybrid')) fuelType = 'hybrid';

                        const existing = variants.find(v => v.name.toLowerCase() === variantName.toLowerCase());
                        if (!existing) {
                            variants.push({ name: variantName, fuelType });
                        }
                    }
                }
            });

            return { variants, fuelTypes };
        }, modelName);

        // Deduplicate and clean variants
        const seenVariants = new Set();
        for (const v of variantsData.variants) {
            const key = `${v.name}|${v.fuelType}`;
            if (!seenVariants.has(key)) {
                seenVariants.add(key);
                result.variants.push(v);
                result.fuelTypes.add(v.fuelType);
            }
        }

        for (const ft of variantsData.fuelTypes) {
            result.fuelTypes.add(ft);
        }

    } catch (e) {
        // Price page failed, variants not available
    }

    result.fuelTypes = Array.from(result.fuelTypes);
    return result;
}

async function scrapeAllData() {
    console.log('🚗 CarWale Full Data Scraper\n');
    console.log('Fetching models, variants, and tank capacity from CarWale...\n');

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36');

    // Block images for faster loading
    await page.setRequestInterception(true);
    page.on('request', (req) => {
        if (['image', 'stylesheet', 'font'].includes(req.resourceType())) {
            req.abort();
        } else {
            req.continue();
        }
    });

    const outputData = {
        version: "2.0",
        lastUpdated: new Date().toISOString().split('T')[0],
        source: "CarWale",
        makes: []
    };

    const tankCapacityData = {
        version: "2.0",
        lastUpdated: new Date().toISOString().split('T')[0],
        source: "CarWale",
        note: "All data scraped from CarWale.com. Tank in litres, battery in kWh.",
        data: {}
    };

    let totalModels = 0;
    let foundModels = 0;
    let totalVariants = 0;
    let tankFound = 0;

    // Priority brands
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

        const makeData = {
            name: make.name,
            models: []
        };

        for (const model of make.models) {
            totalModels++;
            const modelSlug = modelToSlug(model);
            process.stdout.write(`   ${model}... `);

            const data = await scrapeModelData(page, brandSlug, modelSlug, make.name, model);

            if (data) {
                const modelData = {
                    name: model,
                    variants: data.variants,
                    fuelTypes: data.fuelTypes
                };

                makeData.models.push(modelData);
                foundModels++;
                totalVariants += data.variants.length;

                // Store tank capacity
                const key = `${make.name}|${model}`;
                if (data.tankCapacity) {
                    tankCapacityData.data[key] = { tankL: data.tankCapacity };
                    tankFound++;
                } else if (data.batteryCapacity) {
                    tankCapacityData.data[key] = { batteryKWh: data.batteryCapacity };
                    tankFound++;
                }

                const capacityInfo = data.tankCapacity ? `${data.tankCapacity}L` :
                                    data.batteryCapacity ? `${data.batteryCapacity}kWh` : 'no capacity';
                console.log(`✓ ${data.variants.length} variants | ${capacityInfo}`);
            } else {
                makeData.models.push({
                    name: model,
                    variants: [],
                    fuelTypes: []
                });
                console.log('✗ not found');
            }

            await delay(1000 + Math.random() * 500);
        }

        outputData.makes.push(makeData);

        // Save progress periodically
        if (outputData.makes.length % 5 === 0) {
            fs.writeFileSync(
                '../AutoLedger/Resources/IndianVehicleDataV2.json',
                JSON.stringify(outputData, null, 2)
            );
            fs.writeFileSync(
                '../AutoLedger/Resources/TankCapacityData.json',
                JSON.stringify(tankCapacityData, null, 2)
            );
        }
    }

    await browser.close();

    // Final save
    fs.writeFileSync(
        '../AutoLedger/Resources/IndianVehicleDataV2.json',
        JSON.stringify(outputData, null, 2)
    );
    fs.writeFileSync(
        '../AutoLedger/Resources/TankCapacityData.json',
        JSON.stringify(tankCapacityData, null, 2)
    );

    console.log('\n✅ Data saved!');
    console.log(`\n📊 Summary:`);
    console.log(`   Total models: ${totalModels}`);
    console.log(`   Found on CarWale: ${foundModels}`);
    console.log(`   Total variants: ${totalVariants}`);
    console.log(`   Tank capacities: ${tankFound}`);
    console.log(`\n📁 Files created:`);
    console.log(`   IndianVehicleDataV2.json`);
    console.log(`   TankCapacityData.json`);
}

scrapeAllData().catch(console.error);

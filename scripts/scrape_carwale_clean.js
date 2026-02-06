/**
 * CarWale Clean Data Scraper
 *
 * Scrapes models, variants grouped by fuel type, and tank capacity.
 * Structure: variants grouped by fuel type to avoid double counting.
 *
 * Usage: node scrape_carwale_clean.js
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

// Clean variant name - remove fuel type suffix and model name prefix
function cleanVariantName(variantText, modelName, fuelType) {
    let name = variantText.trim();

    // Remove model name prefix (case insensitive)
    const modelLower = modelName.toLowerCase();
    const nameLower = name.toLowerCase();
    if (nameLower.startsWith(modelLower)) {
        name = name.substring(modelName.length).trim();
    }

    // Remove fuel type suffixes
    name = name
        .replace(/\s*(petrol|diesel|cng|electric|hybrid)\s*/gi, ' ')
        .replace(/\s+/g, ' ')
        .trim();

    // Remove price info
    name = name.replace(/₹[\d,.\s]*(lakh|cr)?/gi, '').trim();
    name = name.replace(/rs\.?\s*[\d,.\s]*(lakh|cr)?/gi, '').trim();

    // Remove specs
    name = name.replace(/\d+(\.\d+)?\s*(kmpl|bhp|cc|km\/l)/gi, '').trim();

    // Clean up extra dashes/spaces
    name = name.replace(/^[-\s]+|[-\s]+$/g, '').trim();

    return name;
}

// Detect fuel type from text
function detectFuelType(text) {
    const lower = text.toLowerCase();
    if (lower.includes('diesel')) return 'diesel';
    if (lower.includes('cng')) return 'cng';
    if (lower.includes('electric') || lower.includes(' ev') || lower.endsWith('ev')) return 'electric';
    if (lower.includes('hybrid')) return 'hybrid';
    return 'petrol'; // default
}

async function scrapeModelData(page, brandSlug, modelSlug, brandName, modelName) {
    const result = {
        tankCapacity: null,
        batteryCapacity: null,
        isDiscontinued: false,
        modelYear: null,
        variantsByFuel: {}, // { petrol: ["LXi", "VXi"], diesel: ["VDi"], cng: ["VXi CNG"] }
        fuelTypes: []
    };

    // Helper to find a key recursively
    function findKey(obj, key) {
        if (!obj || typeof obj !== 'object') return null;
        if (obj[key] !== undefined) return obj[key];
        for (const k of Object.keys(obj)) {
            const result = findKey(obj[k], key);
            if (result) return result;
        }
        return null;
    }

    // First get tank capacity and model info from main page
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

        const mainPageData = await page.evaluate(() => {
            let tankCapacity = null;
            let batteryCapacity = null;
            let isDiscontinued = false;
            let modelYear = null;

            // Helper to find key recursively
            function findKey(obj, key) {
                if (!obj || typeof obj !== 'object') return null;
                if (obj[key] !== undefined) return obj[key];
                for (const k of Object.keys(obj)) {
                    const result = findKey(obj[k], key);
                    if (result) return result;
                }
                return null;
            }

            // Parse JSON-LD
            const scripts = document.querySelectorAll('script[type="application/ld+json"]');
            for (const script of scripts) {
                try {
                    const json = JSON.parse(script.textContent);
                    const fuelCap = findKey(json, 'fuelCapacity');
                    if (fuelCap && fuelCap.value) {
                        tankCapacity = parseFloat(fuelCap.value);
                    }
                    const modelDate = findKey(json, 'vehicleModelDate');
                    if (modelDate) {
                        modelYear = parseInt(modelDate);
                    }
                } catch (e) {}
            }

            // Check if discontinued
            const pageText = document.body.innerText.toLowerCase();
            if (pageText.includes('discontinued') || pageText.includes('no longer available')) {
                isDiscontinued = true;
            }

            // Check for battery capacity (EVs)
            const batteryMatch = pageText.match(/battery\s*(?:capacity)?[:\s]*(\d+(?:\.\d+)?)\s*kwh/i);
            if (batteryMatch) {
                batteryCapacity = parseFloat(batteryMatch[1]);
            }

            return { tankCapacity, batteryCapacity, isDiscontinued, modelYear };
        });

        result.tankCapacity = mainPageData.tankCapacity;
        result.batteryCapacity = mainPageData.batteryCapacity;
        result.isDiscontinued = mainPageData.isDiscontinued;
        result.modelYear = mainPageData.modelYear;

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
            const variantsByFuel = {};
            const seenVariants = new Set();

            // Look for variant links - they typically have the pattern /model-variant-fueltype/
            const links = document.querySelectorAll('a[href*="-cars/"]');

            links.forEach(link => {
                const href = link.getAttribute('href') || '';
                const text = link.textContent?.trim() || '';

                // Match variant URLs: /brand-cars/model/variant-name-fueltype/
                const urlMatch = href.match(/\/([^\/]+)-(petrol|diesel|cng|electric|hybrid)\/?$/i);
                if (urlMatch) {
                    const variantSlug = urlMatch[1];
                    const fuelType = urlMatch[2].toLowerCase();

                    // Convert slug to name
                    let variantName = variantSlug
                        .split('-')
                        .map(word => {
                            const upper = word.toUpperCase();
                            // Common variant abbreviations
                            if (['LXI', 'VXI', 'ZXI', 'VDI', 'ZDI', 'SX', 'EX', 'GX', 'HX', 'MX', 'TX', 'DX',
                                 'MT', 'AT', 'AMT', 'CVT', 'DCT', 'IMT', 'AGS', 'GT', 'RS', 'SE', 'LE',
                                 'XE', 'XM', 'XZ', 'XT', 'XTA', 'XMA', 'XZA', 'PLUS', 'PRO', 'MAX',
                                 'SIGMA', 'DELTA', 'ZETA', 'ALPHA', 'OMEGA', 'CNG', 'EV', 'AWD', '4WD',
                                 'O', 'S', 'N', 'R', 'T', 'V', 'W', 'X', 'Z'].includes(upper)) {
                                return upper;
                            }
                            return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
                        })
                        .join(' ');

                    // Remove model name from variant if present
                    const modelLower = modelName.toLowerCase();
                    const variantLower = variantName.toLowerCase();
                    if (variantLower.startsWith(modelLower + ' ')) {
                        variantName = variantName.substring(modelName.length).trim();
                    }

                    // Clean up
                    variantName = variantName.trim();
                    if (variantName.length < 2 || variantName.length > 40) return;

                    // Create unique key
                    const key = `${variantName}|${fuelType}`;
                    if (seenVariants.has(key)) return;
                    seenVariants.add(key);

                    // Add to fuel type group
                    if (!variantsByFuel[fuelType]) {
                        variantsByFuel[fuelType] = [];
                    }
                    if (!variantsByFuel[fuelType].includes(variantName)) {
                        variantsByFuel[fuelType].push(variantName);
                    }
                }
            });

            return variantsByFuel;
        }, modelName);

        result.variantsByFuel = variantsData;
        result.fuelTypes = Object.keys(variantsData);

    } catch (e) {
        // Price page failed
    }

    return result;
}

async function scrapeAllData() {
    console.log('🚗 CarWale Clean Data Scraper\n');
    console.log('Fetching models, variants (grouped by fuel), and tank capacity...\n');

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
        note: "All data from CarWale.com. Tank in litres, battery in kWh.",
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
                // Count total variants across fuel types
                let variantCount = 0;
                for (const ft of Object.keys(data.variantsByFuel)) {
                    variantCount += data.variantsByFuel[ft].length;
                }

                const modelData = {
                    name: model,
                    variants: data.variantsByFuel, // { petrol: [...], diesel: [...] }
                    fuelTypes: data.fuelTypes,
                    discontinued: data.isDiscontinued,
                    year: data.modelYear
                };

                makeData.models.push(modelData);
                foundModels++;
                totalVariants += variantCount;

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
                                    data.batteryCapacity ? `${data.batteryCapacity}kWh` : '-';
                const fuelInfo = data.fuelTypes.join('/') || '-';
                const discInfo = data.isDiscontinued ? ' [DISC]' : '';
                console.log(`✓ ${variantCount} variants (${fuelInfo}) | ${capacityInfo}${discInfo}`);
            } else {
                makeData.models.push({
                    name: model,
                    variants: {},
                    fuelTypes: [],
                    discontinued: true,
                    year: null
                });
                console.log('✗ not found');
            }

            await delay(1200 + Math.random() * 500);
        }

        outputData.makes.push(makeData);

        // Save progress periodically
        fs.writeFileSync(
            '../AutoLedger/Resources/IndianVehicleDataV2.json',
            JSON.stringify(outputData, null, 2)
        );
        fs.writeFileSync(
            '../AutoLedger/Resources/TankCapacityData.json',
            JSON.stringify(tankCapacityData, null, 2)
        );
    }

    await browser.close();

    console.log('\n✅ Data saved!');
    console.log(`\n📊 Summary:`);
    console.log(`   Total models: ${totalModels}`);
    console.log(`   Found on CarWale: ${foundModels}`);
    console.log(`   Total variants: ${totalVariants}`);
    console.log(`   Tank capacities: ${tankFound}`);
    console.log(`\n📁 Files created:`);
    console.log(`   IndianVehicleDataV2.json - Models with variants grouped by fuel`);
    console.log(`   TankCapacityData.json - Tank capacities`);
}

scrapeAllData().catch(console.error);

/**
 * CarWale Tank Capacity Scraper
 *
 * Scrapes fuel tank capacity from CarWale variant pages.
 * CarWale has JSON-LD structured data which is easier to parse.
 *
 * Usage: node scrape_carwale_tank.js
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

const BASE_URL = 'https://www.carwale.com';

// Load existing vehicle data
const vehicleData = require('../AutoLedger/Resources/IndianVehicleData.json');

// Force fresh fetch - don't use existing data
const FORCE_REFETCH = process.argv.includes('--force');
let existingTankData = {};
if (!FORCE_REFETCH) {
    try {
        const tankFile = require('../AutoLedger/Resources/TankCapacityData.json');
        existingTankData = tankFile.data || {};
    } catch (e) {
        console.log('No existing tank data found, starting fresh');
    }
} else {
    console.log('⚠️  Force mode: Re-fetching ALL models from CarWale\n');
}

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

async function scrapeTankCapacity(page, brandSlug, modelSlug, brandName, modelName) {
    // First try the main model page to find a variant link
    const modelUrl = `${BASE_URL}/${brandSlug}-cars/${modelSlug}/`;

    try {
        const response = await page.goto(modelUrl, {
            waitUntil: 'domcontentloaded',
            timeout: 20000
        });

        if (!response || response.status() === 404) {
            return null;
        }

        await delay(1500);

        // Try to extract tank capacity from page
        const data = await page.evaluate(() => {
            let tankCapacity = null;
            let batteryCapacity = null;

            // Method 1: Look for JSON-LD structured data
            const scripts = document.querySelectorAll('script[type="application/ld+json"]');
            for (const script of scripts) {
                try {
                    const json = JSON.parse(script.textContent);
                    if (json.fuelCapacity) {
                        const match = json.fuelCapacity.match(/(\d+(?:\.\d+)?)/);
                        if (match) tankCapacity = parseFloat(match[1]);
                    }
                } catch (e) {}
            }

            // Method 2: Look in page text for fuel tank capacity
            if (!tankCapacity) {
                const pageText = document.body.innerText;

                // Pattern for "fuel tank capacity of X is Y litres"
                const patterns = [
                    /fuel tank capacity[^0-9]*(\d+(?:\.\d+)?)\s*(?:litres?|L|ltr)/gi,
                    /tank capacity[^0-9]*(\d+(?:\.\d+)?)\s*(?:litres?|L|ltr)/gi,
                    /(\d+(?:\.\d+)?)\s*(?:litres?|L)\s*(?:fuel)?\s*tank/gi
                ];

                for (const pattern of patterns) {
                    const matches = [...pageText.matchAll(pattern)];
                    for (const match of matches) {
                        const val = parseFloat(match[1]);
                        if (val >= 15 && val <= 150) {
                            tankCapacity = val;
                            break;
                        }
                    }
                    if (tankCapacity) break;
                }
            }

            // Method 3: Look for battery capacity (EVs)
            if (!tankCapacity) {
                const pageText = document.body.innerText;
                const batteryMatch = pageText.match(/battery capacity[^0-9]*(\d+(?:\.\d+)?)\s*kwh/i);
                if (batteryMatch) {
                    batteryCapacity = parseFloat(batteryMatch[1]);
                }
            }

            // Method 4: Find first variant link and get its URL
            let variantUrl = null;
            const variantLinks = document.querySelectorAll('a[href*="/"]');
            for (const link of variantLinks) {
                const href = link.getAttribute('href');
                if (href && href.includes('-cars/') &&
                    (href.includes('petrol') || href.includes('diesel') ||
                     href.includes('lxi') || href.includes('vxi') || href.includes('zxi'))) {
                    variantUrl = href;
                    break;
                }
            }

            return { tankCapacity, batteryCapacity, variantUrl };
        });

        // If we found capacity, return it
        if (data.tankCapacity || data.batteryCapacity) {
            return data;
        }

        // If we found a variant URL, try that page
        if (data.variantUrl) {
            const fullVariantUrl = data.variantUrl.startsWith('http')
                ? data.variantUrl
                : `${BASE_URL}${data.variantUrl}`;

            await page.goto(fullVariantUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
            await delay(1000);

            const variantData = await page.evaluate(() => {
                let tankCapacity = null;
                let batteryCapacity = null;
                const pageText = document.body.innerText;

                const tankMatch = pageText.match(/fuel tank capacity[^0-9]*(\d+(?:\.\d+)?)\s*(?:litres?|L)/i);
                if (tankMatch) tankCapacity = parseFloat(tankMatch[1]);

                const batteryMatch = pageText.match(/battery capacity[^0-9]*(\d+(?:\.\d+)?)\s*kwh/i);
                if (batteryMatch) batteryCapacity = parseFloat(batteryMatch[1]);

                return { tankCapacity, batteryCapacity };
            });

            if (variantData.tankCapacity || variantData.batteryCapacity) {
                return variantData;
            }
        }

        return null;
    } catch (error) {
        return null;
    }
}

async function scrapeAllTankCapacities() {
    console.log('🚗 CarWale Tank Capacity Scraper\n');
    console.log('This will take ~20-30 minutes for 500+ models.\n');

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

    const newData = FORCE_REFETCH ? {} : { ...existingTankData };
    let found = 0;
    let updated = 0;
    let skipped = 0;
    let notFound = 0;

    // Priority brands (most common in India)
    const priorityBrands = [
        'Maruti Suzuki', 'Hyundai', 'Tata', 'Mahindra', 'Kia', 'Honda', 'Toyota',
        'MG', 'Volkswagen', 'Skoda', 'Renault', 'Nissan', 'Jeep', 'Citroen',
        'Ford', 'Chevrolet', 'Fiat'
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

        for (const model of make.models) {
            const key = `${make.name}|${model}`;
            const modelSlug = modelToSlug(model);

            // Skip if we already have data (unless force mode)
            if (!FORCE_REFETCH && existingTankData[key]) {
                process.stdout.write(`   ${model}... ⏭️ exists\n`);
                skipped++;
                continue;
            }

            process.stdout.write(`   ${model}... `);

            const data = await scrapeTankCapacity(page, brandSlug, modelSlug, make.name, model);

            if (data && (data.tankCapacity || data.batteryCapacity)) {
                newData[key] = {};
                if (data.tankCapacity) newData[key].tankL = data.tankCapacity;
                if (data.batteryCapacity) newData[key].batteryKWh = data.batteryCapacity;

                const display = data.tankCapacity
                    ? `✓ ${data.tankCapacity}L`
                    : `✓ ${data.batteryCapacity}kWh`;
                console.log(display);
                found++;
            } else {
                console.log('✗');
                notFound++;
            }

            await delay(500 + Math.random() * 500);
        }
    }

    await browser.close();

    // Save updated data
    const outputData = {
        version: "2.0",
        lastUpdated: new Date().toISOString().split('T')[0],
        source: "CarWale",
        note: "All data scraped directly from CarWale.com. Tank capacity in litres (L) or battery capacity in kWh for EVs.",
        data: newData
    };

    fs.writeFileSync(
        '../AutoLedger/Resources/TankCapacityData.json',
        JSON.stringify(outputData, null, 2)
    );

    console.log('\n✅ Data saved to TankCapacityData.json');
    console.log(`\n📊 Summary:`);
    console.log(`   Found on CarWale: ${found}`);
    if (!FORCE_REFETCH) console.log(`   Skipped (existing): ${skipped}`);
    console.log(`   Not found on CarWale: ${notFound}`);
    console.log(`   Total entries: ${Object.keys(newData).length}`);

    return newData;
}

scrapeAllTankCapacities().catch(console.error);

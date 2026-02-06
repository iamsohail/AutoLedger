/**
 * Comprehensive Vehicle Data Scraper
 *
 * Scrapes from both CarWale and CarDekho for comprehensive data.
 * Merges variants from both sources.
 *
 * Usage: node scrape_comprehensive.js
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

const vehicleData = require('../AutoLedger/Resources/IndianVehicleData.json');

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Brand slugs for CarWale
const CARWALE_BRAND_SLUGS = {
    'Maruti Suzuki': 'maruti-suzuki',
    'Mercedes-Benz': 'mercedes-benz',
    'Land Rover': 'land-rover',
    'Rolls-Royce': 'rolls-royce',
    'Aston Martin': 'aston-martin',
    'Force Motors': 'force',
    'Hindustan Motors': 'hindustan-motors',
    'BMW': 'bmw', 'MG': 'mg', 'BYD': 'byd'
};

// Brand slugs for CarDekho
const CARDEKHO_BRAND_SLUGS = {
    'Maruti Suzuki': 'maruti-suzuki',
    'Mercedes-Benz': 'mercedes-benz',
    'Land Rover': 'land-rover',
    'Rolls-Royce': 'rolls-royce',
    'Aston Martin': 'aston-martin',
    'Force Motors': 'force-motors',
    'Hindustan Motors': 'hindustan-motors',
    'BMW': 'bmw', 'MG': 'mg', 'BYD': 'byd'
};

function brandToSlug(brandName, site) {
    const slugs = site === 'cardekho' ? CARDEKHO_BRAND_SLUGS : CARWALE_BRAND_SLUGS;
    return slugs[brandName] || brandName.toLowerCase().replace(/\s+/g, '-');
}

// Special model slug mappings for CarWale
const MODEL_SLUGS = {
    'WagonR': 'wagon-r',
    'Grand Vitara': 'grand-vitara',
    'i10': 'i10',
    'i20': 'i20',
    'Grand i10': 'grand-i10',
    'Grand i10 Nios': 'grand-i10-nios',
    'i20 N Line': 'i20-n-line',
    'IONIQ 5': 'ioniq-5',
    'e2o': 'e2o',
    'e2o Plus': 'e2o-plus',
    'XEV 9E': 'xev-9e',
    'XEV 9S': 'xev-9s',
    'XUV 3XO': 'xuv-3xo',
    'XUV 3XO EV': 'xuv-3xo-ev',
    'XUV 7XO': 'xuv-7xo',
    'EV6': 'ev6',
    'EV9': 'ev9',
    'C3': 'c3',
    'C5 Aircross': 'c5-aircross',
    'EC3': 'ec3',
    'e-tron': 'e-tron',
    'e-tron GT': 'e-tron-gt',
    'Q8 e-tron': 'q8-e-tron',
    'A-Class': 'a-class',
    'B-Class': 'b-class',
    'C-Class': 'c-class',
    'E-Class': 'e-class',
    'S-Class': 's-class',
    'G-Class': 'g-class',
    'M-Class': 'm-class',
    'R-Class': 'r-class',
    'BR-V': 'br-v',
    'CR-V': 'cr-v',
    'WR-V': 'wr-v',
    'HR-V': 'hr-v'
};

function modelToSlug(modelName) {
    // Check special mappings first
    if (MODEL_SLUGS[modelName]) {
        return MODEL_SLUGS[modelName];
    }
    return modelName.toLowerCase()
        .replace(/[()]/g, '')
        .replace(/\s+/g, '-')
        .replace(/\./g, '-')
        .replace(/--+/g, '-')
        .replace(/^-|-$/g, '');
}

// Helper to find key recursively in object
function findKey(obj, key) {
    if (!obj || typeof obj !== 'object') return null;
    if (obj[key] !== undefined) return obj[key];
    for (const k of Object.keys(obj)) {
        const result = findKey(obj[k], key);
        if (result) return result;
    }
    return null;
}

// Parse variant from URL/text
function parseVariant(text, fuelType) {
    let name = text.trim()
        .replace(/₹[\d,.\s]*(lakh|cr)?/gi, '')
        .replace(/rs\.?\s*[\d,.\s]*(lakh|cr)?/gi, '')
        .replace(/\d+(\.\d+)?\s*(kmpl|bhp|cc|km\/l|nm)/gi, '')
        .replace(/\s*(petrol|diesel|cng|electric|hybrid|ev)\s*/gi, ' ')
        .replace(/\s+/g, ' ')
        .trim();

    // Capitalize variant codes properly
    const words = name.split(' ').map(word => {
        const upper = word.toUpperCase();
        const codes = ['LXI', 'VXI', 'ZXI', 'VDI', 'ZDI', 'SX', 'EX', 'GX', 'HX', 'MX', 'TX', 'DX',
            'MT', 'AT', 'AMT', 'CVT', 'DCT', 'IMT', 'AGS', 'GT', 'RS', 'SE', 'LE',
            'XE', 'XM', 'XZ', 'XT', 'XTA', 'XMA', 'XZA', 'PLUS', 'PRO', 'MAX',
            'SIGMA', 'DELTA', 'ZETA', 'ALPHA', 'OMEGA', 'CNG', 'EV', 'AWD', '4WD',
            'DT', 'O', 'S', 'N', 'R', 'T', 'V', 'W', 'X', 'Z', 'TOUR', 'BASE',
            'STD', 'LX', 'VX', 'ZX', 'SXT', 'GLX', 'GLS'];
        if (codes.includes(upper)) return upper;
        return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
    });

    return words.join(' ').trim();
}

// Detect fuel type from text
function detectFuelType(text) {
    const lower = text.toLowerCase();
    if (lower.includes('diesel')) return 'diesel';
    if (lower.includes('cng')) return 'cng';
    if (lower.includes('electric') || /\bev\b/.test(lower)) return 'electric';
    if (lower.includes('hybrid')) return 'hybrid';
    return 'petrol';
}

// Scrape from CarWale
async function scrapeCarWale(page, brandSlug, modelSlug, modelName) {
    const result = { tankCapacity: null, batteryCapacity: null, variants: {}, discontinued: false };

    try {
        // Main page for tank capacity
        const mainUrl = `https://www.carwale.com/${brandSlug}-cars/${modelSlug}/`;
        const response = await page.goto(mainUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });

        if (!response || response.status() === 404) return null;
        await delay(800);

        const mainData = await page.evaluate(() => {
            function findKey(obj, key) {
                if (!obj || typeof obj !== 'object') return null;
                if (obj[key] !== undefined) return obj[key];
                for (const k of Object.keys(obj)) {
                    const r = findKey(obj[k], key);
                    if (r) return r;
                }
                return null;
            }

            let tankCapacity = null, batteryCapacity = null, discontinued = false;

            const scripts = document.querySelectorAll('script[type="application/ld+json"]');
            for (const script of scripts) {
                try {
                    const json = JSON.parse(script.textContent);
                    const fc = findKey(json, 'fuelCapacity');
                    if (fc && fc.value) tankCapacity = parseFloat(fc.value);
                } catch (e) {}
            }

            const pageText = document.body.innerText.toLowerCase();
            if (pageText.includes('discontinued')) discontinued = true;

            const batteryMatch = pageText.match(/battery\s*(?:capacity)?[:\s]*(\d+(?:\.\d+)?)\s*kwh/i);
            if (batteryMatch) batteryCapacity = parseFloat(batteryMatch[1]);

            return { tankCapacity, batteryCapacity, discontinued };
        });

        result.tankCapacity = mainData.tankCapacity;
        result.batteryCapacity = mainData.batteryCapacity;
        result.discontinued = mainData.discontinued;

        // Price page for variants
        const priceUrl = `https://www.carwale.com/${brandSlug}-cars/${modelSlug}/price-in-delhi/`;
        await page.goto(priceUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
        await delay(1000);

        const variantsData = await page.evaluate((modelName, modelSlug) => {
            const variants = {};

            // Non-variant pages to skip
            const skipPages = ['price-in', 'brochure', 'reviews', 'mileage', 'specifications',
                'images', 'colours', 'videos', 'news', 'compare', 'variants', 'on-road-price',
                'emi-calculator', 'service-cost', 'dealers', 'user-reviews', 'expert-reviews'];

            // Extract from variant links
            // CarWale URL pattern: /brand-cars/model/variant-slug/ (petrol default)
            //                      /brand-cars/model/variant-slug-cng/ (CNG)
            //                      /brand-cars/model/variant-slug-diesel/ (diesel)
            const links = document.querySelectorAll('a[href*="/' + modelSlug + '/"]');
            links.forEach(link => {
                const href = link.getAttribute('href') || '';

                // Match: /brand-cars/model/something/
                const match = href.match(new RegExp('/' + modelSlug + '/([^/]+)/?$', 'i'));
                if (!match) return;

                let variantSlug = match[1];

                // Skip non-variant pages
                if (skipPages.some(s => variantSlug.includes(s))) return;
                if (variantSlug.startsWith('#')) return;

                // Detect fuel type - can be at end or in middle of slug
                let fuelType = 'petrol'; // default
                if (variantSlug.includes('-cng')) {
                    fuelType = 'cng';
                    variantSlug = variantSlug.replace(/-cng(-|$)/, '$1');
                } else if (variantSlug.includes('-diesel')) {
                    fuelType = 'diesel';
                    variantSlug = variantSlug.replace(/-diesel(-|$)/, '$1');
                } else if (variantSlug.includes('-electric')) {
                    fuelType = 'electric';
                    variantSlug = variantSlug.replace(/-electric(-|$)/, '$1');
                } else if (variantSlug.match(/-ev(-|$)/)) {
                    fuelType = 'electric';
                    variantSlug = variantSlug.replace(/-ev(-|$)/, '$1');
                } else if (variantSlug.includes('-hybrid')) {
                    fuelType = 'hybrid';
                    variantSlug = variantSlug.replace(/-hybrid(-|$)/, '$1');
                }

                // Clean up trailing dash
                variantSlug = variantSlug.replace(/-$/, '');

                // Convert slug to name
                const codes = ['LXI','VXI','ZXI','VDI','ZDI','SX','EX','GX','HX','MX','TX','DX',
                    'MT','AT','AMT','CVT','DCT','IMT','AGS','GT','RS','SE','LE','LX','VX','ZX',
                    'XE','XM','XZ','XT','XTA','XMA','XZA','PLUS','PRO','MAX','STD',
                    'SIGMA','DELTA','ZETA','ALPHA','OMEGA','AWD','4WD','DT','O','S',
                    'DUAL','TONE','TURBO','SPORT','STYLE','SMART','FLEX','FUEL'];
                let variantName = variantSlug.split('-').map(w => {
                    const up = w.toUpperCase();
                    // Handle engine size numbers (10 -> 1.0L, 12 -> 1.2L, 15 -> 1.5L)
                    if (/^\d{2}$/.test(w)) {
                        return w.charAt(0) + '.' + w.charAt(1) + 'L';
                    }
                    return codes.includes(up) ? up : w.charAt(0).toUpperCase() + w.slice(1);
                }).join(' ');

                if (variantName.length >= 2 && variantName.length <= 50) {
                    if (!variants[fuelType]) variants[fuelType] = [];
                    if (!variants[fuelType].includes(variantName)) {
                        variants[fuelType].push(variantName);
                    }
                }
            });

            // Method 2: Extract from page text if no variants found
            if (Object.keys(variants).length === 0) {
                const pageText = document.body.innerText;
                const lines = pageText.split('\n');

                for (const line of lines) {
                    if (!line.toLowerCase().includes(modelLower)) continue;

                    // Match patterns like "Swift LXi Petrol"
                    const variantMatch = line.match(new RegExp(modelName + '\\s+([A-Za-z0-9\\s\\(\\)\\+]+?)\\s*(Petrol|Diesel|CNG|Electric|Hybrid)?', 'i'));
                    if (variantMatch) {
                        let variantName = variantMatch[1].trim();
                        let fuelType = (variantMatch[2] || 'petrol').toLowerCase();

                        // Clean up
                        variantName = variantName
                            .replace(/₹[\d,.\s]*/g, '')
                            .replace(/\d+\.\d+\s*(kmpl|lakh)/gi, '')
                            .trim();

                        if (variantName.length >= 2 && variantName.length <= 40) {
                            if (!variants[fuelType]) variants[fuelType] = [];
                            if (!variants[fuelType].includes(variantName)) {
                                variants[fuelType].push(variantName);
                            }
                        }
                    }
                }
            }

            return variants;
        }, modelName, modelSlug);

        result.variants = variantsData;

    } catch (e) {
        // CarWale failed
    }

    return result;
}

// Scrape from CarDekho
async function scrapeCarDekho(page, brandSlug, modelSlug, modelName) {
    const result = { tankCapacity: null, batteryCapacity: null, variants: {} };

    try {
        const url = `https://www.cardekho.com/${brandSlug}/${modelSlug}`;
        const response = await page.goto(url, { waitUntil: 'networkidle2', timeout: 20000 });

        if (!response || response.status() === 404) return null;
        await delay(1500);

        const data = await page.evaluate((modelName) => {
            const variants = {};
            let tankCapacity = null;
            let batteryCapacity = null;
            const modelLower = modelName.toLowerCase();

            // Try to find tank capacity in specs
            const pageText = document.body.innerText;

            // Tank capacity patterns
            const tankMatch = pageText.match(/fuel\s*tank\s*capacity[:\s]*(\d+(?:\.\d+)?)\s*(?:litres?|L)/i);
            if (tankMatch) tankCapacity = parseFloat(tankMatch[1]);

            // Battery capacity
            const batteryMatch = pageText.match(/battery\s*capacity[:\s]*(\d+(?:\.\d+)?)\s*kwh/i);
            if (batteryMatch) batteryCapacity = parseFloat(batteryMatch[1]);

            // Find variant links - CarDekho uses different URL patterns
            const links = document.querySelectorAll('a[href*="/"]');
            links.forEach(link => {
                const href = link.getAttribute('href') || '';
                const text = link.textContent?.trim() || '';

                // Pattern: /brand/model/variant-fueltype
                // Also: /brand/model/variants with text content
                if (href.includes(modelSlug) && text.length > 2) {
                    let fuelType = 'petrol';
                    const textLower = text.toLowerCase();

                    if (textLower.includes('diesel')) fuelType = 'diesel';
                    else if (textLower.includes('cng')) fuelType = 'cng';
                    else if (textLower.includes('electric') || /\bev\b/.test(textLower)) fuelType = 'electric';
                    else if (textLower.includes('hybrid')) fuelType = 'hybrid';

                    // Clean variant name
                    let variantName = text
                        .replace(/₹[\d,.\s]*(lakh|cr)?/gi, '')
                        .replace(/\d+(\.\d+)?\s*(kmpl|bhp|cc)/gi, '')
                        .replace(/\s*(petrol|diesel|cng|electric|hybrid)\s*/gi, ' ')
                        .replace(new RegExp('^' + modelName + '\\s*', 'i'), '')
                        .trim();

                    if (variantName.length >= 2 && variantName.length <= 40 &&
                        !variantName.match(/^(view|see|more|all|compare|price|spec)/i)) {
                        if (!variants[fuelType]) variants[fuelType] = [];
                        if (!variants[fuelType].includes(variantName)) {
                            variants[fuelType].push(variantName);
                        }
                    }
                }
            });

            return { tankCapacity, batteryCapacity, variants };
        }, modelName);

        result.tankCapacity = data.tankCapacity;
        result.batteryCapacity = data.batteryCapacity;
        result.variants = data.variants;

    } catch (e) {
        // CarDekho failed
    }

    return result;
}

// Merge variants from both sources
function mergeVariants(cwVariants, cdVariants) {
    const merged = { ...cwVariants };

    for (const fuelType of Object.keys(cdVariants)) {
        if (!merged[fuelType]) {
            merged[fuelType] = [];
        }
        for (const variant of cdVariants[fuelType]) {
            // Check if variant already exists (case insensitive)
            const exists = merged[fuelType].some(v =>
                v.toLowerCase() === variant.toLowerCase()
            );
            if (!exists) {
                merged[fuelType].push(variant);
            }
        }
    }

    // Sort variants within each fuel type
    for (const fuelType of Object.keys(merged)) {
        merged[fuelType].sort();
    }

    return merged;
}

async function scrapeAllData() {
    console.log('🚗 Comprehensive Vehicle Data Scraper\n');
    console.log('Scraping from CarWale + CarDekho for complete data...\n');

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36');

    await page.setRequestInterception(true);
    page.on('request', (req) => {
        if (['image', 'stylesheet', 'font'].includes(req.resourceType())) {
            req.abort();
        } else {
            req.continue();
        }
    });

    const outputData = {
        version: "3.0",
        lastUpdated: new Date().toISOString().split('T')[0],
        sources: ["CarWale", "CarDekho"],
        makes: []
    };

    const tankCapacityData = {
        version: "3.0",
        lastUpdated: new Date().toISOString().split('T')[0],
        sources: ["CarWale", "CarDekho"],
        note: "Tank in litres, battery in kWh. Merged from multiple sources.",
        data: {}
    };

    let stats = { total: 0, found: 0, variants: 0, tanks: 0 };

    // Priority brands
    const priorityBrands = [
        'Maruti Suzuki', 'Hyundai', 'Tata', 'Mahindra', 'Kia', 'Honda', 'Toyota',
        'MG', 'Volkswagen', 'Skoda'
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
        const cwBrandSlug = brandToSlug(make.name, 'carwale');
        const cdBrandSlug = brandToSlug(make.name, 'cardekho');

        console.log(`\n📦 ${make.name} (${make.models.length} models)`);

        const makeData = { name: make.name, models: [] };

        for (const model of make.models) {
            stats.total++;
            const modelSlug = modelToSlug(model);
            process.stdout.write(`   ${model}... `);

            // Scrape from both sources
            const cwData = await scrapeCarWale(page, cwBrandSlug, modelSlug, model);
            await delay(500);
            const cdData = await scrapeCarDekho(page, cdBrandSlug, modelSlug, model);

            // Merge data
            let tankCapacity = cwData?.tankCapacity || cdData?.tankCapacity || null;
            let batteryCapacity = cwData?.batteryCapacity || cdData?.batteryCapacity || null;
            let variants = mergeVariants(cwData?.variants || {}, cdData?.variants || {});
            let discontinued = cwData?.discontinued || false;

            // Count variants
            let variantCount = 0;
            for (const ft of Object.keys(variants)) {
                variantCount += variants[ft].length;
            }

            if (cwData || cdData) {
                stats.found++;
                stats.variants += variantCount;

                const modelData = {
                    name: model,
                    variants: variants,
                    fuelTypes: Object.keys(variants),
                    discontinued: discontinued
                };

                makeData.models.push(modelData);

                // Store tank capacity
                const key = `${make.name}|${model}`;
                if (tankCapacity) {
                    tankCapacityData.data[key] = { tankL: tankCapacity };
                    stats.tanks++;
                } else if (batteryCapacity) {
                    tankCapacityData.data[key] = { batteryKWh: batteryCapacity };
                    stats.tanks++;
                }

                const capInfo = tankCapacity ? `${tankCapacity}L` : batteryCapacity ? `${batteryCapacity}kWh` : '-';
                const fuelInfo = Object.keys(variants).join('/') || '-';
                const src = [cwData ? 'CW' : null, cdData ? 'CD' : null].filter(Boolean).join('+');
                console.log(`✓ ${variantCount} (${fuelInfo}) | ${capInfo} [${src}]`);
            } else {
                makeData.models.push({
                    name: model,
                    variants: {},
                    fuelTypes: [],
                    discontinued: true
                });
                console.log('✗');
            }

            await delay(800);
        }

        outputData.makes.push(makeData);

        // Save progress
        fs.writeFileSync('../AutoLedger/Resources/IndianVehicleDataV2.json', JSON.stringify(outputData, null, 2));
        fs.writeFileSync('../AutoLedger/Resources/TankCapacityData.json', JSON.stringify(tankCapacityData, null, 2));
    }

    await browser.close();

    console.log('\n✅ Done!');
    console.log(`\n📊 Summary:`);
    console.log(`   Models: ${stats.found}/${stats.total}`);
    console.log(`   Variants: ${stats.variants}`);
    console.log(`   Tank capacities: ${stats.tanks}`);
}

scrapeAllData().catch(console.error);

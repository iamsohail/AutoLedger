/**
 * CarWale Comprehensive Scraper
 *
 * Scrapes models, variants, and tank capacity from CarWale.
 * Output structure supports variant dropdown in the app.
 *
 * Usage: node scrape_carwale_variants.js
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

async function scrapeModelVariants(page, brandSlug, modelSlug, brandName, modelName) {
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

        // Extract variants and specs from page
        const data = await page.evaluate(() => {
            const result = {
                variants: [],
                tankCapacity: null,
                batteryCapacity: null,
                fuelTypes: []
            };

            // Method 1: Get tank capacity from JSON-LD
            const scripts = document.querySelectorAll('script[type="application/ld+json"]');
            for (const script of scripts) {
                try {
                    const json = JSON.parse(script.textContent);
                    if (json.fuelCapacity && json.fuelCapacity.value) {
                        result.tankCapacity = parseFloat(json.fuelCapacity.value);
                    }
                    if (json.fuelType) {
                        const ft = json.fuelType.toLowerCase();
                        if (!result.fuelTypes.includes(ft)) {
                            result.fuelTypes.push(ft);
                        }
                    }
                } catch (e) {}
            }

            // Method 2: Find variant links on the page
            // CarWale typically lists variants with links containing the variant name
            const variantElements = document.querySelectorAll('[class*="variant"], [data-variant], a[href*="-cars/"][href*="/"]');
            const seenVariants = new Set();

            variantElements.forEach(el => {
                const text = el.textContent?.trim();
                const href = el.getAttribute('href') || '';

                // Extract variant name from href or text
                // Typical patterns: swift-lxi-petrol, creta-sx-diesel
                const variantMatch = href.match(/\/([^\/]+)-(petrol|diesel|cng|electric|hybrid)\/?$/i);
                if (variantMatch) {
                    const variantSlug = variantMatch[1];
                    const fuelType = variantMatch[2].toLowerCase();
                    // Convert slug to display name: "lxi" -> "LXi"
                    const variantName = variantSlug
                        .split('-')
                        .map(part => {
                            // Common variant suffixes to capitalize properly
                            const upper = part.toUpperCase();
                            if (['LXI', 'VXI', 'ZXI', 'SX', 'EX', 'GX', 'HX', 'MX', 'TX', 'DX', 'MT', 'AT', 'AMT', 'CVT', 'DCT', 'IMT', 'GT', 'RS', 'SE', 'XE', 'XM', 'XZ', 'XT', 'XTA', 'XMA', 'XZA', 'PLUS', 'PRO'].includes(upper)) {
                                return upper;
                            }
                            return part.charAt(0).toUpperCase() + part.slice(1);
                        })
                        .join(' ');

                    const key = `${variantName}|${fuelType}`;
                    if (!seenVariants.has(key) && variantName.length > 1 && variantName.length < 50) {
                        seenVariants.add(key);
                        result.variants.push({
                            name: variantName,
                            fuelType: fuelType
                        });
                    }
                }
            });

            // Method 3: Look for variant names in text content
            const pageText = document.body.innerText;

            // Common variant patterns
            const variantPatterns = [
                /\b(LXi|VXi|ZXi|ZXi\+|LXi\(O\)|VXi\(O\)|ZXi\(O\))\b/gi,
                /\b(SX|EX|GX|HX|MX|TX|DX|Sigma|Delta|Zeta|Alpha)\b/gi,
                /\b(XE|XM|XZ|XT|XZ\+|XZA\+|XMA|XTA)\b/gi,
                /\b(Base|Mid|Top|Premium|Prestige|Technology|Luxury)\b/gi
            ];

            // Get fuel type from page if not found
            if (result.fuelTypes.length === 0) {
                if (pageText.match(/\bpetrol\b/i)) result.fuelTypes.push('petrol');
                if (pageText.match(/\bdiesel\b/i)) result.fuelTypes.push('diesel');
                if (pageText.match(/\bcng\b/i)) result.fuelTypes.push('cng');
                if (pageText.match(/\belectric\b/i)) result.fuelTypes.push('electric');
                if (pageText.match(/\bhybrid\b/i)) result.fuelTypes.push('hybrid');
            }

            // Check for battery capacity (EVs)
            const batteryMatch = pageText.match(/battery capacity[^0-9]*(\d+(?:\.\d+)?)\s*kwh/i);
            if (batteryMatch) {
                result.batteryCapacity = parseFloat(batteryMatch[1]);
            }

            return result;
        });

        // If no variants found from links, try to get them from the variants page
        if (data.variants.length === 0) {
            const variantsUrl = `${BASE_URL}/${brandSlug}-cars/${modelSlug}/variants/`;
            try {
                await page.goto(variantsUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
                await delay(1000);

                const variantsData = await page.evaluate(() => {
                    const variants = [];
                    const seenVariants = new Set();

                    // Look for variant listing
                    const links = document.querySelectorAll('a[href*="-cars/"]');
                    links.forEach(link => {
                        const href = link.getAttribute('href') || '';
                        const text = link.textContent?.trim() || '';

                        // Match variant URLs
                        const match = href.match(/\/([^\/]+)-(petrol|diesel|cng|electric|hybrid)\/?$/i);
                        if (match && text.length > 2 && text.length < 60) {
                            const fuelType = match[2].toLowerCase();
                            // Clean up the variant name from the link text
                            let variantName = text
                                .replace(/₹[\d,\.]+\s*(Lakh|Cr)?/gi, '')
                                .replace(/\d+\.\d+\s*km\/l/gi, '')
                                .replace(/\d+\s*bhp/gi, '')
                                .replace(/\s+/g, ' ')
                                .trim();

                            // Remove model name prefix if present
                            const key = `${variantName}|${fuelType}`;
                            if (!seenVariants.has(key) && variantName.length > 1) {
                                seenVariants.add(key);
                                variants.push({ name: variantName, fuelType });
                            }
                        }
                    });

                    return variants;
                });

                if (variantsData.length > 0) {
                    data.variants = variantsData;
                }
            } catch (e) {
                // Variants page might not exist
            }
        }

        return data;
    } catch (error) {
        console.error(`   Error: ${error.message}`);
        return null;
    }
}

async function scrapeAllData() {
    console.log('🚗 CarWale Comprehensive Scraper\n');
    console.log('Fetching models, variants, and tank capacity...\n');

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
        note: "Tank capacity in litres (L) or battery capacity in kWh for EVs. Data from CarWale.",
        data: {}
    };

    let totalModels = 0;
    let foundModels = 0;
    let totalVariants = 0;

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

            const data = await scrapeModelVariants(page, brandSlug, modelSlug, make.name, model);

            if (data) {
                const modelData = {
                    name: model,
                    variants: data.variants.map(v => v.name),
                    fuelTypes: data.fuelTypes
                };

                // Store unique variants
                const uniqueVariants = [...new Set(data.variants.map(v => v.name))];
                modelData.variants = uniqueVariants;

                makeData.models.push(modelData);
                foundModels++;
                totalVariants += uniqueVariants.length;

                // Store tank capacity
                const key = `${make.name}|${model}`;
                if (data.tankCapacity) {
                    tankCapacityData.data[key] = { tankL: data.tankCapacity };
                } else if (data.batteryCapacity) {
                    tankCapacityData.data[key] = { batteryKWh: data.batteryCapacity };
                }

                const variantCount = uniqueVariants.length;
                const capacityInfo = data.tankCapacity ? `${data.tankCapacity}L` :
                                    data.batteryCapacity ? `${data.batteryCapacity}kWh` : '';
                console.log(`✓ ${variantCount} variants ${capacityInfo ? `| ${capacityInfo}` : ''}`);
            } else {
                // Still add the model even if not found on CarWale
                makeData.models.push({
                    name: model,
                    variants: [],
                    fuelTypes: []
                });
                console.log('✗');
            }

            await delay(800 + Math.random() * 400);
        }

        outputData.makes.push(makeData);
    }

    await browser.close();

    // Save vehicle data with variants
    fs.writeFileSync(
        '../AutoLedger/Resources/IndianVehicleDataV2.json',
        JSON.stringify(outputData, null, 2)
    );

    // Save tank capacity data
    fs.writeFileSync(
        '../AutoLedger/Resources/TankCapacityData.json',
        JSON.stringify(tankCapacityData, null, 2)
    );

    console.log('\n✅ Data saved!');
    console.log(`\n📊 Summary:`);
    console.log(`   Total models processed: ${totalModels}`);
    console.log(`   Models found on CarWale: ${foundModels}`);
    console.log(`   Total variants found: ${totalVariants}`);
    console.log(`   Tank capacities found: ${Object.keys(tankCapacityData.data).length}`);
    console.log(`\n📁 Files:`);
    console.log(`   IndianVehicleDataV2.json - Models with variants`);
    console.log(`   TankCapacityData.json - Tank capacities`);
}

scrapeAllData().catch(console.error);

#!/usr/bin/env node
/**
 * Vehicle Data Scraper for GitHub Actions
 * Scrapes latest vehicle data from CarDekho and updates IndianVehicleData.json
 */

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

const OUTPUT_FILE = path.join(__dirname, '../AutoLedger/Resources/IndianVehicleData.json');

// CarDekho brand URLs
const BRANDS = [
    { name: 'Maruti Suzuki', slug: 'maruti' },
    { name: 'Hyundai', slug: 'hyundai' },
    { name: 'Tata', slug: 'tata' },
    { name: 'Mahindra', slug: 'mahindra' },
    { name: 'Kia', slug: 'kia' },
    { name: 'Toyota', slug: 'toyota' },
    { name: 'Honda', slug: 'honda' },
    { name: 'MG', slug: 'mg' },
    { name: 'Volkswagen', slug: 'volkswagen' },
    { name: 'Skoda', slug: 'skoda' },
    { name: 'Renault', slug: 'renault' },
    { name: 'Nissan', slug: 'nissan' },
    { name: 'Jeep', slug: 'jeep' },
    { name: 'Citroen', slug: 'citroen' },
    { name: 'Mercedes-Benz', slug: 'mercedes-benz' },
    { name: 'BMW', slug: 'bmw' },
    { name: 'Audi', slug: 'audi' },
    { name: 'Lexus', slug: 'lexus' },
    { name: 'Volvo', slug: 'volvo' },
    { name: 'Porsche', slug: 'porsche' },
    { name: 'Land Rover', slug: 'land-rover' },
    { name: 'Jaguar', slug: 'jaguar' },
    { name: 'BYD', slug: 'byd' },
    { name: 'Mini', slug: 'mini' },
    { name: 'Isuzu', slug: 'isuzu' },
    { name: 'Ferrari', slug: 'ferrari' },
    { name: 'Lamborghini', slug: 'lamborghini' },
    { name: 'Bentley', slug: 'bentley' },
    { name: 'Rolls-Royce', slug: 'rolls-royce' },
    { name: 'Maserati', slug: 'maserati' },
    { name: 'Aston Martin', slug: 'aston-martin' },
    { name: 'McLaren', slug: 'mclaren' },
];

async function scrapeModels(browser, brand) {
    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36');

    const url = `https://www.cardekho.com/${brand.slug}-cars`;
    console.log(`Scraping ${brand.name}...`);

    try {
        await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });
        await page.waitForSelector('.gsc_col-xs-12', { timeout: 10000 });

        const models = await page.evaluate(() => {
            const items = document.querySelectorAll('.gsc_col-xs-12.gsc_col-sm-6.gsc_col-md-4.gsc_col-lg-4');
            const results = [];

            items.forEach(item => {
                const nameEl = item.querySelector('h3, .title');
                const name = nameEl?.textContent?.trim();

                if (name && !name.includes('Price') && !name.includes('₹')) {
                    // Default values
                    const model = {
                        name: name,
                        fuelTypes: ['petrol'],
                        transmission: 'Manual'
                    };

                    // Check for fuel type hints in text
                    const text = item.textContent.toLowerCase();
                    if (text.includes('diesel')) model.fuelTypes.push('diesel');
                    if (text.includes('cng')) model.fuelTypes.push('cng');
                    if (text.includes('electric') || text.includes('ev')) model.fuelTypes = ['electric'];
                    if (text.includes('hybrid')) model.fuelTypes.push('hybrid');

                    // Check transmission
                    if (text.includes('automatic') && text.includes('manual')) {
                        model.transmission = 'Both';
                    } else if (text.includes('automatic')) {
                        model.transmission = 'Automatic';
                    }

                    results.push(model);
                }
            });

            return results;
        });

        await page.close();
        return models;
    } catch (error) {
        console.error(`Error scraping ${brand.name}: ${error.message}`);
        await page.close();
        return [];
    }
}

async function main() {
    console.log('🚗 Starting vehicle data scrape...\n');

    // Load existing data
    let existingData = { makes: [] };
    if (fs.existsSync(OUTPUT_FILE)) {
        existingData = JSON.parse(fs.readFileSync(OUTPUT_FILE, 'utf8'));
        console.log(`📂 Loaded existing data: ${existingData.makes.length} makes\n`);
    }

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const newMakes = [];
    let newModelsCount = 0;

    for (const brand of BRANDS) {
        const models = await scrapeModels(browser, brand);

        if (models.length > 0) {
            // Find existing make
            const existingMake = existingData.makes.find(m => m.name === brand.name);
            const existingModelNames = existingMake?.models.map(m => m.name) || [];

            // Find new models
            const newModels = models.filter(m => !existingModelNames.includes(m.name));

            if (newModels.length > 0) {
                console.log(`  ✨ ${brand.name}: ${newModels.length} new model(s)`);
                newModelsCount += newModels.length;
            }

            // Merge with existing
            if (existingMake) {
                existingMake.models = [...existingMake.models, ...newModels];
                newMakes.push(existingMake);
            } else {
                newMakes.push({ name: brand.name, models });
            }
        }

        // Rate limiting
        await new Promise(r => setTimeout(r, 1000));
    }

    await browser.close();

    // Update data
    const updatedData = {
        version: existingData.version || "6.3",
        lastUpdated: new Date().toISOString().split('T')[0],
        makes: newMakes.length > 0 ? newMakes : existingData.makes
    };

    // Bump version if changes
    if (newModelsCount > 0) {
        const [major, minor] = (existingData.version || "6.0").split('.').map(Number);
        updatedData.version = `${major}.${minor + 1}`;
    }

    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(updatedData, null, 2));

    console.log(`\n✅ Scrape complete!`);
    console.log(`   New models found: ${newModelsCount}`);
    console.log(`   Total makes: ${updatedData.makes.length}`);
    console.log(`   Version: ${updatedData.version}`);
}

main().catch(console.error);

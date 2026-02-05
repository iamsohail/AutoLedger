/**
 * CarDekho Scraper for Auto Ledger
 *
 * Scrapes vehicle makes, models from cardekho.com
 * For personal use only.
 *
 * Usage:
 * 1. Install dependencies: npm install puppeteer
 * 2. Run: node scrape_cardekho.js
 * 3. Output will be saved to cardekho_vehicles.json
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

const BASE_URL = 'https://www.cardekho.com';

// Delay helper
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// All Indian market car brands (current + discontinued)
// Note: urlSlug is for the page URL, linkSlug is for model links within the page
const BRANDS = [
    // Current major brands
    { name: 'Maruti Suzuki', slug: 'maruti-suzuki', linkSlug: 'maruti', country: 'India' },
    { name: 'Tata', slug: 'tata', country: 'India' },
    { name: 'Mahindra', slug: 'mahindra', country: 'India' },
    { name: 'Hyundai', slug: 'hyundai', country: 'South Korea' },
    { name: 'Honda', slug: 'honda', country: 'Japan' },
    { name: 'Toyota', slug: 'toyota', country: 'Japan' },
    { name: 'Kia', slug: 'kia', country: 'South Korea' },
    { name: 'MG', slug: 'mg', country: 'China' },
    { name: 'Skoda', slug: 'skoda', country: 'Czech Republic' },
    { name: 'Volkswagen', slug: 'volkswagen', country: 'Germany' },
    { name: 'Renault', slug: 'renault', country: 'France' },
    { name: 'Nissan', slug: 'nissan', country: 'Japan' },
    { name: 'Jeep', slug: 'jeep', country: 'USA' },
    { name: 'Citroen', slug: 'citroen', country: 'France' },
    { name: 'Mercedes-Benz', slug: 'mercedes-benz', country: 'Germany' },
    { name: 'BMW', slug: 'bmw', country: 'Germany' },
    { name: 'Audi', slug: 'audi', country: 'Germany' },
    { name: 'Lexus', slug: 'lexus', country: 'Japan' },
    { name: 'Volvo', slug: 'volvo', country: 'Sweden' },
    { name: 'Porsche', slug: 'porsche', country: 'Germany' },
    { name: 'Land Rover', slug: 'land-rover', country: 'UK' },
    { name: 'Jaguar', slug: 'jaguar', country: 'UK' },
    { name: 'BYD', slug: 'byd', country: 'China' },
    { name: 'Mini', slug: 'mini', country: 'UK' },
    { name: 'Isuzu', slug: 'isuzu', country: 'Japan' },
    { name: 'Force Motors', slug: 'force', country: 'India' },
    { name: 'Ferrari', slug: 'ferrari', country: 'Italy' },
    { name: 'Lamborghini', slug: 'lamborghini', country: 'Italy' },
    { name: 'Bentley', slug: 'bentley', country: 'UK' },
    { name: 'Rolls-Royce', slug: 'rolls-royce', country: 'UK' },
    { name: 'Maserati', slug: 'maserati', country: 'Italy' },
    { name: 'Aston Martin', slug: 'aston-martin', country: 'UK' },
    { name: 'McLaren', slug: 'mclaren', country: 'UK' },
    // Discontinued brands (still have owners in India)
    { name: 'Ford', slug: 'ford', country: 'USA', discontinued: true },
    { name: 'Chevrolet', slug: 'chevrolet', country: 'USA', discontinued: true },
    { name: 'Fiat', slug: 'fiat', country: 'Italy', discontinued: true },
    { name: 'Datsun', slug: 'datsun', country: 'Japan', discontinued: true },
    { name: 'Mitsubishi', slug: 'mitsubishi', country: 'Japan', discontinued: true },
    { name: 'Opel', slug: 'opel', country: 'Germany', discontinued: true },
    { name: 'Hindustan Motors', slug: 'hindustan-motors', linkSlug: 'hindustan', country: 'India', discontinued: true },
    { name: 'Premier', slug: 'premier', country: 'India', discontinued: true },
    { name: 'San Motors', slug: 'san', country: 'India', discontinued: true },
];

// All brand names for filtering (don't include other brands in a brand's model list)
const ALL_BRAND_NAMES = BRANDS.map(b => b.name.toLowerCase());
const BRAND_FIRST_WORDS = BRANDS.map(b => b.name.split(' ')[0].toLowerCase());

// Words/phrases that indicate it's NOT a model name
const BLACKLIST = [
    // Social media & websites
    'facebook', 'instagram', 'twitter', 'youtube', 'linkedin', 'bikedekho', 'cardekho',
    'revv', 'rupyy', 'criteo', 'google', 'whatsapp',
    // Navigation & UI elements
    'home', 'menu', 'search', 'login', 'sign', 'privacy', 'terms', 'policy', 'corporate',
    'by body', 'by budget', 'by fuel', 'by feature', 'by seating', 'by transmission',
    'car comparison', 'car insurance', 'car showroom', 'fuel station', 'new launch',
    'sell my car', 'ad content', 'iframe', '3rd party',
    // View descriptions
    'front left', 'front right', 'side profile', 'rear view', 'quarter view', 'interior',
    'dashboard', 'engine', 'wheel', 'headlight', 'taillight', 'grill',
    // Price related
    'price', 'road', 'lakh', 'crore', '₹', 'rs.', 'inr', 'emi', 'loan', 'finance',
    // Content types
    'upcoming', 'news', 'review', 'video', 'image', 'gallery', 'compare', 'specification',
    'mileage', 'feature', 'colour', 'color', 'variant', 'brochure',
    // Car types (categories, not models)
    'electric cars', 'diesel cars', 'petrol cars', 'automatic cars', 'sunroof',
    'suv cars', 'sedan cars', 'hatchback cars', 'coupe cars', 'convertible cars',
    'luxury cars', 'minivan', 'muv',
    // Used cars
    'used car', 'second hand',
    // Locations
    'new delhi', 'mumbai', 'bangalore', 'chennai', 'kolkata', 'hyderabad', 'pune', 'india',
    // Actions
    'view all', 'read more', 'show more', 'click here', 'download', 'subscribe',
    // Year ranges (old models)
    '2019-', '2020-', '2021-', '2022-', '2023-', '2024-', '2025-',
    // Misc
    'powerdrift', 'auto expo', 'on sale', 'drama', 'logic', 'defend your',
    'charging station', 'service center', 'dealer', 'showroom',
];

function isValidModel(model, brandName) {
    if (!model || typeof model !== 'string') return false;

    const lower = model.toLowerCase().trim();

    // Length check
    if (lower.length < 2 || lower.length > 35) return false;

    // Check blacklist
    for (const black of BLACKLIST) {
        if (lower.includes(black)) return false;
    }

    // Check if it's another brand name (not the current brand)
    const brandLower = brandName.toLowerCase();
    const brandFirst = brandName.split(' ')[0].toLowerCase();

    for (const otherBrand of ALL_BRAND_NAMES) {
        if (otherBrand === brandLower || otherBrand.startsWith(brandFirst)) continue;
        if (lower.startsWith(otherBrand) || lower.includes(` ${otherBrand}`)) {
            return false;
        }
    }

    for (const otherBrandFirst of BRAND_FIRST_WORDS) {
        if (otherBrandFirst === brandFirst) continue;
        if (otherBrandFirst.length > 3 && (lower.startsWith(otherBrandFirst + ' ') || lower.startsWith(otherBrandFirst + '-'))) {
            return false;
        }
    }

    // Must contain at least one letter
    if (!/[a-zA-Z]/.test(model)) return false;

    // Shouldn't be all uppercase generic words
    if (/^[A-Z\s]+$/.test(model) && model.length > 10) return false;

    return true;
}

function cleanModelName(model, brandName) {
    if (!model || typeof model !== 'string') return null;

    let cleaned = model.trim();

    // Remove brand name prefix (various formats)
    const brandVariations = [
        brandName,
        brandName.split(' ')[0],
        brandName.replace('-', ' '),
        brandName.replace(' ', '-'),
        brandName.replace(' ', ''),
    ];

    for (const brand of brandVariations) {
        const regex = new RegExp(`^${brand}[\\s-]*`, 'i');
        cleaned = cleaned.replace(regex, '').trim();
    }

    // Remove common suffixes and year ranges
    cleaned = cleaned
        .replace(/\s*Price.*$/i, '')
        .replace(/\s*On Road.*$/i, '')
        .replace(/\s*in\s+\w+$/i, '')
        .replace(/\s*\(.*\)$/i, '')  // Remove parenthetical info
        .replace(/\s+\d{4}\s*\d{0,4}$/i, '')  // Remove year ranges like "2023 2025" or "2024"
        .replace(/\s+(1st|2nd|3rd|4th|5th)\s+gen$/i, '')  // Remove generation info
        .trim();

    // Final validation
    if (!isValidModel(cleaned, brandName)) return null;

    // Capitalize properly
    cleaned = cleaned.split(' ')
        .map(word => {
            if (word.length <= 2 && /^[A-Z0-9]+$/i.test(word)) {
                return word.toUpperCase(); // Keep short acronyms uppercase (EV, XL, etc.)
            }
            return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
        })
        .join(' ')
        // Fix known model names
        .replace(/\bEv\b/g, 'EV')
        .replace(/\bSuv\b/g, 'SUV')
        .replace(/\bXl\b/g, 'XL')
        .replace(/\bXuv\b/g, 'XUV')
        .replace(/\bXe\b/g, 'XE')
        .replace(/\bXf\b/g, 'XF')
        .replace(/\bAmg\b/g, 'AMG')
        .replace(/\bGt\b/g, 'GT')
        .replace(/\bRs\b/g, 'RS');

    return cleaned;
}

async function scrapeModelsFromPage(page, brandSlug) {
    const linkSlug = brandSlug;
    return await page.evaluate((brandSlug) => {
        const models = new Set();

        // Method 1: Extract from model links (most reliable)
        document.querySelectorAll(`a[href^="/${brandSlug}/"]`).forEach(link => {
            const href = link.getAttribute('href');
            const parts = href.split('/').filter(p => p && p !== brandSlug);

            if (parts.length >= 1) {
                const modelSlug = parts[0];
                // Only get direct model pages, not sub-pages
                if (modelSlug &&
                    !modelSlug.includes('price') &&
                    !modelSlug.includes('review') &&
                    !modelSlug.includes('images') &&
                    !modelSlug.includes('specs') &&
                    !modelSlug.includes('mileage') &&
                    !modelSlug.includes('colours') &&
                    !modelSlug.includes('variants') &&
                    !modelSlug.includes('on-road-price') &&
                    !modelSlug.includes('discontinued') &&
                    modelSlug.length > 1) {

                    // Convert slug to name: "grand-vitara" -> "Grand Vitara"
                    const modelName = modelSlug
                        .split('-')
                        .map(w => w.charAt(0).toUpperCase() + w.slice(1))
                        .join(' ');
                    models.add(modelName);
                }
            }
        });

        // Method 2: Extract from JSON-LD ItemList (if available)
        document.querySelectorAll('script[type="application/ld+json"]').forEach(script => {
            try {
                const data = JSON.parse(script.textContent);
                if (data['@type'] === 'ItemList' && data.itemListElement) {
                    data.itemListElement.forEach(item => {
                        if (item.name && item.item && item.item['@type'] === 'Car') {
                            models.add(item.name);
                        }
                    });
                }
            } catch (e) {}
        });

        return Array.from(models);
    }, linkSlug);
}

async function scrapeCarDekho() {
    console.log('🚗 Starting CarDekho Scraper (with discontinued models)...\n');

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

    const vehicleData = [];

    for (let i = 0; i < BRANDS.length; i++) {
        const brand = BRANDS[i];
        console.log(`[${i + 1}/${BRANDS.length}] Scraping ${brand.name}...`);

        try {
            const allModels = new Set();
            const linkSlug = brand.linkSlug || brand.slug;

            // Scrape current models
            const currentUrl = `${BASE_URL}/${brand.slug}-cars`;
            await page.goto(currentUrl, { waitUntil: 'networkidle2', timeout: 60000 });
            await delay(1500 + Math.random() * 1000);

            const currentModels = await scrapeModelsFromPage(page, linkSlug);
            currentModels.forEach(m => allModels.add(m));
            console.log(`   ✓ Found ${currentModels.length} current models`);

            // Scrape discontinued models
            try {
                const discontinuedUrl = `${BASE_URL}/${brand.slug}-cars/discontinued`;
                await page.goto(discontinuedUrl, { waitUntil: 'networkidle2', timeout: 30000 });
                await delay(1000 + Math.random() * 500);

                const discontinuedModels = await scrapeModelsFromPage(page, linkSlug);
                discontinuedModels.forEach(m => allModels.add(m));
                if (discontinuedModels.length > 0) {
                    console.log(`   ✓ Found ${discontinuedModels.length} discontinued models`);
                }
            } catch (e) {
                // No discontinued page or error - that's okay
            }

            // Clean and filter models
            const rawModels = Array.from(allModels);
            const cleanedModels = rawModels
                .map(m => cleanModelName(m, brand.name))
                .filter(m => m !== null && m.length > 1);

            // Remove duplicates (case-insensitive)
            const uniqueModels = [];
            const seenLower = new Set();
            for (const model of cleanedModels) {
                const lower = model.toLowerCase();
                if (!seenLower.has(lower)) {
                    seenLower.add(lower);
                    uniqueModels.push(model);
                }
            }

            // Sort alphabetically
            uniqueModels.sort((a, b) => a.localeCompare(b));

            console.log(`   → Total: ${uniqueModels.length} models\n`);

            vehicleData.push({
                id: brand.slug.replace(/-/g, '_'),
                name: brand.name,
                country: brand.country,
                discontinued: brand.discontinued || false,
                models: uniqueModels.length > 0 ? uniqueModels : ['Other']
            });

        } catch (error) {
            console.log(`   ✗ Error: ${error.message}\n`);
            vehicleData.push({
                id: brand.slug.replace(/-/g, '_'),
                name: brand.name,
                country: brand.country,
                discontinued: brand.discontinued || false,
                models: ['Other']
            });
        }
    }

    await browser.close();

    // Save results
    const outputPath = './cardekho_vehicles.json';
    fs.writeFileSync(outputPath, JSON.stringify(vehicleData, null, 2));
    console.log(`\n✅ Data saved to ${outputPath}`);

    // Create Firebase seed script
    const seedScriptContent = generateSeedScript(vehicleData);
    fs.writeFileSync('./seed_firebase_scraped.js', seedScriptContent);
    console.log('✅ Firebase seed script saved to seed_firebase_scraped.js');

    // Summary
    const totalModels = vehicleData.reduce((sum, b) => sum + b.models.length, 0);
    console.log('\n📊 Summary:');
    console.log(`   Total brands: ${vehicleData.length}`);
    console.log(`   Total models: ${totalModels}`);
    console.log('\n📋 Sample data:');
    vehicleData.slice(0, 5).forEach(b => {
        console.log(`\n   ${b.name}:`);
        console.log(`   ${b.models.slice(0, 10).join(', ')}${b.models.length > 10 ? '...' : ''}`);
    });

    return vehicleData;
}

function generateSeedScript(data) {
    return `/**
 * Firebase Seed Script - Auto-generated from CarDekho scrape
 * Generated on: ${new Date().toISOString()}
 *
 * Usage:
 * 1. npm install firebase-admin
 * 2. export GOOGLE_APPLICATION_CREDENTIALS="./serviceAccountKey.json"
 * 3. node seed_firebase_scraped.js
 */

const admin = require('firebase-admin');

admin.initializeApp({
    credential: admin.credential.applicationDefault()
});

const db = admin.firestore();

const vehicleMakes = ${JSON.stringify(data, null, 2)};

async function seedDatabase() {
    console.log('Starting to seed vehicle_makes collection...\\n');

    const batch = db.batch();

    for (const make of vehicleMakes) {
        const docRef = db.collection('vehicle_makes').doc(make.id);
        batch.set(docRef, {
            name: make.name,
            country: make.country,
            models: make.models,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(\`  Added: \${make.name} (\${make.models.length} models)\`);
    }

    await batch.commit();
    console.log(\`\\n✓ Successfully seeded \${vehicleMakes.length} makes to Firestore!\`);
    process.exit(0);
}

seedDatabase().catch((error) => {
    console.error('Error seeding database:', error);
    process.exit(1);
});
`;
}

// Run
scrapeCarDekho().catch(console.error);

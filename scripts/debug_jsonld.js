const puppeteer = require('puppeteer');

function findKey(obj, key) {
    if (!obj || typeof obj !== 'object') return null;
    if (obj[key] !== undefined) return obj[key];
    for (const k of Object.keys(obj)) {
        const result = findKey(obj[k], key);
        if (result) return result;
    }
    return null;
}

(async () => {
    const browser = await puppeteer.launch({ headless: 'new' });
    const page = await browser.newPage();

    await page.goto('https://www.carwale.com/maruti-suzuki-cars/swift/', {
        waitUntil: 'domcontentloaded',
        timeout: 30000
    });

    const jsonldData = await page.evaluate(() => {
        const scripts = document.querySelectorAll('script[type="application/ld+json"]');
        const results = [];
        for (const script of scripts) {
            try {
                results.push(JSON.parse(script.textContent));
            } catch (e) {}
        }
        return results;
    });

    console.log('Found', jsonldData.length, 'JSON-LD blocks');

    for (let i = 0; i < jsonldData.length; i++) {
        console.log(`\n--- Block ${i + 1} ---`);
        const data = jsonldData[i];

        const fc = findKey(data, 'fuelCapacity');
        const fe = findKey(data, 'fuelEfficiency');
        const ft = findKey(data, 'fuelType');

        if (fc) console.log('fuelCapacity:', JSON.stringify(fc));
        if (fe) console.log('fuelEfficiency:', JSON.stringify(fe));
        if (ft) console.log('fuelType:', JSON.stringify(ft));

        // Also check for fuel in the stringified version
        const str = JSON.stringify(data);
        if (str.includes('fuel') || str.includes('capacity') || str.includes('tank')) {
            console.log('Contains fuel/capacity/tank keywords');
        }
    }

    await browser.close();
})();

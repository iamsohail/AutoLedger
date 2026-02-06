/**
 * Quick test of tank capacity scraper on a few models
 */

const puppeteer = require('puppeteer');

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const TEST_MODELS = [
    { brand: 'maruti-suzuki', model: 'swift' },
    { brand: 'hyundai', model: 'creta' },
    { brand: 'tata', model: 'nexon' },
    { brand: 'mahindra', model: 'thar' },
    { brand: 'honda', model: 'city' }
];

async function testScrape() {
    console.log('🧪 Testing tank capacity scraper on sample models...\n');

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox']
    });

    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)');

    for (const { brand, model } of TEST_MODELS) {
        console.log(`\n📍 Testing ${brand}/${model}`);

        const url = `https://www.cardekho.com/${brand}/${model}`;
        console.log(`   URL: ${url}`);

        try {
            await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 20000 });
            await delay(1500);

            // Get page title to verify we're on right page
            const title = await page.title();
            console.log(`   Title: ${title.substring(0, 60)}...`);

            // Extract specs from page
            const data = await page.evaluate(() => {
                const pageText = document.body.innerText;

                // Look for fuel tank capacity
                let tankCapacity = null;
                const tankPatterns = [
                    /fuel\s*tank\s*(?:capacity)?\s*[:\-]?\s*(\d+(?:\.\d+)?)\s*(?:l(?:itres?)?|ltr)/gi,
                    /(\d+(?:\.\d+)?)\s*(?:l(?:itres?)?|ltr)\s*(?:fuel)?\s*tank/gi,
                    /tank\s*capacity[^0-9]*(\d+(?:\.\d+)?)/gi
                ];

                for (const pattern of tankPatterns) {
                    const matches = [...pageText.matchAll(pattern)];
                    for (const match of matches) {
                        const val = parseFloat(match[1]);
                        if (val >= 20 && val <= 100) {
                            tankCapacity = val;
                            break;
                        }
                    }
                    if (tankCapacity) break;
                }

                // Find relevant text snippets mentioning tank/fuel
                const lines = pageText.split('\n')
                    .filter(l => l.toLowerCase().includes('fuel') || l.toLowerCase().includes('tank'))
                    .filter(l => l.length < 100)
                    .slice(0, 5);

                return {
                    tankCapacity,
                    relevantLines: lines
                };
            });

            console.log(`   Tank Capacity: ${data.tankCapacity ? data.tankCapacity + 'L' : 'Not found'}`);
            if (data.relevantLines.length > 0) {
                console.log(`   Relevant text found:`);
                data.relevantLines.forEach(l => console.log(`     - "${l.trim().substring(0, 70)}..."`));
            }

        } catch (error) {
            console.log(`   Error: ${error.message}`);
        }
    }

    await browser.close();
    console.log('\n✅ Test complete');
}

testScrape().catch(console.error);

/**
 * Test with better JavaScript wait handling
 */

const puppeteer = require('puppeteer');

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function test() {
    console.log('🧪 Testing with better JS handling...\n');

    const browser = await puppeteer.launch({
        headless: false, // Show browser for debugging
        args: ['--no-sandbox']
    });

    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36');
    await page.setViewport({ width: 1280, height: 800 });

    const url = 'https://www.cardekho.com/maruti-suzuki/swift/specifications';
    console.log(`Loading: ${url}`);

    try {
        await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });

        // Wait for content to load
        console.log('Waiting for content...');
        await delay(5000);

        // Try to find specs section
        const specs = await page.evaluate(() => {
            const text = document.body.innerText;

            // Look for tank capacity
            let tank = null;
            const tankMatch = text.match(/fuel\s*tank\s*capacity[^\d]*(\d+(?:\.\d+)?)\s*(?:litres?|L|ltr)/i);
            if (tankMatch) tank = parseFloat(tankMatch[1]);

            // Find all numbers followed by L/litres
            const allLitres = [];
            const regex = /(\d+(?:\.\d+)?)\s*(?:litres?|L(?:tr)?)\b/gi;
            let match;
            while ((match = regex.exec(text)) !== null) {
                const val = parseFloat(match[1]);
                if (val >= 20 && val <= 100) {
                    allLitres.push({ value: val, context: text.substring(Math.max(0, match.index - 30), match.index + 40) });
                }
            }

            return {
                title: document.title,
                textLength: text.length,
                tankCapacity: tank,
                allLitreValues: allLitres.slice(0, 5)
            };
        });

        console.log(`\nResults:`);
        console.log(`  Title: ${specs.title}`);
        console.log(`  Text length: ${specs.textLength}`);
        console.log(`  Tank capacity found: ${specs.tankCapacity || 'No'}`);
        console.log(`  Litre values found: ${specs.allLitreValues.length}`);
        specs.allLitreValues.forEach(v => {
            console.log(`    - ${v.value}L: "${v.context.replace(/\s+/g, ' ')}"`);
        });

    } catch (error) {
        console.log(`Error: ${error.message}`);
    }

    // Keep browser open for 10 seconds to inspect
    console.log('\nBrowser will close in 10 seconds...');
    await delay(10000);

    await browser.close();
}

test().catch(console.error);

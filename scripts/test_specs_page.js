/**
 * Test scraping specs from detailed pages
 */

const puppeteer = require('puppeteer');

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function testSpecsPages() {
    console.log('🧪 Testing specs pages...\n');

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox']
    });

    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)');

    // Test URLs that should have tank capacity
    const testUrls = [
        'https://www.cardekho.com/maruti-suzuki/swift/specifications',
        'https://www.cardekho.com/hyundai/creta/specifications',
        'https://www.cardekho.com/tata/nexon/specs',
        'https://www.cardekho.com/maruti-suzuki/swift/vxi-amt/specifications'
    ];

    for (const url of testUrls) {
        console.log(`\n📍 Testing: ${url}`);

        try {
            await page.goto(url, { waitUntil: 'networkidle0', timeout: 30000 });
            await delay(2000);

            const title = await page.title();
            console.log(`   Title: ${title.substring(0, 50)}...`);

            // Check page content for tank capacity
            const data = await page.evaluate(() => {
                const pageText = document.body.innerText;

                // Look for "Fuel Tank Capacity" specifically
                let tankCapacity = null;
                let context = '';

                // Method 1: Find in page text
                const lines = pageText.split('\n');
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].toLowerCase();
                    if (line.includes('fuel tank') || line.includes('tank capacity')) {
                        context = lines.slice(Math.max(0, i-1), i+3).join(' | ');
                        const match = context.match(/(\d+(?:\.\d+)?)\s*(?:l(?:itres?)?|ltr)/i);
                        if (match) {
                            tankCapacity = parseFloat(match[1]);
                        }
                        break;
                    }
                }

                // Method 2: Look for spec table rows
                document.querySelectorAll('tr').forEach(row => {
                    const text = row.innerText.toLowerCase();
                    if (text.includes('fuel tank') && !tankCapacity) {
                        const match = row.innerText.match(/(\d+(?:\.\d+)?)\s*(?:l(?:itres?)?|ltr)/i);
                        if (match) {
                            tankCapacity = parseFloat(match[1]);
                            context = row.innerText.substring(0, 100);
                        }
                    }
                });

                // Method 3: Look for elements containing "litres" or "L"
                if (!tankCapacity) {
                    const allElements = document.querySelectorAll('div, span, td, p');
                    for (const el of allElements) {
                        const text = el.innerText;
                        if (text.length < 50 && /^\d{2,3}\s*(l|litres?|ltr)\s*$/i.test(text.trim())) {
                            tankCapacity = parseFloat(text);
                            context = el.closest('tr, .row')?.innerText?.substring(0, 100) || text;
                            break;
                        }
                    }
                }

                return { tankCapacity, context, pageTextLength: pageText.length };
            });

            console.log(`   Page text length: ${data.pageTextLength} chars`);
            console.log(`   Tank Capacity: ${data.tankCapacity ? data.tankCapacity + 'L' : 'Not found'}`);
            if (data.context) {
                console.log(`   Context: "${data.context.substring(0, 80)}..."`);
            }

        } catch (error) {
            console.log(`   Error: ${error.message}`);
        }
    }

    await browser.close();
    console.log('\n✅ Test complete');
}

testSpecsPages().catch(console.error);

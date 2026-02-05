/**
 * Enhance vehicle data with well-known discontinued models
 * These are cars people still own in India
 */

const fs = require('fs');

// Load scraped data
const scrapedData = require('./cardekho_vehicles.json');

// Additional discontinued models to add (commonly owned in India)
const additionalModels = {
    'maruti_suzuki': [
        '800', 'Zen', 'Zen Estilo', 'Esteem', 'Baleno', 'SX4', 'Kizashi',
        'A-Star', 'Ritz', 'Omni', 'Versa', 'Gypsy', 'Grand Vitara',
        'Celerio', 'Celerio X', 'Ciaz', 'Ignis', 'S-Cross', 'Ertiga', 'XL6'
    ],
    'tata': [
        'Indica', 'Indica Vista', 'Indigo', 'Indigo eCS', 'Indigo Marina',
        'Nano', 'Nano GenX', 'Bolt', 'Zest', 'Manza', 'Aria', 'Sumo',
        'Sumo Grande', 'Sumo Gold', 'Sierra', 'Estate', 'Hexa', 'Safari Storme',
        'Safari Dicor', 'Tiago', 'Xenon', 'Movus', 'Venture'
    ],
    'mahindra': [
        'Xylo', 'Verito', 'Verito Vibe', 'Logan', 'Quanto', 'NuvoSport',
        'TUV300', 'TUV300 Plus', 'KUV100', 'e2o', 'e2o Plus', 'Reva',
        'Scorpio Classic', 'Scorpio Getaway', 'Gio', 'Maxximo', 'Supro',
        'Commander', 'Marshal', 'Armada', 'CL', 'MM', 'Jeep', 'Major'
    ],
    'hyundai': [
        'Santro', 'Santro Xing', 'i10', 'Grand i10', 'Eon', 'Getz', 'Getz Prime',
        'Accent', 'Verna Transform', 'Sonata', 'Sonata Embera', 'Elantra',
        'Terracan', 'Tucson', 'Santa Fe', 'Elite i20', 'Active i20', 'Xcent'
    ],
    'honda': [
        'Brio', 'Mobilio', 'BR-V', 'CR-V', 'Civic', 'Accord', 'Jazz (Old)',
        'City (Gen 1-4)', 'City VTEC', 'City ZX'
    ],
    'toyota': [
        'Etios', 'Etios Liva', 'Etios Cross', 'Corolla', 'Corolla Altis',
        'Prius', 'Prado', 'Qualis', 'Innova (Old)', 'Land Cruiser Prado'
    ],
    'ford': [
        'Figo', 'Figo Aspire', 'Aspire', 'EcoSport', 'Endeavour', 'Freestyle',
        'Fiesta', 'Fiesta Classic', 'Classic', 'Fusion', 'Ikon', 'Mondeo',
        'Mustang', 'Focus', 'Escort'
    ],
    'chevrolet': [
        'Spark', 'Beat', 'Sail', 'Sail U-VA', 'Enjoy', 'Cruze', 'Captiva',
        'Tavera', 'Trailblazer', 'Aveo', 'Aveo U-VA', 'Optra', 'Optra Magnum',
        'Optra SRV', 'Forester'
    ],
    'fiat': [
        'Punto', 'Punto Evo', 'Linea', 'Linea Classic', 'Avventura',
        'Avventura Urban Cross', 'Grande Punto', 'Palio', 'Palio Stile',
        'Palio Adventure', 'Petra', 'Siena', 'Uno', '500', '500 Abarth'
    ],
    'volkswagen': [
        'Polo', 'Polo GT', 'Polo GTI', 'Vento', 'Jetta', 'Passat', 'Beetle',
        'Cross Polo', 'Ameo'
    ],
    'skoda': [
        'Fabia', 'Fabia Scout', 'Rapid', 'Laura', 'Yeti', 'Octavia vRS'
    ],
    'renault': [
        'Duster', 'Kwid', 'Lodgy', 'Scala', 'Pulse', 'Fluence', 'Koleos',
        'Captur'
    ],
    'nissan': [
        'Micra', 'Micra Active', 'Sunny', 'Terrano', 'Evalia', 'X-Trail',
        '370Z', 'GT-R', 'Kicks', 'Teana'
    ],
    'datsun': [
        'Go', 'Go Plus', 'redi-GO', 'Go Cross'
    ],
    'mitsubishi': [
        'Pajero', 'Pajero Sport', 'Outlander', 'Lancer', 'Cedia', 'Montero'
    ],
    'mercedes_benz': [
        'C-Class', 'A-Class', 'B-Class', 'CLA', 'CLS', 'SLK', 'SLC',
        'GL-Class', 'M-Class', 'R-Class'
    ],
    'bmw': [
        '1 Series', '3 Series GT', '5 Series GT', '6 Series', '6 Series GT',
        'X6', 'X6 M'
    ],
    'audi': [
        'A3', 'A3 Cabriolet', 'A5', 'A5 Cabriolet', 'A6', 'A7', 'TT',
        'Q3 (Old)', 'Q5 (Old)', 'Q7 (Old)', 'R8', 'RS6', 'RS7'
    ],
    'hindustan_motors': [
        'Ambassador', 'Ambassador Classic', 'Ambassador Grand',
        'Ambassador Avigo', 'Contessa', 'Contessa Classic'
    ],
    'premier': [
        'Padmini', 'Premier 118NE', 'Premier 137', 'Rio'
    ]
};

// Merge additional models with scraped data
const enhancedData = scrapedData.map(brand => {
    const additions = additionalModels[brand.id] || [];
    if (additions.length === 0) return brand;

    // Combine existing and additional models
    const allModels = new Set([...brand.models, ...additions]);

    // Remove 'Other' if we have real models
    allModels.delete('Other');

    // Sort alphabetically
    const sortedModels = Array.from(allModels).sort((a, b) => a.localeCompare(b));

    return {
        ...brand,
        models: sortedModels
    };
});

// Convert to the format expected by the iOS app
const iosFormat = {
    makes: enhancedData.map(brand => ({
        id: brand.id,
        name: brand.name,
        country: brand.country,
        models: brand.models
    }))
};

// Save enhanced data
fs.writeFileSync('./cardekho_vehicles_enhanced.json', JSON.stringify(enhancedData, null, 2));
console.log('✅ Enhanced data saved to cardekho_vehicles_enhanced.json');

// Save iOS format
fs.writeFileSync('../AutoLedger/Resources/IndianVehicleData.json', JSON.stringify(iosFormat, null, 2));
console.log('✅ iOS app data updated at AutoLedger/Resources/IndianVehicleData.json');

// Summary
const totalModels = enhancedData.reduce((sum, b) => sum + b.models.length, 0);
console.log(`\n📊 Summary:`);
console.log(`   Total brands: ${enhancedData.length}`);
console.log(`   Total models: ${totalModels}`);

// Show sample
console.log('\n📋 Sample (showing added discontinued models):');
['ford', 'chevrolet', 'maruti_suzuki', 'tata'].forEach(id => {
    const brand = enhancedData.find(b => b.id === id);
    if (brand) {
        console.log(`\n   ${brand.name}: ${brand.models.length} models`);
        console.log(`   ${brand.models.slice(0, 15).join(', ')}${brand.models.length > 15 ? '...' : ''}`);
    }
});

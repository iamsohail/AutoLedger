# Auto Ledger - Session Notes

**Last Updated:** February 5, 2026
**Repository:** https://github.com/iamsohail/AutoLedger

---

## Project Overview

**Auto Ledger** is an iOS app for all-in-one vehicle management, including:
- Fuel expense tracking with mileage calculations
- Maintenance schedule and cost tracking
- Trip logging
- Document storage
- Multi-vehicle support

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI |
| Data Persistence | SwiftData (iOS 17+) |
| Architecture | MVVM |
| Cloud Database | Firebase Firestore |
| Project Generation | XcodeGen |
| Minimum iOS | 17.0 |
| Bundle ID | com.iamsohail.AutoLedger |

---

## What Has Been Completed

### 1. Project Setup ✅
- Created Xcode project using XcodeGen (`project.yml`)
- Set up SwiftData models for all entities
- Configured GitHub repository with proper structure
- Added entitlements for CloudKit (currently disabled)

### 2. Data Models ✅
All models created in `/AutoLedger/Models/`:
- `Vehicle.swift` - Core vehicle entity with relationships
- `FuelEntry.swift` - Fuel fillup records
- `MaintenanceRecord.swift` - Service/repair records
- `MaintenanceSchedule.swift` - Scheduled maintenance items
- `Trip.swift` - Trip logging
- `Expense.swift` - General expenses
- `Document.swift` - Document storage

### 3. Views ✅
Created views in `/AutoLedger/Views/`:
- **Dashboard:** `DashboardView.swift` - Main overview
- **Vehicles:** `AddVehicleView.swift`, `EditVehicleView.swift`, `VehicleListView.swift`, `VehicleDetailView.swift`
- **Fuel:** `FuelLogView.swift`, `AddFuelEntryView.swift`
- **Maintenance:** `MaintenanceListView.swift`, `AddMaintenanceRecordView.swift`
- **Trips:** `TripListView.swift`, `StartTripView.swift`, `EndTripView.swift`
- **Settings:** `SettingsView.swift`
- **Components:** `EmptyStateView.swift`, `StatCard.swift`

### 4. Services ✅
- `FirebaseVehicleService.swift` - Fetches vehicle makes/models from Firestore
- `DataExportService.swift` - Export data functionality

### 5. Firebase Integration ✅
- Added Firebase SDK dependency in `project.yml`
- Created `FirebaseVehicleService` for cloud vehicle database
- Integrated into `AutoLedgerApp.swift` with automatic fetching
- Created fallback to local JSON if Firebase unavailable

### 6. Web Scraper ✅
Created CarDekho scraper in `/scripts/`:
- `scrape_cardekho.js` - Puppeteer-based scraper
- Scrapes 33 brands, 294+ models from cardekho.com
- Auto-generates Firebase seed script
- `cardekho_vehicles.json` - Scraped data output
- `seed_firebase_scraped.js` - Auto-generated Firebase seeder

### 7. Local Fallback Data ✅
- `IndianVehicleData.json` in Resources - Bundled vehicle data
- Used when Firebase is unavailable or offline

---

## What Is Left To Do

### High Priority - Firebase Setup 🔴

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create project named "AutoLedger"
   - Add iOS app with bundle ID: `com.iamsohail.AutoLedger`

2. **Download & Add Config File**
   - Download `GoogleService-Info.plist`
   - Add to: `AutoLedger/AutoLedger/Resources/GoogleService-Info.plist`

3. **Enable Firestore**
   - In Firebase Console: Build → Firestore Database
   - Create database in test mode
   - Select `asia-south1` region (India)

4. **Seed the Database**
   ```bash
   cd scripts
   npm install firebase-admin  # Already installed
   # Download service account key from Firebase Console
   export GOOGLE_APPLICATION_CREDENTIALS="./serviceAccountKey.json"
   node seed_firebase_scraped.js
   ```

5. **Regenerate & Build**
   ```bash
   xcodegen generate
   # Open in Xcode and build
   ```

### Medium Priority - App Enhancements 🟡

1. **Add Missing Models to Scraper**
   - Some popular models may be missing (Baleno, Grand Vitara, Celerio)
   - Review `cardekho_vehicles.json` and add manually if needed

2. **Implement Remaining Features**
   - Document upload/storage view
   - Expense tracking view
   - Data export functionality (CSV/PDF)
   - Fuel efficiency charts/graphs

3. **UI Polish**
   - Add app icon and launch screen
   - Improve empty states
   - Add haptic feedback
   - Dark mode testing

### Low Priority - Future Enhancements 🟢

1. **CloudKit Sync** (Optional)
   - Re-enable CloudKit for cross-device sync
   - Requires fixing inverse relationships

2. **Notifications**
   - Maintenance reminders
   - Insurance/document expiry alerts

3. **Widgets**
   - Home screen widget for quick stats

4. **Apple Watch App**
   - Quick fuel logging from watch

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen project configuration |
| `AutoLedgerApp.swift` | App entry point, Firebase init |
| `FirebaseVehicleService.swift` | Firebase Firestore service |
| `AddVehicleView.swift` | Vehicle creation with make/model picker |
| `Vehicle.swift` | Core vehicle model |
| `FIREBASE_SETUP.md` | Detailed Firebase setup guide |
| `scripts/scrape_cardekho.js` | Web scraper for vehicle data |
| `scripts/seed_firebase.js` | Manual Firebase seed script |
| `scripts/seed_firebase_scraped.js` | Auto-generated seed from scrape |

---

## Commands Quick Reference

```bash
# Generate Xcode project
xcodegen generate

# Build project
xcodebuild -project AutoLedger.xcodeproj -scheme AutoLedger -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run in simulator
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/AutoLedger-*/Build/Products/Debug-iphonesimulator/AutoLedger.app
xcrun simctl launch booted com.iamsohail.AutoLedger

# Run scraper (from scripts directory)
cd scripts && node scrape_cardekho.js

# Seed Firebase (after setup)
export GOOGLE_APPLICATION_CREDENTIALS="./serviceAccountKey.json"
node seed_firebase_scraped.js
```

---

## Known Issues

1. **Firebase SDK disabled** - SPM has submodule clone failures; using local data only for now
2. **Some models may be missing** - Scraper may not capture all models due to dynamic page loading
3. **CloudKit disabled** - Disabled due to SwiftData compatibility issues

### Firebase SPM Issue Details
The Firebase iOS SDK package fails to resolve due to git submodule cloning errors:
```
Failed to clone 'Sources/protobuf/protobuf'
Couldn't update repository submodules
```
**Workaround:** Firebase is commented out in `project.yml`. App uses local `IndianVehicleData.json`.

---

## Session Summary (Feb 5, 2026)

### What We Did Today:
1. Continued from previous session with Firebase integration
2. Built and verified the app compiles successfully
3. Created CarDekho web scraper using Puppeteer
4. Scraped 33 vehicle brands with 294 models
5. Fixed scraper issues (Maruti URL pattern, noise filtering, year ranges)
6. Generated Firebase seed script from scraped data
7. Encountered Firebase SDK SPM resolution issues (submodule clone failures)
8. Temporarily disabled Firebase, app now uses local JSON data
9. Successfully ran app in iPhone 17 simulator
10. Committed all changes to GitHub

### Tomorrow's First Steps:
1. Try to resolve Firebase SPM issues (clear caches, try different network)
2. If Firebase still fails, consider CocoaPods as alternative
3. Test the app functionality with local vehicle data
4. Continue with remaining feature implementation

---

*This file should be updated at the end of each session.*

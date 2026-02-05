# Auto Ledger - Session Notes

**Last Updated:** February 6, 2026
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
| Authentication | Firebase Auth (Email, Google, Apple, Phone) |
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
- `UserProfile.swift` - User profile data

### 3. Views ✅
Created views in `/AutoLedger/Views/`:
- **Dashboard:** `DashboardView.swift` - Main overview with gauges
- **Vehicles:** `AddVehicleView.swift`, `EditVehicleView.swift`, `VehicleListView.swift`, `VehicleDetailView.swift`, `OnboardingView.swift`
- **Fuel:** `FuelLogView.swift`, `AddFuelEntryView.swift`
- **Maintenance:** `MaintenanceListView.swift`, `AddMaintenanceRecordView.swift`
- **Trips:** `TripListView.swift`, `StartTripView.swift`, `EndTripView.swift`
- **Settings:** `SettingsView.swift`
- **Auth:** `SignInView.swift`, `ProfileCompletionView.swift`, `PhoneAuthView.swift`
- **Components:** `EmptyStateView.swift`, `StatCard.swift`, `CircularGaugeView.swift`, `SpeedometerGaugeView.swift`, `GreetingHeaderView.swift`, `VehicleHeroCard.swift`, `DarkFeatureRow.swift`

### 4. Services ✅
- `FirebaseVehicleService.swift` - Fetches vehicle makes/models from Firestore
- `AuthenticationService.swift` - Firebase Auth with Email, Google, Apple Sign-In, Phone OTP
- `BrandfetchService.swift` - Car brand logos with fallback initials
- `CarImageService.swift` - Vehicle images
- `TankCapacityService.swift` - Tank capacity data
- `DataExportService.swift` - Export data functionality

### 5. Firebase Integration ✅
- Firebase SDK integrated via SPM
- Firestore for vehicle database
- Firebase Auth with multiple providers (Email, Google, Apple, Phone)
- Phone OTP verification with auto-keyboard dismiss

### 6. Dark Mode UI Theme ✅
- Lamborghini-inspired dark theme
- Color palette: Primary Purple (#8364E9), Green Accent, Pink Accent
- Dark backgrounds with card styling
- Theme.swift with Typography, Spacing, CornerRadius constants
- Gradient cards and quick action buttons

### 7. Onboarding Flow ✅
- Feature showcase (Fuel, Maintenance, Trip tracking)
- Shows only for first-time users (AppStorage flag)
- Floating particle animations
- Skip button and swipeable pages

### 8. Car Brand Logos ✅
- 39 brand logos set up in Assets.xcassets/CarLogos
- SVG format with vector preservation
- White logos on black circle background (template rendering)
- Fallback to initials for missing logos

### 9. Vehicle Data ✅
- 400 models across 39 brands
- JSON structure with tankL, batteryKWh, fuelTypes, transmission
- Removed minor brands (ICML, DC)

---

## What Is Left To Do

### High Priority 🔴

1. **Fix Problematic Logos (15 brands)**
   Need white outline SVGs for these brands that don't render well with template mode:
   - Aston Martin
   - Audi
   - BMW
   - BYD
   - Bentley
   - Chevrolet
   - Ford
   - Honda
   - Kia
   - Lamborghini
   - MG
   - Mercedes-Benz
   - Mini
   - Porsche
   - Land Rover (PNG - check manually)
   - Toyota (PNG - check manually)

2. **Test Full App Flow**
   - Verify onboarding → sign-in → add vehicle → dashboard flow
   - Test all authentication methods
   - Verify vehicle data loads correctly

### Medium Priority 🟡

1. **Implement Remaining Features**
   - Document upload/storage view
   - Expense tracking view
   - Data export functionality (CSV/PDF)
   - Fuel efficiency charts/graphs

2. **UI Polish**
   - Add app icon and launch screen
   - Improve empty states
   - Add haptic feedback

### Low Priority 🟢

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
| `Theme.swift` | Dark mode colors, typography, spacing |
| `BrandfetchService.swift` | Car brand logos service |
| `AuthenticationService.swift` | Firebase Auth service |
| `SignInView.swift` | Sign-in UI with Email/Google/Apple/Phone |
| `OnboardingView.swift` | First-time user onboarding |
| `AddVehicleView.swift` | Vehicle creation with make/model picker |
| `IndianVehicleData.json` | Bundled vehicle database |
| `Assets.xcassets/CarLogos/` | Brand logo imagesets |

---

## Commands Quick Reference

```bash
# Generate Xcode project
xcodegen generate

# Build for simulator
xcodebuild -project AutoLedger.xcodeproj -scheme AutoLedger -destination 'platform=iOS Simulator,name=iPhone 17' build

# Build for device
xcodebuild -project AutoLedger.xcodeproj -scheme AutoLedger -destination 'id=00008130-001250502110001C' build

# Install on device
xcrun devicectl device install app --device 00008130-001250502110001C /path/to/AutoLedger.app

# Launch on device
xcrun devicectl device process launch --device 00008130-001250502110001C com.iamsohail.AutoLedger

# Run in simulator
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/AutoLedger-*/Build/Products/Debug-iphonesimulator/AutoLedger.app
xcrun simctl launch booted com.iamsohail.AutoLedger
```

---

## Session Summary (Feb 6, 2026)

### What We Did Today:
1. **Vehicle Data Import**
   - Imported 402 models from CSV with 41 makes
   - Fixed JSON structure (tankL, batteryKWh fields)
   - Removed ICML and DC brands (39 brands, 400 models final)

2. **Onboarding Flow Fix**
   - Made onboarding show only for first-time users
   - Added AppStorage("hasSeenOnboarding") flag
   - Removed permission request cards
   - Shows feature showcase before login

3. **Car Brand Logos Setup**
   - Set up 39 brand logos from SVG files
   - Created imagesets with vector preservation
   - Final solution: White logos (template rendering) on black circles
   - Identified 15 brands needing replacement SVGs

4. **Theme Typography**
   - Applied consistent Theme.Typography throughout
   - Title Case capitalization
   - Stat values with rounded design fonts

5. **OTP Input Enhancement**
   - Keyboard auto-dismisses when 6th digit entered

6. **Bug Fixes**
   - Fixed various build issues
   - Tested on physical device

### Pending for Next Session:
1. Find and replace 15 problematic logo SVGs (white outline versions)
2. Test complete app flow on device
3. Implement remaining features (documents, expenses, charts)
4. Add app icon and launch screen

---

*This file should be updated at the end of each session.*

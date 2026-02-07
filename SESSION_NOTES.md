# Auto Ledger - Session Notes

**Last Updated:** February 7, 2026
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
- **Dashboard:** `DashboardView.swift` - Hero card + stats + quick actions + alerts + chart + activity
- **Vehicles:** `AddVehicleView.swift` (3-step wizard), `EditVehicleView.swift`, `VehicleListView.swift`, `VehicleDetailView.swift`, `OnboardingView.swift`
- **Log (unified):** `LogView.swift` (4-segment picker) → `FuelLogContentView.swift`, `MaintenanceContentView.swift`, `TripContentView.swift`
- **Expenses:** `ExpenseListView.swift`, `AddExpenseView.swift`
- **Explore:** `ExploreView.swift` (map), `SaveParkingSpotView.swift`, `ParkingSpotDetailView.swift`
- **Vault:** `VaultView.swift` (grid/list), `AddDocumentView.swift`, `DocumentDetailView.swift`
- **Settings:** `SettingsView.swift`, `BackupSettingsView.swift`, `AISettingsView.swift`, `AboutView.swift`
- **Auth:** `SignInView.swift` (phone OTP default + email toggle), `ProfileCompletionView.swift`
- **Components:** `SummaryStatView.swift`, `CarLoadingView.swift`, `DarkFeatureRow.swift`
- **Debug:** `CarImageGalleryView.swift`

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

### Session 2 (Feb 6, 2026 — continued):

1. **Dashboard Redesign**
   - Rewrote DashboardView top sections to match reference screenshot
   - New hero card: greeting + avatar + search icon + large fuel economy metric + car image in one card
   - Vehicle info strip: "Car Number" (left) + "Your Vehicle" make (right)
   - Gradient stat cards: purple-to-pink gradient sub-cards for Fuel Spent and Service costs
   - Removed old heroCard (centered car with glow), statsRow, statTile
   - Removed separate GreetingHeaderView() call — greeting now inline in hero card
   - Added @EnvironmentObject authService to DashboardView for user profile access

2. **Car Image Generation — Batch 1 Complete (242 models)**
   - 225 reference-based (CarWale og:image + gpt-image-1 restyle)
   - 17 text-only fallbacks (discontinued/unavailable on CarWale)
   - All 1536x1024 PNG, glossy black, dark studio background

3. **Car Image Generation — Batch 2 In Progress (151 remaining models)**
   - Modified generate script: removed discontinued filter to include all 393 models
   - Resume logic skips the 244 already generated, processes remaining 149
   - Added "no license plates, no number plates" to both prompts
   - Estimated cost: ~$6 | Time: ~38 min

4. **Script Updates**
   - `generate_car_images.py`: removed `discontinued` filter, added no-plate prompt instructions
   - `optimize_car_images.py`: already handles horizontal flip (mirror to face left)

5. **Housekeeping**
   - Saved OpenAI API key to `.env` (gitignored)
   - Set up persistent memory files for Claude context across sessions
   - New services added: FirestoreSyncService, ReceiptScannerService
   - New components: CarLoadingView, DocumentScannerView

### Session 3 (Feb 7, 2026):

1. **Plus Jakarta Sans Custom Font — Attempted & Reverted**
   - Downloaded 4 TTF weights (Regular, Medium, SemiBold, Bold) from Google Fonts
   - Added to `Resources/Fonts/`, registered in `project.yml` via `UIAppFonts`
   - Updated `Theme.swift` with `font(size:weight:)` helper mapping SwiftUI weights to PostScript names
   - Updated ~13 view files replacing inline `.font(.system(...))` with custom font calls
   - Updated `UINavigationBarAppearance` and `UITabBarAppearance` with custom UIFont
   - Added runtime font verification (`NSLog` in `#if DEBUG`) — all 4 fonts confirmed loading
   - **Reverted:** Log page and other UIKit-rendered elements (nav bar titles, List section headers, tab bar labels) still showed system font. UIKit appearance APIs don't fully cover all elements. Decided to stick with SF Pro for consistency.

2. **Car Image Assets Committed**
   - 380+ AI-generated car images added to `xcassets/CarImages/` (JPG, optimized from PNG sources)
   - Covers all supported Indian market vehicles across 30+ brands

3. **Log Tab Content Views Committed**
   - Replaced old separate views (`FuelLogView`, `MaintenanceListView`, `TripListView`) with unified Log tab
   - `LogView.swift` with 4-segment picker: Fuel, Service, Expenses, Trips
   - New shared `SummaryStatView` component used across all segments
   - New `CarImageGalleryView` debug view for auditing car images

4. **Commits & Push**
   - `e116e21` — Restructure from 6 tabs to 5: Home, Log, Explore, Vault, Settings
   - `93b1b5a` — Add car image assets, Log tab content views, and utility scripts (782 files)
   - Both pushed to GitHub

### Lessons Learned (Feb 7):
- **Custom fonts in iOS** require overriding UIKit appearance APIs separately from SwiftUI `.font()`
- **`print()` doesn't appear in `log stream`** — use `NSLog()` or `os.Logger`
- **SwiftUI `.custom()` silently falls back** to system font if PostScript name is wrong
- Some UIKit elements (List section headers, search bars, alerts) **cannot be overridden** via appearance proxies

### Session 4 (Feb 8, 2026):

1. **Gradient Avatars (GradientAvatarView)**
   - Created reusable component with 12 curated gradient palettes × 4 directions = 48 combinations
   - Deterministic selection via djb2 hash of Firebase UID
   - Initials overlay with white text, falls back to person.fill icon
   - Replaced avatar in GreetingHeaderView (44pt), ProfileCompletionView (100pt), SettingsView (40pt)

2. **Gradient Spinner (GradientSpinner)**
   - Replaced car silhouette loading animation with spinning gradient arc
   - Purple→pink angular gradient, configurable size and stroke width
   - Used in splash screen, AddVehicleView, and CarLoadingOverlay

3. **Empty State Redesign**
   - Redesigned "No Vehicles Yet" page with greeting, gradient glow icon, feature chips, gradient CTA button
   - Feature chips match onboarding card colors: Fuel=green, Service=orange, Trips=purple, Docs=cyan
   - Auto-presents AddVehicleView after onboarding via fullScreenCover

4. **Onboarding — Document Vault Card**
   - Added 4th onboarding page for Document Vault with Cyan/Teal (#00BCD4) color
   - Consistent color across onboarding card, empty state chip, and feature references

5. **Brand Logo Fixes**
   - Fixed Citroën, MINI, Škoda display: diacritics normalization + asset name overrides
   - Added Tesla logo (SVG)
   - Detailed logos (BMW, Datsun, Porsche, Bentley): grayscale + contrast for monochrome consistency
   - Simple logos: white template on black circle

6. **FuelType Mapping Bug Fix**
   - Fixed "Petrol, Diesel, Petrol" duplicate — `"strong hybrid"` was falling through to default `.petrol`
   - Added mappings for "strong hybrid", "mild hybrid", "plug-in hybrid", "hydrogen", "flex fuel"
   - Added deduplication with `.uniqued()` extension

7. **Model Selection Page Redesign**
   - Replaced text nav title with brand logo (56pt) in toolbar
   - Removed fuel type chips from model cards
   - Removed card backgrounds — images sit directly on dark page (seamless blending)
   - Model name as minimal caption below image
   - Added search bar for brands with 6+ models
   - Color-coded fuel chip helper (kept for future use)

8. **Theme Compliance**
   - Replaced all raw `.font(.system(...))` with Theme.Typography tokens
   - Replaced raw spacing/radius values with Theme.Spacing/CornerRadius tokens
   - Title Case capitalization with Your/You capitalized (matching existing codebase)

9. **Sign-In View Updates**
   - Various auth flow improvements

### Pending for Next Session:
1. Test complete app flow on device
2. UI polish — remaining spacing/layout tweaks
3. Implement remaining features (data export, fuel efficiency charts)
4. `CarImages/` root directory (387 source PNGs) — add to `.gitignore` or separate storage

---

*This file should be updated at the end of each session.*

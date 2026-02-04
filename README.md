# Auto Ledger

An all-in-one iOS vehicle management app for tracking fuel expenses, mileage, maintenance schedules, and more.

## Features

### Fuel Tracking
- Log fuel fill-ups with date, odometer, quantity, and price
- Calculate fuel economy (MPG)
- Track fuel expenses over time
- Support for different fuel grades

### Maintenance Management
- Schedule and track vehicle maintenance
- Pre-defined service types (oil change, tire rotation, etc.)
- Custom service entries
- Cost tracking with labor/parts breakdown
- Service provider contacts

### Trip Logging
- Track business and personal trips
- IRS mileage rate calculations for tax purposes
- Start/end trip functionality
- Distance and reimbursement tracking

### Expense Tracking
- Categorize vehicle expenses (insurance, registration, parking, etc.)
- Total cost of ownership calculations
- Monthly/yearly summaries

### Additional Features
- Multiple vehicle support
- Document storage (insurance cards, registration, receipts)
- Expiration reminders for documents
- iCloud sync across devices
- Data export (CSV, JSON)

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Architecture

- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Architecture Pattern**: MVVM
- **Cloud Sync**: CloudKit

## Project Structure

```
AutoLedger/
├── App/
│   ├── AutoLedgerApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Vehicle.swift
│   ├── FuelEntry.swift
│   ├── MaintenanceRecord.swift
│   ├── MaintenanceSchedule.swift
│   ├── Trip.swift
│   ├── Expense.swift
│   └── Document.swift
├── Views/
│   ├── Dashboard/
│   ├── Vehicles/
│   ├── Fuel/
│   ├── Maintenance/
│   ├── Trips/
│   ├── Settings/
│   └── Components/
├── Services/
│   ├── NotificationService.swift
│   └── DataExportService.swift
├── Utilities/
│   ├── Extensions.swift
│   └── Constants.swift
└── Resources/
    └── Assets.xcassets/
```

## Setup

1. Clone the repository
2. Open `AutoLedger.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run on simulator or device

## Data Models

### Vehicle
- Name, make, model, year
- VIN, license plate
- Fuel type, tank capacity
- Odometer tracking
- Insurance and registration details

### FuelEntry
- Date, odometer reading
- Quantity, price per unit
- Fuel grade, station location
- Full tank indicator for MPG calculation

### MaintenanceRecord
- Service type and date
- Cost breakdown (labor, parts)
- Service provider details
- Odometer at service

### Trip
- Start/end odometer
- Trip type (business, personal, etc.)
- Purpose and location
- Tax deduction tracking

## License

MIT License

## Version History

- **1.0.0** - Initial release
  - Vehicle management
  - Fuel tracking
  - Maintenance logging
  - Trip tracking
  - iCloud sync

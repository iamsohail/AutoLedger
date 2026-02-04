# Firebase Setup Guide for Auto Ledger

This guide walks you through setting up Firebase Firestore for the vehicle database.

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add Project"**
3. Name it `AutoLedger` (or any name you prefer)
4. Disable Google Analytics (optional)
5. Click **"Create Project"**

## Step 2: Add iOS App to Firebase

1. In your Firebase project, click the iOS icon to add an iOS app
2. Enter the Bundle ID: `com.iamsohail.AutoLedger`
3. Enter App nickname: `Auto Ledger`
4. Click **"Register app"**
5. Download `GoogleService-Info.plist`
6. Move the file to: `AutoLedger/AutoLedger/Resources/GoogleService-Info.plist`

## Step 3: Enable Firestore

1. In Firebase Console, go to **Build → Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
4. Select a location (asia-south1 for India)
5. Click **"Enable"**

## Step 4: Set Firestore Rules

In Firestore, go to **Rules** tab and set:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Vehicle makes collection - read-only for app users
    match /vehicle_makes/{makeId} {
      allow read: if true;
      allow write: if false; // Only admin can write
    }
  }
}
```

Click **"Publish"** to save.

## Step 5: Seed the Database

### Option A: Using Firebase Console (Manual)

1. Go to **Firestore Database**
2. Click **"Start collection"**
3. Collection ID: `vehicle_makes`
4. Add documents for each make (see data below)

### Option B: Using Node.js Script (Automated)

1. Install Firebase CLI and Admin SDK:
```bash
npm install -g firebase-tools
npm install firebase-admin
```

2. Login to Firebase:
```bash
firebase login
```

3. Get service account key:
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save as `serviceAccountKey.json` in the `scripts` folder

4. Run the seed script:
```bash
cd scripts
export GOOGLE_APPLICATION_CREDENTIALS="./serviceAccountKey.json"
node seed_firebase.js
```

## Step 6: Verify in Xcode

1. Open the project in Xcode
2. Ensure `GoogleService-Info.plist` is in the project
3. Build and run
4. The app should now fetch vehicle data from Firestore

## Firestore Data Structure

```
vehicle_makes/
├── maruti_suzuki/
│   ├── name: "Maruti Suzuki"
│   ├── country: "India"
│   ├── models: ["Alto K10", "Swift", "Dzire", ...]
│   └── updatedAt: <timestamp>
├── tata/
│   ├── name: "Tata Motors"
│   ├── country: "India"
│   ├── models: ["Tiago", "Nexon", "Harrier", ...]
│   └── updatedAt: <timestamp>
└── ... (more makes)
```

## Adding New Vehicles

To add a new make or model:

1. Go to Firebase Console → Firestore
2. Navigate to `vehicle_makes` collection
3. Either:
   - Add new document for a new make
   - Edit existing document to add models to the `models` array

Changes are reflected in the app immediately (or on next refresh).

## Production Security Rules

For production, update Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /vehicle_makes/{makeId} {
      allow read: if true;
      allow write: if request.auth != null &&
                     request.auth.token.admin == true;
    }
  }
}
```

## Troubleshooting

### App shows "Failed to fetch makes"
- Check internet connection
- Verify `GoogleService-Info.plist` is correctly placed
- Check Firestore rules allow read access

### Empty dropdown
- Ensure Firestore has data in `vehicle_makes` collection
- Check console logs for errors
- Try refreshing the app

### Build errors
- Run `xcodegen generate` to regenerate project
- Clean build folder (Cmd + Shift + K)
- Resolve Swift Package Manager dependencies

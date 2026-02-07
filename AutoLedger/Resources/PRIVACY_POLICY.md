# Privacy Policy

**AutoLedger - Vehicle Management App**
**Last Updated:** February 7, 2026
**Effective Date:** February 7, 2026

---

## 1. Introduction

AutoLedger ("we", "our", "the App") is committed to protecting your privacy. This Privacy Policy explains what data we collect, how we use it, and your rights regarding your personal information.

## 2. Data We Collect

### 2.1. Account Information
- **Name** (provided during sign-up or profile completion)
- **Email address** (for email-based authentication)
- **Phone number** (for OTP-based authentication)
- **Profile photo** (optional, user-uploaded)
- **Authentication provider** (Email, Google, Apple, or Phone)

### 2.2. Vehicle Data
- Vehicle specifications (make, model, year, color, VIN, license plate)
- Purchase details (date, price)
- Insurance information (provider, policy number, expiration)
- Registration details (state, expiration)
- Odometer readings
- Vehicle images

### 2.3. Transaction Records
- **Fuel entries:** Date, quantity, price, fuel grade, station name, location
- **Maintenance records:** Date, service type, costs, service provider details, receipt images
- **Trips:** Date, distance, type (business/personal), start and end locations
- **Expenses:** Date, category, amount, vendor, description
- **Documents:** Name, type, expiration date, images, and PDFs

### 2.4. Location Data
- Current device location (only when you explicitly request it)
- Parking spot coordinates (saved by you)
- Trip start and end locations (entered by you)
- Fuel station and service provider locations (entered by you)

### 2.5. Device and Usage Data
- Device type and operating system version
- App version
- Last sync timestamps

## 3. How We Use your Data

We use the collected data solely to:
- Provide and maintain the App's core functionality
- Authenticate your identity and secure your account
- Sync your data across your devices via cloud backup
- Calculate fuel economy, expense totals, and maintenance schedules
- Send maintenance and document expiration reminders
- Process receipt images for data extraction (only when you initiate a scan)

**We do not use your data for advertising, profiling, or selling to third parties.**

## 4. Data Storage

### 4.1. On-Device Storage
Your data is stored locally on your device using Apple's SwiftData framework. This data remains on your device and is protected by your device's built-in security (passcode, Face ID, Touch ID).

### 4.2. Cloud Storage
When you enable cloud sync, your data is stored in Google Firebase Firestore. Data is:
- Encrypted in transit using HTTPS/TLS
- Isolated under your unique user ID (no other user can access your data)
- Stored in Firebase's secure infrastructure (see [Firebase Security](https://firebase.google.com/support/privacy))

### 4.3. Secure Credential Storage
Sensitive credentials (such as your optional OpenAI API key) are stored in your device's Keychain, Apple's encrypted credential storage system. These are never transmitted to our servers.

## 5. Third-Party Data Sharing

### 5.1. Data We Do NOT Share
- Your personal information (name, email, phone) is never sold to or shared with advertisers or data brokers
- Your vehicle data, financial records, and documents are never shared with third parties for their own purposes

### 5.2. Data Shared with Service Providers
We share limited data with the following service providers solely to operate the App:

| Service Provider | Data Shared | Purpose |
|---|---|---|
| **Firebase (Google)** | Account info, synced app data | Authentication, cloud storage and sync |
| **Google Sign-In** | OAuth token | Account authentication |
| **Apple Sign-In** | OAuth token | Account authentication |
| **Apple Maps** | Device location (when requested) | Map display, nearby location search |

### 5.3. Optional AI Processing
If you choose to use AI-powered receipt scanning:
- Receipt images are sent to **OpenAI's API** for text extraction
- This requires your own API key (we do not provide one)
- Images are compressed before transmission (max 1024px, JPEG 80%)
- If you do not use this feature, no data is sent to OpenAI
- The on-device OCR fallback processes images entirely on your device with no external transmission

## 6. Data Retention

- **Account data:** Retained until you delete your account
- **Cloud sync data:** Retained in Firebase until you delete it or delete your account
- **Local device data:** Retained until you delete it within the App or uninstall the App
- **Sync timestamps:** Cleared upon sign-out

## 7. your Rights

### 7.1. Access and Export
You can view all your data within the App at any time. You can export your data in CSV, JSON, or PDF formats using the App's export functionality.

### 7.2. Correction
You can edit or update any of your data directly within the App.

### 7.3. Deletion
- **Individual records:** Delete specific fuel entries, maintenance records, trips, expenses, or documents within the App
- **Cloud data:** Delete all cloud-synced data from the App's settings
- **Account deletion:** Delete your entire account and all associated data from the App's settings

### 7.4. Data Portability
You can export all your data before deleting your account using the App's export feature.

## 8. Children's Privacy

AutoLedger is not intended for use by anyone under the age of 18. We do not knowingly collect personal information from children. If we become aware that we have collected data from a child under 18, we will take steps to delete it promptly.

## 9. Security Measures

We implement the following security measures to protect your data:
- HTTPS/TLS encryption for all network communications
- Firebase Security Rules to isolate user data
- Apple Keychain for secure credential storage
- On-device data protected by iOS device security
- No server-side storage of passwords (handled by Firebase Auth)

## 10. Changes to This Policy

We may update this Privacy Policy from time to time. We will notify you of material changes through the App or via email. Your continued use of the App after changes constitutes acceptance of the updated policy.

## 11. Applicable Laws

This Privacy Policy complies with:
- **India's Digital Personal Data Protection Act (DPDPA) 2023**
- **Apple App Store Privacy Requirements**
- **General Data Protection Regulation (GDPR)** for EU users
- **California Consumer Privacy Act (CCPA)** for California users

## 12. Contact

For privacy-related questions, data requests, or concerns, contact us at:
- **Email:** privacy@autoledger.app

---

*By using AutoLedger, you acknowledge that you have read and understood this Privacy Policy.*

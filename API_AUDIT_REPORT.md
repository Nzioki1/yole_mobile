# API Connection Audit Report
Generated: $(date)

## Executive Summary

This audit identifies which screens in the YOLE mobile application are connected to the backend API and which are using mock/simulated data. The goal is to ensure all user actions that should persist data are successfully posting information to the API.

---

## ✅ FULLY CONNECTED TO API

### 1. Authentication Flow
- **Login Screen** (`lib/screens/login_screen.dart`)
  - ✅ **Connected**: Uses `AuthService.login()` → `POST /login`
  - **Status**: Successfully posting login credentials
  - **Provider**: `authProvider` → `AuthService`

- **Create Account Screen** (`lib/screens/create_account_screen.dart`)
  - ✅ **Connected**: Uses `AuthService.register()` → `POST /register`
  - **Status**: Successfully posting registration data
  - **Provider**: `authProvider` → `AuthService`
  - **Note**: Has fallback to `MockAuthService` on failure (line 234)

- **Logout** (`lib/providers/auth_provider.dart`)
  - ✅ **Connected**: Uses `AuthService.logout()` → `POST /logout`
  - **Status**: Successfully posting logout request

- **Forgot Password Screen** (implied)
  - ✅ **Connected**: `AuthService.sendPasswordReset()` → `POST /password/forgot`
  - **Status**: API method exists and is called

### 2. Send Money Flow
- **Send Money Enter Details Screen** (`lib/screens/send_money_enter_details_screen.dart`)
  - ✅ **Connected**: Uses `ChargesProvider` → `TransactionService.getCharges()` → `POST /charges`
  - **Status**: Successfully calculating and fetching charges from API

- **Send Money Checkout Screen** (`lib/screens/send_money_checkout_screen.dart`)
  - ✅ **Connected**: Uses `SendMoneyProvider` → `TransactionService.sendMoney()` → `POST /send-money`
  - **Status**: Successfully posting transaction data to API
  - **Lines 154-158**: Mobile money payment uses `sendMoneyProvider`
  - **Lines 198-202**: PesaPal payment also creates YOLE transaction first

- **Transaction History** (`lib/providers/transaction_provider.dart`)
  - ✅ **Connected**: Uses `TransactionService.getTransactions()` → `GET /transactions`
  - **Status**: Successfully fetching transactions from API

---

## ❌ NOT CONNECTED TO API (Using Mock/Simulated Data)

### 1. KYC Verification Flow

#### **KYC Phone Screen** (`lib/screens/kyc_phone_screen.dart`)
- ❌ **NOT Connected**: Uses `Future.delayed()` simulation (line 124)
- **Issue**: Should call `YoleApiService.sendSmsOtp()` → `POST /sms/send-otp`
- **Expected API Call**: 
  ```dart
  await apiService.sendSmsOtp(
    phoneCode: countryCode,
    phone: phoneNumber,
  )
  ```
- **Current Implementation**: Lines 114-136 show simulated delay with no API call
- **Impact**: OTP codes are not actually sent to users

#### **KYC OTP Screen** (`lib/screens/kyc_otp_screen.dart`)
- ❌ **NOT Connected**: Uses `Future.delayed()` simulation (line 148)
- **Issue**: Should verify OTP with backend
- **Expected API Call**: OTP verification should be part of KYC validation
- **Current Implementation**: Lines 138-160 show simulated verification with no API call
- **Impact**: OTP codes are not actually verified against backend

#### **KYC ID Capture Screen** (`lib/screens/kyc_id_capture_screen.dart`)
- ❌ **NOT Connected**: No API calls found
- **Issue**: Should upload ID documents using `YoleApiService.validateKyc()` → `POST /validate-kyc`
- **Expected API Call**: 
  ```dart
  await apiService.validateKyc(
    phoneNumber: phone,
    otpCode: otp,
    idNumber: idNumber,
    idPhotoPath: idFrontPath,
    passportPhotoPath: idBackPath, // or selfie
  )
  ```
- **Current Implementation**: Only handles local file selection, no API submission
- **Impact**: ID documents are not uploaded to backend

#### **KYC Selfie Screen** (`lib/screens/kyc_selfie_screen.dart`)
- ❌ **NOT Connected**: No API calls found
- **Issue**: Should upload selfie as part of KYC validation
- **Expected API Call**: Selfie should be included in `validateKyc()` call
- **Current Implementation**: Only handles local camera capture, no API submission
- **Impact**: Selfie photos are not uploaded to backend

#### **KYC Intro Screen** (`lib/screens/kyc_screen.dart`)
- ❌ **NOT Connected**: Only handles UI flow, no data submission
- **Status**: This is an informational screen, no API calls expected

#### **KYC Success Screen** (`lib/screens/kyc_success_screen.dart`)
- ❌ **NOT Connected**: Only displays success message
- **Status**: Informational screen, but should confirm KYC was submitted

### 2. Email Verification

#### **Email Verification Screen** (`lib/screens/email_verification_screen.dart`)
- ❌ **NOT Connected**: Resend email uses simulation (lines 104-140)
- **Issue**: Should call email verification API
- **Expected API Call**: `POST /email/verification-notification`
- **Current Implementation**: Uses `Future.delayed()` simulation
- **Impact**: Email verification links are not actually sent

---

## 📊 Summary Statistics

| Category | Connected | Not Connected | Total |
|----------|-----------|---------------|-------|
| Authentication | 4 | 0 | 4 |
| Send Money | 3 | 0 | 3 |
| KYC Flow | 0 | 6 | 6 |
| Email Verification | 0 | 1 | 1 |
| **TOTAL** | **7** | **7** | **14** |

---

## 🔧 Required Fixes

### Priority 1: Critical User Flows

1. **KYC Phone Screen** - Send OTP API Integration
   - File: `lib/screens/kyc_phone_screen.dart`
   - Action: Replace simulation with `YoleApiService.sendSmsOtp()` call
   - Provider: Need to create or use existing API service provider

2. **KYC OTP Screen** - Verify OTP API Integration
   - File: `lib/screens/kyc_otp_screen.dart`
   - Action: Verify OTP against backend before proceeding
   - Note: OTP verification may be part of `validateKyc` endpoint

3. **KYC ID Capture & Selfie** - Upload Documents API Integration
   - Files: `lib/screens/kyc_id_capture_screen.dart`, `lib/screens/kyc_selfie_screen.dart`
   - Action: Implement `YoleApiService.validateKyc()` with multipart file upload
   - Requirements: Phone number, OTP code, ID number, ID photo, selfie/passport photo

4. **Email Verification** - Resend Email API Integration
   - File: `lib/screens/email_verification_screen.dart`
   - Action: Replace simulation with actual email verification resend API call

### Priority 2: API Service Methods Available

The following API methods already exist in `YoleApiService` but are not being called:

- ✅ `sendSmsOtp()` - Available (line 273-283)
- ✅ `validateKyc()` - Available (line 254-270) - **NOTE**: Currently simplified, needs multipart file upload support
- ⚠️ Email verification resend - Check if endpoint exists

---

## 📝 Implementation Notes

### KYC Flow Implementation Pattern

The KYC flow should work as follows:

1. **Phone Verification**: User enters phone → Call `POST /sms/send-otp` → Navigate to OTP screen
2. **OTP Verification**: User enters OTP → Verify with backend (or store for KYC submission) → Navigate to ID capture
3. **ID Capture**: User captures/selects ID → Store locally until all data collected
4. **Selfie Capture**: User captures selfie → Store locally
5. **Submit KYC**: When all data collected → Call `POST /validate-kyc` with:
   - Phone number
   - OTP code
   - ID number
   - ID photo (multipart file)
   - Selfie photo (multipart file)

### API Endpoints Reference

Based on codebase analysis:
- `POST /login` - ✅ Connected
- `POST /register` - ✅ Connected
- `POST /logout` - ✅ Connected
- `POST /password/forgot` - ✅ Connected
- `POST /charges` - ✅ Connected
- `POST /send-money` - ✅ Connected
- `GET /transactions` - ✅ Connected
- `POST /sms/send-otp` - ❌ **NOT Connected** (KYC Phone Screen)
- `POST /validate-kyc` - ❌ **NOT Connected** (KYC ID/Selfie Screens)
- `POST /email/verification-notification` - ❌ **NOT Connected** (Email Verification Screen)

---

## ✅ Verification Checklist

After implementing fixes, verify:

- [ ] KYC Phone screen sends OTP via API and receives response
- [ ] KYC OTP screen verifies code against backend
- [ ] KYC ID Capture uploads ID document via multipart form
- [ ] KYC Selfie uploads selfie photo via multipart form
- [ ] Complete KYC submission includes all required data
- [ ] Email verification resend actually sends email
- [ ] All API errors are properly handled and displayed to users
- [ ] Loading states show during API calls
- [ ] Success/error messages are user-friendly

---

## 📌 Next Steps

1. Create KYC service/provider to handle KYC API calls
2. Implement OTP sending in KYC Phone screen
3. Implement OTP verification in KYC OTP screen  
4. Implement document upload in KYC ID Capture screen
5. Implement selfie upload in KYC Selfie screen
6. Implement complete KYC validation submission
7. Implement email verification resend
8. Test all API integrations with real backend
9. Handle all error cases gracefully
10. Update user journey documentation

---

## 🔍 Files Requiring Changes

1. `lib/screens/kyc_phone_screen.dart` - Add OTP sending API call
2. `lib/screens/kyc_otp_screen.dart` - Add OTP verification
3. `lib/screens/kyc_id_capture_screen.dart` - Add document upload
4. `lib/screens/kyc_selfie_screen.dart` - Add selfie upload and complete KYC submission
5. `lib/screens/email_verification_screen.dart` - Add email resend API call
6. `lib/services/yole_api_service.dart` - Enhance `validateKyc()` to support multipart file uploads
7. Potentially create `lib/services/kyc_service.dart` - Service layer for KYC operations
8. Potentially create `lib/providers/kyc_provider.dart` - State management for KYC flow

---

**Report Generated**: Comprehensive audit of all screens in the application


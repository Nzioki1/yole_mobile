# Poste Finance Mobile Offline Demo Punch List — Design

**Date**: 2026-09-18  
**Status**: Approved & Implemented  
**Scope**: Flutter customer app offline demo fixes  

---

## Overview

This document summarizes the approved offline demo improvements for the Poste Finance mobile customer app (Flutter). All changes are gated to offline demo mode and do not affect live API builds.

---

## 1. Pay Bill — Kinshasa Biller Picker

### Problem
Biller code field is free-text only; users must know exact codes.

### Solution
- Add chips/picker of common Kinshasa billers above biller code field
- Seed list: SNEL, REGIDESO, Vodacom Congo, Airtel Congo, Orange RDC, Canal+ Congo, DGI, City of Kinshasa
- Selecting a biller prefills biller code; user can still override with free text
- Stored as constant `kKinshasaBillers` in `OfflineDemoRepository`

### Acceptance
- Chips render on Pay Bill screen when rail type is 'BILL'
- Tap prefills biller code field
- Free-text entry remains functional

---

## 2. KYC — Verification Code Step Must Conclude

### Problem
OTP screen collects code but never completes KYC; user stuck at ID capture.

### Solution
- After OTP entry, call `kyc_service.submitKyc()` (offline path accepts demo OTP `123456`)
- Navigate directly to `kyc_success_screen` on success
- Skip ID capture for offline demo

### Acceptance
- Enter demo OTP `123456` → see success screen
- No stuck spinner or dead navigation

---

## 3. Virtual Cards — Visa Branding, Remove Mock Banner

### Problem
Cards show "MOCK — not Visa/Mastercard certified" banner and `mockNetwork: MOCK` label.

### Solution
- Change `mockNetwork` field to `'VISA'` in `_cardDto` and `issueCard`
- Remove `honestyBanner` field from card DTOs
- Remove yellow banner widget from `cards_screen.dart`
- Display cardholder name as logged-in user (Jean-Paul Kabila for demo)

### Acceptance
- Cards screen shows Visa branding, no mock banner
- Cardholder name: Jean-Paul Kabila
- Network label: VISA

---

## 4. Credit & Loans — Red Screen + Stuck Confirm Fixes

### Problem A: My Loans Red Screen
Loans list crashes (likely type mismatch or missing field).

### Solution A
- Add null safety to `_LoanCard` widget in `credit_screen.dart`
- Ensure `listLoans()` always returns properly typed `principalMinor`/`receivableMinor` strings

### Problem B: Apply Confirm Stuck
After biometric/PIN confirm, loan apply stays in loading state.

### Solution B
- After `requestLoan()` succeeds, pop back to Credit screen and reload
- Show success snackbar with loan ID

### Acceptance
- My Loans screen renders without crash
- Apply loan → confirm → success → return to Credit with new loan visible

---

## 5. International Remittance — Red Screen Fix

### Problem
Remittance screen crashes on open or quote (likely missing/null fields).

### Solution
- Add null checks and fallback defaults for quote fields (`feeMinor`, `netCreditMinor`, `exchangeRate`)
- Outbound quote: provide placeholder structure if backend fields are undefined
- Inbound quote: ensure all display fields are nullable and safe to render

### Acceptance
- Remittance screen opens without crash
- Get quote → display → confirm completes offline happy path

---

## Implementation Notes

- All changes constrained to offline demo mode (`OFFLINE_DEMO=true`)
- Live API paths unchanged
- Reused existing screens and offline repository patterns
- No new parallel UI components introduced
- Offline honesty banners removed per user approval

---

## Testing Checklist

- [ ] Pay Bill screen shows Kinshasa biller chips
- [ ] KYC flow completes after OTP entry
- [ ] Cards screen shows Visa branding, no mock banner
- [ ] My Loans screen renders without crash
- [ ] Loan apply completes and returns to Credit screen
- [ ] Remittance screen opens and completes quote/claim flow

---

## Files Modified

- `lib/services/offline_demo_repository.dart`
- `lib/screens/payment_form_screen.dart`
- `lib/screens/kyc_otp_screen.dart`
- `lib/screens/cards_screen.dart`
- `lib/screens/credit_screen.dart`
- `lib/screens/credit_apply_screen.dart`
- `lib/screens/remittance_screen.dart`

---

**End of Design Document**

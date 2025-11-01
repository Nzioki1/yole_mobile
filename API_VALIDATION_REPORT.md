# YOLE API Validation Report
**Generated:** 2025-10-27T18:11:07.759699

## Summary

- **Total Endpoints:** 16
- **Operational (200-299):** 6
- **Auth Issues (401):** 0
- **Down/Errors:** 10
- **Average Response Time:** 437.00ms
- **Success Rate:** 37.5%

## Public Endpoints

| Endpoint | Method | Status | Response Time | Notes |
|----------|--------|--------|---------------|-------|
| Get Status | GET | ✅ UP | 1029ms | Working |
| Get Countries | GET | ✅ UP | 295ms | Working |
| Login | POST | ✅ UP | 315ms | Working |
| Register | POST | ❌ DOWN | 246ms | Registration failed |
| Forgot Password | POST | ✅ UP | 1224ms | Working |


## Protected Endpoints

| Endpoint | Method | Status | Response Time | Notes |
|----------|--------|--------|---------------|-------|
| My Profile | GET | ❌ DOWN | 236ms | Profile fetch failed |
| Refresh Token | POST | ❌ DOWN | N/A | No refresh token available |
| Send Email Verification | POST | ✅ UP | 1113ms | Working |
| Get Charges | POST | ❌ DOWN | 232ms | Request failed |
| Get Service Charge | POST | ❌ DOWN | 295ms | Request failed |
| Transaction Status | POST | ❌ DOWN | 238ms | Request failed |
| Send Money | POST | ❌ DOWN | 236ms | Request failed |
| Get Transactions | GET | ❌ DOWN | 238ms | Transactions fetch failed |
| Validate KYC | POST | ❌ DOWN | 240ms | Request failed |
| Send SMS OTP | POST | ✅ UP | 273ms | Working |
| Logout | POST | ❌ DOWN | 345ms | Logout failed |


## Detailed Results

### Get Status

- **Endpoint:** `/status`
- **Method:** `GET`
- **Requires Auth:** No
- **Status Code:** `200`
- **Status:** ✅ UP
- **Response Time:** 1029ms
- **Response Keys:** status


### Get Countries

- **Endpoint:** `/countries`
- **Method:** `GET`
- **Requires Auth:** No
- **Status Code:** `200`
- **Status:** ✅ UP
- **Response Time:** 295ms
- **Response Keys:** status, data


### Login

- **Endpoint:** `/login`
- **Method:** `POST`
- **Requires Auth:** No
- **Status Code:** `200`
- **Status:** ✅ UP
- **Response Time:** 315ms
- **Response Keys:** access_token, token_type, expires_in, kyc_submitted, kyc_validated


### Register

- **Endpoint:** `/register`
- **Method:** `POST`
- **Requires Auth:** No
- **Status Code:** `422`
- **Status:** ❌ DOWN
- **Response Time:** 246ms
- **Error:** Registration failed
- **Response Keys:** message, errors, status_code


### Forgot Password

- **Endpoint:** `/password/forgot`
- **Method:** `POST`
- **Requires Auth:** No
- **Status Code:** `200`
- **Status:** ✅ UP
- **Response Time:** 1224ms


### My Profile

- **Endpoint:** `/me`
- **Method:** `GET`
- **Requires Auth:** Yes
- **Status Code:** `403`
- **Status:** ❌ DOWN
- **Response Time:** 236ms
- **Error:** Profile fetch failed
- **Response Keys:** message, status_code


### Refresh Token

- **Endpoint:** `/refresh-token`
- **Method:** `POST`
- **Requires Auth:** Yes
- **Status Code:** `0`
- **Status:** ❌ DOWN
- **Response Time:** 0ms
- **Error:** No refresh token available


### Send Email Verification

- **Endpoint:** `/email/verification-notification`
- **Method:** `POST`
- **Requires Auth:** Yes
- **Status Code:** `200`
- **Status:** ✅ UP
- **Response Time:** 1113ms


### Get Charges

- **Endpoint:** `/charges`
- **Method:** `POST`
- **Requires Auth:** Yes
- **Status Code:** `403`
- **Status:** ❌ DOWN
- **Response Time:** 232ms
- **Error:** Request failed
- **Response Keys:** message, status_code


### Get Service Charge

- **Endpoint:** `/yole-charges`
- **Method:** `POST`
- **Requires Auth:** Yes
- **Status Code:** `403`
- **Status:** ❌ DOWN
- **Response Time:** 295ms
- **Error:** Request failed
- **Response Keys:** message, status_code


### Transaction Status

- **Endpoint:** `/transaction/status`
- **Method:** `POST`
- **Requires Auth:** Yes
- **Status Code:** `403`
- **Status:** ❌ DOWN
- **Response Time:** 238ms
- **Error:** Request failed
- **Response Keys:** message, status_code


### Send Money

- **Endpoint:** `/send-money`
- **Method:** `POST`
- **Requires Auth:** Yes
- **Status Code:** `403`
- **Status:** ❌ DOWN
- **Response Time:** 236ms
- **Error:** Request failed
- **Response Keys:** message, status_code


### Get Transactions

- **Endpoint:** `/transactions`
- **Method:** `GET`
- **Requires Auth:** Yes
- **Status Code:** `403`
- **Status:** ❌ DOWN
- **Response Time:** 238ms
- **Error:** Transactions fetch failed
- **Response Keys:** message, status_code


### Validate KYC

- **Endpoint:** `/validate-kyc`
- **Method:** `POST`
- **Requires Auth:** Yes
- **Status Code:** `422`
- **Status:** ❌ DOWN
- **Response Time:** 240ms
- **Error:** Request failed
- **Response Keys:** message, errors, status_code


### Send SMS OTP

- **Endpoint:** `/sms/send-otp`
- **Method:** `POST`
- **Requires Auth:** Yes
- **Status Code:** `200`
- **Status:** ✅ UP
- **Response Time:** 273ms
- **Response Keys:** message, status


### Logout

- **Endpoint:** `/logout`
- **Method:** `POST`
- **Requires Auth:** Yes
- **Status Code:** `403`
- **Status:** ❌ DOWN
- **Response Time:** 345ms
- **Error:** Logout failed



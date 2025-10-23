# User Journey - YOLE Money Transfer App

This document maps the complete user experience flow for the YOLE money transfer application, from initial app launch through authenticated user flows. Each step mirrors the exact UX design and interactions.

---

## Step 1: Splash Screen (Default Entry Point)

**User Goal:** Learn about YOLE and decide to create account or sign in  
**App Icon Tap:** This is the first screen displayed when users tap the app icon

### Actions Available:
- **"Get started" button** - Primary CTA to begin registration
- **"Log In" link** - Navigate to login for existing users
- **Language toggle** - Switch between English/French (EN/FR)  
- **Theme toggle** - Switch between light/dark mode

### Expected Outcome:
- **"Get started"** → Navigate to Create Account Screen
- **"Log In"** → Navigate to Login Screen
- **Language toggle** → Interface updates to selected language
- **Theme toggle** → Visual theme changes immediately

### Error/Edge Cases:
- None (informational screen with no form validation)

### Navigation:
- **Next:** Create Account Screen OR Login Screen
- **No back navigation** (default entry point)

---

## Step 2: Create Account Screen

**User Goal:** Register new account with personal information

### Actions Available:
- **Back arrow** - Return to Welcome Screen
- **Email input field** - Enter email address
  - Placeholder: "you@example.com"
- **First Name input field** - Enter first name
  - Placeholder: "First Name" (localized)
- **Last Name input field** - Enter last name  
  - Placeholder: "Last Name" (localized)
- **Password input field** - Create password
  - Placeholder: "Create a password" (localized)
  - **Eye icon toggle** - Show/hide password visibility
- **Country dropdown** - Select country of residence
  - Placeholder: "Select your country" (localized)
  - Options include flag emoji + country name
- **"Create account" button** - Submit registration form
- **"Sign in" link** - Switch to login for existing users

### Expected Outcome:
- **Back arrow** → Return to Welcome Screen
- **Form submission** → Navigate to Email Verification Screen
- **"Sign in" link** → Navigate to Login Screen
- **Show/hide password** → Toggle password field visibility
- **Country selection** → Update dropdown with selected country

### Error/Edge Cases:
- **Empty email field** → Show "This field is required" error
- **Invalid email format** → Show "Please enter a valid email" error
- **Empty name fields** → Show "This field is required" error
- **Empty password field** → Show "This field is required" error
- **Password too short** → Show "Password must be at least 8 characters" error
- **No country selected** → Show "This field is required" error
- **Network error** → Show "Network error. Please check your connection."
- **Server error** → Show "Server error. Please try again later."
- **Email already exists** → Show "An account with this email already exists"

### Navigation:
- **Back:** Welcome Screen (Step 1)
- **Next:** Email Verification Screen (Step 3)
- **Alternative:** Login Screen (Step 4)

---

## Step 3: Email Verification Screen

**User Goal:** Verify email address to complete account creation

### Actions Available:
- **Back arrow** - Return to Create Account Screen
- **Email display** - Shows the email address entered (read-only)
- **Verification code input** - 6-digit OTP entry
- **"Verify email" button** - Submit verification code
- **"Resend code" link** - Request new verification code
- **"Change email" link** - Return to edit email address

### Expected Outcome:
- **Back arrow** → Return to Create Account Screen
- **Valid verification code** → Navigate to KYC Screen
- **"Resend code"** → Send new verification email, show success message
- **"Change email"** → Return to Create Account Screen with email field focused

### Error/Edge Cases:
- **Empty verification code** → Show "Please enter the verification code"
- **Invalid verification code** → Show "Invalid verification code. Please try again."
- **Expired verification code** → Show "Verification code has expired. Please request a new one."
- **Too many attempts** → Show "Too many attempts. Please try again later."
- **Resend cooldown active** → Show "Please wait 60 seconds before requesting another code"
- **Network error** → Show "Network error. Please check your connection."

### Navigation:
- **Back:** Create Account Screen (Step 2)
- **Next:** KYC Screen (Step 6)
- **Alternative:** Create Account Screen (change email)

---

## Step 4: Login Screen

**User Goal:** Sign in with existing account credentials

### Actions Available:
- **Back arrow** - Return to Welcome Screen
- **Email input field** - Enter registered email
  - Placeholder: "you@example.com"
- **Password input field** - Enter account password
  - Placeholder: "Enter your password" (localized)
  - **Eye icon toggle** - Show/hide password visibility
- **"Log in" button** - Submit login credentials
- **"Forgot Password?" link** - Navigate to password reset
- **"Sign up" link** - Navigate to Create Account Screen

### Expected Outcome:
- **Back arrow** → Return to Welcome Screen
- **Successful login** → Navigate to Home Screen (authenticated state)
- **"Forgot Password?"** → Navigate to Forgot Password Screen
- **"Sign up"** → Navigate to Create Account Screen
- **Show/hide password** → Toggle password field visibility

### Error/Edge Cases:
- **Empty email field** → Show "This field is required" error
- **Invalid email format** → Show "Please enter a valid email" error
- **Empty password field** → Show "This field is required" error
- **Invalid credentials** → Show "Invalid email or password"
- **Account not verified** → Show "Please verify your email address first"
- **Account locked** → Show "Account temporarily locked. Please try again later."
- **Network error** → Show "Network error. Please check your connection."

### Navigation:
- **Back:** Welcome Screen (Step 1)
- **Next:** Home Screen (Step 13, if successful) OR Forgot Password Screen (Step 5)
- **Alternative:** Create Account Screen (Step 2)

---

## Step 5: Forgot Password Screen

**User Goal:** Reset forgotten password via email

### Actions Available:
- **Back arrow** - Return to Login Screen
- **Email input field** - Enter registered email address
  - Placeholder: "you@example.com"
- **"Send reset link" button** - Request password reset email
- **"Remember password?" link** - Return to Login Screen

### Expected Outcome:
- **Back arrow** → Return to Login Screen
- **Valid email submission** → Show success message and return to Login Screen
- **"Remember password?"** → Return to Login Screen

### Error/Edge Cases:
- **Empty email field** → Show "This field is required" error
- **Invalid email format** → Show "Please enter a valid email" error
- **Email not found** → Show "No account found with this email address"
- **Rate limiting** → Show "Too many reset requests. Please try again later."
- **Network error** → Show "Network error. Please check your connection."

### Navigation:
- **Back:** Login Screen (Step 4)
- **Next:** Login Screen (Step 4, with success message)

---

## Step 6: KYC Screen

**User Goal:** Begin identity verification process

### Actions Available:
- **Back arrow** - Return to previous screen
- **"Verify your identity" button** - Start KYC process
- **Skip/Later option** (if applicable) - Postpone verification

### Expected Outcome:
- **Back arrow** → Return to Email Verification Screen
- **"Verify your identity"** → Navigate to KYC Phone Screen
- **Skip** → Navigate to Home Screen with limited functionality

### Error/Edge Cases:
- None (informational screen)

### Navigation:
- **Back:** Email Verification Screen
- **Next:** KYC Phone Screen

---

## Step 7: KYC Phone Screen

**User Goal:** Provide and verify phone number

### Actions Available:
- **Back arrow** - Return to KYC Screen
- **Phone number input field** - Enter mobile number
  - Country code dropdown with flags
  - Phone number formatting based on country
- **"Send verification code" button** - Request SMS verification
- **"Skip" link** (if applicable) - Skip phone verification

### Expected Outcome:
- **Back arrow** → Return to KYC Screen
- **Valid phone submission** → Navigate to KYC OTP Screen
- **Skip** → Navigate to KYC ID Capture Screen

### Error/Edge Cases:
- **Empty phone field** → Show "This field is required" error
- **Invalid phone format** → Show "Please enter a valid phone number"
- **Phone already registered** → Show "This phone number is already associated with another account"
- **SMS delivery failure** → Show "Failed to send SMS. Please try again."
- **Network error** → Show "Network error. Please check your connection."

### Navigation:
- **Back:** KYC Screen
- **Next:** KYC OTP Screen

---

## Step 8: KYC OTP Screen

**User Goal:** Verify phone number with SMS code

### Actions Available:
- **Back arrow** - Return to KYC Phone Screen
- **OTP input fields** - 6-digit SMS verification code
- **"Verify" button** - Submit verification code
- **"Resend SMS" link** - Request new verification code
- **"Change phone number" link** - Return to edit phone number

### Expected Outcome:
- **Back arrow** → Return to KYC Phone Screen
- **Valid OTP** → Navigate to KYC ID Capture Screen
- **"Resend SMS"** → Send new SMS code, show success message
- **"Change phone number"** → Return to KYC Phone Screen

### Error/Edge Cases:
- **Empty OTP fields** → Show "Please enter the verification code"
- **Invalid OTP** → Show "Invalid verification code. Please try again."
- **Expired OTP** → Show "Verification code has expired. Please request a new one."
- **Too many attempts** → Show "Too many attempts. Please try again later."
- **Resend cooldown active** → Show "Please wait 60 seconds before requesting another code"

### Navigation:
- **Back:** KYC Phone Screen
- **Next:** KYC ID Capture Screen

---

## Step 9: KYC ID Capture Screen

**User Goal:** Upload government-issued ID document

### Actions Available:
- **Back arrow** - Return to KYC OTP Screen
- **Camera button** - Take photo of ID document
- **Gallery button** - Select photo from device gallery
- **"Continue" button** - Proceed with uploaded document
- **Retake photo option** - Capture new image
- **Document type selector** - Choose ID type (passport, driver's license, etc.)

### Expected Outcome:
- **Back arrow** → Return to KYC OTP Screen
- **Camera/Gallery** → Open camera or photo picker
- **Photo captured/selected** → Enable Continue button
- **"Continue"** → Navigate to KYC Selfie Screen

### Error/Edge Cases:
- **No photo selected** → Show "Please upload a document photo"
- **Photo quality poor** → Show "Photo quality is too low. Please retake."
- **Document not recognized** → Show "Document not clearly visible. Please retake."
- **File size too large** → Show "File size too large. Please choose a smaller image."
- **Camera permission denied** → Show "Camera access required to take photo"
- **Upload failure** → Show "Failed to upload document. Please try again."

### Navigation:
- **Back:** KYC OTP Screen
- **Next:** KYC Selfie Screen

---

## Step 10: KYC Selfie Screen

**User Goal:** Take selfie for identity verification

### Actions Available:
- **Back arrow** - Return to KYC ID Capture Screen
- **Camera button** - Take selfie photo
- **"Continue" button** - Proceed with selfie
- **Retake photo option** - Capture new selfie

### Expected Outcome:
- **Back arrow** → Return to KYC ID Capture Screen
- **Selfie captured** → Enable Continue button
- **"Continue"** → Navigate to KYC Success Screen (or KYC Error Screen if verification fails)

### Error/Edge Cases:
- **No selfie taken** → Show "Please take a selfie to continue"
- **Face not detected** → Show "Face not clearly visible. Please retake."
- **Multiple faces detected** → Show "Multiple faces detected. Please ensure only you are in the photo."
- **Poor lighting** → Show "Lighting is too poor. Please move to better lighting."
- **Camera permission denied** → Show "Camera access required to take selfie"
- **Upload failure** → Show "Failed to upload selfie. Please try again."

### Navigation:
- **Back:** KYC ID Capture Screen
- **Next:** KYC Success Screen OR KYC Error Screen

---

## Step 11: KYC Success Screen

**User Goal:** Confirmation that identity verification was successful

### Actions Available:
- **"Continue to app" button** - Proceed to main app functionality
- **"View verification details" link** - See verification information

### Expected Outcome:
- **"Continue to app"** → Navigate to Home Screen (authenticated state)
- **"View verification details"** → Show verification status details

### Error/Edge Cases:
- None (success confirmation screen)

### Navigation:
- **Next:** Home Screen (authenticated)

---

## Step 12: KYC Error Screen

**User Goal:** Understand why identity verification failed and retry

### Actions Available:
- **"Try again" button** - Restart KYC process
- **"Contact support" link** - Access customer support
- **"Continue with limited access" button** - Proceed with restricted functionality

### Expected Outcome:
- **"Try again"** → Navigate to KYC Phone Screen
- **"Contact support"** → Open support contact options
- **"Continue with limited access"** → Navigate to Home Screen with restrictions

### Error/Edge Cases:
- None (error handling screen)

### Navigation:
- **Retry:** KYC Phone Screen
- **Alternative:** Home Screen (limited access)

---

## AUTHENTICATED USER FLOW

---

## Step 13: Home Screen

**User Goal:** View account overview, recent transactions, and quick actions

### Actions Available:
- **Profile avatar** - Access profile settings
- **"Send money" button** - Initiate money transfer
- **Recent transactions list** - View transaction history
- **Transaction items** - Tap to view transaction details
- **Balance display** - View current account balance
- **"Add money" button** - Top up account
- **Settings gear icon** - Access app settings
- **Notification bell** - View notifications
- **Bottom navigation tabs** - Navigate between main sections

### Expected Outcome:
- **Profile avatar** → Navigate to Profile Screen
- **"Send money"** → Navigate to Send Screen
- **Transaction tap** → View transaction details
- **"Add money"** → Navigate to add funds flow
- **Settings** → Navigate to settings
- **Bottom navigation** → Switch to selected tab (Send, Favorites, Profile)

### Error/Edge Cases:
- **Network error loading data** → Show "Unable to load account information"
- **No transactions available** → Show empty state with "No transactions yet"
- **Account suspended** → Show warning banner with contact support

### Navigation:
- **Profile:** Profile Screen
- **Send:** Send Screen
- **Favorites:** Favorites Screen
- **Bottom tabs:** Send Screen, Favorites Screen, Profile Screen

---

## Step 14: Send Money — PSP Checkout (Pesapal)

### Step 14.1: Enter Details

**User Goal:** Enter transfer amount, currency, recipient, and optional note

### Actions Available:
- **Amount input field** - Enter transfer amount
  - Placeholder: "0.00"
  - Validation: Amount > 0, numeric, 2 decimal places max
- **Currency selector** - Choose USD or EUR only (segmented buttons)
- **Recipient selector** - Choose or add recipient (required)
- **Note field** - Optional message to recipient
- **"Continue" button** - Proceed to review (disabled until valid)
- **Recent recipients** - Quick select from previous transfers
- **Bottom navigation tabs** - Navigate between main sections

### Expected Outcome:
- **Amount entered** → Enable currency selection and validation
- **Currency selected** → Show selected currency (USD | EUR only)
- **Recipient selected** → Enable continue button when all required fields valid
- **"Continue"** → Navigate to Review & Fees screen
- **Bottom navigation** → Switch to selected tab

### Error/Edge Cases:
- **Amount = 0 or empty** → Show "Amount must be greater than 0"
- **Invalid amount format** → Show "Please enter a valid amount"
- **More than 2 decimal places** → Show "Amount can have maximum 2 decimal places"
- **No currency selected** → Show "Please select a currency"
- **Currency not USD/EUR** → Reject at validation level
- **No recipient selected** → Show "Please select a recipient"

### Analytics Events:
- `send_details_filled` - When all required fields completed

### Navigation:
- **Home:** Home Screen
- **Favorites:** Favorites Screen  
- **Profile:** Profile Screen
- **Next:** Review & Fees screen

---

### Step 14.2: Review & Fees

**User Goal:** Review transfer details and confirm fees before proceeding

### Actions Available:
- **Amount row** - Display formatted amount (e.g., "$120.00 USD" or "€120.00 EUR")
- **Fees row** - Display fees from Fees API
- **Total charged row** - Display Amount + Fees (bold)
- **"Refresh fees" button** - Reload fees quote (right-aligned text button)
- **"Edit" button** - Return to Enter Details screen
- **"Continue" button** - Proceed to payment method selection

### Expected Outcome:
- **Fees loaded successfully** → Show all three rows with accurate amounts
- **"Refresh fees"** → Reload fees with loading state
- **"Edit"** → Return to Enter Details screen with data preserved
- **"Continue"** → Navigate to Choose Payment Method screen

### Error/Edge Cases:
- **Fees quote fails** → Show inline error "We couldn't load fees. Try again." with Retry button
- **Network error during refresh** → Show same error with retry option
- **Stale fees data** → Auto-refresh after timeout period

### UI Notes:
- Remove FX rate and arrival estimate entirely
- Add subtle caption: "Fees provided by Yole Fees API" below rows
- Three rows only: Amount, Fees, Total charged

### Analytics Events:
- `fees_quote_requested` - When fees API called
- `fees_quote_received` - When fees successfully loaded
- `fees_quote_failed` - When fees API fails
- `send_review_continue` - When user proceeds from review

### Navigation:
- **Back:** Enter Details screen
- **Next:** Choose Payment Method screen

---

### Step 14.3: Choose Payment Method

**User Goal:** Select payment method to complete transfer

### Actions Available:
- **Pesapal option** - Single payment method available
  - Title: "Pesapal"
  - Subtitle: "Cards • Mobile Money"
- **"Continue to secure checkout" button** - Proceed to PSP checkout

### Expected Outcome:
- **Pesapal selection** → Highlight selected option
- **"Continue to secure checkout"** → Navigate to PSP Checkout screen

### Error/Edge Cases:
- None (single option, simple selection)

### Analytics Events:
- `psp_method_selected` - When Pesapal selected

### Navigation:
- **Back:** Review & Fees screen
- **Next:** PSP Checkout screen

---

### Step 14.4: PSP Checkout (Pesapal)

**User Goal:** Complete payment through Pesapal secure checkout

### Actions Available:
- **Full-screen webview/iframe** - Pesapal payment interface
- **Loading state** - "Connecting to Pesapal…"
- **Error retry** - If checkout fails to load
- **"Open in browser" option** - Alternative if webview fails

### Expected Outcome:
- **Checkout loads successfully** → User completes payment in Pesapal interface
- **Payment completed** → Navigate to Result screen based on payment status
- **User cancels** → Navigate to Result screen with cancelled status

### Error/Edge Cases:
- **Checkout fails to load** → Show "Couldn't load Pesapal." with Retry and "Open in browser" options
- **Network timeout** → Show connection error with retry
- **User closes/navigates away** → Handle as cancelled transaction

### UI Notes:
- Header: "Secure checkout • Powered by Pesapal"
- Full-screen experience
- Loading text: "Connecting to Pesapal…"

### Analytics Events:
- `psp_checkout_opened` - When PSP interface launched
- `psp_checkout_loaded` - When PSP interface successfully loads

### Navigation:
- **Back:** Choose Payment Method screen
- **Next:** Result screen (Success/Pending/Failed/Cancelled)

---

### Step 14.5: Result

**User Goal:** See transfer outcome and transaction details

### Actions Available:
- **Status display** - Success/Pending/Failed based on payment result
- **Transaction details** - Amount, Fees, Total charged, Recipient, YOLE Ref, PSP Txn ID
- **"Done" button** - Return to Home screen
- **"Try again" button** - For failed transfers, return to Enter Details
- **"Change method" button** - For failed transfers, return to Choose Payment Method

### Expected Outcome:
- **Success** → Show "Transfer scheduled" with complete details
- **Pending** → Show "Payment processing" with notification promise
- **Failed/Cancelled** → Show error reason with retry options
- **"Done"** → Navigate to Home screen
- **"Try again"** → Navigate to Enter Details screen
- **"Change method"** → Navigate to Choose Payment Method screen

### Success State:
- Title: "Transfer scheduled"
- Details shown: Amount, Fees, Total charged, Recipient, YOLE Ref, PSP Txn ID
- No FX rate or ETA displayed

### Pending State:
- Title: "Payment processing"
- Message: "We'll notify you once payment is confirmed"
- Same transaction details as success

### Failed/Cancelled State:
- Title: "Transfer failed" or "Transfer cancelled"
- Error reason if available
- Action buttons: "Try again", "Change method"

### Error/Edge Cases:
- **Unclear payment status** → Default to pending with notification promise
- **Missing transaction details** → Show available information, note missing data

### Notifications:
- In-app notifications for status updates
- Email notifications for final status

### Analytics Events:
- `psp_result_success` - Successful payment completion
- `psp_result_pending` - Payment pending confirmation
- `psp_result_failed` - Payment failed
- `psp_result_cancelled` - User cancelled payment

### Navigation:
- **Done:** Home Screen
- **Try again:** Enter Details screen
- **Change method:** Choose Payment Method screen

---

### Engineering Annotations:

**Fees API (placeholder):**
- Request: `{ amount: number, currency: 'USD'|'EUR', country?: string, corridor?: string }`
- Response: `{ feeAmount: number, feeCurrency: string, feeType: string, breakdown?: object }`

**Callback Parameters:**
- `yoleReference`: string - Internal transaction reference
- `pspTransactionId`: string - Pesapal transaction ID
- `status`: 'success'|'pending'|'failed'|'cancelled'
- `amount`: number - Transfer amount
- `currency`: 'USD'|'EUR' - Transfer currency
- `feeAmount`: number - Fee charged
- `totalAmount`: number - Total amount charged (amount + fees)

**Currency Validation:**
- Only USD and EUR allowed
- Reject all other currencies at validation level
- No FX conversion or rates displayed

---

## Step 15: Favorites Screen

**User Goal:** Manage saved recipients and frequently used transfers

### Actions Available:
- **Favorite recipients list** - View saved recipients
- **"Add to favorites" button** - Save new recipient
- **Recipient items** - Tap to send money or edit
- **Edit recipient button** - Modify recipient details
- **Remove from favorites** - Delete saved recipient
- **Search favorites** - Find specific recipient
- **"Send money" quick action** - Start transfer to favorite
- **Bottom navigation tabs** - Navigate between main sections

### Expected Outcome:
- **Recipient tap** → Navigate to Send Screen with pre-filled recipient
- **"Send money"** → Navigate to Send Screen with selected recipient
- **Edit** → Navigate to edit recipient form
- **Remove** → Show confirmation dialog then remove
- **"Add to favorites"** → Navigate to add recipient flow
- **Bottom navigation** → Switch to selected tab

### Error/Edge Cases:
- **No favorites saved** → Show empty state "No favorite recipients yet"
- **Network error** → Show "Unable to load favorites"
- **Remove confirmation** → Show "Are you sure you want to remove this recipient?"

### Navigation:
- **Home:** Home Screen
- **Send:** Send Screen
- **Profile:** Profile Screen
- **Next:** Send Screen (with recipient) OR Add recipient flow

---

## Step 16: Profile Screen

**User Goal:** Manage account settings, view personal information, and access app features

### Actions Available:
- **Profile photo** - Change profile picture
- **Personal information section** - View/edit name, email, phone
- **"Edit profile" button** - Modify personal details
- **Account settings** - Manage account preferences
- **Security settings** - Password, 2FA, biometrics
- **Language selection** - Switch between EN/FR
- **Theme toggle** - Light/dark mode
- **Verification status** - View KYC status
- **Transaction history** - View all transactions
- **Help & support** - Access customer service
- **"Log out" button** - Sign out of account
- **Bottom navigation tabs** - Navigate between main sections

### Expected Outcome:
- **Profile photo** → Open camera/gallery picker
- **"Edit profile"** → Navigate to edit profile form
- **Settings sections** → Navigate to respective settings screens
- **Language/Theme** → Update preferences immediately
- **Transaction history** → Navigate to full transaction list
- **Help & support** → Open support options
- **"Log out"** → Show confirmation, then return to Welcome Screen
- **Bottom navigation** → Switch to selected tab

### Error/Edge Cases:
- **Profile update failure** → Show "Failed to update profile. Please try again."
- **Camera permission denied** → Show "Camera access required to change photo"
- **Logout confirmation** → Show "Are you sure you want to log out?"
- **Network error** → Show "Unable to load profile information"

### Navigation:
- **Home:** Home Screen
- **Send:** Send Screen
- **Favorites:** Favorites Screen
- **Logout:** Welcome Screen (unauthenticated)
- **Settings:** Various settings screens

---

## Global Navigation & Error Handling

### Bottom Navigation (Authenticated Users)
Always visible on main screens with active state indicators:
- **Home** - Dashboard and account overview
- **Send** - Money transfer functionality  
- **Favorites** - Saved recipients
- **Profile** - Account settings and preferences

### Universal Actions
Available throughout the app:
- **Theme toggle** - Switch between light/dark mode (preserves user preference)
- **Language toggle** - Switch between English/French (updates all text immediately)
- **Back navigation** - Hardware back button or on-screen back arrow
- **Deep linking** - Direct navigation to specific screens via URLs

### Global Error States
- **Network connectivity loss** → Show "No internet connection" banner
- **Server maintenance** → Show "Service temporarily unavailable" message
- **Session expiration** → Automatically redirect to Login Screen
- **Account suspension** → Show suspension notice with support contact

### Accessibility Features
- **Screen reader support** - All elements properly labeled
- **Touch target sizes** - Minimum 44px for all interactive elements
- **High contrast mode** - Enhanced contrast for better visibility
- **Text scaling** - Support for system text size preferences
- **Keyboard navigation** - Full app navigation without touch

### Security Features
- **Auto-logout** - Session timeout after inactivity
- **Biometric authentication** - Fingerprint/Face ID support
- **PIN protection** - Secondary authentication for sensitive actions
- **Secure data handling** - Encrypted storage and transmission

---

This user journey document captures the complete UX flow with exact screen names, button labels, placeholders, and error messages as implemented in the YOLE money transfer application. Each step maintains the precise interaction patterns and visual feedback designed in the Figma prototype.
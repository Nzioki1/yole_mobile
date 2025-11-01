# Customer Registration Test Guide

## Required Fields for Registration

Based on the Create Account screen, you need to fill in:

### 1. **Email** (Required)
- Must be a valid email format
- Example: `test@example.com`
- **Test Examples:**
  - ✅ `john.doe@test.com`
  - ✅ `jane.smith@yole.com`
  - ✅ `testuser@gmail.com`
  - ❌ `invalid-email` (no @ symbol)
  - ❌ `test@` (incomplete)

### 2. **First Name** (Required)
- Cannot be empty
- Any text accepted
- **Test Examples:**
  - ✅ `John`
  - ✅ `Mary`
  - ✅ `Ahmed`
  - ❌ Empty field

### 3. **Last Name** (Required)
- Cannot be empty
- Any text accepted
- **Test Examples:**
  - ✅ `Smith`
  - ✅ `Kamau`
  - ✅ `Ochieng`
  - ❌ Empty field

### 4. **Password** (Required)
- ⚠️ **Note:** Password validation is currently DISABLED for UI/UX testing
- You can use any password (no minimum length required)
- **Test Examples:**
  - ✅ `123456`
  - ✅ `password`
  - ✅ `Test123`
  - ✅ `a` (even a single character works)

### 5. **Confirm Password** (Required)
- Must match the password field
- Currently no validation, but should match password

### 6. **Country** (Required)
Available options in dropdown:
- 🇰🇪 **Kenya** (KE)
- 🇳🇬 **Nigeria** (NG)
- 🇬🇭 **Ghana** (GH)
- 🇺🇬 **Uganda** (UG)
- 🇹🇿 **Tanzania** (TZ)
- 🇿🇦 **South Africa** (ZA)
- 🇨🇩 **DRC** (CD) - Default
- 🇫🇷 **France** (FR)
- 🇩🇪 **Germany** (DE)
- 🇺🇸 **United States** (US)

## Complete Test Registration Examples

### Example 1: Standard User (Kenya)
```
Email: john.kamau@test.com
First Name: John
Last Name: Kamau
Password: Test1234
Confirm Password: Test1234
Country: 🇰🇪 Kenya
```

### Example 2: Standard User (DRC)
```
Email: grace.mukadi@example.com
First Name: Grace
Last Name: Mukadi
Password: password123
Confirm Password: password123
Country: 🇨🇩 DRC
```

### Example 3: Quick Test User
```
Email: test@yole.com
First Name: Test
Last Name: User
Password: 123456
Confirm Password: 123456
Country: 🇰🇪 Kenya
```

### Example 4: International User
```
Email: jane.smith@test.com
First Name: Jane
Last Name: Smith
Password: SecurePass123
Confirm Password: SecurePass123
Country: 🇺🇸 United States
```

## Validation Rules

### Email Validation
- ✅ Must contain `@` symbol
- ✅ Must have domain part (e.g., `@gmail.com`)
- ✅ Basic format: `something@domain.extension`
- Pattern: `^[^\s@]+@[^\s@]+\.[^\s@]+$`

### Name Validation
- ✅ First Name: Required (cannot be empty)
- ✅ Last Name: Required (cannot be empty)
- ✅ No minimum/maximum length enforced
- ✅ Accepts any text characters

### Password Validation
- ⚠️ **Currently DISABLED** (removed for UI/UX testing)
- No minimum length required
- No complexity requirements
- Can be any value (even single character)

### Country Validation
- ✅ Must select from dropdown
- ✅ Cannot be null/empty
- Default: DRC (CD) if not selected

## Registration Flow

1. Fill all required fields
2. Click "Create Account" button
3. **On Success:**
   - Navigates to Email Verification screen
   - User receives verification email (if backend configured)
4. **On Failure:**
   - Shows error message in SnackBar
   - Error displayed at bottom of screen

## What Gets Sent to Backend

The registration API call sends:
```json
{
  "email": "user@example.com",
  "name": "John",
  "surname": "Kamau",
  "password": "Test1234",
  "password_confirmation": "Test1234",
  "country": "KE"
}
```

## Common Issues

### Issue: Email Already Exists
- **Error:** Backend returns 422/409
- **Solution:** Use a different email address

### Issue: Invalid Email Format
- **Error:** Form validation fails
- **Solution:** Ensure email has @ and domain

### Issue: Password Mismatch
- **Note:** Currently not validated in UI
- **Backend may:** Require password and password_confirmation to match

### Issue: Network Error
- **Error:** Connection timeout or SSL error
- **Solution:** Check internet connection

## Testing Checklist

- [ ] Valid email format
- [ ] First name filled
- [ ] Last name filled
- [ ] Password entered (any value works)
- [ ] Confirm password matches password
- [ ] Country selected
- [ ] All fields validated before submission
- [ ] Success navigation to email verification
- [ ] Error handling for failed registration

## Quick Test Credentials

**Ready-to-use test account:**
```
Email: testuser@yole.com
First Name: Test
Last Name: User
Password: test123
Confirm Password: test123
Country: KE (Kenya)
```

---

**Note:** Password validation is intentionally disabled for testing. In production, passwords should meet security requirements.





# YOLE Flutter App - Figma to Flutter Export

This directory contains production-ready Flutter .dart files converted from the original Figma design, maintaining pixel-perfect fidelity to the design specifications.

## 📁 File Structure

```
/lib/
├── main.dart                    # Main app entry point
├── example_app.dart            # Complete example implementation
├── screens/                    # All screen widgets
│   ├── welcome_screen.dart     # Welcome/onboarding screen
│   ├── splash_screen.dart      # App splash screen
│   ├── login_screen.dart       # User authentication
│   └── home_screen.dart        # Main dashboard
├── widgets/                    # Reusable UI components
│   ├── gradient_button.dart    # Primary CTA buttons
│   ├── yole_logo.dart         # YOLE brand logo component
│   ├── sparkle_animation.dart  # Animated sparkles for dark theme
│   ├── bottom_navigation.dart  # Tab navigation component
│   └── status_chip.dart       # Transaction status indicators
/flutter/
├── yole_theme.dart            # Material 3 theme configuration
├── yole_localization.dart     # Bilingual support (EN/FR)
└── create_account_screen.dart # Additional screen (pre-existing)
```

## 🎨 Design System

### Color Palette
- **Primary Gradient**: `#3B82F6` → `#8B5CF6`
- **Light Background**: `#FFFFFF`
- **Dark Background**: `#19173D` with gradient from `#0B0F19`
- **Success**: `#10B981`
- **Error**: `#EF4444`
- **Warning**: `#F59E0B`

### Typography
- **Headings**: Material 3 typography with custom font weights
- **Body Text**: 16px base with 1.5 line height
- **Labels**: Medium weight (500) for all interactive elements

### Theme Support
- ✅ Light theme with clean, modern aesthetics
- ✅ Dark theme with sophisticated glassmorphism effects
- ✅ Automatic system theme detection
- ✅ Consistent spacing using 8pt grid system

## 🚀 Getting Started

### 1. Basic Usage
```dart
import 'package:flutter/material.dart';
import 'lib/main.dart';

void main() {
  runApp(const YoleApp());
}
```

### 2. Complete Example
```dart
import 'package:flutter/material.dart';
import 'lib/example_app.dart';

void main() {
  runApp(const ExampleYoleApp());
}
```

### 3. Individual Screen Usage
```dart
import 'lib/screens/welcome_screen.dart';

// Use in your widget tree
WelcomeScreen(
  onGetStarted: () => print('Get Started tapped'),
  onSignIn: () => print('Sign In tapped'),
  locale: 'en', // or 'fr'
  isDarkTheme: false,
)
```

## 📱 Screens Implemented

### ✅ Welcome Screen (`welcome_screen.dart`)
- **Purpose**: First screen when users tap app icon
- **Features**: 
  - Hero image with gradient overlay
  - YOLE logo and branding
  - Primary "Get Started" CTA
  - Secondary "Sign In" link
  - Smooth entrance animations
  - Dark theme sparkle effects

### ✅ Splash Screen (`splash_screen.dart`)
- **Purpose**: App loading/branding screen
- **Features**:
  - Large YOLE logo
  - Tagline text
  - Primary and secondary CTAs
  - Language selector
  - Configurable sparkle animations

### ✅ Login Screen (`login_screen.dart`)
- **Purpose**: User authentication
- **Features**:
  - Email and password fields
  - Password visibility toggle
  - Form validation
  - "Forgot Password" link
  - Loading states
  - "Sign Up" navigation

### ✅ Home Screen (`home_screen.dart`)
- **Purpose**: Main authenticated dashboard
- **Features**:
  - Personalized greeting
  - Weekly transaction statistics
  - Primary "Send Money" CTA
  - Recent transactions list
  - Empty state handling
  - User avatar with profile navigation

## 🎛️ Components Implemented

### ✅ Gradient Button (`gradient_button.dart`)
```dart
GradientButton(
  onPressed: () => print('Pressed'),
  child: Text('Send Money'),
)
```

### ✅ YOLE Logo (`yole_logo.dart`)
```dart
YoleLogo(
  height: 64,
  isDarkTheme: true,
)
```

### ✅ Bottom Navigation (`bottom_navigation.dart`)
```dart
YoleBottomNavigation(
  currentIndex: 0,
  onTabChanged: (index) => print('Tab $index'),
  locale: 'en',
)
```

### ✅ Status Chip (`status_chip.dart`)
```dart
StatusChip(
  text: 'Delivered',
  variant: StatusChipVariant.success,
)
```

### ✅ Sparkle Animation (`sparkle_animation.dart`)
- Subtle animated sparkles for dark theme backgrounds
- Configurable count, size, opacity, and timing
- Automatic fade-in and looping

## 🌐 Localization

Both English and French are supported:

```dart
// English
locale: 'en'

// French  
locale: 'fr'
```

All text strings are parameterized and can be easily localized.

## 🎨 Theme Usage

### Apply Theme
```dart
MaterialApp(
  theme: YoleTheme.lightTheme,
  darkTheme: YoleTheme.darkTheme,
  themeMode: ThemeMode.system,
)
```

### Access Theme Colors
```dart
// Using extension methods
context.primaryGradientStart
context.primaryGradientEnd
context.primaryGradient  // BoxDecoration
context.glassmorphism    // BoxDecoration
```

### Manual Theme Detection
```dart
bool isDark = Theme.of(context).brightness == Brightness.dark;
```

## 📐 Design Fidelity

### Layout
- ✅ Exact spacing matches Figma design
- ✅ Component dimensions preserved
- ✅ Typography hierarchy maintained
- ✅ Safe area handling for all devices

### Colors
- ✅ Gradient implementations match design
- ✅ Opacity values precisely replicated
- ✅ Dark theme glassmorphism effects
- ✅ State-based color variations

### Animations
- ✅ Entrance animations with proper timing
- ✅ Micro-interactions with haptic feedback
- ✅ Loading states and transitions
- ✅ Sparkle effects for premium feel

## 🔧 Dependencies Required

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # No additional dependencies required!
  # All implementations use Flutter's built-in widgets
```

## 📱 Responsive Design

All screens are designed for mobile-first with:
- ✅ Constraints for maximum width (400px equivalent)
- ✅ Flexible layouts that adapt to screen sizes
- ✅ Touch target sizes (44px minimum)
- ✅ Safe area considerations

## 🎯 Next Steps

To complete the full app:

1. **Implement remaining screens**:
   - Register/Create Account screen
   - Forgot Password screen
   - Send Money flow screens
   - Favorites screen
   - Profile screen
   - KYC screens

2. **Add backend integration**:
   - API service classes
   - State management (Riverpod recommended)
   - Authentication flow
   - Transaction management

3. **Enhanced features**:
   - Push notifications
   - Biometric authentication
   - Offline support
   - Analytics integration

## 📄 Notes

- All animations use Flutter's built-in `AnimationController`
- No external packages required for UI implementation
- Follows Material 3 design principles
- Code is production-ready and well-documented
- Maintains exact Figma design specifications

## 🤝 Integration

These Flutter files can be:
- ✅ Directly integrated into existing Flutter projects
- ✅ Used as reference for custom implementations
- ✅ Extended with additional functionality
- ✅ Modified while maintaining design consistency

The code prioritizes maintainability, performance, and pixel-perfect design fidelity.
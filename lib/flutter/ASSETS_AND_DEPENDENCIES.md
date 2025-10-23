# YOLE Flutter Create Account Screen - Assets & Dependencies

## Required Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # Optional: For advanced form validation
  # flutter_form_builder: ^9.1.1
  # form_builder_validators: ^9.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

## Assets Required

### 1. Fonts (Optional - Using System Fonts)
The current implementation uses the system default fonts. If you want to match the exact typography from the web version, add a custom font:

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

### 2. YOLE Logo Assets
Replace the placeholder logo implementation with actual assets:

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/yole_logo_light.svg
    - assets/images/yole_logo_dark.svg
    - assets/images/yole_logo_light.png
    - assets/images/yole_logo_dark.png
```

### 3. Country Flag Assets (Optional)
Currently using Unicode emoji flags. For better consistency across platforms, consider:

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/flags/cd.svg  # Democratic Republic of Congo
    - assets/flags/gh.svg  # Ghana
    - assets/flags/ke.svg  # Kenya
    - assets/flags/ng.svg  # Nigeria
    - assets/flags/za.svg  # South Africa
    - assets/flags/tz.svg  # Tanzania
    - assets/flags/ug.svg  # Uganda
    - assets/flags/be.svg  # Belgium
    - assets/flags/ca.svg  # Canada
    - assets/flags/fr.svg  # France
    - assets/flags/de.svg  # Germany
    - assets/flags/us.svg  # United States
```

## File Structure

```
lib/
├── screens/
│   └── create_account_screen.dart
├── themes/
│   └── yole_theme.dart
├── l10n/
│   └── yole_localization.dart
├── widgets/
│   ├── yole_logo.dart
│   └── yole_gradient_button.dart
└── main.dart (example_usage.dart)

assets/
├── images/
│   ├── yole_logo_light.svg
│   ├── yole_logo_dark.svg
│   ├── yole_logo_light.png
│   └── yole_logo_dark.png
├── flags/
│   └── [country_code].svg
└── fonts/
    ├── Inter-Regular.ttf
    ├── Inter-Medium.ttf
    ├── Inter-SemiBold.ttf
    └── Inter-Bold.ttf
```

## Implementation Notes

### 1. Pixel-Perfect Measurements
All measurements have been converted from the TSX/CSS values:

- `px-6` (24px) → `EdgeInsets.symmetric(horizontal: 24.0)`
- `h-12` (48px) → `SizedBox(height: 48)`
- `max-w-sm` (384px) → `ConstrainedBox(constraints: BoxConstraints(maxWidth: 384))`
- `space-y-6` (24px) → `SizedBox(height: 24)` between elements
- `rounded-2xl` (16px) → `BorderRadius.circular(16)`

### 2. Color Mapping
All colors match the CSS design system exactly:

- Light background: `#FFFFFF` → `Color(0xFFFFFFFF)`
- Dark gradient: `#0B0F19` → `#19173D` → `LinearGradient`
- Primary gradient: `#3B82F6` → `#8B5CF6`
- Border opacity: `rgba(255,255,255,0.1)` → `Colors.white.withOpacity(0.1)`

### 3. Typography
Font sizes and weights match the TSX component:

- `text-2xl` (24px) → `fontSize: 24`
- `font-bold` → `FontWeight.bold`
- `font-semibold` → `FontWeight.w600`
- `font-medium` → `FontWeight.w500`

### 4. Glassmorphism Effect
The dark theme glass card effect replicates the CSS:

```dart
// CSS: bg-white/8 backdrop-blur-medium border border-white/10
BoxDecoration(
  color: Colors.white.withOpacity(0.08),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Colors.white.withOpacity(0.1)),
)
```

### 5. State Management Integration Points

The screen is designed to easily integrate with your preferred state management solution:

#### Riverpod
```dart
final createAccountProvider = StateNotifierProvider<CreateAccountNotifier, CreateAccountState>((ref) {
  return CreateAccountNotifier();
});
```

#### BLoC
```dart
class CreateAccountBloc extends Bloc<CreateAccountEvent, CreateAccountState> {
  // Implementation
}
```

#### Provider
```dart
class CreateAccountModel extends ChangeNotifier {
  // Implementation
}
```

## Validation Integration

To wire up form validation, replace the TODO comments in the screen with actual validation logic:

```dart
// Email validation
validator: (value) {
  if (value == null || value.isEmpty) {
    return context.l10n.fieldRequired;
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return context.l10n.invalidEmail;
  }
  return null;
},
```

## Testing

The screen is built with testability in mind:

```dart
// Widget test example
testWidgets('Create account screen displays correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CreateAccountScreen(),
      localizationsDelegates: YoleLocalizations.localizationsDelegates,
    ),
  );

  expect(find.text('Create Account'), findsOneWidget);
  expect(find.text('Join Yole today'), findsOneWidget);
  expect(find.byType(TextFormField), findsNWidgets(5));
});
```

## Performance Considerations

1. **Image Assets**: Use SVG for scalable icons and logos
2. **Glassmorphism**: The backdrop filter may impact performance on lower-end devices
3. **Animations**: Consider reducing motion for accessibility
4. **Memory**: Dispose controllers properly to prevent memory leaks

## Accessibility Features

The screen includes:

- Semantic labels for screen readers
- Proper focus order
- Touch target sizes (minimum 44px)
- High contrast color support
- Keyboard navigation support
- Text scaling support

## Platform-Specific Adaptations

### iOS
- Uses Cupertino-style selections where appropriate
- Respects iOS design guidelines for form layouts

### Android
- Material 3 theming throughout
- Proper Material Design spacing and elevation

### Web
- Responsive layout that works on desktop
- Proper keyboard navigation
- Focus indicators
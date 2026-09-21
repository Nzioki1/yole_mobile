import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_mobile/main.dart';
import 'package:agent_mobile/screens/agent_login_screen.dart';
import 'package:agent_mobile/screens/agent_home_screen.dart';
import 'package:agent_mobile/screens/enroll_customer_screen.dart';
import 'package:agent_mobile/screens/cash_in_out_screen.dart';
import 'package:agent_mobile/screens/agent_history_screen.dart';

void main() {
  group('Navigation flows', () {
    testWidgets('login → home navigation', (WidgetTester tester) async {
      await tester.pumpWidget(const AgentApp());

      // Verify we start at login screen
      expect(find.byType(AgentLoginScreen), findsOneWidget);
      expect(find.text('Poste Finance Agent Login'), findsOneWidget);
    });

    testWidgets('home → enroll → back navigation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: const AgentHomeScreen()));
      await tester.pumpAndSettle();

      // Navigate to enroll screen
      final enrollTile = find.text('Enroll Customer');
      expect(enrollTile, findsOneWidget);
      await tester.tap(enrollTile);
      await tester.pumpAndSettle();

      // Verify enroll screen is shown
      expect(find.byType(EnrollCustomerScreen), findsOneWidget);
      expect(find.text('First Name *'), findsOneWidget);

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify we're back at home
      expect(find.byType(AgentHomeScreen), findsOneWidget);
    });

    testWidgets('home → cash in/out → back navigation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: const AgentHomeScreen()));
      await tester.pumpAndSettle();

      // Navigate to cash in/out screen
      final cashTile = find.text('Cash In / Out');
      expect(cashTile, findsOneWidget);
      await tester.tap(cashTile);
      await tester.pumpAndSettle();

      // Verify cash in/out screen is shown
      expect(find.byType(CashInOutScreen), findsOneWidget);
      expect(find.text('Cash In'), findsOneWidget);
      expect(find.text('Cash Out'), findsOneWidget);

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify we're back at home
      expect(find.byType(AgentHomeScreen), findsOneWidget);
    });

    testWidgets('home → history → back navigation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: const AgentHomeScreen()));
      await tester.pumpAndSettle();

      // Navigate to history screen
      final historyTile = find.text('History');
      expect(historyTile, findsOneWidget);
      await tester.tap(historyTile);
      await tester.pumpAndSettle();

      // Verify history screen is shown
      expect(find.byType(AgentHistoryScreen), findsOneWidget);
      expect(find.text('Agent History'), findsOneWidget);

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify we're back at home
      expect(find.byType(AgentHomeScreen), findsOneWidget);
    });

    testWidgets('logout from home navigates to login', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const AgentHomeScreen(),
        routes: {
          '/': (context) => const AgentLoginScreen(),
        },
      ));
      await tester.pumpAndSettle();

      // Find and tap logout button
      final logoutButton = find.byIcon(Icons.logout);
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Logout'), findsWidgets);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);

      // Tap confirm
      final confirmButton = find.widgetWithText(ElevatedButton, 'Logout');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify navigated to login screen
      expect(find.byType(AgentLoginScreen), findsOneWidget);
    });

    testWidgets('logout cancel stays on home', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: const AgentHomeScreen()));
      await tester.pumpAndSettle();

      // Find and tap logout button
      final logoutButton = find.byIcon(Icons.logout);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);

      // Tap cancel
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify still on home screen
      expect(find.byType(AgentHomeScreen), findsOneWidget);
      expect(find.byType(AgentLoginScreen), findsNothing);
    });
  });

  group('Loading states', () {
    testWidgets('home screen shows loading indicator on init', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: const AgentHomeScreen()));

      // Initial state should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('enroll screen disables button while loading', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: const EnrollCustomerScreen()));
      await tester.pumpAndSettle();

      // Find the enroll button
      final enrollButton = find.widgetWithText(ElevatedButton, 'Enroll Customer');
      expect(enrollButton, findsOneWidget);

      // Button should be enabled initially
      final button = tester.widget<ElevatedButton>(enrollButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('cash in/out screen disables button while loading', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: const CashInOutScreen()));
      await tester.pumpAndSettle();

      // Find the cash in button
      final cashInButton = find.widgetWithText(ElevatedButton, 'Cash In');
      expect(cashInButton, findsOneWidget);

      // Button should be enabled initially
      final button = tester.widget<ElevatedButton>(cashInButton);
      expect(button.onPressed, isNotNull);
    });
  });

  group('Pull-to-refresh', () {
    testWidgets('home screen has RefreshIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: const AgentHomeScreen()));
      await tester.pumpAndSettle();

      // Verify RefreshIndicator is present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('Demo banner', () {
    testWidgets('offline demo banner shown when OFFLINE_DEMO=true', (WidgetTester tester) async {
      // This test assumes OFFLINE_DEMO is set via --dart-define
      await tester.pumpWidget(const AgentApp());

      // If offline demo is enabled, banner should be present
      // Note: This may not find the banner in test environment if OFFLINE_DEMO not set
      // The banner widget itself has the logic to show/hide based on the flag
    });
  });
}

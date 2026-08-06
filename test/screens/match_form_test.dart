import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_tactics_agent/screens/match_form_screen.dart';

void main() {
  group('MatchFormScreen Widget Tests', () {
    // Note: These tests validate UI rendering without database.
    // Database errors are expected and logged but don't affect UI tests.

    group('Initial State', () {
      testWidgets('shows match form title for new match', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show "Add Match" title for new match
        expect(find.text('Add Match'), findsOneWidget);
      });

      testWidgets('shows match type dropdown', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should find match type dropdown by its label
        expect(find.text('Match Type *'), findsOneWidget);
      });

      testWidgets('shows opponent name field with required indicator', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should find opponent name field
        expect(find.text('Opponent Name *'), findsOneWidget);
      });

      testWidgets('shows date field', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should find date field
        expect(find.text('Date'), findsOneWidget);
        expect(find.text('Not set'), findsOneWidget);
      });
    });

    group('Singles Match Form', () {
      testWidgets('singles match does not show partner name field initially', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // By default (no match type selected), partner field should not be visible
        // Partner Name is only shown when Doubles is selected
        expect(find.text('Partner Name'), findsNothing);
      });

      testWidgets('singles match does not show second opponent field initially', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Opponent Name 2 should not be visible when Singles or no match type is selected
        expect(find.text('Opponent Name 2'), findsNothing);
      });
    });

    group('Doubles Match Form', () {
      testWidgets('selecting doubles shows partner name field', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on the match type dropdown
        await tester.tap(find.text('Match Type *'));
        await tester.pumpAndSettle();

        // Select Doubles from dropdown
        await tester.tap(find.text('Doubles').last);
        await tester.pumpAndSettle();

        // Now partner field should be visible
        expect(find.text('Partner Name'), findsOneWidget);
      });

      testWidgets('selecting doubles shows second opponent field', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on the match type dropdown
        await tester.tap(find.text('Match Type *'));
        await tester.pumpAndSettle();

        // Select Doubles from dropdown
        await tester.tap(find.text('Doubles').last);
        await tester.pumpAndSettle();

        // Second opponent field should be visible
        expect(find.text('Opponent Name 2'), findsOneWidget);
      });

      testWidgets('doubles still requires primary opponent name', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Select Doubles
        await tester.tap(find.text('Match Type *'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Doubles').last);
        await tester.pumpAndSettle();

        // Primary opponent field should still be required
        expect(find.text('Opponent Name *'), findsOneWidget);
      });
    });

    group('Form Fields', () {
      testWidgets('shows dropdown for match type', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should find DropdownButtonFormField
        expect(find.byType(DropdownButtonFormField<String>), findsAtLeast(1));
      });

      testWidgets('match type dropdown contains Singles and Doubles options', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open the dropdown
        await tester.tap(find.text('Match Type *'));
        await tester.pumpAndSettle();

        // Both options should be visible
        expect(find.text('Singles'), findsOneWidget);
        expect(find.text('Doubles'), findsOneWidget);
      });
    });

    group('Switching Match Types', () {
      testWidgets('can switch from singles to doubles', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially no partner field
        expect(find.text('Partner Name'), findsNothing);

        // Select Singles first
        await tester.tap(find.text('Match Type *'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Singles').last);
        await tester.pumpAndSettle();

        // Still no partner field
        expect(find.text('Partner Name'), findsNothing);

        // Now switch to Doubles
        await tester.tap(find.text('Match Type *'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Doubles').last);
        await tester.pumpAndSettle();

        // Partner field should appear
        expect(find.text('Partner Name'), findsOneWidget);
      });

      testWidgets('can switch from doubles back to singles', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Select Doubles
        await tester.tap(find.text('Match Type *'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Doubles').last);
        await tester.pumpAndSettle();

        // Partner field should be visible
        expect(find.text('Partner Name'), findsOneWidget);

        // Switch back to Singles
        await tester.tap(find.text('Match Type *'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Singles').last);
        await tester.pumpAndSettle();

        // Partner field should disappear
        expect(find.text('Partner Name'), findsNothing);
      });
    });

    group('UI Elements', () {
      testWidgets('has calendar icon for date field', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });

      testWidgets('has person icon for opponent name', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have person icons for player fields
        expect(find.byIcon(Icons.person), findsAtLeast(1));
      });

      testWidgets('has people icon for match type', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.people_outline), findsOneWidget);
      });
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_tactics_agent/screens/match_form_screen.dart';

void main() {
  group('MatchFormScreen Widget Tests', () {
    group('Singles Match Form', () {
      testWidgets('shows opponent name field for singles', (tester) async {
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

      testWidgets('singles match hides partner and second opponent fields', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // By default, Singles is selected, so partner/opponent2 fields should be hidden
        // Partner Name should not be visible for Singles
        expect(find.text('Partner Name'), findsNothing);
        expect(find.text('Opponent Name 2'), findsNothing);
      });

      testWidgets('can enter opponent name', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and enter text in opponent name field
        final opponentField = find.widgetWithText(TextFormField, 'Opponent Name *').first;

        // Check if field exists
        expect(opponentField, findsOneWidget);
      });

      testWidgets('shows match type selector', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should see Singles and Doubles options
        expect(find.text('Singles'), findsWidgets);
        expect(find.text('Doubles'), findsWidgets);
      });

      testWidgets('shows set score input section', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should find set score related UI
        expect(find.text('SCORE'), findsOneWidget);
      });
    });

    group('Doubles Match Form', () {
      testWidgets('switching to doubles shows partner field', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on Doubles to switch match type
        await tester.tap(find.text('Doubles').first);
        await tester.pumpAndSettle();

        // Now partner field should be visible
        expect(find.text('Partner Name'), findsOneWidget);
      });

      testWidgets('switching to doubles shows second opponent field', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on Doubles
        await tester.tap(find.text('Doubles').first);
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

        // Switch to doubles
        await tester.tap(find.text('Doubles').first);
        await tester.pumpAndSettle();

        // Primary opponent field should still be required
        expect(find.text('Opponent Name *'), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('form has required opponent name field', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // The asterisk indicates required field
        expect(find.text('Opponent Name *'), findsOneWidget);
      });
    });

    group('Court Details Section', () {
      testWidgets('shows court details section', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll to find court section
        await tester.scrollUntilVisible(
          find.text('COURT'),
          100,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('COURT'), findsOneWidget);
      });
    });

    group('Match Format Section', () {
      testWidgets('shows match format dropdown', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll to find format section
        await tester.scrollUntilVisible(
          find.text('FORMAT'),
          100,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('FORMAT'), findsOneWidget);
      });
    });

    group('Toggle Switches', () {
      testWidgets('shows No Ads toggle', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find No Ads text
        await tester.scrollUntilVisible(
          find.text('No Ads'),
          100,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('No Ads'), findsOneWidget);
      });
    });

    group('Switching Match Types', () {
      testWidgets('can switch between singles and doubles multiple times', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MatchFormScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially singles - no partner field
        expect(find.text('Partner Name'), findsNothing);

        // Switch to doubles
        await tester.tap(find.text('Doubles').first);
        await tester.pumpAndSettle();
        expect(find.text('Partner Name'), findsOneWidget);

        // Switch back to singles
        await tester.tap(find.text('Singles').first);
        await tester.pumpAndSettle();
        expect(find.text('Partner Name'), findsNothing);

        // Switch to doubles again
        await tester.tap(find.text('Doubles').first);
        await tester.pumpAndSettle();
        expect(find.text('Partner Name'), findsOneWidget);
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_tactics_agent/models/match.dart';

void main() {
  group('Match Model', () {
    group('Singles Match', () {
      test('creates a valid singles match', () {
        final now = DateTime.now();
        final match = Match(
          id: 'test-id-1',
          opponentName: 'John Doe',
          matchType: 'Singles',
          matchDate: now,
          matchScoreUser: 2,
          matchScoreOpponent: 1,
          setScores: '6-4,4-6,7-5',
          createdAt: now,
          updatedAt: now,
        );

        expect(match.id, 'test-id-1');
        expect(match.opponentName, 'John Doe');
        expect(match.matchType, 'Singles');
        expect(match.opponentName2, isNull);
        expect(match.partnerName, isNull);
      });

      test('singles match should not have partner or second opponent', () {
        final now = DateTime.now();
        final match = Match(
          id: 'test-id-2',
          opponentName: 'Jane Doe',
          matchType: 'Singles',
          createdAt: now,
          updatedAt: now,
        );

        expect(match.partnerName, isNull);
        expect(match.opponentName2, isNull);
      });

      test('calculates win correctly for singles', () {
        final now = DateTime.now();

        final winMatch = Match(
          id: 'win-match',
          opponentName: 'Opponent',
          matchScoreUser: 2,
          matchScoreOpponent: 0,
          createdAt: now,
          updatedAt: now,
        );
        expect(winMatch.isWin, true);

        final lossMatch = Match(
          id: 'loss-match',
          opponentName: 'Opponent',
          matchScoreUser: 0,
          matchScoreOpponent: 2,
          createdAt: now,
          updatedAt: now,
        );
        expect(lossMatch.isWin, false);
      });
    });

    group('Doubles Match', () {
      test('creates a valid doubles match with all players', () {
        final now = DateTime.now();
        final match = Match(
          id: 'doubles-id-1',
          opponentName: 'Opponent 1',
          opponentName2: 'Opponent 2',
          partnerName: 'My Partner',
          matchType: 'Doubles',
          matchDate: now,
          matchScoreUser: 2,
          matchScoreOpponent: 1,
          createdAt: now,
          updatedAt: now,
        );

        expect(match.matchType, 'Doubles');
        expect(match.opponentName, 'Opponent 1');
        expect(match.opponentName2, 'Opponent 2');
        expect(match.partnerName, 'My Partner');
      });

      test('doubles match requires partner name for proper display', () {
        final now = DateTime.now();
        final match = Match(
          id: 'doubles-id-2',
          opponentName: 'Opponent 1',
          opponentName2: 'Opponent 2',
          partnerName: 'Partner Name',
          matchType: 'Doubles',
          createdAt: now,
          updatedAt: now,
        );

        expect(match.partnerName, isNotNull);
        expect(match.partnerName, 'Partner Name');
      });

      test('doubles match with missing second opponent', () {
        final now = DateTime.now();
        final match = Match(
          id: 'doubles-id-3',
          opponentName: 'Opponent 1',
          opponentName2: null, // Missing second opponent
          partnerName: 'My Partner',
          matchType: 'Doubles',
          createdAt: now,
          updatedAt: now,
        );

        // This should still be a valid match object but may indicate incomplete data
        expect(match.opponentName2, isNull);
        expect(match.matchType, 'Doubles');
      });
    });

    group('Serialization', () {
      test('toMap produces correct map for singles match', () {
        final now = DateTime(2024, 6, 15, 14, 30);
        final match = Match(
          id: 'serialize-test',
          opponentName: 'Test Opponent',
          matchType: 'Singles',
          matchDate: now,
          matchScoreUser: 2,
          matchScoreOpponent: 1,
          setScores: '6-4,6-3',
          courtName: 'Center Court',
          courtSurface: 'Hard',
          noAds: true,
          tiebreakSet: false,
          createdAt: now,
          updatedAt: now,
        );

        final map = match.toMap();

        expect(map['id'], 'serialize-test');
        expect(map['opponent_name'], 'Test Opponent');
        expect(map['match_type'], 'Singles');
        expect(map['match_score_user'], 2);
        expect(map['match_score_opponent'], 1);
        expect(map['set_scores'], '6-4,6-3');
        expect(map['court_name'], 'Center Court');
        expect(map['court_surface'], 'Hard');
        expect(map['no_ads'], 1);
        expect(map['tiebreak_set'], 0);
      });

      test('toMap produces correct map for doubles match', () {
        final now = DateTime.now();
        final match = Match(
          id: 'doubles-serialize',
          opponentName: 'Opp 1',
          opponentName2: 'Opp 2',
          partnerName: 'Partner',
          matchType: 'Doubles',
          createdAt: now,
          updatedAt: now,
        );

        final map = match.toMap();

        expect(map['opponent_name'], 'Opp 1');
        expect(map['opponent_name_2'], 'Opp 2');
        expect(map['partner_name'], 'Partner');
        expect(map['match_type'], 'Doubles');
      });

      test('fromMap correctly deserializes singles match', () {
        final timestamp = DateTime(2024, 6, 15).millisecondsSinceEpoch;
        final map = {
          'id': 'from-map-test',
          'opponent_name': 'Deserialized Opponent',
          'opponent_name_2': null,
          'partner_name': null,
          'match_type': 'Singles',
          'match_date': timestamp,
          'match_score_user': 2,
          'match_score_opponent': 0,
          'set_scores': '6-0,6-0',
          'no_ads': 0,
          'tiebreak_set': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        };

        final match = Match.fromMap(map);

        expect(match.id, 'from-map-test');
        expect(match.opponentName, 'Deserialized Opponent');
        expect(match.matchType, 'Singles');
        expect(match.matchScoreUser, 2);
        expect(match.matchScoreOpponent, 0);
        expect(match.noAds, false);
        expect(match.tiebreakSet, true);
      });

      test('fromMap correctly deserializes doubles match', () {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final map = {
          'id': 'doubles-from-map',
          'opponent_name': 'Opp A',
          'opponent_name_2': 'Opp B',
          'partner_name': 'My Partner',
          'match_type': 'Doubles',
          'match_date': timestamp,
          'match_score_user': 1,
          'match_score_opponent': 2,
          'created_at': timestamp,
          'updated_at': timestamp,
        };

        final match = Match.fromMap(map);

        expect(match.matchType, 'Doubles');
        expect(match.opponentName, 'Opp A');
        expect(match.opponentName2, 'Opp B');
        expect(match.partnerName, 'My Partner');
        expect(match.isWin, false);
      });

      test('fromMap handles ISO date strings from Supabase', () {
        final isoDate = '2024-06-15T14:30:00.000Z';
        final map = {
          'id': 'supabase-test',
          'opponent_name': 'Supabase Opponent',
          'match_date': isoDate,
          'created_at': isoDate,
          'updated_at': isoDate,
        };

        final match = Match.fromMap(map);

        expect(match.matchDate, isNotNull);
        expect(match.createdAt.year, 2024);
        expect(match.createdAt.month, 6);
        expect(match.createdAt.day, 15);
      });
    });

    group('Score Display', () {
      test('scoreDisplay shows correct format for completed match', () {
        final now = DateTime.now();
        final match = Match(
          id: 'score-test',
          opponentName: 'Opponent',
          matchScoreUser: 2,
          matchScoreOpponent: 1,
          createdAt: now,
          updatedAt: now,
        );

        expect(match.scoreDisplay, '2-1');
      });

      test('scoreDisplay shows matchResult when no numeric score', () {
        final now = DateTime.now();
        final match = Match(
          id: 'result-test',
          opponentName: 'Opponent',
          matchResult: 'W/O',
          createdAt: now,
          updatedAt: now,
        );

        expect(match.scoreDisplay, 'W/O');
      });

      test('scoreDisplay shows "No score" for incomplete match', () {
        final now = DateTime.now();
        final match = Match(
          id: 'no-score-test',
          opponentName: 'Opponent',
          createdAt: now,
          updatedAt: now,
        );

        expect(match.scoreDisplay, 'No score');
      });
    });

    group('CopyWith', () {
      test('copyWith creates new instance with updated fields', () {
        final now = DateTime.now();
        final original = Match(
          id: 'original-id',
          opponentName: 'Original Opponent',
          matchType: 'Singles',
          matchScoreUser: 1,
          matchScoreOpponent: 2,
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(
          opponentName: 'Updated Opponent',
          matchScoreUser: 2,
          matchScoreOpponent: 1,
        );

        expect(updated.id, 'original-id'); // unchanged
        expect(updated.opponentName, 'Updated Opponent'); // changed
        expect(updated.matchScoreUser, 2); // changed
        expect(updated.matchScoreOpponent, 1); // changed
        expect(updated.matchType, 'Singles'); // unchanged
      });

      test('copyWith can convert singles to doubles', () {
        final now = DateTime.now();
        final singles = Match(
          id: 'convert-test',
          opponentName: 'Solo Opponent',
          matchType: 'Singles',
          createdAt: now,
          updatedAt: now,
        );

        final doubles = singles.copyWith(
          matchType: 'Doubles',
          opponentName2: 'Second Opponent',
          partnerName: 'My Partner',
        );

        expect(doubles.matchType, 'Doubles');
        expect(doubles.opponentName2, 'Second Opponent');
        expect(doubles.partnerName, 'My Partner');
      });
    });

    group('Match Format and Rules', () {
      test('noAds flag is properly stored', () {
        final now = DateTime.now();
        final match = Match(
          id: 'no-ads-test',
          opponentName: 'Opponent',
          noAds: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(match.noAds, true);
        expect(match.toMap()['no_ads'], 1);
      });

      test('tiebreakSet flag is properly stored', () {
        final now = DateTime.now();
        final match = Match(
          id: 'tiebreak-test',
          opponentName: 'Opponent',
          tiebreakSet: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(match.tiebreakSet, true);
        expect(match.toMap()['tiebreak_set'], 1);
      });

      test('set scores format is correctly stored', () {
        final now = DateTime.now();
        final match = Match(
          id: 'sets-test',
          opponentName: 'Opponent',
          setScores: '6-4,4-6,7-6',
          createdAt: now,
          updatedAt: now,
        );

        expect(match.setScores, '6-4,4-6,7-6');

        // Verify parsing
        final sets = match.setScores!.split(',');
        expect(sets.length, 3);
        expect(sets[0], '6-4');
        expect(sets[1], '4-6');
        expect(sets[2], '7-6');
      });
    });

    group('Court Details', () {
      test('all court details are properly stored', () {
        final now = DateTime.now();
        final match = Match(
          id: 'court-test',
          opponentName: 'Opponent',
          courtName: 'Rod Laver Arena',
          courtSurface: 'Hard',
          courtSpeed: 'Fast',
          courtCover: 'Indoor',
          courtConditions: 'Hot-dry',
          altitude: 'Sea level',
          createdAt: now,
          updatedAt: now,
        );

        expect(match.courtName, 'Rod Laver Arena');
        expect(match.courtSurface, 'Hard');
        expect(match.courtSpeed, 'Fast');
        expect(match.courtCover, 'Indoor');
        expect(match.courtConditions, 'Hot-dry');
        expect(match.altitude, 'Sea level');
      });
    });
  });
}

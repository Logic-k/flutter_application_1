import 'package:flutter_application_1/features/training/domain/training_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('training catalog', () {
    test('contains the exact eight stable activities in course order', () {
      expect(
        trainingCatalog.map((activity) => activity.id),
        orderedEquals(<String>[
          'comparison',
          'multiplication',
          'sequence',
          'categorization',
          'shape_sudoku',
          'shape_match',
          'sentence_reading',
          'daily_recall',
        ]),
      );
      expect(
        trainingCatalog.map((activity) => activity.id).toSet(),
        hasLength(8),
      );
      expect(
        trainingCatalog.map((activity) => activity.route).toSet(),
        hasLength(8),
      );
    });

    test('defines every locked catalog field', () {
      expect(
        trainingCatalog.map(
          (activity) => <Object?>[
            activity.id,
            activity.displayArea,
            activity.route,
            activity.adaptiveCategory,
            activity.scoreCategory,
            activity.prerequisiteId,
            activity.isAlwaysUnlocked,
          ],
        ),
        equals(<List<Object?>>[
          <Object?>[
            'comparison',
            '계산',
            '/game/comparison',
            'calculation',
            'calculation',
            null,
            false,
          ],
          <Object?>[
            'multiplication',
            '계산',
            '/game/multiplication',
            'calculation',
            'calculation',
            'comparison',
            false,
          ],
          <Object?>[
            'sequence',
            '논리',
            '/game/sequence',
            'logic',
            'logic',
            null,
            false,
          ],
          <Object?>[
            'categorization',
            '논리',
            '/game/categorization',
            'logic',
            'logic',
            'sequence',
            false,
          ],
          <Object?>[
            'shape_sudoku',
            '기억',
            '/game/sudoku',
            'memory',
            'memory',
            null,
            false,
          ],
          <Object?>[
            'shape_match',
            '지각',
            '/game/shape_match',
            'perception',
            'attention',
            null,
            false,
          ],
          <Object?>[
            'sentence_reading',
            '언어',
            '/game/reading',
            'perception',
            'voice',
            'shape_match',
            false,
          ],
          <Object?>[
            'daily_recall',
            '스마트 케어',
            '/training/recall',
            null,
            null,
            null,
            true,
          ],
        ]),
      );

      final categorization = trainingActivityById('categorization');
      expect(categorization.adaptiveCategory, 'logic');
      expect(categorization.scoreCategory, 'logic');
      expect(trainingActivityById('daily_recall').isParticipationOnly, isTrue);
    });

    test('exposes the locked initial and legacy unlock sets', () {
      expect(
        initialTrainingActivityIds,
        equals(<String>{
          'comparison',
          'sequence',
          'shape_sudoku',
          'shape_match',
          'daily_recall',
        }),
      );
      expect(
        legacyTrainingActivityIds,
        equals(trainingCatalog.map((activity) => activity.id).toSet()),
      );
      expect(initialTrainingActivityIds, isNot(contains('multiplication')));
      expect(initialTrainingActivityIds, isNot(contains('categorization')));
      expect(initialTrainingActivityIds, isNot(contains('sentence_reading')));
      expect(
        trainingCatalog
            .where((activity) => activity.isAlwaysUnlocked)
            .map((activity) => activity.id),
        orderedEquals(<String>['daily_recall']),
      );
    });

    test('looks up known IDs and rejects unknown IDs', () {
      for (final activity in trainingCatalog) {
        expect(trainingActivityById(activity.id), same(activity));
        expect(isKnownTrainingActivity(activity.id), isTrue);
      }

      for (final invalidId in <String>[
        '',
        ' ',
        'not_an_activity',
        ' comparison',
        'comparison ',
        'Comparison',
        '../comparison',
        'comparison\u0000',
      ]) {
        expect(
          () => trainingActivityById(invalidId),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.name, 'name', 'id')
                .having(
                  (error) => error.invalidValue,
                  'invalidValue',
                  invalidId,
                ),
          ),
        );
        expect(isKnownTrainingActivity(invalidId), isFalse);
      }
    });

    test('has no duplicate IDs or routes', () {
      final ids = trainingCatalog.map((activity) => activity.id).toList();
      final routes = trainingCatalog.map((activity) => activity.route).toList();

      expect(ids.toSet(), hasLength(ids.length));
      expect(routes.toSet(), hasLength(routes.length));
    });
  });
}

import 'package:adblocker_manager/adblocker_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterConfig', () {
    test('creates config with valid filter types', () {
      final config = FilterConfig(filterTypes: [FilterType.easyList]);
      expect(config.filterTypes, hasLength(1));
      expect(config.filterTypes, contains(FilterType.easyList));
    });

    test('creates config with multiple filter types', () {
      final config = FilterConfig(
        filterTypes: [FilterType.easyList, FilterType.adGuard],
      );
      expect(config.filterTypes, hasLength(2));
      expect(config.filterTypes, contains(FilterType.easyList));
      expect(config.filterTypes, contains(FilterType.adGuard));
    });

    test('throws assertion error when filterTypes is empty', () {
      expect(
        () => FilterConfig(filterTypes: []),
        throwsAssertionError,
      );
    });
  });

  group('FilterType', () {
    test('has expected values', () {
      expect(FilterType.values, hasLength(2));
      expect(FilterType.values, contains(FilterType.easyList));
      expect(FilterType.values, contains(FilterType.adGuard));
    });
  });

  group('FilterException', () {
    test('creates exception with message', () {
      const message = 'Test error message';
      final exception = FilterException(message);

      expect(exception.message, equals(message));
      expect(exception.error, isNull);
      expect(exception.toString(), contains(message));
    });

    test('creates exception with message and error', () {
      const message = 'Test error message';
      final error = Exception('Underlying error');
      final exception = FilterException(message, error);

      expect(exception.message, equals(message));
      expect(exception.error, equals(error));
      expect(exception.toString(), contains(message));
      expect(exception.toString(), contains('Caused by'));
    });
  });

  group('FilterInitializationException', () {
    test('is a FilterException', () {
      final exception = FilterInitializationException('Init failed');
      expect(exception, isA<FilterException>());
    });

    test('creates with message and error', () {
      final error = Exception('Asset not found');
      final exception = FilterInitializationException('Init failed', error);

      expect(exception.message, equals('Init failed'));
      expect(exception.error, equals(error));
    });
  });
}

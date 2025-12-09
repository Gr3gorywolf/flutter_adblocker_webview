import 'package:adblocker_core/adblocker_core.dart';
import 'package:adblocker_manager/adblocker_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdblockFilterManager', () {
    late AdblockFilterManager filterManager;

    setUp(() {
      filterManager = AdblockFilterManager();
    });

    group('initialization', () {
      test('initializes successfully with EasyList filter', () async {
        final config = FilterConfig(filterTypes: [FilterType.easyList]);

        await expectLater(
          filterManager.init(config),
          completes,
        );
      });

      test('initializes successfully with AdGuard filter', () async {
        final config = FilterConfig(filterTypes: [FilterType.adGuard]);

        await expectLater(
          filterManager.init(config),
          completes,
        );
      });

      test('initializes successfully with multiple filters', () async {
        final config = FilterConfig(
          filterTypes: [FilterType.easyList, FilterType.adGuard],
        );

        await expectLater(
          filterManager.init(config),
          completes,
        );
      });
    });

    group('operations before initialization', () {
      test('shouldBlockResource throws FilterException', () {
        expect(
          () => filterManager.shouldBlockResource('https://ads.example.com'),
          throwsA(isA<FilterException>()),
        );
      });

      test('getCSSRulesForWebsite throws FilterException', () {
        expect(
          () => filterManager.getCSSRulesForWebsite('https://example.com'),
          throwsA(isA<FilterException>()),
        );
      });

      test('getAllResourceRules throws FilterException', () {
        expect(
          () => filterManager.getAllResourceRules(),
          throwsA(isA<FilterException>()),
        );
      });
    });

    group('after initialization', () {
      setUp(() async {
        final config = FilterConfig(
          filterTypes: [FilterType.easyList, FilterType.adGuard],
        );
        await filterManager.init(config);
      });

      test('shouldBlockResource returns false for normal URLs', () {
        expect(
          filterManager.shouldBlockResource('https://example.com/page.html'),
          isFalse,
        );
      });

      test('getCSSRulesForWebsite returns list', () {
        final rules =
            filterManager.getCSSRulesForWebsite('https://example.com');
        expect(rules, isA<List<String>>());
      });

      test('getAllResourceRules returns combined rules from all filters', () {
        final rules = filterManager.getAllResourceRules();
        expect(rules, isA<List<ResourceRule>>());
        expect(rules, isNotEmpty);
      });

      test('getAllResourceRules contains both block and exception rules', () {
        final rules = filterManager.getAllResourceRules();
        final blockRules = rules.where((r) => !r.isException);
        final exceptionRules = rules.where((r) => r.isException);

        expect(blockRules, isNotEmpty);
        expect(exceptionRules, isNotEmpty);
      });
    });

    group('isInitialized', () {
      test('returns false before initialization', () {
        final manager = AdblockFilterManager();
        expect(manager.isInitialized, isFalse);
      });

      test('returns true after initialization', () async {
        final manager = AdblockFilterManager();
        await manager.init(
          FilterConfig(filterTypes: [FilterType.easyList]),
        );
        expect(manager.isInitialized, isTrue);
      });
    });

    group('dispose', () {
      test('dispose completes without error', () async {
        final manager = AdblockFilterManager();
        await manager.init(
          FilterConfig(filterTypes: [FilterType.easyList]),
        );

        await expectLater(manager.dispose(), completes);
      });

      test('operations throw after dispose', () async {
        final manager = AdblockFilterManager();
        await manager.init(
          FilterConfig(filterTypes: [FilterType.easyList]),
        );
        await manager.dispose();

        expect(
          () => manager.shouldBlockResource('https://example.com'),
          throwsA(isA<FilterException>()),
        );
      });

      test('init throws after dispose', () async {
        final manager = AdblockFilterManager();
        await manager.init(
          FilterConfig(filterTypes: [FilterType.easyList]),
        );
        await manager.dispose();

        await expectLater(
          manager.init(FilterConfig(filterTypes: [FilterType.easyList])),
          throwsA(isA<FilterException>()),
        );
      });
    });
  });
}

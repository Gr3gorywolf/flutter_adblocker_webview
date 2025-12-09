import 'package:adblocker_manager/adblocker_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Whitelist functionality', () {
    late AdblockFilterManager filterManager;

    setUp(() async {
      filterManager = AdblockFilterManager();
      await filterManager.init(
        FilterConfig(
          filterTypes: [FilterType.easyList],
          allowedDomains: ['example.com'],
        ),
      );
    });

    tearDown(() async {
      await filterManager.dispose();
    });

    test('initial allowed domains from config', () {
      expect(filterManager.allowedDomains, contains('example.com'));
    });

    test('addAllowedDomain adds domain', () {
      filterManager.addAllowedDomain('trusted.com');
      expect(filterManager.allowedDomains, contains('trusted.com'));
    });

    test('removeAllowedDomain removes domain', () {
      filterManager.addAllowedDomain('temp.com');
      expect(filterManager.allowedDomains, contains('temp.com'));

      final removed = filterManager.removeAllowedDomain('temp.com');
      expect(removed, isTrue);
      expect(filterManager.allowedDomains, isNot(contains('temp.com')));
    });

    test('removeAllowedDomain returns false for non-existent domain', () {
      final removed = filterManager.removeAllowedDomain('nonexistent.com');
      expect(removed, isFalse);
    });

    test('isAllowedDomain returns true for whitelisted domain', () {
      expect(filterManager.isAllowedDomain('https://example.com'), isTrue);
    });

    test('isAllowedDomain returns true for subdomain of whitelisted domain',
        () {
      expect(filterManager.isAllowedDomain('https://sub.example.com'), isTrue);
    });

    test('isAllowedDomain returns false for non-whitelisted domain', () {
      expect(filterManager.isAllowedDomain('https://other.com'), isFalse);
    });

    test('shouldBlockResource returns false for whitelisted domain', () {
      // Even if this would normally be blocked, it should be allowed
      expect(
        filterManager.shouldBlockResource('https://ads.example.com'),
        isFalse,
      );
    });

    test('getCSSRulesForWebsite returns empty for whitelisted domain', () {
      final rules = filterManager.getCSSRulesForWebsite('https://example.com');
      expect(rules, isEmpty);
    });

    test('domains are stored lowercase', () {
      filterManager.addAllowedDomain('UPPERCASE.COM');
      expect(filterManager.allowedDomains, contains('uppercase.com'));
      expect(filterManager.isAllowedDomain('https://uppercase.com'), isTrue);
    });
  });
}

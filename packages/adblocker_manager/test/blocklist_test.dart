import 'package:adblocker_manager/adblocker_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Blocklist functionality', () {
    late AdblockFilterManager manager;

    setUp(() async {
      manager = AdblockFilterManager();
      await manager.init(
        FilterConfig(
          filterTypes: [FilterType.easyList],
          blockedDomains: ['custom-ads.com'],
        ),
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('initial blocked domains from config', () {
      expect(manager.blockedDomains, contains('custom-ads.com'));
    });

    test('addBlockedDomain adds domain', () {
      manager.addBlockedDomain('new-tracker.com');
      expect(manager.blockedDomains, contains('new-tracker.com'));
    });

    test('removeBlockedDomain removes domain', () {
      manager.addBlockedDomain('temp.com');
      expect(manager.blockedDomains, contains('temp.com'));
      final removed = manager.removeBlockedDomain('temp.com');
      expect(removed, isTrue);
      expect(manager.blockedDomains, isNot(contains('temp.com')));
    });

    test('removeBlockedDomain returns false for non-existent domain', () {
      final removed = manager.removeBlockedDomain('nonexistent.com');
      expect(removed, isFalse);
    });

    test('isBlockedDomain returns true for blocked domain', () {
      expect(manager.isBlockedDomain('custom-ads.com'), isTrue);
    });

    test('isBlockedDomain returns true for subdomain of blocked domain', () {
      expect(manager.isBlockedDomain('foo.custom-ads.com'), isTrue);
    });

    test('isBlockedDomain returns false for non-blocked domain', () {
      expect(manager.isBlockedDomain('example.com'), isFalse);
    });

    test('shouldBlockResource returns true for blocked domain', () {
      expect(
        manager.shouldBlockResource('https://custom-ads.com/script.js'),
        isTrue,
      );
    });

    test('allowed domains have priority over blocked domains', () async {
      await manager.dispose();
      manager = AdblockFilterManager();
      await manager.init(
        FilterConfig(
          filterTypes: [FilterType.easyList],
          allowedDomains: ['trusted.com'],
          blockedDomains: ['trusted.com'], // Same domain in both lists
        ),
      );
      // Allowed should have priority
      expect(
        manager.shouldBlockResource('https://trusted.com/script.js'),
        isFalse,
      );
    });

    test('getAllResourceRules includes blocked domains', () {
      final rules = manager.getAllResourceRules();
      final customRule = rules.where((r) => r.url == 'custom-ads.com');
      expect(customRule, isNotEmpty);
      expect(customRule.first.isException, isFalse);
    });

    test('domains are stored lowercase', () {
      manager.addBlockedDomain('UPPERCASE.COM');
      expect(manager.blockedDomains, contains('uppercase.com'));
      expect(manager.isBlockedDomain('uppercase.com'), isTrue);
    });
  });
}

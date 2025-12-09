import 'package:adblocker_manager/adblocker_manager.dart';
import 'package:adblocker_webview/src/block_resource_loading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getResourceLoadingBlockerScript', () {
    test('generates valid JavaScript with empty rules', () {
      final script = getResourceLoadingBlockerScript([]);

      expect(script, contains('blockUrls'));
      expect(script, contains('exceptionUrls'));
      expect(script, contains('shouldBlock'));
    });

    test('generates JavaScript with block rules', () {
      final rules = [
        ResourceRule(url: 'ads.example.com', isException: false),
        ResourceRule(url: 'tracker.com', isException: false),
      ];

      final script = getResourceLoadingBlockerScript(rules);

      expect(script, contains('ads.example.com'));
      expect(script, contains('tracker.com'));
      expect(script, contains('blockUrls'));
    });

    test('generates JavaScript with exception rules', () {
      final rules = [
        ResourceRule(url: 'allowed.example.com', isException: true),
      ];

      final script = getResourceLoadingBlockerScript(rules);

      expect(script, contains('allowed.example.com'));
      expect(script, contains('exceptionUrls'));
    });

    test('generates JavaScript with mixed rules', () {
      final rules = [
        ResourceRule(url: 'ads.example.com', isException: false),
        ResourceRule(url: 'allowed.example.com', isException: true),
      ];

      final script = getResourceLoadingBlockerScript(rules);

      expect(script, contains('ads.example.com'));
      expect(script, contains('allowed.example.com'));
    });

    test('generates self-invoking function', () {
      final script = getResourceLoadingBlockerScript([]);

      expect(script, contains('(function()'));
      expect(script, contains('})();'));
    });

    test('overrides XMLHttpRequest', () {
      final script = getResourceLoadingBlockerScript([]);

      expect(script, contains('XMLHttpRequest'));
      expect(script, contains('xhr.open'));
    });

    test('overrides Fetch API', () {
      final script = getResourceLoadingBlockerScript([]);

      expect(script, contains('window.fetch'));
      expect(script, contains('origFetch'));
    });

    test('blocks dynamic script and iframe loading', () {
      final script = getResourceLoadingBlockerScript([]);

      expect(script, contains('document.createElement'));
      expect(script, contains("'script'"));
      expect(script, contains("'iframe'"));
    });

    test('blocks image loading', () {
      final script = getResourceLoadingBlockerScript([]);

      expect(script, contains('HTMLImageElement.prototype'));
    });

    test('blocks WebSocket connections', () {
      final script = getResourceLoadingBlockerScript([]);

      expect(script, contains('WebSocket'));
      expect(script, contains('OrigWS'));
    });

    test('uses indexed rules for fast lookups', () {
      final script = getResourceLoadingBlockerScript([]);

      expect(script, contains('blockIndex'));
      expect(script, contains('new Map'));
    });

    test('uses Set for exception rules', () {
      final script = getResourceLoadingBlockerScript([]);

      expect(script, contains('new Set'));
      expect(script, contains('isException'));
    });
  });
}

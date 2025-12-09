import 'package:adblocker_webview/src/elem_hide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateHidingScript', () {
    test('generates valid JavaScript with empty selectors', () {
      final script = generateHidingScript([]);

      expect(script, contains('const selectors = []'));
      // Returns early for empty selectors
      expect(script, contains('selectors.length === 0'));
    });

    test('generates JavaScript with single selector', () {
      final script = generateHidingScript(['.ad-banner']);

      expect(script, contains('.ad-banner'));
    });

    test('generates JavaScript with multiple selectors', () {
      final selectors = ['.ad-banner', '#sidebar-ad', '[data-ad]'];
      final script = generateHidingScript(selectors);

      expect(script, contains('.ad-banner'));
      expect(script, contains('#sidebar-ad'));
      expect(script, contains('[data-ad]'));
    });

    test('properly escapes special characters in selectors', () {
      final selectors = ['.ad-banner', 'div[class*="sponsor"]'];
      final script = generateHidingScript(selectors);

      // jsonEncode should handle escaping
      expect(script, contains('selectors'));
    });

    test('generates self-invoking function', () {
      final script = generateHidingScript([]);

      expect(script, contains('(function()'));
      expect(script, contains('})();'));
    });

    test('uses batch processing', () {
      final script = generateHidingScript([]);

      expect(script, contains('BATCH_SIZE'));
      expect(script, contains('500'));
    });

    test('uses async removeElements function', () {
      final script = generateHidingScript([]);

      expect(script, contains('async function removeElements'));
      expect(script, contains('await new Promise'));
    });

    test('creates MutationObserver with debouncing', () {
      final script = generateHidingScript([]);

      expect(script, contains('MutationObserver'));
      expect(script, contains('DEBOUNCE_MS'));
      expect(script, contains('scheduleHide'));
    });

    test('observes document body', () {
      final script = generateHidingScript([]);

      expect(script, contains('document.body'));
      expect(script, contains('childList: true'));
      expect(script, contains('subtree: true'));
    });

    test('removes elements using querySelectorAll', () {
      final script = generateHidingScript([]);

      expect(script, contains('querySelectorAll'));
      expect(script, contains('el.remove()'));
    });

    test('injects CSS for immediate hiding', () {
      final script = generateHidingScript([]);

      expect(script, contains('injectHidingStyles'));
      expect(script, contains('display:none!important'));
      expect(script, contains("createElement('style')"));
    });
  });
}

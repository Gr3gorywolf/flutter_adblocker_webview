import 'package:adblocker_webview/src/block_resource_loading.dart';
import 'package:adblocker_webview/src/elem_hide.dart';

import 'package:test/test.dart';

void main() {
  group('Blocker Script Generation', () {
    test('contains beacon blocking logic', () {
      final script = getResourceLoadingBlockerScript([]);
      expect(script, contains('navigator.sendBeacon'));
      expect(script, contains("shouldBlock(url, 'ping')"));
    });

    test('contains strict domain matching logic', () {
      final script = getResourceLoadingBlockerScript([]);
      expect(script, contains("domain.endsWith('.' + ruleDomain)"));
    });
  });

  group('Element Hiding Script Generation', () {
    test('injects styles logically', () {
      final script = generateHidingScript(['.ad', '#banner']);
      expect(
        script,
        contains("selectors.join(',') + ' { display: none !important; }'"),
      );
    });

    test('handles empty selectors safely', () {
      final script = generateHidingScript([]);
      expect(
        script,
        contains(
          'if (!Array.isArray(selectors) || selectors.length === 0) return;',
        ),
      );
    });
  });
}

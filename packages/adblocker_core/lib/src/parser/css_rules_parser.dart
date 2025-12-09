import 'package:adblocker_core/src/rules/css_rule.dart';

/// Optimized CSS rules parser with batch processing support.
///
/// Performance optimizations:
/// - Uses string operations instead of RegExp where possible for hot paths
/// - Supports batch parsing to reduce overhead
/// - Early exit for non-matching lines
class CSSRulesParser {
  // Pre-compiled pattern for complex matching only
  static final _cssRulePattern = RegExp(r'^([^#]*)(##|#@#|#\?#)(.+)$');

  /// Quick check if a line could be a CSS rule (avoids RegExp for non-matches)
  bool _couldBeCSSRule(String line) {
    return line.contains('##') || line.contains('#@#') || line.contains('#?#');
  }

  /// Parses a single line into a CSSRule.
  /// Returns null if the line is not a valid CSS rule.
  CSSRule? parseLine(String line) {
    // Fast path: skip lines that can't be CSS rules
    if (!_couldBeCSSRule(line)) return null;

    final match = _cssRulePattern.firstMatch(line);
    if (match == null) return null;

    final domainGroup = match.group(1);
    final domains = <String>[];
    if (domainGroup != null && domainGroup.isNotEmpty) {
      // Split and normalize domains
      for (final d in domainGroup.split(',')) {
        final trimmed = d.trim().toLowerCase();
        if (trimmed.isNotEmpty) {
          domains.add(trimmed);
        }
      }
    }

    final separator = match.group(2) ?? '##';
    final selector = match.group(3) ?? '';
    final isException = separator == '#@#';

    // Skip complex attribute selectors that are not well-supported
    // if (selector.contains('[') && selector.contains(']')) return null;

    return CSSRule(
      domain: domains,
      selector: selector,
      isException: isException,
    );
  }

  /// Batch parse multiple lines for improved performance.
  ///
  /// This reduces function call overhead when processing large filter lists.
  List<CSSRule> parseLines(Iterable<String> lines) {
    final rules = <CSSRule>[];
    for (final line in lines) {
      if (line.isEmpty) continue;
      final rule = parseLine(line);
      if (rule != null) {
        rules.add(rule);
      }
    }
    return rules;
  }
}

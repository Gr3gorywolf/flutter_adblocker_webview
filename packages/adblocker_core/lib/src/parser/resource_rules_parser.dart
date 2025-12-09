import 'package:adblocker_core/src/rules/resource_rule.dart';

/// Optimized resource rules parser with batch processing support.
///
/// Performance optimizations:
/// - Uses string operations instead of RegExp for hot paths
/// - Supports batch parsing to reduce overhead
/// - Early exit for non-matching lines
class ResourceRulesParser {
  // Pre-compiled pattern for complex matching only
  // Pre-compiled pattern for complex matching only
  // Matches constraint: ||domain^$options
  static final _resourceRulePattern = RegExp(r'\|\|([^$]+)(?:\^)?(?:\$(.*))?');

  /// Quick check if a line could be a resource rule (avoids RegExp for non-matches)
  bool _couldBeResourceRule(String line) {
    // Resource rules start with || or @@||
    return line.startsWith('||') || line.startsWith('@@||');
  }

  /// Parses a single line into a ResourceRule.
  /// Returns null if the line is not a valid resource rule.
  ResourceRule? parseLine(String line) {
    // Fast path: skip lines that can't be resource rules
    if (!_couldBeResourceRule(line)) return null;

    // Check for exception before regex processing
    final isException = line.startsWith('@@');
    final processLine = isException ? line.substring(2) : line;

    final match = _resourceRulePattern.firstMatch(processLine);
    if (match == null) return null;

    final urlPart = match.group(1)?.toLowerCase() ?? '';
    if (urlPart.isEmpty) return null;

    // Remove trailing ^ if captured in group 1 (regex should handle it but for safety)
    final cleanUrl = urlPart.endsWith('^')
        ? urlPart.substring(0, urlPart.length - 1)
        : urlPart;

    final optionsPart = match.group(2);

    List<String>? domains;
    List<String>? resourceTypes;
    var isImportant = false;
    var isThirdParty = false;

    if (optionsPart != null && optionsPart.isNotEmpty) {
      final options = optionsPart.split(',');
      for (final option in options) {
        if (option.startsWith('domain=')) {
          final domainString = option.substring(7);
          domains = domainString.split('|');
        } else if (option == 'important') {
          isImportant = true;
        } else if (option == 'third-party') {
          isThirdParty = true;
        } else {
          // Assume other options are resource types (script, image, etc.)
          // Note: This is a simplification. There are other modifiers like 'match-case', etc.
          // valid resource types: script, image, stylesheet, object, xmlhttprequest, object-subrequest, subdocument, etc.
          resourceTypes ??= [];
          resourceTypes.add(option);
        }
      }
    }

    return ResourceRule(
      url: cleanUrl,
      isException: isException,
      domains: domains,
      resourceTypes: resourceTypes,
      isImportant: isImportant,
      isThirdParty: isThirdParty,
    );
  }

  /// Batch parse multiple lines for improved performance.
  ///
  /// Returns two lists: [blockRules, exceptionRules] for efficient categorization.
  ({List<ResourceRule> blockRules, List<ResourceRule> exceptionRules})
  parseLines(Iterable<String> lines) {
    final blockRules = <ResourceRule>[];
    final exceptionRules = <ResourceRule>[];

    for (final line in lines) {
      if (line.isEmpty) continue;
      final rule = parseLine(line);
      if (rule != null) {
        if (rule.isException) {
          exceptionRules.add(rule);
        } else {
          blockRules.add(rule);
        }
      }
    }

    return (blockRules: blockRules, exceptionRules: exceptionRules);
  }
}

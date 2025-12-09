import 'package:adblocker_core/src/adblocker_filter.dart';
import 'package:adblocker_core/src/lru_cache.dart';
import 'package:adblocker_core/src/parser/css_rules_parser.dart';
import 'package:adblocker_core/src/parser/resource_rules_parser.dart';
import 'package:adblocker_core/src/rules/css_rule.dart';
import 'package:adblocker_core/src/rules/resource_rule.dart';

/// Optimized implementation of AdblockerFilter.
///
/// Performance optimizations:
/// - Domain-based rule indexing for O(1) lookup instead of O(n) linear search
/// - LRU cache for shouldBlockResource decisions
/// - LRU cache for CSS rules per domain
/// - CSS rules indexed by domain for O(k) lookup
/// - Batch parsing for reduced function call overhead
/// - Pre-normalizes domains to lowercase
class AdblockerFilterImpl implements AdblockerFilter {
  // Raw rule storage
  final List<CSSRule> _cssRules = [];
  final List<ResourceRule> _resourceRules = [];
  final List<ResourceRule> _resourceExceptionRules = [];

  // Domain-indexed resource rules for O(1) lookup
  final Map<String, List<ResourceRule>> _rulesByDomain = {};
  final Map<String, List<ResourceRule>> _exceptionsByDomain = {};

  // Domain-indexed CSS rules for O(k) lookup
  final Map<String, List<CSSRule>> _cssRulesByDomain = {};
  final List<CSSRule> _globalCssRules = []; // Rules with empty domain

  // Caches
  final _cssRulesCache = LRUCache<String, List<String>>(100);
  final _blockDecisionCache = LRUCache<String, bool>(500);

  final _cssRulesParser = CSSRulesParser();
  final _resourceRulesParser = ResourceRulesParser();

  @override
  Future<void> init(String filterData) async {
    _parseRules(filterData);
    _buildOptimizedStructures();
  }

  /// Builds optimized data structures after parsing for faster lookups.
  void _buildOptimizedStructures() {
    // Index resource rules by domain
    for (final rule in _resourceRules) {
      final domain = _extractDomainFromRule(rule.url);
      _rulesByDomain.putIfAbsent(domain, () => []).add(rule);
    }

    // Index exception rules by domain
    for (final rule in _resourceExceptionRules) {
      final domain = _extractDomainFromRule(rule.url);
      _exceptionsByDomain.putIfAbsent(domain, () => []).add(rule);
    }

    // Index CSS rules by domain
    for (final rule in _cssRules) {
      if (rule.domain.isEmpty) {
        _globalCssRules.add(rule);
      } else {
        // Check if ALL domains are exclusions (start with ~)
        // If so, treat as global rule (applies everywhere except those domains)
        final allExclusions = rule.domain.every((d) => d.startsWith('~'));
        if (allExclusions) {
          _globalCssRules.add(rule);
        }

        // Also index by domain for faster lookup
        for (final domain in rule.domain) {
          final cleanDomain = domain.startsWith('~')
              ? domain.substring(1)
              : domain;
          _cssRulesByDomain.putIfAbsent(cleanDomain, () => []).add(rule);
        }
      }
    }
  }

  @override
  List<String> getCSSRulesForWebsite(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return [];
    final domain = uri.host.toLowerCase();

    // Check cache first
    final cached = _cssRulesCache.get(domain);
    if (cached != null) return cached;

    final applicableRules = <String>[];
    final exceptionSelectors = <String>{};

    // Get relevant rules for this domain and its parent domains
    final rulesToCheck = <CSSRule>[..._globalCssRules];
    _addRulesForDomainHierarchy(domain, rulesToCheck);

    // First pass: collect exception selectors
    for (final rule in rulesToCheck) {
      if (!rule.isException) continue;
      if (rule.domain.isEmpty ||
          rule.domain.any((d) => _domainMatches(d, domain))) {
        exceptionSelectors.add(rule.selector);
      }
    }

    // Second pass: collect applicable rules (excluding exceptions)
    for (final rule in rulesToCheck) {
      if (rule.isException) continue;
      if (exceptionSelectors.contains(rule.selector)) continue;

      if (rule.domain.isEmpty ||
          rule.domain.any((d) => _domainMatches(d, domain))) {
        applicableRules.add(rule.selector);
      }
    }

    // Cache the result
    _cssRulesCache.put(domain, applicableRules);

    return applicableRules;
  }

  /// Adds CSS rules for a domain and all its parent domains.
  void _addRulesForDomainHierarchy(String domain, List<CSSRule> rules) {
    final parts = domain.split('.');
    for (var i = 0; i < parts.length - 1; i++) {
      final parentDomain = parts.sublist(i).join('.');
      final domainRules = _cssRulesByDomain[parentDomain];
      if (domainRules != null) {
        rules.addAll(domainRules);
      }
    }
  }

  @override
  List<ResourceRule> getAllResourceRules() {
    return [..._resourceRules, ..._resourceExceptionRules];
  }

  @override
  bool shouldBlockResource(String url) {
    final lowerUrl = url.toLowerCase();

    // Check cache first - O(1)
    final cached = _blockDecisionCache.get(lowerUrl);
    if (cached != null) return cached;

    final domain = _extractDomain(lowerUrl);
    final urlWithoutProtocol = _removeProtocol(lowerUrl);

    // Compute blocking decision
    final shouldBlock = _computeBlockDecision(domain, urlWithoutProtocol);

    // Cache the result
    _blockDecisionCache.put(lowerUrl, shouldBlock);

    return shouldBlock;
  }

  /// Computes whether to block a resource based on domain-indexed lookups.
  bool _computeBlockDecision(String domain, String urlWithoutProtocol) {
    // Check exception rules for this domain hierarchy - O(k) where k = rules for domain
    final exceptionRules = _getRulesForDomainHierarchy(
      domain,
      _exceptionsByDomain,
    );
    for (final rule in exceptionRules) {
      if (_matchesRule(urlWithoutProtocol, rule.url)) return false;
    }

    // Check block rules for this domain hierarchy - O(k)
    final blockRules = _getRulesForDomainHierarchy(domain, _rulesByDomain);
    for (final rule in blockRules) {
      if (_matchesRule(urlWithoutProtocol, rule.url)) return true;
    }

    return false;
  }

  /// Gets all rules that apply to a domain and its parent domains.
  List<ResourceRule> _getRulesForDomainHierarchy(
    String domain,
    Map<String, List<ResourceRule>> rulesMap,
  ) {
    final result = <ResourceRule>[];
    final parts = domain.split('.');

    // Check domain and all parent domains (e.g., ads.google.com -> google.com -> com)
    for (var i = 0; i < parts.length; i++) {
      final parentDomain = parts.sublist(i).join('.');
      final rules = rulesMap[parentDomain];
      if (rules != null) {
        result.addAll(rules);
      }
    }

    return result;
  }

  /// Extracts domain from a rule URL (e.g., "google.com/ads" -> "google.com").
  String _extractDomainFromRule(String ruleUrl) {
    final slashIndex = ruleUrl.indexOf('/');
    if (slashIndex == -1) return ruleUrl.toLowerCase();
    return ruleUrl.substring(0, slashIndex).toLowerCase();
  }

  /// Matches a URL against a rule using proper prefix/path matching.
  ///
  /// The rule "google.com/adsense/" should match "google.com/adsense/foo"
  /// but NOT match "google.com/" or "google.com/search".
  bool _matchesRule(String urlWithoutProtocol, String ruleUrl) {
    return urlWithoutProtocol.startsWith(ruleUrl);
  }

  /// Removes the protocol (http:// or https://) from a URL.
  String _removeProtocol(String url) {
    if (url.startsWith('https://')) {
      return url.substring(8);
    } else if (url.startsWith('http://')) {
      return url.substring(7);
    }
    return url;
  }

  @override
  Future<void> dispose() async {
    _cssRules.clear();
    _resourceRules.clear();
    _resourceExceptionRules.clear();
    _rulesByDomain.clear();
    _exceptionsByDomain.clear();
    _cssRulesByDomain.clear();
    _globalCssRules.clear();
    _cssRulesCache.clear();
    _blockDecisionCache.clear();
  }

  void _parseRules(String content) {
    final lines = content.split('\n');
    final trimmedLines = <String>[];

    // Pre-process: trim and filter lines
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('!')) continue;
      trimmedLines.add(trimmed);
    }

    // Batch parse CSS rules
    final cssRules = _cssRulesParser.parseLines(trimmedLines);
    _cssRules.addAll(cssRules);

    // Create a set of lines that were parsed as CSS rules
    // to avoid re-parsing them as resource rules
    final cssLines = <String>{};
    for (final line in trimmedLines) {
      if (line.contains('##') || line.contains('#@#') || line.contains('#?#')) {
        cssLines.add(line);
      }
    }

    // Filter lines for resource parsing
    final resourceLines = trimmedLines.where(
      (line) => !cssLines.contains(line),
    );

    // Batch parse resource rules
    final resourceResult = _resourceRulesParser.parseLines(resourceLines);
    _resourceRules.addAll(resourceResult.blockRules);
    _resourceExceptionRules.addAll(resourceResult.exceptionRules);
  }

  /// Extracts domain from a URL or returns the input if already a domain.
  String _extractDomain(String urlOrDomain) {
    if (urlOrDomain.contains('://')) {
      final uri = Uri.tryParse(urlOrDomain);
      return uri?.host ?? '';
    }
    // Already a domain or path
    return urlOrDomain.split('/').first;
  }

  /// Checks if a rule domain matches the target domain.
  /// Supports subdomain matching: "example.com" matches "sub.example.com"
  bool _domainMatches(String ruleDomain, String targetDomain) {
    if (ruleDomain.isEmpty) return false;

    // Handle exclusion domains (starting with ~)
    if (ruleDomain.startsWith('~')) {
      final excludeDomain = ruleDomain.substring(1);
      return !_domainMatchesExact(excludeDomain, targetDomain);
    }

    return _domainMatchesExact(ruleDomain, targetDomain);
  }

  bool _domainMatchesExact(String ruleDomain, String targetDomain) {
    // Exact match
    if (targetDomain == ruleDomain) return true;
    // Subdomain match
    if (targetDomain.endsWith('.$ruleDomain')) return true;
    return false;
  }
}

/// Statistics about blocked resources
class BlockingStatistics {
  int _blockedResourceCount = 0;
  final Set<String> _appliedCssRules = {};
  final Map<String, int> _blockedDomains = {};

  /// Total number of resources blocked
  int get blockedResourceCount => _blockedResourceCount;

  /// Total number of unique CSS rules applied for element hiding
  int get cssRulesAppliedCount => _appliedCssRules.length;

  /// Map of domain to number of blocked resources from that domain
  Map<String, int> get blockedDomains => Map.unmodifiable(_blockedDomains);

  /// Increments the blocked resource count and tracks the domain
  void recordBlockedResource(String url) {
    _blockedResourceCount++;
    final domain = _extractDomain(url);
    if (domain.isNotEmpty) {
      _blockedDomains[domain] = (_blockedDomains[domain] ?? 0) + 1;
    }
  }

  /// Records CSS rules being applied.
  /// Only unique rules are counted across the session.
  void recordCssRulesApplied(List<String> rules) {
    _appliedCssRules.addAll(rules);
  }

  /// Resets all statistics
  void reset() {
    _blockedResourceCount = 0;
    _appliedCssRules.clear();
    _blockedDomains.clear();
  }

  /// Extracts domain from URL
  String _extractDomain(String url) {
    try {
      final uri = Uri.tryParse(url);
      return uri?.host ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  String toString() =>
      'BlockingStatistics('
      'blockedResources: $_blockedResourceCount, '
      'cssRulesApplied: ${_appliedCssRules.length}, '
      'uniqueDomains: ${_blockedDomains.length})';
}

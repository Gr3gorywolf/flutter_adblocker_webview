import 'package:adblocker_manager/adblocker_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Manager class that handles multiple ad-blocking filters
class AdblockFilterManager {
  final List<AdblockerFilter> _filters = [];
  final Set<String> _allowedDomains = {};
  final Set<String> _blockedDomains = {};
  final BlockingStatistics _statistics = BlockingStatistics();
  bool _isInitialized = false;
  bool _isDisposed = false;

  /// Returns whether the manager has been initialized
  bool get isInitialized => _isInitialized;

  /// Returns the blocking statistics
  BlockingStatistics get statistics => _statistics;

  /// Returns the list of allowed (whitelisted) domains
  Set<String> get allowedDomains => Set.unmodifiable(_allowedDomains);

  /// Returns the list of blocked domains (custom block list)
  Set<String> get blockedDomains => Set.unmodifiable(_blockedDomains);

  /// Initializes the filter manager with the given configuration
  ///
  /// Throws [FilterInitializationException] if initialization fails
  /// Throws [FilterException] if called after dispose
  Future<void> init(FilterConfig config) async {
    if (_isDisposed) {
      throw FilterException(
        'AdblockFilterManager has been disposed and cannot be reused.',
      );
    }

    try {
      _filters.clear();
      _allowedDomains.clear();
      _blockedDomains.clear();

      // Add allowed domains from config
      _allowedDomains.addAll(config.allowedDomains.map((d) => d.toLowerCase()));

      // Add blocked domains from config
      _blockedDomains.addAll(config.blockedDomains.map((d) => d.toLowerCase()));

      for (final filterType in config.filterTypes) {
        final filter = await _createFilter(filterType);
        _filters.add(filter);
      }

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint(
          '[AdblockFilterManager] Initialized with ${_filters.length} filters, '
          '${_allowedDomains.length} allowed, ${_blockedDomains.length} blocked',
        );
      }
    } catch (e) {
      throw FilterInitializationException('Failed to initialize filters', e);
    }
  }

  /// Creates a filter instance based on the filter type
  Future<AdblockerFilter> _createFilter(FilterType type) async {
    final filter = AdblockerFilter.createInstance();
    switch (type) {
      case FilterType.easyList:
        await filter.init(
          await rootBundle.loadString(
            'packages/adblocker_manager/assets/easylist.txt',
          ),
        );
        return filter;
      case FilterType.adGuard:
        await filter.init(
          await rootBundle.loadString(
            'packages/adblocker_manager/assets/adguard_base.txt',
          ),
        );
        return filter;
    }
  }

  /// Adds a domain to the whitelist (allowed domains)
  ///
  /// Resources from this domain will not be blocked.
  void addAllowedDomain(String domain) {
    _checkInitialization();
    _allowedDomains.add(domain.toLowerCase());
    if (kDebugMode) {
      debugPrint('[AdblockFilterManager] Added allowed domain: $domain');
    }
  }

  /// Removes a domain from the whitelist
  ///
  /// Returns true if the domain was removed, false if it wasn't in the list.
  bool removeAllowedDomain(String domain) {
    _checkInitialization();
    final removed = _allowedDomains.remove(domain.toLowerCase());
    if (kDebugMode && removed) {
      debugPrint('[AdblockFilterManager] Removed allowed domain: $domain');
    }
    return removed;
  }

  /// Checks if a domain is in the whitelist
  bool isAllowedDomain(String urlOrDomain) {
    final domain = _extractDomain(urlOrDomain).toLowerCase();
    if (domain.isEmpty) return false;

    return _allowedDomains.any(
      (allowed) => domain == allowed || domain.endsWith('.$allowed'),
    );
  }

  /// Adds a domain to the custom block list
  ///
  /// Resources from this domain will always be blocked.
  void addBlockedDomain(String domain) {
    _checkInitialization();
    _blockedDomains.add(domain.toLowerCase());
    if (kDebugMode) {
      debugPrint('[AdblockFilterManager] Added blocked domain: $domain');
    }
  }

  /// Removes a domain from the custom block list
  ///
  /// Returns true if the domain was removed, false if it wasn't in the list.
  bool removeBlockedDomain(String domain) {
    _checkInitialization();
    final removed = _blockedDomains.remove(domain.toLowerCase());
    if (kDebugMode && removed) {
      debugPrint('[AdblockFilterManager] Removed blocked domain: $domain');
    }
    return removed;
  }

  /// Checks if a domain is in the custom block list
  bool isBlockedDomain(String urlOrDomain) {
    final domain = _extractDomain(urlOrDomain).toLowerCase();
    if (domain.isEmpty) return false;

    return _blockedDomains.any(
      (blocked) => domain == blocked || domain.endsWith('.$blocked'),
    );
  }

  /// Checks if a resource should be blocked
  ///
  /// Returns true if:
  /// 1. Domain is in custom blocked list, OR
  /// 2. Any filter indicates the resource should be blocked
  /// AND the domain is not in the whitelist.
  bool shouldBlockResource(String url) {
    _checkInitialization();

    // Don't block if domain is whitelisted (whitelist has priority)
    if (isAllowedDomain(url)) return false;

    // Check custom blocked domains first
    if (isBlockedDomain(url)) {
      _statistics.recordBlockedResource(url);
      return true;
    }

    // Check if any filter says to block
    final shouldBlock = _filters.any(
      (filter) => filter.shouldBlockResource(url),
    );

    if (shouldBlock) {
      _statistics.recordBlockedResource(url);
    }

    return shouldBlock;
  }

  /// Gets CSS rules for the given website
  ///
  /// Returns empty list if domain is whitelisted, otherwise returns
  /// a list of unique CSS rules from all filters.
  List<String> getCSSRulesForWebsite(String domain) {
    _checkInitialization();

    // Don't apply CSS rules to whitelisted domains
    if (isAllowedDomain(domain)) return [];

    // Combine unique rules from all filters
    final rules = <String>{};
    for (final filter in _filters) {
      rules.addAll(filter.getCSSRulesForWebsite(domain));
    }

    final rulesList = rules.toList();
    _statistics.recordCssRulesApplied(rulesList);

    return rulesList;
  }

  /// Gets all resource rules from all filters
  List<ResourceRule> getAllResourceRules() {
    _checkInitialization();

    final rules = _filters
        .expand((filter) => filter.getAllResourceRules())
        .toList();

    // Add custom blocked domains as ResourceRules
    for (final domain in _blockedDomains) {
      rules.add(ResourceRule(url: domain, isException: false));
    }

    return rules;
  }

  /// Resets the blocking statistics
  void resetStatistics() {
    _statistics.reset();
  }

  /// Disposes all filters and releases resources
  ///
  /// After calling dispose, the manager cannot be reused.
  /// Create a new instance if needed.
  Future<void> dispose() async {
    if (_isDisposed) return;

    for (final filter in _filters) {
      await filter.dispose();
    }
    _filters.clear();
    _allowedDomains.clear();
    _blockedDomains.clear();
    _statistics.reset();
    _isInitialized = false;
    _isDisposed = true;

    if (kDebugMode) {
      debugPrint('[AdblockFilterManager] Disposed');
    }
  }

  /// Extracts domain from URL
  String _extractDomain(String urlOrDomain) {
    // If it's already just a domain (no protocol)
    if (!urlOrDomain.contains('://')) {
      return urlOrDomain.split('/').first;
    }

    try {
      final uri = Uri.tryParse(urlOrDomain);
      return uri?.host ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Checks if the manager is initialized
  void _checkInitialization() {
    if (_isDisposed) {
      throw FilterException(
        'AdblockFilterManager has been disposed and cannot be used.',
      );
    }
    if (!_isInitialized) {
      throw FilterException(
        'AdblockFilterManager is not initialized. Call init() first.',
      );
    }
  }
}

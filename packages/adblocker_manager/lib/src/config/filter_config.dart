import 'package:adblocker_manager/src/config/filter_type.dart';

/// Configuration for the AdblockFilterManager
class FilterConfig {
  /// Creates a new [FilterConfig] instance
  ///
  /// [filterTypes] must not be empty.
  /// [allowedDomains] is an optional list of domains where ad blocking
  /// will be disabled (whitelist).
  /// [blockedDomains] is an optional list of additional domains to always
  /// block, regardless of filter rules.
  FilterConfig({
    required this.filterTypes,
    this.allowedDomains = const [],
    this.blockedDomains = const [],
  }) : assert(
         filterTypes.isNotEmpty,
         'At least one filter type must be specified',
       );

  /// List of filter types to be used
  final List<FilterType> filterTypes;

  /// List of domains where ad blocking is disabled (whitelist)
  ///
  /// When a URL matches one of these domains, no ads will be blocked.
  /// Supports both exact matches and subdomain matches.
  /// Example: 'example.com' will match 'example.com' and 'sub.example.com'
  final List<String> allowedDomains;

  /// List of additional domains to always block (custom block list)
  ///
  /// Resources from these domains will always be blocked.
  /// Supports both exact matches and subdomain matches.
  /// Example: 'ads.example.com' will block 'ads.example.com'
  final List<String> blockedDomains;
}

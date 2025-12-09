import 'package:adblocker_webview/adblocker_webview.dart';
import 'package:flutter/material.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({
    required this.url,
    required this.shouldBlockAds,
    super.key,
  });

  final Uri url;
  final bool shouldBlockAds;

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final _controller = AdBlockerWebviewController.instance;
  bool _canGoBack = false;
  String _appbarUrl = "";
  int _blockedCount = 0;

  @override
  void initState() {
    super.initState();
    _appbarUrl = widget.url.host;
    // Reset statistics for new page
    _controller.resetStatistics();
    //_controller.addAllowedDomain("google.com");
  }

  void _updateBlockedCount() {
    if (!mounted) return;
    final newCount = _controller.statistics.blockedResourceCount;
    if (newCount != _blockedCount) {
      setState(() {
        _blockedCount = newCount;
      });
    }
  }

  void _showStatisticsSheet() {
    final stats = _controller.statistics;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _StatisticsSheet(statistics: stats),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appbarUrl),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                _controller.goBack();
              } else {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _canGoBack
                  ? () {
                      _controller.goBack();
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _controller.reload();
              },
            ),
            // Statistics badge button
            if (widget.shouldBlockAds)
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shield),
                    onPressed: _showStatisticsSheet,
                    tooltip: 'Blocking Statistics',
                  ),
                  if (_blockedCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          _blockedCount > 99 ? '99+' : '$_blockedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        body: AdBlockerWebview(
          url: widget.url,
          shouldBlockAds: widget.shouldBlockAds,
          adBlockerWebviewController: _controller,
          onLoadStart: (url) {
            debugPrint('Started loading: $url');
          },
          onLoadFinished: (url) {
            debugPrint('Finished loading: $url');
            _updateNavigationState(url);
            _updateBlockedCount();
          },
          onLoadError: (url, code) {
            debugPrint('Error loading: $url (code: $code)');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading page: $code'),
                backgroundColor: Colors.red,
              ),
            );
          },
          onProgress: (progress) {
            debugPrint('Loading progress: $progress%');
            // Update blocked count during loading
            _updateBlockedCount();
          },
          onUrlChanged: (url) {
            _updateNavigationState(url);
          },
        ),
      ),
    );
  }

  Future<void> _updateNavigationState(String? url) async {
    if (!mounted) return;

    final canGoBack = await _controller.canGoBack();
    if (canGoBack != _canGoBack) {
      setState(() {
        _canGoBack = canGoBack;
        _appbarUrl = Uri.tryParse(url ?? "")?.host ?? "";
      });
    }
  }
}

/// Bottom sheet widget to display blocking statistics
class _StatisticsSheet extends StatelessWidget {
  const _StatisticsSheet({required this.statistics});

  final BlockingStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final sortedDomains = statistics.blockedDomains.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Text(
                'Ad Blocking Statistics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatRow(
            icon: Icons.block,
            label: 'Resources Blocked',
            value: '${statistics.blockedResourceCount}',
          ),
          _StatRow(
            icon: Icons.style,
            label: 'CSS Rules Applied',
            value: '${statistics.cssRulesAppliedCount}',
          ),
          _StatRow(
            icon: Icons.domain,
            label: 'Unique Domains',
            value: '${statistics.blockedDomains.length}',
          ),
          if (sortedDomains.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Top Blocked Domains',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...sortedDomains.take(5).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}


/// A Trie (prefix tree) data structure optimized for domain matching.
///
/// This implementation stores domains in reverse order (e.g., "com.example.ads")
/// to enable efficient subdomain matching. Lookups are O(k) where k is the
/// domain length, compared to O(n) for linear search.
class DomainTrie {
  final _TrieNode _root = _TrieNode();
  int _size = 0;

  /// Returns the number of domains in the trie
  int get size => _size;

  /// Returns whether the trie is empty
  bool get isEmpty => _size == 0;

  /// Inserts a domain into the trie
  ///
  /// The domain is stored in reverse order for subdomain matching.
  /// Example: "ads.example.com" is stored as "com.example.ads"
  void insert(String domain) {
    if (domain.isEmpty) return;

    final parts = _reverseDomainParts(domain.toLowerCase());
    var current = _root;

    for (final part in parts) {
      current = current.children.putIfAbsent(part, _TrieNode.new);
    }

    if (!current.isEnd) {
      current.isEnd = true;
      _size++;
    }
  }

  /// Checks if a domain or any of its parent domains are in the trie
  ///
  /// Example: If "example.com" is in the trie, this returns true for:
  /// - "example.com"
  /// - "ads.example.com"
  /// - "sub.ads.example.com"
  bool contains(String domain) {
    if (domain.isEmpty || _size == 0) return false;

    final parts = _reverseDomainParts(domain.toLowerCase());
    var current = _root;

    for (final part in parts) {
      // Check if we've reached a matching domain
      if (current.isEnd) return true;

      final child = current.children[part];
      if (child == null) return false;
      current = child;
    }

    return current.isEnd;
  }

  /// Checks if an exact domain is in the trie (no subdomain matching)
  bool containsExact(String domain) {
    if (domain.isEmpty || _size == 0) return false;

    final parts = _reverseDomainParts(domain.toLowerCase());
    var current = _root;

    for (final part in parts) {
      final child = current.children[part];
      if (child == null) return false;
      current = child;
    }

    return current.isEnd;
  }

  /// Removes a domain from the trie
  ///
  /// Returns true if the domain was removed.
  bool remove(String domain) {
    if (domain.isEmpty || _size == 0) return false;

    final parts = _reverseDomainParts(domain.toLowerCase());
    return _removeHelper(_root, parts, 0);
  }

  bool _removeHelper(_TrieNode node, List<String> parts, int index) {
    if (index == parts.length) {
      if (!node.isEnd) return false;
      node.isEnd = false;
      _size--;
      return node.children.isEmpty;
    }

    final part = parts[index];
    final child = node.children[part];
    if (child == null) return false;

    final shouldDeleteChild = _removeHelper(child, parts, index + 1);
    if (shouldDeleteChild) {
      node.children.remove(part);
      return !node.isEnd && node.children.isEmpty;
    }

    return false;
  }

  /// Clears all domains from the trie
  void clear() {
    _root.children.clear();
    _size = 0;
  }

  /// Reverses domain parts for storage
  /// "ads.example.com" -> ["com", "example", "ads"]
  List<String> _reverseDomainParts(String domain) {
    return domain.split('.').reversed.toList();
  }
}

/// Internal node class for the trie
class _TrieNode {
  final Map<String, _TrieNode> children = {};
  bool isEnd = false;
}

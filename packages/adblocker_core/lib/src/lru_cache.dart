/// A simple LRU (Least Recently Used) cache implementation.
///
/// When the cache reaches its maximum size, the least recently accessed
/// item is removed to make room for new entries.
class LRUCache<K, V> {
  /// Creates an LRU cache with the specified maximum size.
  LRUCache(this.maxSize) : assert(maxSize > 0, 'maxSize must be positive');

  /// Maximum number of entries the cache can hold
  final int maxSize;

  /// Internal storage using LinkedHashMap to maintain insertion order
  final _cache = <K, V>{};

  /// Returns the number of items in the cache
  int get size => _cache.length;

  /// Returns whether the cache is empty
  bool get isEmpty => _cache.isEmpty;

  /// Gets a value from the cache, or null if not present.
  ///
  /// Accessing an item moves it to the end (most recently used).
  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  /// Puts a value in the cache.
  ///
  /// If the cache is full, removes the least recently used item.
  void put(K key, V value) {
    // Remove if exists to update position
    _cache.remove(key);

    // Evict oldest if at capacity
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = value;
  }

  /// Gets a value or computes it if not present.
  ///
  /// This is useful for caching expensive computations.
  V getOrPut(K key, V Function() compute) {
    final existing = get(key);
    if (existing != null) {
      return existing;
    }
    final value = compute();
    put(key, value);
    return value;
  }

  /// Checks if a key is in the cache
  bool containsKey(K key) => _cache.containsKey(key);

  /// Removes a key from the cache
  V? remove(K key) => _cache.remove(key);

  /// Clears all entries from the cache
  void clear() => _cache.clear();
}

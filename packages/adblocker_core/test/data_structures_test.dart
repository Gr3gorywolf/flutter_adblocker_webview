import 'package:adblocker_core/adblocker_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainTrie', () {
    late DomainTrie trie;

    setUp(() {
      trie = DomainTrie();
    });

    test('starts empty', () {
      expect(trie.isEmpty, isTrue);
      expect(trie.size, equals(0));
    });

    test('insert increases size', () {
      trie.insert('example.com');
      expect(trie.size, equals(1));
      expect(trie.isEmpty, isFalse);
    });

    test('insert handles duplicate domains', () {
      trie.insert('example.com');
      trie.insert('example.com');
      expect(trie.size, equals(1));
    });

    test('contains finds exact domain', () {
      trie.insert('example.com');
      expect(trie.contains('example.com'), isTrue);
    });

    test('contains finds subdomain when parent is inserted', () {
      trie.insert('example.com');
      expect(trie.contains('ads.example.com'), isTrue);
      expect(trie.contains('sub.ads.example.com'), isTrue);
    });

    test('contains returns false for non-matching domain', () {
      trie.insert('example.com');
      expect(trie.contains('other.com'), isFalse);
    });

    test('contains returns false for partial match', () {
      trie.insert('ads.example.com');
      expect(trie.contains('example.com'), isFalse);
    });

    test('containsExact finds only exact match', () {
      trie.insert('example.com');
      expect(trie.containsExact('example.com'), isTrue);
      expect(trie.containsExact('ads.example.com'), isFalse);
    });

    test('remove removes domain', () {
      trie.insert('example.com');
      expect(trie.remove('example.com'), isTrue);
      expect(trie.size, equals(0));
      expect(trie.contains('example.com'), isFalse);
    });

    test('remove returns false for non-existent domain', () {
      expect(trie.remove('nonexistent.com'), isFalse);
    });

    test('clear removes all domains', () {
      trie.insert('example.com');
      trie.insert('test.com');
      trie.clear();
      expect(trie.isEmpty, isTrue);
      expect(trie.size, equals(0));
    });

    test('case insensitive matching', () {
      trie.insert('EXAMPLE.COM');
      expect(trie.contains('example.com'), isTrue);
      expect(trie.contains('Example.Com'), isTrue);
    });

    test('handles empty domain', () {
      trie.insert('');
      expect(trie.size, equals(0));
      expect(trie.contains(''), isFalse);
    });
  });

  group('LRUCache', () {
    late LRUCache<String, int> cache;

    setUp(() {
      cache = LRUCache<String, int>(3);
    });

    test('starts empty', () {
      expect(cache.isEmpty, isTrue);
      expect(cache.size, equals(0));
    });

    test('put and get work correctly', () {
      cache.put('a', 1);
      expect(cache.get('a'), equals(1));
    });

    test('get returns null for missing key', () {
      expect(cache.get('missing'), isNull);
    });

    test('evicts oldest when at capacity', () {
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      cache.put('d', 4); // Should evict 'a'

      expect(cache.size, equals(3));
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), equals(2));
      expect(cache.get('c'), equals(3));
      expect(cache.get('d'), equals(4));
    });

    test('get updates recency', () {
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      cache.get('a'); // Move 'a' to most recent
      cache.put('d', 4); // Should evict 'b' (now oldest)

      expect(cache.get('a'), equals(1));
      expect(cache.get('b'), isNull);
    });

    test('getOrPut computes and caches', () {
      var computed = 0;
      final result = cache.getOrPut('key', () {
        computed++;
        return 42;
      });

      expect(result, equals(42));
      expect(computed, equals(1));

      // Second call should use cache
      final result2 = cache.getOrPut('key', () {
        computed++;
        return 99;
      });

      expect(result2, equals(42));
      expect(computed, equals(1));
    });

    test('containsKey works correctly', () {
      cache.put('a', 1);
      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
    });

    test('remove removes entry', () {
      cache.put('a', 1);
      expect(cache.remove('a'), equals(1));
      expect(cache.containsKey('a'), isFalse);
    });

    test('clear removes all entries', () {
      cache.put('a', 1);
      cache.put('b', 2);
      cache.clear();
      expect(cache.isEmpty, isTrue);
    });
  });
}

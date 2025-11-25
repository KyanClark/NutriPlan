/// Simple caching service for API responses
class APICacheService {
  static final APICacheService _instance = APICacheService._internal();
  factory APICacheService() => _instance;
  APICacheService._internal();

  // Cache storage
  final Map<String, CacheEntry> _cache = {};
  
  // Default cache duration
  static const Duration _defaultCacheDuration = Duration(minutes: 5);

  /// Get cached data if available and not expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }
    
    return entry.data as T?;
  }

  /// Store data in cache
  void set<T>(String key, T data, {Duration? duration}) {
    final cacheDuration = duration ?? _defaultCacheDuration;
    _cache[key] = CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(cacheDuration),
    );
  }

  /// Check if cache has valid data for key
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }

  /// Remove specific cache entry
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Clear expired entries
  void clearExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.isAfter(entry.expiresAt));
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final total = _cache.length;
    final expired = _cache.values.where((entry) => now.isAfter(entry.expiresAt)).length;
    final valid = total - expired;
    
    return {
      'total': total,
      'valid': valid,
      'expired': expired,
    };
  }

  /// Generate cache key for smart suggestions
  static String generateSmartSuggestionsKey(String userId, String mealCategory, DateTime targetTime) {
    // Round to nearest 30 minutes to increase cache hits
    final roundedTime = DateTime(
      targetTime.year,
      targetTime.month,
      targetTime.day,
      targetTime.hour,
      (targetTime.minute ~/ 30) * 30,
    );
    
    return 'smart_suggestions_${userId}_${mealCategory}_${roundedTime.millisecondsSinceEpoch}';
  }

  /// Generate cache key for AI integration test
  static String generateAITestKey() {
    // Cache AI test for 10 minutes
    final now = DateTime.now();
    final roundedTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      (now.minute ~/ 10) * 10, // Round to nearest 10 minutes
    );
    
    return 'ai_test_${roundedTime.millisecondsSinceEpoch}';
  }
}

/// Cache entry with expiration
class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  
  CacheEntry({
    required this.data,
    required this.expiresAt,
  });
}

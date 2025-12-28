// ============================================================================
// cache_service.dart
// lib/core/services/cache_service.dart
// ============================================================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';
import '../config/app_config.dart';

final cacheServiceProvider = Provider<CacheService>((ref) {
return CacheService(ref.read(storageServiceProvider));
});

class CacheService {
final StorageService _storage;

CacheService(this._storage);

Future<void> cacheData(String key, dynamic data) async {
final timestamp = DateTime.now().millisecondsSinceEpoch;
final cacheData = {
'data': data,
'timestamp': timestamp,
};

await _storage.write(key, jsonEncode(cacheData));
}

Future<dynamic> getCachedData(String key) async {
final cached = _storage.read(key);

if (cached == null) return null;

try {
final Map<String, dynamic> cacheData = jsonDecode(cached);
final timestamp = cacheData['timestamp'] as int;
final now = DateTime.now().millisecondsSinceEpoch;

// Check if cache is still valid
final duration = Duration(minutes: AppConfig.cacheDurationMinutes);
if (now - timestamp > duration.inMilliseconds) {
await _storage.remove(key);
return null;
}

return cacheData['data'];
} catch (e) {
return null;
}
}

Future<void> clearCache() async {
// Clear specific cache keys
final cacheKeys = [
'cached_jobs',
'cached_products',
'cached_categories',
];

for (final key in cacheKeys) {
await _storage.remove(key);
}
}

Future<void> clearExpiredCache() async {
// Implementation for clearing expired cache
}
}

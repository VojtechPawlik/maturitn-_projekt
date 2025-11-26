import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;

import 'firestore_service.dart';

/// Služba pro načítání fotbalových novinek z externího API.
///
/// Implementace počítá s tím, že v Remote Config je klíč:
/// - `news_api_url`  – základní URL endpointu, který vrací seznam článků (JSON)
///   ve tvaru:
///   {
///     "articles": [
///       {
///         "id": "unikatni-id-nebo-url",
///         "title": "...",
///         "content": "...",
///         "imageUrl": "...",
///         "source": "...",
///         "url": "...",
///         "publishedAt": "2025-11-26T12:00:00Z"
///       }
///     ]
///   }
///
/// Můžeš si to namapovat na libovolné vlastní backend/API, hlavní je formát odpovědi.
class NewsApiService {
  String? _baseUrl;

  Future<void> _ensureInitialized() async {
    if (_baseUrl != null) return;
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(seconds: 0),
    ));
    await remoteConfig.fetchAndActivate();
    _baseUrl = remoteConfig.getString('news_api_url');
  }

  /// Načte nejnovější novinky z externího API a převede je na `News`.
  Future<List<News>> fetchLatestNews() async {
    await _ensureInitialized();
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      return [];
    }

    try {
      final response = await http.get(Uri.parse(_baseUrl!));
      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body);
      final List articles = data['articles'] as List? ?? [];

      return articles.map<News>((raw) {
        final map = raw as Map<String, dynamic>;
        final id = (map['id'] ?? map['url'] ?? '').toString();
        final publishedAtStr = (map['publishedAt'] ?? '').toString();
        DateTime? publishedAt;
        if (publishedAtStr.isNotEmpty) {
          publishedAt = DateTime.tryParse(publishedAtStr);
        }

        return News(
          id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
          title: (map['title'] ?? '').toString(),
          content: (map['content'] ?? '').toString(),
          imageUrl: (map['imageUrl'] ?? '').toString(),
          source: (map['source'] ?? '').toString(),
          url: (map['url'] ?? '').toString(),
          publishedAt: publishedAt,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}



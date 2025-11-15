// lib/service/algolia_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:algoliasearch/algoliasearch.dart';
import 'package:http/http.dart' as http;

/// AlgoliaService with retry + REST fallback (works without modifying algolia Dart client options)
class AlgoliaService {
  // Your Algolia credentials
  static const String _appId = 'BVW4RU2C7H';
  static const String _searchApiKey = '39c025c938dad959c70cd40415b02a6b';

  // The SDK client (leave as-is; don't attempt to set .options on it if your package version doesn't allow it)
  static final SearchClient _client = SearchClient(
    appId: _appId,
    apiKey: _searchApiKey,
  );

  // How many times to retry the SDK call before falling back
  static const int _sdkRetries = 2;

  // REST fallback timeouts
  static const Duration _restTimeout = Duration(seconds: 10);

  /// Public search function (uses SDK first, then REST fallback)
  static Future<List<Map<String, dynamic>>> search({
    required String queryText,
    required String indexName,
    String? instituteId,
  }) async {
    // Try SDK with retries
    for (int attempt = 0; attempt <= _sdkRetries; attempt++) {
      try {
        final params = SearchParamsObject(
          query: queryText,
          filters: (instituteId != null && instituteId.isNotEmpty)
              ? 'instituteId:"$instituteId"'
              : null,
        );

        final response = await _client.searchSingleIndex(
          indexName: indexName,
          searchParams: params,
        );

        // Convert hits to List<Map<String,dynamic>>
        return response.hits.map<Map<String, dynamic>>((hit) {
          return Map<String, dynamic>.from(hit as Map);
        }).toList();
      } catch (e, st) {
        // If last attempt, break to fallback
        print('⚠ Algolia SDK attempt #$attempt failed: $e\n$st');
        // small backoff before retrying
        if (attempt < _sdkRetries) {
          await Future.delayed(Duration(milliseconds: 300 + attempt * 300));
          continue;
        } else {
          break;
        }
      }
    }

    // SDK failed after retries -> REST fallback
    try {
      print('➡ Falling back to Algolia REST API (longer timeout)...');

      final restHits = await _searchViaAlgoliaRest(
        queryText: queryText,
        indexName: indexName,
        instituteId: instituteId,
      );

      return restHits;
    } catch (e, st) {
      print('❌ Algolia REST fallback failed: $e\n$st');
      return [];
    }
  }

  /// REST fallback that performs a POST to Algolia's /1/indexes/<indexName>/query endpoint
  static Future<List<Map<String, dynamic>>> _searchViaAlgoliaRest({
    required String queryText,
    required String indexName,
    String? instituteId,
  }) async {
    final url =
        Uri.parse('https://$_appId-dsn.algolia.net/1/indexes/$indexName/query');

    final Map<String, dynamic> payload = {
      'params': _encodeQueryParameters({
        'query': queryText,
        // you can include other query params if needed (hitsPerPage, attributesToRetrieve, etc.)
      }),
    };

    // If you want server-side exact filter, add it as a "filters" query param in params string
    if (instituteId != null && instituteId.isNotEmpty) {
      // merge filters into params (Algolia expects URL-encoded params string)
      final filterString = 'instituteId:"$instituteId"';
      // append to params field (params is a url-encoded query string)
      payload['params'] = payload['params'] +
          '&filters=' +
          Uri.encodeQueryComponent(filterString);
    }

    final headers = {
      'Content-Type': 'application/json',
      'X-Algolia-API-Key': _searchApiKey,
      'X-Algolia-Application-Id': _appId,
    };

    final client = http.Client();
    try {
      final resp = await client
          .post(
            url,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(_restTimeout);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final hits = decoded['hits'] as List<dynamic>? ?? [];

        return hits.map<Map<String, dynamic>>((h) {
          return Map<String, dynamic>.from(h as Map);
        }).toList();
      } else {
        throw HttpException(
            'Algolia REST returned ${resp.statusCode}: ${resp.body}');
      }
    } finally {
      client.close();
    }
  }

  /// Helper to convert query map to url-encoded param string (Algolia REST expects params string)
  static String _encodeQueryParameters(Map<String, dynamic> params) {
    // This creates a 'key=value&key2=value2' style string, URL encoded
    final parts = <String>[];
    params.forEach((k, v) {
      final strValue = v == null ? '' : v.toString();
      parts.add(
          '${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(strValue)}');
    });
    return parts.join('&');
  }

  /// Optional: fetch single record by email using same fallback strategy
  static Future<Map<String, dynamic>?> getByEmail({
    required String indexName,
    required String email,
    String? instituteId,
  }) async {
    final results = await search(
      queryText: email,
      indexName: indexName,
      instituteId: instituteId,
    );

    if (results.isNotEmpty) return results.first;
    return null;
  }
}
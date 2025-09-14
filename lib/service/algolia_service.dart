import 'dart:convert';
import 'package:algoliasearch/algoliasearch.dart';

class AlgoliaService {
  static final SearchClient _client = SearchClient(
    appId: 'BVW4RU2C7H', // your Algolia App ID
    apiKey: '39c025c938dad959c70cd40415b02a6b', // your Search-Only API Key
  );

  /// Free-text search
  static Future<List<Map<String, dynamic>>> search({
    required String queryText,
    required String indexName,
  }) async {
    try {
      final response = await _client.searchSingleIndex(
        indexName: indexName,
        searchParams: SearchParamsObject(query: queryText),
      );

      return response.hits.map<Map<String, dynamic>>((hit) {
        return Map<String, dynamic>.from(hit as Map);
      }).toList();
    } catch (e) {
      print("❌ Algolia search error: $e");
      return [];
    }
  }

  /// Fetch a single record by objectID (optional, not used for QR now)
  static Future<Map<String, dynamic>?> getById({
    required String indexName,
    required String objectId,
  }) async {
    try {
      final response = await _client.getObject(
        indexName: indexName,
        objectID: objectId,
      );

      if (response == null) return null;

      final Map<String, dynamic> map =
          jsonDecode(jsonEncode(response)) as Map<String, dynamic>;
      return map;
    } catch (e) {
      print("❌ Algolia getById error: $e");
      return null;
    }
  }

  /// ✅ Fetch a record by email (for QR codes)
  static Future<Map<String, dynamic>?> getByEmail({
    required String indexName,
    required String email,
  }) async {
    try {
      final response = await _client.searchSingleIndex(
        indexName: indexName,
        searchParams: SearchParamsObject(
          query: email,
          filters: 'email:"$email"', // exact match
        ),
      );

      if (response.hits.isNotEmpty) {
        return Map<String, dynamic>.from(response.hits.first as Map);
      }
      return null;
    } catch (e) {
      print("❌ Algolia getByEmail error: $e");
      return null;
    }
  }
}

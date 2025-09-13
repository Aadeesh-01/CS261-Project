import 'package:algoliasearch/algoliasearch.dart';

class AlgoliaService {
  static final SearchClient _client = SearchClient(
    appId: 'BVW4RU2C7H', // ✅ Your Algolia App ID
    apiKey: '39c025c938dad959c70cd40415b02a6b', // ✅ Search-Only API Key
  );

  /// Searches a specified index for a given query.
  static Future<List<Map<String, dynamic>>> search({
    required String queryText,
    required String indexName,
  }) async {
    try {
      final response = await _client.searchSingleIndex(
        indexName: indexName,
        searchParams: SearchParamsObject(
          query: queryText,
        ),
      );

      // Convert hits to List<Map<String, dynamic>>
      return response.hits.map((hit) {
        return Map<String, dynamic>.from(hit);
      }).toList();
    } catch (e) {
      print("❌ Algolia search error: $e");
      return [];
    }
  }
}

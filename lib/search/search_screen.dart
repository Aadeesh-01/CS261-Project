import 'package:flutter/material.dart';
import 'package:cs261_project/service/algolia_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  // Your Algolia index
  final String indexName = 'alumni_index';

  Future<void> _performSearch() async {
    final queryText = _searchController.text.trim();

    if (queryText.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final results = await AlgoliaService.search(
      queryText: queryText,
      indexName: indexName,
    );

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildResultItem(Map<String, dynamic> hit) {
    final skills = (hit['skills'] is List)
        ? (hit['skills'] as List).join(', ')
        : (hit['skills']?.toString() ?? 'No skills');

    return ListTile(
      title: Text(hit['name'] ?? 'No name'),
      subtitle: Text(hit['company'] ?? 'No company'),
      trailing: Text(skills),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search input field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                    decoration: const InputDecoration(
                      labelText: 'Search alumni',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Results or loading
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_searchResults.isEmpty)
              const Text('No results found.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final hit = _searchResults[index];
                    return _buildResultItem(hit);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

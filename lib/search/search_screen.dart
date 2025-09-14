import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cs261_project/service/algolia_service.dart';
import 'package:cs261_project/profile/alumni_detail_page.dart';
import 'package:cs261_project/screen/qr_scanner_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;

  Timer? _debounce;

  final String indexName = 'alumni_index';
  final String historyKey = 'search_history';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _performSearch(query);
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(historyKey) ?? [];
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(historyKey, _searchHistory);
  }

  Future<void> _performSearch(String queryText) async {
    if (queryText.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final results = await AlgoliaService.search(
        queryText: queryText,
        indexName: indexName,
      );

      if (!_searchHistory.contains(queryText)) {
        _searchHistory.insert(0, queryText);
        if (_searchHistory.length > 3) {
          _searchHistory.removeLast();
        }
        await _saveSearchHistory();
      }

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      // Handle errors if needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeHistoryItem(String term) async {
    _searchHistory.remove(term);
    await _saveSearchHistory();
    setState(() {});
  }

  Widget _buildResultItem(Map<String, dynamic> hit) {
    final skills = (hit['skills'] is List)
        ? (hit['skills'] as List).join(', ')
        : (hit['skills']?.toString() ?? 'No skills');

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => AlumniDetailPage(alumniData: hit),
        ));
      },
      child: ListTile(
        title: Text(hit['name'] ?? 'No name'),
        subtitle: Text(hit['company'] ?? 'No company'),
        trailing: Text(skills),
      ),
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          "🔍 Recent Searches",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ..._searchHistory.map((term) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(term),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _removeHistoryItem(term),
              ),
              onTap: () {
                _searchController.text = term;
                _performSearch(term);
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Custom Row for title + QR icon button
        title: Row(
          children: [
            const Text('Alumni Search'),
            const Spacer(),
            IconButton(
              tooltip: 'Scan QR Code',
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () async {
                final scannedCode = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                );

                if (scannedCode != null && scannedCode.isNotEmpty) {
                  _searchController.text = scannedCode;
                  await _performSearch(scannedCode);
                }
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search input row WITHOUT QR button here
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      labelText: 'Search alumni',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final query = _searchController.text.trim();
                    if (query.isNotEmpty) {
                      _performSearch(query);
                    }
                  },
                  child: const Text('Search'),
                ),
              ],
            ),

            const SizedBox(height: 20),

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

            const SizedBox(height: 10),

            _buildSearchHistory(),
          ],
        ),
      ),
    );
  }
}

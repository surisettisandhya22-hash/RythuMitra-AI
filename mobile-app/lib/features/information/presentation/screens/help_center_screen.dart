import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../services/help_service.dart';
import '../../data/models/help_topic.dart';
import 'help_detail_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  final StorageService storageService;

  const HelpCenterScreen({super.key, required this.storageService});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<HelpTopic> _topics = [];
  List<HelpTopic> _faqs = [];
  bool _isSearching = false;
  List<HelpTopic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  void _loadContent() {
    final lang = widget.storageService.getSelectedLanguage() ?? 'en';
    setState(() {
      _topics = HelpService.getTopics(lang);
      _faqs = HelpService.getFaqs(lang);
    });
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final lang = widget.storageService.getSelectedLanguage() ?? 'en';
    setState(() {
      _isSearching = true;
      _searchResults = HelpService.searchTopics(query, lang);
    });
  }

  void _navigateToDetail(HelpTopic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HelpDetailScreen(
          topic: topic,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.green.shade700,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search Help...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildBrowseContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No help topic found.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _onSearch('');
                FocusScope.of(context).unfocus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                foregroundColor: Colors.green.shade900,
              ),
              child: const Text('Browse All Topics'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final topic = _searchResults[index];
        return _buildTopicTile(topic);
      },
    );
  }

  Widget _buildBrowseContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Help Categories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _topics.length,
          itemBuilder: (context, index) {
            final topic = _topics[index];
            return GestureDetector(
              onTap: () => _navigateToDetail(topic),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(topic.icon, size: 40, color: Colors.green.shade600),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        topic.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        ..._faqs.map((faq) => _buildTopicTile(faq)),
      ],
    );
  }

  Widget _buildTopicTile(HelpTopic topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(topic.icon, color: Colors.green.shade700),
        ),
        title: Text(
          topic.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            topic.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _navigateToDetail(topic),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../services/scheme_service.dart';
import '../../data/models/government_scheme.dart';

class SchemesScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;

  const SchemesScreen({
    super.key,
    required this.storageService,
    required this.profileStorageService,
    required this.networkService,
  });

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  late SchemeService _schemeService;
  bool _isLoading = true;
  List<GovernmentScheme> _schemes = [];
  String? _errorMessage;
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'Subsidy', 'Insurance', 'Loan'];

  @override
  void initState() {
    super.initState();
    _schemeService = SchemeService(widget.networkService);
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final state = widget.profileStorageService.getFarmerProfile()?.location;
      final results = await _schemeService.getAvailableSchemes(
        state: state, 
        category: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _schemes = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Subsidy':
        return Icons.account_balance;
      case 'Insurance':
        return Icons.security;
      case 'Loan':
        return Icons.credit_card;
      default:
        return Icons.article;
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Government Schemes'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                          _loadSchemes();
                        }
                      },
                      selectedColor: Colors.teal.shade700,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSchemes,
                              child: const Text('Retry'),
                            )
                          ],
                        ),
                      )
                    : _schemes.isEmpty
                        ? const Center(
                            child: Text(
                              'No schemes found for the selected category.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSchemes,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _schemes.length,
                              itemBuilder: (context, index) {
                                final scheme = _schemes[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.teal.shade50,
                                        child: Icon(_getCategoryIcon(scheme.category), color: Colors.teal.shade700),
                                      ),
                                      title: Text(
                                        scheme.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          scheme.category,
                                          style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                              const SizedBox(height: 4),
                                              Text(scheme.description),
                                              const SizedBox(height: 12),
                                              
                                              const Text('Eligibility', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                              const SizedBox(height: 4),
                                              Text(scheme.eligibility),
                                              const SizedBox(height: 12),
                                              
                                              const Text('Benefits', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                              const SizedBox(height: 4),
                                              Text(scheme.benefits),
                                              const SizedBox(height: 16),
                                              
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.calendar_today, size: 16, color: Colors.red.shade700),
                                                      const SizedBox(width: 4),
                                                      Text('Deadline: ${scheme.deadline}', style: TextStyle(color: Colors.red.shade900)),
                                                    ],
                                                  ),
                                                  TextButton.icon(
                                                    onPressed: () => _launchUrl(scheme.sourceUrl),
                                                    icon: const Icon(Icons.open_in_new, size: 16),
                                                    label: const Text('Apply Now'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

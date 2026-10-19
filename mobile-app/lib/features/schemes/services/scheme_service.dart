import 'dart:async';
import '../data/models/government_scheme.dart';
import '../../../../core/services/network_service.dart';

class SchemeService {
  final NetworkService _networkService;
  
  SchemeService(this._networkService);
  
  Future<List<GovernmentScheme>> getAvailableSchemes({String? state, String? category}) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (!_networkService.isOnline.value) {
      throw Exception('No internet connection. Cannot fetch government schemes.');
    }
    
    // In a real app, this would call a backend endpoint to fetch relevant schemes
    // based on the farmer's state/location.
    // For now, we return mock data.
    
    List<GovernmentScheme> allSchemes = [
      GovernmentScheme(
        id: '1',
        title: 'PM-KISAN Samman Nidhi',
        description: 'Income support scheme for landholding farmers providing ₹6000 per year.',
        eligibility: 'All landholding farmers families, subject to certain exclusion criteria.',
        benefits: '₹6000 per year in 3 equal installments.',
        deadline: 'Ongoing',
        sourceUrl: 'https://pmkisan.gov.in/',
        category: 'Subsidy',
      ),
      GovernmentScheme(
        id: '2',
        title: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
        description: 'Crop insurance scheme to protect farmers against crop failure.',
        eligibility: 'Farmers growing notified crops in notified areas.',
        benefits: 'Financial support in case of crop loss due to natural calamities.',
        deadline: 'Varies by Season (Kharif/Rabi)',
        sourceUrl: 'https://pmfby.gov.in/',
        category: 'Insurance',
      ),
      GovernmentScheme(
        id: '3',
        title: 'Kisan Credit Card (KCC)',
        description: 'Credit scheme to provide adequate and timely credit support from the banking system.',
        eligibility: 'All farmers, individuals/joint borrowers who are owner cultivators.',
        benefits: 'Low-interest short-term loans for agriculture and allied activities.',
        deadline: 'Ongoing',
        sourceUrl: 'https://www.india.gov.in/',
        category: 'Loan',
      ),
    ];
    
    // Simple mock filtering
    if (category != null && category != 'All') {
      return allSchemes.where((s) => s.category == category).toList();
    }
    
    return allSchemes;
  }
}

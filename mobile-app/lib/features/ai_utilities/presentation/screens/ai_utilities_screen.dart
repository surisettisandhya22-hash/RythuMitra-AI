import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import 'document_explainer_screen.dart';
import 'farm_calculator_screen.dart';
import 'fertilizer_calculator_screen.dart';
import 'soil_health_screen.dart';

class AiUtilitiesScreen extends StatelessWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;

  const AiUtilitiesScreen({
    super.key,
    required this.storageService,
    required this.profileStorageService,
    required this.networkService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('AI Utilities'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Smart Tools for Farmers',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Use AI to simplify complex farming information.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildUtilityCard(
                    context,
                    title: 'Document Explainer',
                    icon: Icons.description,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DocumentExplainerScreen(
                          title: 'Document Explainer',
                          description: 'Take a photo of any farming document or scheme form, and the AI will explain it simply.',
                          storageService: storageService,
                          networkService: networkService,
                        ),
                      ));
                    },
                  ),
                  _buildUtilityCard(
                    context,
                    title: 'Product Label Explainer',
                    icon: Icons.science,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DocumentExplainerScreen(
                          title: 'Product Label Explainer',
                          description: 'Take a photo of a pesticide or fertilizer label to learn exactly how and when to use it safely.',
                          storageService: storageService,
                          networkService: networkService,
                        ),
                      ));
                    },
                  ),
                  _buildUtilityCard(
                    context,
                    title: 'Fertilizer Advisor',
                    icon: Icons.science,
                    color: Colors.green,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const FertilizerCalculatorScreen(),
                      ));
                    },
                  ),
                  _buildUtilityCard(
                    context,
                    title: 'Seed Calculator',
                    icon: Icons.calculate,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const FarmCalculatorScreen(),
                      ));
                    },
                  ),
                  _buildUtilityCard(
                    context,
                    title: 'Soil Health Info',
                    icon: Icons.landscape,
                    color: Colors.brown,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SoilHealthScreen(),
                      ));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityCard(BuildContext context, {required String title, required IconData icon, required MaterialColor color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.shade50,
                radius: 32,
                child: Icon(icon, size: 32, color: color.shade700),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

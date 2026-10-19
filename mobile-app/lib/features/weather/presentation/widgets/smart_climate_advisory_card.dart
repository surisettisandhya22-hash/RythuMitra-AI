import 'package:flutter/material.dart';
import '../../services/weather_service.dart';
import '../../domain/models/climate_advisory_model.dart';

class SmartClimateAdvisoryCard extends StatefulWidget {
  final String location;
  final String? initialCrop;

  const SmartClimateAdvisoryCard({
    super.key,
    required this.location,
    this.initialCrop,
  });

  @override
  State<SmartClimateAdvisoryCard> createState() => _SmartClimateAdvisoryCardState();
}

class _SmartClimateAdvisoryCardState extends State<SmartClimateAdvisoryCard> {
  final WeatherService _weatherService = WeatherService();
  bool _isLoading = true;
  String? _error;
  ClimateAdvisoryModel? _advisory;
  late String _selectedCrop;

  final List<String> _crops = [
    'Rice (వరి)',
    'Cotton (ప్రత్తి)',
    'Chilli (మిర్చి)',
    'Maize (మొక్కజొన్న)',
    'Groundnut (వేరుశనగ)',
    'Tomato (టమాట)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCrop = widget.initialCrop ?? 'Rice (వరి)';
    _fetchAdvisory();
  }

  Future<void> _fetchAdvisory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _weatherService.fetchClimateAdvisory(
        locationName: widget.location,
        crop: _selectedCrop.split(' ')[0], // Pass english crop name
      );
      if (mounted) {
        setState(() {
          _advisory = ClimateAdvisoryModel.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load AI advisory. Check connection.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.eco, color: Colors.green, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'AI Smart Farm Climate Advisory',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _fetchAdvisory,
                  tooltip: 'Refresh Advisory',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Crop Selector Chip Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _crops.map((c) {
                  final isSelected = c == _selectedCrop;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        c,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2E7D32),
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (selected) {
                        if (selected && c != _selectedCrop) {
                          setState(() => _selectedCrop = c);
                          _fetchAdvisory();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 24),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5),
                      SizedBox(height: 12),
                      Text(
                        'Analyzing microclimate & farm risks...',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ),
                    TextButton(onPressed: _fetchAdvisory, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_advisory != null)
              _buildAdvisoryContent(_advisory!),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisoryContent(ClimateAdvisoryModel adv) {
    final spray = adv.sprayingWindow;
    final irr = adv.irrigationAdvice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Summary Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA5D6A7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates, color: Color(0xFF2E7D32), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  adv.summary,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2 Column Grid: Spraying Window & Irrigation
        Row(
          children: [
            // Spraying Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: spray.isFavorable ? const Color(0xFFF1F8E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: spray.isFavorable ? Colors.green.shade300 : Colors.orange.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          spray.isFavorable ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: spray.isFavorable ? Colors.green : Colors.orange.shade800,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Spraying Window',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spray.statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: spray.isFavorable ? Colors.green.shade800 : Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spray.reason,
                      style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.3),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Irrigation Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: irr.shouldIrrigate ? const Color(0xFFE1F5FE) : const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: irr.shouldIrrigate ? Colors.blue.shade300 : Colors.deepPurple.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          irr.shouldIrrigate ? Icons.water_drop : Icons.pause_circle_outline,
                          color: irr.shouldIrrigate ? Colors.blue : Colors.deepPurple,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Irrigation Advice',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      irr.shouldIrrigate ? 'Watering Advised' : 'Hold Off Irrigation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: irr.shouldIrrigate ? Colors.blue.shade800 : Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      irr.adviceText,
                      style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.3),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Pest / Disease Outbreak Warning
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bug_report, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pest & Fungal Risk Outlook:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      adv.pestDiseaseRisk,
                      style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Severe Alerts if any
        if (adv.severeAlerts.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...adv.severeAlerts.map(
            (al) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          al.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          al.description,
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Harvesting Guidance
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.agriculture, color: Colors.grey, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Fieldwork / Harvest: ${adv.harvestingAdvice}',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

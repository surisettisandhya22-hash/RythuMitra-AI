import 'package:flutter/material.dart';
import '../../services/fertilizer_service.dart';

class FertilizerScheduleScreen extends StatelessWidget {
  final String cropName;
  final double areaInAcres;
  final String mopAmount;
  final String tspAmount;
  final String ureaAmount;
  final FertilizerRecommendation? recommendation;

  const FertilizerScheduleScreen({
    super.key,
    required this.cropName,
    required this.areaInAcres,
    required this.mopAmount,
    required this.tspAmount,
    required this.ureaAmount,
    this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasStages = recommendation != null && recommendation!.growthStageSchedule.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        title: const Text('Application Schedule & Guide'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Fertilizer Schedule for $cropName',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Farm Area: ${areaInAcres.toStringAsFixed(2)} Acres',
                    style: TextStyle(fontSize: 14, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (hasStages) ...[
              ...recommendation!.growthStageSchedule.asMap().entries.map((entry) {
                final int idx = entry.key;
                final GrowthStageScheduleItem stage = entry.value;
                final bool isLast = idx == recommendation!.growthStageSchedule.length - 1;

                final Map<String, String> itemsMap = {};
                for (var f in stage.fertilizers) {
                  itemsMap[f.productName] = '${f.quantityKg} kg (${f.bagsApprox})';
                }

                return _buildTimelineStep(
                  stepNum: idx + 1,
                  title: stage.stageName,
                  subtitle: stage.timingDays,
                  description: stage.description,
                  waterNotice: stage.waterPrecaution,
                  icon: idx == 0
                      ? Icons.grass
                      : (idx == 1 ? Icons.eco : Icons.calendar_month),
                  items: itemsMap,
                  isLast: isLast,
                );
              }),
            ] else ...[
              _buildTimelineStep(
                stepNum: 1,
                title: 'First Fertilization (Basal)',
                subtitle: 'At Sowing / Transplanting',
                icon: Icons.grass,
                items: {
                  'MOP': mopAmount,
                  'TSP / DAP': tspAmount,
                  'Urea': ureaAmount,
                },
              ),
              _buildTimelineStep(
                stepNum: 2,
                title: 'Second Fertilization (Tillering)',
                subtitle: 'Week 4 (Active Vegetative)',
                icon: Icons.calendar_month,
                items: {
                  'MOP': '---',
                  'TSP / DAP': '---',
                  'Urea': ureaAmount,
                },
              ),
              _buildTimelineStep(
                stepNum: 3,
                title: 'Third Fertilization (Panicle/Flowering)',
                subtitle: 'Week 9 (Reproductive Stage)',
                icon: Icons.calendar_month_outlined,
                items: {
                  'MOP': '---',
                  'TSP / DAP': '---',
                  'Urea': ureaAmount,
                },
                isLast: true,
              ),
            ],

            const SizedBox(height: 24),
            const Text(
              'Standard Commercial Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildProductCard('Urea (46% N)', Icons.grain, Colors.white, isWhite: true, subtext: '45kg bag'),
                  _buildProductCard('DAP (18:46:0)', Icons.science_outlined, Colors.amber.shade700, subtext: '50kg bag'),
                  _buildProductCard('MOP (Potash)', Icons.science, Colors.red.shade400, subtext: '50kg bag'),
                  _buildProductCard('SSP (16% P)', Icons.layers_outlined, Colors.teal.shade600, subtext: '50kg bag'),
                  _buildProductCard('Zinc Sulphate', Icons.biotech, Colors.indigo.shade500, subtext: '10kg pack'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNum,
    required String title,
    required String subtitle,
    String? description,
    String? waterNotice,
    required IconData icon,
    required Map<String, String> items,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.green.shade800),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.green.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 13)),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      ...items.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(e.value, style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                              ],
                            ),
                          )),
                      if (waterNotice != null && waterNotice.isNotEmpty) ...[
                        const Divider(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.water_drop, size: 14, color: Colors.blue),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                waterNotice,
                                style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String name, IconData icon, Color color, {bool isWhite = false, String? subtext}) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: isWhite ? Colors.blue.shade700 : Colors.white),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isWhite ? Colors.black87 : Colors.white,
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 10,
                color: isWhite ? Colors.grey.shade600 : Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

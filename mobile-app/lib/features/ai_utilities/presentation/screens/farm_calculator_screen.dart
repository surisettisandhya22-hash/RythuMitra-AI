import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';
import 'fertilizer_schedule_screen.dart';
import 'fertilizer_calculator_screen.dart';

class FarmCalculatorScreen extends StatefulWidget {
  const FarmCalculatorScreen({super.key});

  @override
  State<FarmCalculatorScreen> createState() => _FarmCalculatorScreenState();
}

class _FarmCalculatorScreenState extends State<FarmCalculatorScreen> {
  final _areaController = TextEditingController();
  final _rateController = TextEditingController();
  String _selectedUnit = 'Acres';
  String _selectedCrop = 'Paddy / Rice';
  String? _seedResult;
  Map<String, String>? _fertilizerResult;
  double _lastCalculatedArea = 0.0;
  bool _isLoading = false;

  final List<String> _units = ['Acres', 'Hectares', 'Square Meters'];
  final List<String> _crops = ['Paddy / Rice', 'Wheat', 'Cotton', 'Maize', 'Sugarcane'];

  // Mock calculation logic for seed requirement
  Future<void> _calculate() async {
    final areaText = _areaController.text;
    if (areaText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter farm area.')),
      );
      return;
    }

    final double area = double.tryParse(areaText) ?? 0.0;
    if (area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid area greater than 0.')),
      );
      return;
    }

    // Convert everything to Acres for baseline calculation
    double areaInAcres = area;
    if (_selectedUnit == 'Hectares') {
      areaInAcres = area * 2.47105;
    } else if (_selectedUnit == 'Square Meters') {
      areaInAcres = area * 0.000247105;
    }

    // Seed rate kg per acre
    double seedRatePerAcre = 20.0; // Default
    if (_selectedCrop == 'Paddy / Rice') {
      seedRatePerAcre = 25.0;
    } else if (_selectedCrop == 'Wheat') {
      seedRatePerAcre = 40.0;
    } else if (_selectedCrop == 'Cotton') {
      seedRatePerAcre = 2.5;
    } else if (_selectedCrop == 'Maize') {
      seedRatePerAcre = 8.0;
    } else if (_selectedCrop == 'Sugarcane') {
      seedRatePerAcre = 1500.0; // sets/acre
    }

    final double totalSeedsRequired = areaInAcres * seedRatePerAcre;

    // Optional cost calculation
    final rateText = _rateController.text;
    final double pricePerKg = double.tryParse(rateText) ?? 0.0;
    final double estimatedCost = totalSeedsRequired * pricePerKg;

    setState(() {
      _isLoading = true;
      _lastCalculatedArea = areaInAcres;
      _seedResult = "For ${area.toStringAsFixed(2)} $_selectedUnit of $_selectedCrop:\n\n"
          "Estimated Seed Requirement: ${totalSeedsRequired.toStringAsFixed(2)} ${_selectedCrop == 'Sugarcane' ? 'sets' : 'kg'}\n";
      if (pricePerKg > 0) {
        _seedResult = "$_seedResult\nEstimated Cost: ₹${estimatedCost.toStringAsFixed(2)}";
      }
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/calculate_fertilizer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'crop': _selectedCrop,
          'area': areaInAcres,
          'unit': 'Acres'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fertilizerResult = {
            'MOP': data['mop'] ?? 'Unknown',
            'TSP': data['tsp'] ?? 'Unknown',
            'Urea': data['urea'] ?? 'Unknown',
          };
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load from AI');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Fallback to basic calculation if backend fails
        _fertilizerResult = {
          'MOP': '23kg / 1/2 bag',
          'TSP': '22kg / 1/2 bag',
          'Urea': '66kg / 1 1/4 bags',
        };
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Calculation failed. Using fallback data.')),
      );
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Calculator'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Seed Requirement Calculator',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Calculate how much seed you need based on your farm size.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            
            // Dropdowns
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCrop,
                    decoration: InputDecoration(
                      labelText: 'Crop Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _crops.map((crop) => DropdownMenuItem(value: crop, child: Text(crop))).toList(),
                    onChanged: (val) => setState(() => _selectedCrop = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Area Unit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                    onChanged: (val) => setState(() => _selectedUnit = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // TextFields
            TextField(
              controller: _areaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Farm Area (in $_selectedUnit)',
                prefixIcon: const Icon(Icons.landscape),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Seed Price per kg (Optional)',
                prefixText: '₹ ',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Calculate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            
            if (_seedResult != null && _fertilizerResult != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Estimated Requirements',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      _seedResult!,
                      style: TextStyle(fontSize: 16, color: Colors.green.shade900, height: 1.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recommended Fertilizers',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                    ),
                    const SizedBox(height: 12),
                    Table(
                      border: TableBorder.all(color: Colors.green.shade200, width: 1, borderRadius: BorderRadius.circular(8)),
                      children: [
                        _buildTableRow('Type', 'Quantity', isHeader: true),
                        _buildTableRow('MOP', _fertilizerResult!['MOP']!),
                        _buildTableRow('TSP', _fertilizerResult!['TSP']!),
                        _buildTableRow('Urea', _fertilizerResult!['Urea']!),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => FertilizerScheduleScreen(
                              cropName: _selectedCrop,
                              areaInAcres: _lastCalculatedArea,
                              mopAmount: _fertilizerResult!['MOP']!,
                              tspAmount: _fertilizerResult!['TSP']!,
                              ureaAmount: _fertilizerResult!['Urea']!,
                            ),
                          ));
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green.shade700, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'More Details How To Use ->',
                          style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => FertilizerCalculatorScreen(
                              initialCrop: _selectedCrop,
                              initialArea: _lastCalculatedArea,
                            ),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.science, size: 18),
                        label: const Text(
                          'Open Full Fertilizer & Bag Advisory',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String col1, String col2, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? Colors.green.shade100 : Colors.transparent,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(col1, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.w500, color: Colors.green.shade900)),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(col2, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, color: Colors.green.shade900)),
        ),
      ],
    );
  }
}

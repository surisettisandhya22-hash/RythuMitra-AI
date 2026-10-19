import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/farmer_profile.dart';
import '../../data/models/farm_profile.dart';
import '../../data/models/crop_profile.dart';
import 'edit_profile_screen.dart';

class FarmerProfileDetailsScreen extends StatelessWidget {
  final ProfileStorageService profileStorageService;

  const FarmerProfileDetailsScreen({
    super.key,
    required this.profileStorageService,
  });

  void _navigateToEdit(BuildContext context, FarmerProfile? farmer, FarmProfile? farm) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profileStorageService: profileStorageService,
          currentFarmerProfile: farmer,
          currentFarmProfile: farm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        profileStorageService.farmerProfileNotifier,
        profileStorageService.farmProfileNotifier,
        profileStorageService.cropsNotifier,
      ]),
      builder: (context, _) {
        final farmer = profileStorageService.farmerProfileNotifier.value;
        final farm = profileStorageService.farmProfileNotifier.value;
        final crops = profileStorageService.cropsNotifier.value;

        final farmerName = farmer?.name.isNotEmpty == true ? farmer!.name : t.translate('farmer_name');
        final village = farmer?.village;
        final district = farmer?.district;
        final state = farmer?.state;
        
        final locationParts = [village, district, state]
            .where((s) => s != null && s.trim().isNotEmpty)
            .cast<String>()
            .toList();
        final fullLocation = locationParts.isNotEmpty
            ? locationParts.join(', ')
            : (farmer?.location.isNotEmpty == true ? farmer!.location : null);

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              t.translate('farmer_profile'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: t.translate('edit_profile'),
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _navigateToEdit(context, farmer, farm),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Top Header Card with Avatar & Basic Info
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            Icons.person,
                            size: 52,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        farmerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (fullLocation != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                fullLocation,
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green.shade800,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(
                          t.translate('edit_profile'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _navigateToEdit(context, farmer, farm),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farmer Details Card
                      _buildSectionCard(
                        title: t.translate('farmer_profile'),
                        icon: Icons.person_pin,
                        iconColor: Colors.blue.shade700,
                        children: [
                          _buildDetailRow(
                            icon: Icons.badge_outlined,
                            label: t.translate('farmer_name'),
                            value: farmer?.name.isNotEmpty == true ? farmer!.name : '-',
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            icon: Icons.home_outlined,
                            label: t.translate('village'),
                            value: farmer?.village?.isNotEmpty == true ? farmer!.village! : '-',
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            icon: Icons.map_outlined,
                            label: t.translate('district'),
                            value: farmer?.district?.isNotEmpty == true ? farmer!.district! : '-',
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            icon: Icons.location_city_outlined,
                            label: t.translate('state'),
                            value: farmer?.state?.isNotEmpty == true ? farmer!.state! : '-',
                          ),
                          if (farmer?.latitude != null && farmer?.longitude != null) ...[
                            const Divider(height: 16),
                            _buildDetailRow(
                              icon: Icons.gps_fixed,
                              label: 'GPS Coordinates',
                              value: '${farmer!.latitude!.toStringAsFixed(4)}, ${farmer.longitude!.toStringAsFixed(4)}',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Farm Details Card
                      _buildSectionCard(
                        title: t.translate('farm_profile'),
                        icon: Icons.landscape_outlined,
                        iconColor: Colors.green.shade700,
                        children: [
                          _buildDetailRow(
                            icon: Icons.straighten,
                            label: t.translate('land_size'),
                            value: (farm?.landSize != null && farm!.landSize > 0)
                                ? '${farm.landSize.toString().replaceAll(RegExp(r'\.0$'), '')} ${t.translate(farm.landUnit)}'
                                : '-',
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            icon: Icons.water_drop_outlined,
                            label: t.translate('irrigation_type'),
                            value: farm?.irrigationType != null && farm!.irrigationType!.isNotEmpty
                                ? t.translate(farm.irrigationType!)
                                : '-',
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            icon: Icons.grass_outlined,
                            label: t.translate('farming_type'),
                            value: farm?.farmTypes != null && farm!.farmTypes.isNotEmpty
                                ? farm.farmTypes.map((ft) => t.translate(ft)).join(', ')
                                : '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Registered Crops Card
                      _buildCropsSection(context, crops, t),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropsSection(BuildContext context, List<CropProfile> crops, AppLocalizations t) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco_outlined, color: Colors.teal.shade700, size: 22),
                const SizedBox(width: 8),
                Text(
                  t.translate('my_crops'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${crops.length}',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            if (crops.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  t.translate('no_crops_added_yet'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              )
            else
              Column(
                children: crops.map((crop) {
                  final details = <String>[];
                  if (crop.variety != null && crop.variety!.isNotEmpty) {
                    details.add(crop.variety!);
                  }
                  if (crop.area != null && crop.area! > 0) {
                    details.add('${crop.area!.toString().replaceAll(RegExp(r'\.0$'), '')} ${t.translate(crop.unit ?? 'acres')}');
                  }
                  if (crop.plantingDate != null) {
                    final datePart = crop.plantingDate!.split('T')[0];
                    details.add('${t.translate('sowing_date')}: $datePart');
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                crop.cropName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                              if (details.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  details.join(' • '),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

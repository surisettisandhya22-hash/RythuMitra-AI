import '../../profile/services/profile_storage_service.dart';
import '../../profile/data/models/crop_profile.dart';

class FarmMemoryService {
  final ProfileStorageService profileStorageService;

  FarmMemoryService({required this.profileStorageService});

  /// Builds the relevant context based on the user's message.
  /// If no specific keywords are matched, it still provides the crops list as basic context
  /// so the AI knows what crops the farmer is currently managing.
  Map<String, dynamic>? buildContext(String message, {CropProfile? focusedCrop, String? healthContext}) {
    final lowerMessage = message.toLowerCase();
    
    final farmer = profileStorageService.getFarmerProfile();
    final farm = profileStorageService.getFarmProfile();
    final crops = profileStorageService.getCrops();

    // If absolutely no profile data is saved, return null context.
    if (farmer == null && farm == null && crops.isEmpty) {
      return null;
    }

    final Map<String, dynamic> contextPayload = {};

    // Basic rule-based relevance check
    bool needsFarmInfo = _containsAny(lowerMessage, ['farm', 'land', 'size', 'acre', 'hectare', 'location']);
    bool needsCropInfo = _containsAny(lowerMessage, ['crop', 'leaf', 'leaves', 'sick', 'yellow', 'bug', 'disease', 'water', 'yield', 'harvest', 'grow', 'plant']);

    // By default, if crops are present, it's generally good to include them for general questions,
    // but if the question is "Hello" we might not need to. We'll include crops if needsCropInfo is true
    // or if the message is long enough to be an actual farming question.
    if (needsCropInfo || lowerMessage.length > 10 || focusedCrop != null) {
      if (crops.isNotEmpty) {
        contextPayload['crops'] = crops.map((c) => {
          'name': c.cropName,
          'area': c.area,
          'unit': c.unit,
          'season': c.season,
          'growthStage': c.growthStage,
          'status': c.status,
          'plantingDate': c.plantingDate,
        }).toList();
      }
      
      if (focusedCrop != null) {
        contextPayload['focusedCrop'] = {
          'name': focusedCrop.cropName,
          'area': focusedCrop.area,
          'unit': focusedCrop.unit,
          'season': focusedCrop.season,
          'growthStage': focusedCrop.growthStage,
          'status': focusedCrop.status,
          'plantingDate': focusedCrop.plantingDate,
        };
      }
    }

    if (needsFarmInfo) {
      if (farm != null) {
        contextPayload['farm'] = {
          'name': farm.farmName,
          'landSize': farm.landSize,
          'landUnit': farm.landUnit,
          'farmTypes': farm.farmTypes,
        };
      }
    }

    // Always provide farmer name/location if available so the AI can be personalized/polite.
    if (farmer != null) {
      contextPayload['farmer'] = {
        'name': farmer.name,
        'location': farmer.location,
      };
    }
    
    if (healthContext != null) {
      // Pass the serialized health record history directly to the AI
      contextPayload['healthHistoryContext'] = healthContext;
    }

    return contextPayload.isEmpty ? null : contextPayload;
  }

  bool _containsAny(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }
}

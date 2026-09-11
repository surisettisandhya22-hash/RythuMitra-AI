import '../services/backend_config_service.dart';

class ApiConfig {
  static String get baseUrl => BackendConfigService.getBackendUrl();
}

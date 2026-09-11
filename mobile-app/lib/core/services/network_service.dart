import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  
  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    
    _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }
  
  void _updateStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      if (isOnline.value != false) {
        isOnline.value = false;
      }
    } else {
      if (isOnline.value != true) {
        isOnline.value = true;
      }
    }
  }
}

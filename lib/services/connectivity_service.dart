import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

// Memantau status koneksi. `isOnline` reaktif dan dipakai UI untuk
// beralih ke mode offline (menampilkan hanya konten yang sudah di-download).
class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isOnline = true.obs;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<ConnectivityService> init() async {
    try {
      final result = await _connectivity.checkConnectivity();
      isOnline.value = _isConnected(result);
    } catch (_) {
      isOnline.value = true;
    }
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      isOnline.value = _isConnected(result);
    });
    return this;
  }

  bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

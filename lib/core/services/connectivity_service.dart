import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService extends GetxService {
  final _connectivity = Connectivity();
  final _checker = InternetConnection();

  final isOnline = true.obs;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    _refresh();
    _sub = _connectivity.onConnectivityChanged.listen((_) => _refreshDebounced());
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _sub?.cancel();
    super.onClose();
  }

  Future<void> refreshNow() => _refresh();

  void _refreshDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _refresh);
  }

  Future<void> _refresh() async {
    final bool hasInternet = await _checker.hasInternetAccess;
    isOnline.value = hasInternet;
  }
}


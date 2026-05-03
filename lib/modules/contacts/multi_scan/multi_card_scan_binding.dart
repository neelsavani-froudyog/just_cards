import 'package:get/get.dart';

import 'multi_card_scan_controller.dart';

class MultiCardScanBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MultiCardScanController>()) {
      Get.put<MultiCardScanController>(MultiCardScanController());
    }
  }
}

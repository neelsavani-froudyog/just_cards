import 'package:get/get.dart';

import 'manual_entry_controller.dart';

class ManualEntryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManualEntryController>(ManualEntryController.new);
  }
}


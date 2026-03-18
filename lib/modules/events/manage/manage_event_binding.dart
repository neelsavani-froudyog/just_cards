import 'package:get/get.dart';

import 'manage_event_controller.dart';

class ManageEventBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ManageEventController>(ManageEventController());
  }
}


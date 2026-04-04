import 'package:get/get.dart';

import 'edit_event_controller.dart';

class EditEventBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<EditEventController>(EditEventController());
  }
}

import 'package:get/get.dart';

import 'join_event_controller.dart';

class JoinEventBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<JoinEventController>(JoinEventController());
  }
}


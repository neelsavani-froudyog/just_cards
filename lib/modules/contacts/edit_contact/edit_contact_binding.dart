import 'package:get/get.dart';

import 'edit_contact_controller.dart';

class EditContactBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<EditContactController>(EditContactController());
  }
}

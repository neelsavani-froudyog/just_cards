import 'package:get/get.dart';

import 'edit_organization_controller.dart';

class EditOrganizationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<EditOrganizationController>(EditOrganizationController());
  }
}

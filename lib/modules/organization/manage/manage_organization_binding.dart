import 'package:get/get.dart';

import 'manage_organization_controller.dart';

class ManageOrganizationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ManageOrganizationController>(ManageOrganizationController());
  }
}

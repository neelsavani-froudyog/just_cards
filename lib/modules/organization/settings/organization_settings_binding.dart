import 'package:get/get.dart';

import 'organization_settings_controller.dart';

class OrganizationSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<OrganizationSettingsController>(OrganizationSettingsController());
  }
}

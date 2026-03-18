import 'package:get/get.dart';

import 'create_organization_controller.dart';

class CreateOrganizationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<CreateOrganizationController>(CreateOrganizationController());
  }
}


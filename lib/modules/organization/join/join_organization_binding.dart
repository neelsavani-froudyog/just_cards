import 'package:get/get.dart';

import 'join_organization_controller.dart';

class JoinOrganizationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<JoinOrganizationController>(JoinOrganizationController());
  }
}


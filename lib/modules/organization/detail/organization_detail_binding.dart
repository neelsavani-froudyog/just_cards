import 'package:get/get.dart';

import 'organization_detail_controller.dart';

class OrganizationDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<OrganizationDetailController>(OrganizationDetailController());
  }
}

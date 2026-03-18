import 'package:get/get.dart';

import 'invite_members_controller.dart';

class InviteMembersBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<InviteMembersController>(InviteMembersController());
  }
}


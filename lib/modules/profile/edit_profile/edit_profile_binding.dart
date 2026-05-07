import 'package:get/get.dart';
import 'package:just_cards/modules/profile/profile_controller.dart';

import 'edit_profile_controller.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<EditProfileController>(EditProfileController());
    Get.put<ProfileController>(ProfileController());
  }
}


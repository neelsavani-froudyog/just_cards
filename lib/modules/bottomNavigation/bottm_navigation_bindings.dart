import 'package:get/get.dart';

import 'bottom_navigation_controller.dart';
import '../home/home_controller.dart';
import '../profile/profile_controller.dart';

class BottomNavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<BottomNavigationController>(BottomNavigationController());
    Get.lazyPut<HomeController>(HomeController.new);
    Get.lazyPut<ProfileController>(ProfileController.new);
  }
}


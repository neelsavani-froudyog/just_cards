import 'package:get/get.dart';

import '../home/home_controller.dart';

class BottomNavigationController extends GetxController {
  final selectedIndex = 0.obs;

  Future<void> onSelect(int index) async {
    selectedIndex.value = index;

    if (!Get.isRegistered<HomeController>()) {
      return;
    }

    final homeController = Get.find<HomeController>();

    if (index == 0) {
      await homeController.refreshAllData();
      return;
    }

    if (index == 1) {
      await Future.wait(<Future<void>>[
        homeController.fetchContacts(reset: true),
        homeController.fetchMyContactsTotalCount(),
      ]);
    }
  }
}

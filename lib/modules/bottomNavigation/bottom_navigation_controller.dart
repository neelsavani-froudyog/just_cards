import 'package:get/get.dart';

import '../home/home_controller.dart';

class BottomNavigationController extends GetxController {
  final selectedIndex = 0.obs;

  Future<void> onSelect(int index) async {
    selectedIndex.value = index;

    if (index != 0 || !Get.isRegistered<HomeController>()) {
      return;
    }

    await Get.find<HomeController>().refreshAllData();
  }
}

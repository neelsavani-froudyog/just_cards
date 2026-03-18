import 'package:get/get.dart';

class ProfileController extends GetxController {
  final displayName = 'You'.obs;
  final email = 'you@example.com'.obs;
  final statusText = 'Signed in'.obs;

  void onPrivacyPolicy() {
    Get.snackbar('Privacy Policy', 'Coming soon');
  }

  void onLogout() {
    Get.snackbar('Logout', 'Coming soon');
  }
}

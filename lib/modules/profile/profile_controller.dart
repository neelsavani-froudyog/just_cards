import 'package:get/get.dart';

import '../../core/services/auth_session_service.dart';

class ProfileController extends GetxController {
  late final AuthSessionService _session;

  RxString get displayName => _session.displayName;
  RxString get email => _session.email;
  RxString get statusText => _session.statusText;

  @override
  void onInit() {
    super.onInit();
    _session = Get.find<AuthSessionService>();
  }

  void onPrivacyPolicy() {
    Get.snackbar('Privacy Policy', 'Coming soon');
  }

  void onLogout() {
    _session.clear();
    Get.snackbar('Logout', 'Coming soon');
  }
}

import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class JoinOrganizationArgs {
  const JoinOrganizationArgs({
    required this.orgName,
    required this.role,
    required this.invitedBy,
  });

  final String orgName;
  final String role;
  final String invitedBy;

  static JoinOrganizationArgs from(dynamic args) {
    final map = (args as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return JoinOrganizationArgs(
      orgName: (map['orgName'] as String?) ?? 'Organisation',
      role: (map['role'] as String?) ?? 'Member',
      invitedBy: (map['invitedBy'] as String?) ?? 'Admin',
    );
  }
}

class JoinOrganizationController extends GetxController {
  late final JoinOrganizationArgs args;

  final isWorking = false.obs;

  @override
  void onInit() {
    super.onInit();
    args = JoinOrganizationArgs.from(Get.arguments);
  }

  Future<void> acceptAndJoin() async {
    if (isWorking.value) return;
    isWorking.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      Get.snackbar('Organisation', 'Joined ${args.orgName}');
      Get.offAllNamed(Routes.bottomNavigation);
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> decline() async {
    if (isWorking.value) return;
    isWorking.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      Get.snackbar('Organisation', 'Invitation declined');
      Get.back();
    } finally {
      isWorking.value = false;
    }
  }
}


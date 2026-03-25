import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../routes/app_routes.dart';

class JoinOrganizationArgs {
  const JoinOrganizationArgs({
    required this.orgName,
    required this.role,
    required this.invitedBy,
    required this.inviteId,
    required this.organizationId,
  });

  final String orgName;
  final String role;
  final String invitedBy;
  final String inviteId;
  final String organizationId;

  static JoinOrganizationArgs from(dynamic args) {
    final map = (args as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return JoinOrganizationArgs(
      orgName: (map['orgName'] as String?) ?? 'Organisation',
      role: (map['role'] as String?) ?? 'Member',
      invitedBy: (map['invitedBy'] as String?) ?? 'Admin',
      inviteId: (map['inviteId'] as String?) ?? '',
      organizationId: (map['organizationId'] as String?) ?? '',
    );
  }
}

class JoinOrganizationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  late final JoinOrganizationArgs args;

  final isWorking = false.obs;

  @override
  void onInit() {
    super.onInit();
    args = JoinOrganizationArgs.from(Get.arguments);
  }

  Future<void> acceptAndJoin() async {
    if (isWorking.value) return;
    final inviteId = args.inviteId.trim();
    if (inviteId.isEmpty) {
      Get.snackbar('Organisation', 'Invite ID is missing');
      return;
    }
    isWorking.value = true;
    try {
      await _apiService.postRequest(
        url: ApiUrl.organizationsInvitesRespond,
        queryParameters: <String, dynamic>{'id': inviteId},
        data: const <String, dynamic>{'action': 'accept'},
        showSuccessToast: true,
        successToastMessage: 'Joined ${args.orgName}',
        showErrorToast: true,
        onSuccess: (_) {
          Get.offAllNamed(Routes.bottomNavigation);
        },
        onError: (_) {},
      );
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> decline() async {
    if (isWorking.value) return;
    final inviteId = args.inviteId.trim();
    if (inviteId.isEmpty) {
      Get.snackbar('Organisation', 'Invite ID is missing');
      return;
    }
    isWorking.value = true;
    try {
      await _apiService.postRequest(
        url: ApiUrl.organizationsInvitesRespond,
        queryParameters: <String, dynamic>{'id': inviteId},
        data: const <String, dynamic>{'action': 'decline'},
        showSuccessToast: true,
        successToastMessage: 'Invitation declined',
        showErrorToast: true,
        onSuccess: (_) {
          Get.back();
        },
        onError: (_) {},
      );
    } finally {
      isWorking.value = false;
    }
  }
}


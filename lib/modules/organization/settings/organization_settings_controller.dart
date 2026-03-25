import 'package:get/get.dart';

class OrganizationSettingsArgs {
  const OrganizationSettingsArgs({
    required this.organizationId,
    required this.name,
    this.industry,
  });

  final String organizationId;
  final String name;
  final String? industry;

  factory OrganizationSettingsArgs.from(dynamic arguments) {
    final map = (arguments as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return OrganizationSettingsArgs(
      organizationId: map['organizationId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      industry: map['industry']?.toString(),
    );
  }
}

class OrganizationSettingsController extends GetxController {
  late final OrganizationSettingsArgs args;

  final isPrivateByDefault = true.obs;
  final isExportAllowed = true.obs;
  final isAdminApprovalRequired = true.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    args = OrganizationSettingsArgs.from(Get.arguments);
  }

  Future<void> save() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      Get.back();
      Get.snackbar('Saved', 'Organization settings updated');
    } finally {
      isSaving.value = false;
    }
  }
}

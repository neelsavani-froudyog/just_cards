import 'package:get/get.dart';

import '../../core/services/api.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_session_service.dart';
import '../../core/services/toast_service.dart';
import '../../routes/app_routes.dart';
import 'profile_model.dart';

class ProfileController extends GetxController {
  late final AuthSessionService _session;
  late final ApiService _apiService;
  final isLoading = false.obs;
  final isDeletingAccount = false.obs;
  final profileError = RxnString();
  final profileMe = Rxn<ProfileMeResponse>();

  RxString get displayName => _session.displayName;
  RxString get email => _session.email;
  RxString get statusText => _session.statusText;

  @override
  void onInit() {
    super.onInit();
    _session = Get.find<AuthSessionService>();
    _apiService = Get.find<ApiService>();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    if (isLoading.value) return;
    isLoading.value = true;
    profileError.value = null;

    try {
      await _apiService.getRequest(
        url: ApiUrl.profileMe,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final response = payload['response'];
          if (response is! Map<String, dynamic>) {
            profileError.value = 'Invalid profile response';
            return;
          }

          final parsed = ProfileMeResponse.fromJson(response);
          profileMe.value = parsed;

          if (!parsed.ok || parsed.data == null) {
            profileError.value =
                parsed.message.isNotEmpty ? parsed.message : 'Invalid profile response';
            return;
          }

          _session.completeProfile(
            name: parsed.data!.fullName.isNotEmpty
                ? parsed.data!.fullName
                : AuthSessionService.defaultDisplayName,
            emailAddress: parsed.data!.email,
          );
        },
        onError: (message) {
          profileError.value =
              (message?.isNotEmpty ?? false) ? message : 'Failed to load profile';
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onLogout() async {
    await _session.logout();
    Get.offAllNamed(Routes.login);
  }

  Future<void> deleteAccount() async {
    if (isDeletingAccount.value) return;
    isDeletingAccount.value = true;
    try {
      await _apiService.deleteRequest(
        url: ApiUrl.createProfile,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (_) async {
          await ToastService.success('Account deleted');
          await _session.logout();
          Get.offAllNamed(Routes.login);
        },
        onError: (message) async {
          await ToastService.error(
            message?.trim().isNotEmpty == true
                ? message!.trim()
                : 'Failed to delete account',
          );
        },
      );
    } finally {
      isDeletingAccount.value = false;
    }
  }
}

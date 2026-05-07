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
  Rxn<ProfileMeResponse> profileMe = Rxn<ProfileMeResponse>();
  DateTime? _lastProfileFetchAt;

  static const Duration profileCacheTtl = Duration(minutes: 2);

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

  bool get hasFreshProfileCache {
    if (_lastProfileFetchAt == null) return false;
    return DateTime.now().difference(_lastProfileFetchAt!) <= profileCacheTtl;
  }

  Future<void> fetchProfile({bool silent = false, bool force = false}) async {
    if (!force && hasFreshProfileCache && profileMe.value?.data != null) {
      return;
    }
    if (!silent) {
      if (isLoading.value) return;
      isLoading.value = true;
      profileError.value = null;
      update();
    }

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
          _lastProfileFetchAt = DateTime.now();
          update();

          if (!parsed.ok || parsed.data == null) {
            profileError.value =
                parsed.message.isNotEmpty ? parsed.message : 'Invalid profile response';
            update();
            return;
          }

          _session.completeProfile(
            name: parsed.data!.fullName.isNotEmpty
                ? parsed.data!.fullName
                : AuthSessionService.defaultDisplayName,
            emailAddress: parsed.data!.email,
          );
          update();
        },
        onError: (message) {
          profileError.value =
              (message?.isNotEmpty ?? false) ? message : 'Failed to load profile';
          update();
        },
      );
    } finally {
      if (!silent) {
        isLoading.value = false;
        update();
      }
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

  Future<bool> updateProfileVcfDetails({
    required String fullName,
    required String phone,
    required String avatarUrl,
    required String companyName,
    required String designation,
    required String address,
    required String website,
    required String secondaryEmail,
    required String secondaryPhone,
  }) async {
    var ok = false;

    await _apiService.patchRequest(
      url: ApiUrl.createProfile,
      data: <String, dynamic>{
        'p_full_name': fullName.trim(),
        'p_phone': phone.trim(),
        'p_avatar_url': avatarUrl.trim(),
        'p_company_name': companyName.trim(),
        'p_designation': designation.trim(),
        'p_address': address.trim(),
        'p_website': website.trim(),
        'p_secondary_email': secondaryEmail.trim(),
        'p_secondary_phone': secondaryPhone.trim(),
      },
      showSuccessToast: false,
      showErrorToast: true,
      onSuccess: (_) {
        ok = true;
      },
      onError: (_) {
        ok = false;
      },
    );

    if (ok) {
      await fetchProfile(silent: true);
      update();
    }
    return ok;
  }
}

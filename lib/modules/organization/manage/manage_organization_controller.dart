import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import 'my_organizations_model.dart';

class ManageOrganizationController extends GetxController {
  late final ApiService _apiService;
  final isLoading = false.obs;
  final errorText = RxnString();
  final organizations = <OrganizationSummary>[].obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    fetchOrganizations();
  }

  Future<void> fetchOrganizations() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorText.value = null;

    try {
      await _apiService.getRequest(
        url: ApiUrl.profileOrganizations,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) {
            errorText.value = 'Invalid organizations response';
            return;
          }

          final parsed = MyOrganizationsResponse.fromJson(raw);
          if (!parsed.ok) {
            errorText.value = parsed.message.isNotEmpty
                ? parsed.message
                : 'Failed to load organizations';
            return;
          }
          organizations.assignAll(parsed.data);
        },
        onError: (message) {
          errorText.value = (message?.isNotEmpty ?? false)
              ? message
              : 'Failed to load organizations';
        },
      );
    } finally {
      isLoading.value = false;
    }
  }
}

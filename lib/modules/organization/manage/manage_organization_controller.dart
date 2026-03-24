import 'package:get/get.dart';
import 'package:flutter/widgets.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import 'my_organizations_model.dart';

class ManageOrganizationController extends GetxController {
  static const int _pageLimit = 10;

  late final ApiService _apiService;
  final ScrollController scrollController = ScrollController();
  final isLoading = false.obs;
  final isFetchingMore = false.obs;
  final errorText = RxnString();
  final organizations = <OrganizationSummary>[].obs;
  final totalOrganizations = 0.obs;
  final currentOffset = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    scrollController.addListener(_onScroll);
    fetchOrganizations();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  bool get hasMore => organizations.length < totalOrganizations.value;

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.extentAfter < 200) {
      fetchOrganizations(loadMore: true);
    }
  }

  Future<void> fetchOrganizations({bool loadMore = false}) async {
    if (isLoading.value || isFetchingMore.value) return;
    if (loadMore && !hasMore) return;

    if (loadMore) {
      isFetchingMore.value = true;
    } else {
      isLoading.value = true;
      errorText.value = null;
      currentOffset.value = 0;
    }

    final requestOffset = loadMore ? currentOffset.value : 0;

    try {
      await _apiService.getRequest(
        url: ApiUrl.profileOrganizations,
        queryParameters: <String, dynamic>{
          'limit': _pageLimit,
          'offset': requestOffset,
        },
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

          totalOrganizations.value = parsed.total;
          if (loadMore) {
            organizations.addAll(parsed.data);
          } else {
            organizations.assignAll(parsed.data);
          }
          currentOffset.value = parsed.offset + parsed.data.length;
        },
        onError: (message) {
          errorText.value = (message?.isNotEmpty ?? false)
              ? message
              : 'Failed to load organizations';
        },
      );
    } finally {
      if (loadMore) {
        isFetchingMore.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }
}

import 'package:get/get.dart';

import '../../core/services/api.dart';
import '../../core/services/api_service.dart';
import 'notifications_model.dart';

enum InviteFilter { all, pending, accepted, declined }

class NotificationsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final query = ''.obs;
  final filter = InviteFilter.pending.obs;

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorText = RxnString();

  final counts = const NotificationCounts(
    all: 0,
    pending: 0,
    accepted: 0,
    declined: 0,
  ).obs;

  final notifications = <AppNotificationItem>[].obs;

  final int limit = 10;
  int _offset = 0;
  bool _hasMore = true;
  int _requestSeq = 0;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications(reset: true);
  }

  int countFor(InviteFilter f) {
    final c = counts.value;
    return switch (f) {
      InviteFilter.all => c.all,
      InviteFilter.pending => c.pending,
      InviteFilter.accepted => c.accepted,
      InviteFilter.declined => c.declined,
    };
  }

  void setQuery(String v) {
    query.value = v;
    fetchNotifications(reset: true);
  }

  void setFilter(InviteFilter v) {
    if (filter.value == v) return;
    filter.value = v;
    fetchNotifications(reset: true);
  }

  Future<void> fetchNotifications({required bool reset}) async {
    // Allow a "reset" fetch to start even if another fetch is in-flight.
    // We use `_requestSeq` to ensure only the latest response updates state.
    if (!reset) {
      if (isLoadingMore.value || !_hasMore) return;
      if (isLoading.value) return; // don't paginate during a refresh
    }

    final int seq = ++_requestSeq;
    if (reset) {
      _offset = 0;
      _hasMore = true;
      errorText.value = null;
      isLoading.value = true;
      isLoadingMore.value = false;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final payload = <String, dynamic>{
        'status': filter.value.name,
        'search': query.value.trim(),
        'limit': limit,
        'offset': _offset,
      };

      await _apiService.postRequest(
        url: ApiUrl.notifications,
        data: payload,
        showErrorToast: false,
        onSuccess: (res) {
          if (seq != _requestSeq) return;

          final decoded = res['response'];
          if (decoded is! Map<String, dynamic>) {
            errorText.value = 'Invalid response';
            return;
          }

          final parsed = NotificationsResponse.fromJson(decoded);
          counts.value = parsed.data.counts;

          final items = parsed.data.notifications;
          if (reset) {
            notifications.assignAll(items);
          } else {
            notifications.addAll(items);
          }

          _offset = notifications.length;
          _hasMore = items.length >= limit;
        },
        onError: (message) {
          if (seq != _requestSeq) return;
          errorText.value =
              message.isNotEmpty ? message : 'Failed to load';
        },
      );
    } finally {
      if (seq == _requestSeq) {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> loadMore() => fetchNotifications(reset: false);

  /// Marks a notification as seen on the server (`POST /notifications/seen`).
  Future<void> markNotificationSeen(String notificationId) async {
    if (notificationId.isEmpty) return;

    await _apiService.postRequest(
      url: ApiUrl.notificationsSeen,
      data: <String, dynamic>{'p_notification_id': notificationId},
      showSuccessToast: false,
      showErrorToast: false,
      onSuccess: (_) {
        final idx = notifications.indexWhere((n) => n.id == notificationId);
        if (idx >= 0) {
          notifications[idx] = notifications[idx].copyWith(isSeen: true);
        }
      },
      onError: (_) {},
    );
  }
}


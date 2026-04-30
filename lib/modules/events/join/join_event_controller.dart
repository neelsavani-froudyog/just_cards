import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/toast_service.dart';

class JoinEventArgs {
  const JoinEventArgs({
    required this.eventName,
    required this.role,
    required this.invitedBy,
    required this.inviteId,
    required this.eventId,
  });

  final String eventName;
  final String role;
  final String invitedBy;
  final String inviteId;
  final String eventId;

  static JoinEventArgs from(dynamic args) {
    final map = (args as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return JoinEventArgs(
      eventName: (map['eventName'] as String?) ?? 'Event',
      role: (map['role'] as String?) ?? 'Member',
      invitedBy: (map['invitedBy'] as String?) ?? 'Admin',
      inviteId: (map['inviteId'] as String?) ?? '',
      eventId: (map['eventId'] as String?) ?? '',
    );
  }
}

class JoinEventController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  late final JoinEventArgs args;

  final isWorking = false.obs;

  @override
  void onInit() {
    super.onInit();
    args = JoinEventArgs.from(Get.arguments);
  }

  bool _isNestedSuccess(dynamic decodedBody) {
    if (decodedBody is! Map) return true;
    final data = decodedBody['data'];
    if (data is Map && data['success'] is bool) {
      return data['success'] as bool;
    }
    return true;
  }

  String _nestedMessage(dynamic decodedBody) {
    if (decodedBody is! Map) return '';
    final data = decodedBody['data'];
    if (data is Map) {
      final message = data['message']?.toString() ?? '';
      if (message.trim().isNotEmpty) return message.trim();
    }
    return (decodedBody['message']?.toString() ?? '').trim();
  }

  Future<void> acceptAndJoin() async {
    if (isWorking.value) return;
    final inviteId = args.inviteId.trim();
    if (inviteId.isEmpty) {
      ToastService.error('Invite ID is missing');
      return;
    }

    isWorking.value = true;
    try {
      await _apiService.postRequest(
        url: ApiUrl.eventsInvitesRespond,
        queryParameters: <String, dynamic>{'id': inviteId},
        data: const <String, dynamic>{'action': 'accept'},
        showSuccessToast: false,
        showErrorToast: true,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (!_isNestedSuccess(raw)) {
            ToastService.error(_nestedMessage(raw).isNotEmpty ? _nestedMessage(raw) : 'Invite not found');
            return;
          }
          ToastService.success('Joined ${args.eventName}');
          Get.back(result: true);
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
      ToastService.error('Invite ID is missing');
      return;
    }

    isWorking.value = true;
    try {
      await _apiService.postRequest(
        url: ApiUrl.eventsInvitesRespond,
        queryParameters: <String, dynamic>{'id': inviteId},
        data: const <String, dynamic>{'action': 'decline'},
        showSuccessToast: false,
        showErrorToast: true,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (!_isNestedSuccess(raw)) {
            ToastService.error(_nestedMessage(raw).isNotEmpty ? _nestedMessage(raw) : 'Invite not found');
            return;
          }
          ToastService.success('Invitation declined');
          Get.back(result: true);
        },
        onError: (_) {},
      );
    } finally {
      isWorking.value = false;
    }
  }
}

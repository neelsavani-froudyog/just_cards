import 'package:get/get.dart';

class AuthSessionService extends GetxService {
  final displayName = 'You'.obs;
  final email = 'you@example.com'.obs;
  final statusText = 'Signed in'.obs;

  void setEmail(String value) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      email.value = normalized;
    }
  }

  void completeProfile({required String name, required String emailAddress}) {
    final normalizedName = name.trim();
    final normalizedEmail = emailAddress.trim();

    if (normalizedName.isNotEmpty) {
      displayName.value = normalizedName;
    }
    if (normalizedEmail.isNotEmpty) {
      email.value = normalizedEmail;
    }
    statusText.value = 'Signed in';
  }

  void clear() {
    displayName.value = 'You';
    email.value = 'you@example.com';
    statusText.value = 'Signed in';
  }
}

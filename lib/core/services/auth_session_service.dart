import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionService extends GetxService {
  static const String _accessTokenKey = 'access_token';
  static const String defaultDisplayName = 'Coffee Lover';

  final displayName = defaultDisplayName.obs;
  final email = 'you@example.com'.obs;
  final statusText = 'Signed in'.obs;
  final accessToken = ''.obs;

  void _resetInMemorySession() {
    displayName.value = defaultDisplayName;
    email.value = 'you@example.com';
    statusText.value = 'Signed in';
    accessToken.value = '';
  }

  Future<void> loadPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken.value = prefs.getString(_accessTokenKey) ?? '';
  }

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

  void setAccessToken(String token) {
    final normalized = token.trim();
    accessToken.value = normalized;
    _persistAccessToken(normalized);
  }

  Future<void> _persistAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token.isEmpty) {
      await prefs.remove(_accessTokenKey);
      return;
    }
    await prefs.setString(_accessTokenKey, token);
  }

  Future<void> logout() async {
    _resetInMemorySession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void clear() {
    _resetInMemorySession();
    SharedPreferences.getInstance().then((prefs) {
      prefs.clear();
    });
  }
}

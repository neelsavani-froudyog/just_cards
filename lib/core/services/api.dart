/// Central place to configure your backend base URL + endpoints.
///
/// Note: this project currently doesn't load `.env` automatically, so you must
/// call `ApiUrl.configure(baseUrl: ...)` somewhere during app start.
class ApiUrl {
  /// Base URL for all app API calls.
  /// Change this for different environments.
  static String baseUrl = 'http://127.0.0.1:3000';

  /// Auth
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';
  static const String emailExists = '/profile/email-exists';
  static const String profileMe = '/profile/me';
  static const String createProfile = '/profile';
  static const String profileOrganizations = '/profile/organizations';
  static const String profileCreateOrganizations = '/profile/createOrganizations';

  /// Call this once before making any API calls.
  static void configure({required String baseUrl}) {
    // Remove trailing slash so endpoint joins are consistent.
    ApiUrl.baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  }
}


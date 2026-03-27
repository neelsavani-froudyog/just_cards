/// Central place to configure your backend base URL + endpoints.
///
/// Note: this project currently doesn't load `.env` automatically, so you must
/// call `ApiUrl.configure(baseUrl: ...)` somewhere during app start.
class ApiUrl {
  /// Base URL for all app API calls.
  /// Change this for different environments.
  static String baseUrl = 'https://just-card-backend.vercel.app';
  // static String baseUrl = 'http://localhost:3000';

  /// Auth
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';
  static const String resendOtp = '/auth/otp/resend';
  static const String emailExists = '/profile/email-exists';
  static const String profileMe = '/profile/me';
  static const String createProfile = '/profile';
  static const String profileOrganizations = '/profile/organizations';
  static const String profileOrganizationsSimple =
      '/profile/organizations/simple';
  static const String profileCreateOrganizations =
      '/profile/createOrganizations';
  static const String profileOrganizationsMembers =
      '/profile/organizations/members';
  static const String organizationsInvites = '/organizations/invites';
  static const String organizationsInvitesRole = '/organizations/invites/role';
  static const String organizationsInvitesMember =
      '/organizations/invites/member';
  static const String organizationsInvitesRespond =
      '/organizations/invites/respond';
  static const String eventsInvitesRespond = '/events/invites/respond';
  static const String notifications = '/notifications';
  static const String events = '/events';
  static const String scanQuotaStatus = '/scan-quota/status';
  static const String eventsInvites = '/events/invites';
  static const String eventsMembers = '/events/members';
  static const String eventsOrganization = '/events/organization';

  /// Call this once before making any API calls.
  static void configure({required String baseUrl}) {
    // Remove trailing slash so endpoint joins are consistent.
    ApiUrl.baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  }
}

/// Central place to configure your backend base URL + endpoints.
///
/// Note: this project currently doesn't load `.env` automatically, so you must
/// call `ApiUrl.configure(baseUrl: ...)` somewhere during app start.
class ApiUrl {
  /// Base URL for all app API calls.
  /// Change this for different environments.
  static String baseUrl = 'https://just-card-backend.vercel.app';
  // static String baseUrl = 'http://localhost:3000';
  static String supabaseRestBaseUrl = '';
  static String supabaseApiKey = '';

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
  static const String profileUpdateOrganization = '/profile/organizations';
  static const String profileDeleteOrganization = '/profile/organizations';
  static const String profileOrganizationsMembers =
      '/profile/organizations/members';
  static const String profileOrganizationsMembersRole =
      '/profile/organizations/members/role';
  static const String softDeleteOrganizationMemberRpc =
      '/rest/v1/rpc/soft_delete_organization_member';
  static const String organizationsInvites = '/organizations/invites';
  static const String organizationsInvitesRole = '/organizations/invites/role';
  static const String organizationsInvitesMember =
      '/organizations/invites/member';
  static const String organizationsInvitesRespond =
      '/organizations/invites/respond';
  static const String eventsInvitesRespond = '/events/invites/respond';
  static const String notifications = '/notifications';
  /// Body: `{ "p_notification_id": "<uuid>" }`.
  static const String notificationsSeen = '/notifications/seen';
  /// `POST` create event.
  ///
  /// `PATCH` update (same path), body e.g.:
  /// `{ "p_event_id", "p_name", "p_event_date", "p_location_text", "p_notes", "p_organization_id" }`
  /// (`p_organization_id` may be `null`).
  ///
  /// `DELETE` (same path), body: `{ "p_event_id": "<uuid>" }`.
  static const String events = '/events';
  static const String eventsByOrganization = '/events/by-organization';
  static const String scanQuotaStatus = '/scan-quota/status';
  static const String parseCard = '/scan-quota/parse-card';
  static const String eventsInvites = '/events/invites';
  static const String eventsInvitesRole = '/events/invites/role';
  static const String eventsInvitesMember = '/events/invites/member';
  /// Recall / notify for a pending event invite batch (body: `invite_batch_id`).
  static const String eventInvitesNotify = '/events/invites/notify';
  static const String eventsMembers = '/events/members';
  static const String eventsOrganization = '/events/organization';


  /// Multipart: `eventName`, `file` — returns `data.public_url`.
  static const String profileImagesUpload = '/profile/images/upload';
  static const String profilePhotoUpload = '/profile/photo/upload';

  /// POST create, PATCH update (`p_contact_id` + fields), DELETE (`p_contact_id`).
  static const String contacts = '/contacts';
  static const String contactsByEvent = '/contacts/by-event';
  static const String contactsByEventExport = '/contacts/by-event/export';
  static const String contactsByEventTotalCount = '/contacts/by-event/total-count';
  static const String contactsByOrganization = '/contacts/by-organization';
  static const String contactsByOrganizationExport =
      '/contacts/by-organization/export';
  static const String myContacts = '/contacts/my';
  static const String myContactsTotalCount = '/contacts/my/total-count';
  static const String contactDetail = '/contacts/detail';
  static const String contactNotes = '/contacts/notes';
  static const String contactAttachments = '/contacts/attachments';
  static const String contactAttachmentsUpload = '/contacts/attachments/upload';

  /// Call this once before making any API calls.
  static void configure({required String baseUrl}) {
    // Remove trailing slash so endpoint joins are consistent.
    ApiUrl.baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Optional Supabase REST RPC config for direct RPC calls.
  static void configureSupabase({
    required String restBaseUrl,
    required String apiKey,
  }) {
    supabaseRestBaseUrl = restBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    supabaseApiKey = apiKey.trim();
  }
}

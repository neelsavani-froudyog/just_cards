import 'package:get/get.dart';
import 'package:just_cards/modules/bottomNavigation/bottm_navigation_bindings.dart';
import 'package:just_cards/modules/contacts/qr_import/qr_data_entry/qr_contact_binding.dart';
import 'package:just_cards/modules/contacts/qr_import/qr_data_entry/qr_contact_form_view.dart';

import '../modules/auth/login/login_binding.dart';
import '../modules/auth/login/login_view.dart';
import '../modules/auth/complete_profile/complete_profile_binding.dart';
import '../modules/auth/complete_profile/complete_profile_view.dart';
import '../modules/auth/otp/otp_binding.dart';
import '../modules/auth/otp/otp_view.dart';
import '../modules/bottomNavigation/bottom_navigation_view.dart';
import '../modules/contacts/details/contact_details_binding.dart';
import '../modules/contacts/details/contact_details_view.dart';
import '../modules/events/edit/edit_event_binding.dart';
import '../modules/events/edit/edit_event_view.dart';
import '../modules/events/manage/manage_event_binding.dart';
import '../modules/events/manage/manage_event_view.dart';
import '../modules/events/join/join_event_binding.dart';
import '../modules/events/join/join_event_view.dart';
import '../modules/notifications/notifications_binding.dart';
import '../modules/notifications/notifications_view.dart';
import '../modules/organization/create/create_organization_binding.dart';
import '../modules/organization/create/create_organization_view.dart';
import '../modules/organization/edit/edit_organization_binding.dart';
import '../modules/organization/edit/edit_organization_view.dart';
import '../modules/organization/invite_members/invite_members_binding.dart';
import '../modules/organization/invite_members/invite_members_view.dart';
import '../modules/organization/join/join_organization_binding.dart';
import '../modules/organization/join/join_organization_view.dart';
import '../modules/organization/detail/organization_detail_binding.dart';
import '../modules/organization/detail/organization_detail_view.dart';
import '../modules/organization/manage/manage_organization_binding.dart';
import '../modules/organization/manage/manage_organization_view.dart';
import '../modules/legal/terms_conditions_view.dart';
import '../modules/legal/privacy_policy_view.dart';
import '../modules/legal/support_view.dart';
import '../modules/contacts/scan_result/scan_result_view.dart';
import '../modules/contacts/qr_import/qr_scanner_view.dart';
import '../modules/contacts/edit_contact/edit_contact_binding.dart';
import '../modules/contacts/edit_contact/edit_contact_view.dart';
import '../modules/contacts/manual_entry/manual_entry_binding.dart';
import '../modules/contacts/manual_entry/manual_entry_view.dart';
import '../modules/profile/edit_profile/edit_profile_binding.dart';
import '../modules/profile/edit_profile/edit_profile_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: Routes.splash,
      page: SplashView.new,
      binding: SplashBinding(),
    ),
    GetPage(name: Routes.login, page: LoginView.new, binding: LoginBinding()),
    GetPage(name: Routes.otp, page: OtpView.new, binding: OtpBinding()),
    GetPage(
      name: Routes.completeProfile,
      page: CompleteProfileView.new,
      binding: CompleteProfileBinding(),
    ),
    GetPage(
      name: Routes.bottomNavigation,
      page: BottomNavigationView.new,
      binding: BottomNavigationBinding(),
    ),
    GetPage(
      name: Routes.createOrganization,
      page: CreateOrganizationView.new,
      binding: CreateOrganizationBinding(),
    ),
    GetPage(
      name: Routes.editOrganization,
      page: EditOrganizationView.new,
      binding: EditOrganizationBinding(),
    ),
    GetPage(
      name: Routes.manageOrganization,
      page: ManageOrganizationView.new,
      binding: ManageOrganizationBinding(),
    ),
    GetPage(
      name: Routes.organizationDetail,
      page: OrganizationDetailView.new,
      binding: OrganizationDetailBinding(),
    ),
    GetPage(
      name: Routes.manageEvent,
      page: ManageEventView.new,
      binding: ManageEventBinding(),
    ),
    GetPage(
      name: Routes.editEvent,
      page: EditEventView.new,
      binding: EditEventBinding(),
    ),
    GetPage(
      name: Routes.notifications,
      page: NotificationsView.new,
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: Routes.joinOrganization,
      page: JoinOrganizationView.new,
      binding: JoinOrganizationBinding(),
    ),
    GetPage(
      name: Routes.joinEvent,
      page: JoinEventView.new,
      binding: JoinEventBinding(),
    ),
    GetPage(
      name: Routes.contactDetails,
      page: ContactDetailsView.new,
      binding: ContactDetailsBinding(),
    ),
    GetPage(
      name: Routes.inviteMembers,
      page: InviteMembersView.new,
      binding: InviteMembersBinding(),
    ),
    GetPage(name: Routes.termsConditions, page: TermsConditionsView.new),
    GetPage(name: Routes.privacyPolicy, page: PrivacyPolicyView.new),
    GetPage(name: Routes.support, page: SupportView.new),
    GetPage(
      name: Routes.editProfile,
      page: EditProfileView.new,
      binding: EditProfileBinding(),
    ),
    GetPage(name: Routes.scanResult, page: ScanResultView.new),
    GetPage(name: Routes.qrScanner, page: QrScannerView.new),
    GetPage(
      name: Routes.manualEntry,
      page: ManualEntryView.new,
      binding: ManualEntryBinding(),
    ),
    GetPage(
      name: Routes.editContact,
      page: EditContactView.new,
      binding: EditContactBinding(),
    ),
    GetPage(
      name: Routes.qrContact,
      page: QrContactFormView.new,
      binding: QrContactBinding(),
    ),
  ];
}

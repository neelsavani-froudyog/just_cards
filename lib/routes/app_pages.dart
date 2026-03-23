import 'package:get/get.dart';
import 'package:just_cards/modules/bottomNavigation/bottm_navigation_bindings.dart';

import '../modules/auth/login/login_binding.dart';
import '../modules/auth/login/login_view.dart';
import '../modules/auth/complete_profile/complete_profile_binding.dart';
import '../modules/auth/complete_profile/complete_profile_view.dart';
import '../modules/auth/otp/otp_binding.dart';
import '../modules/auth/otp/otp_view.dart';
import '../modules/bottomNavigation/bottom_navigation_view.dart';
import '../modules/contacts/details/contact_details_binding.dart';
import '../modules/contacts/details/contact_details_view.dart';
import '../modules/events/manage/manage_event_binding.dart';
import '../modules/events/manage/manage_event_view.dart';
import '../modules/notifications/notifications_binding.dart';
import '../modules/notifications/notifications_view.dart';
import '../modules/organization/create/create_organization_binding.dart';
import '../modules/organization/create/create_organization_view.dart';
import '../modules/organization/invite_members/invite_members_binding.dart';
import '../modules/organization/invite_members/invite_members_view.dart';
import '../modules/organization/join/join_organization_binding.dart';
import '../modules/organization/join/join_organization_view.dart';
import '../modules/organization/manage/manage_organization_binding.dart';
import '../modules/organization/manage/manage_organization_view.dart';
import '../modules/legal/terms_conditions_view.dart';
import '../modules/legal/privacy_policy_view.dart';
import '../modules/contacts/scan_result/scan_result_view.dart';
import '../modules/contacts/manual_entry/manual_entry_binding.dart';
import '../modules/contacts/manual_entry/manual_entry_view.dart';
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
      name: Routes.manageOrganization,
      page: ManageOrganizationView.new,
      binding: ManageOrganizationBinding(),
    ),
    GetPage(
      name: Routes.manageEvent,
      page: ManageEventView.new,
      binding: ManageEventBinding(),
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
    GetPage(name: Routes.scanResult, page: ScanResultView.new),
    GetPage(
      name: Routes.manualEntry,
      page: ManualEntryView.new,
      binding: ManualEntryBinding(),
    ),
  ];
}

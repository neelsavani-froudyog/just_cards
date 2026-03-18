import 'package:get/get.dart';
import 'package:just_cards/modules/bottomNavigation/bottm_navigation_bindings.dart';

import '../modules/auth/login/login_binding.dart';
import '../modules/auth/login/login_view.dart';
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
    GetPage(
      name: Routes.login,
      page: LoginView.new,
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.otp,
      page: OtpView.new,
      binding: OtpBinding(),
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
  ];
}

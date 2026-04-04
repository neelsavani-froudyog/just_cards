abstract class Routes {
  /// `Get.back(result: …)` after a successful delete on [contactDetails].
  static const contactDeletedPopResult = 'contact_deleted';

  static const splash = _Paths.splash;
  static const login = _Paths.login;
  static const otp = _Paths.otp;
  static const completeProfile = _Paths.completeProfile;
  static const home = _Paths.home;
  static const bottomNavigation = _Paths.bottomNavigation;
  static const createOrganization = _Paths.createOrganization;
  static const editOrganization = _Paths.editOrganization;
  static const manageOrganization = _Paths.manageOrganization;
  static const organizationDetail = _Paths.organizationDetail;
  static const manageEvent = _Paths.manageEvent;
  static const editEvent = _Paths.editEvent;
  static const notifications = _Paths.notifications;
  static const joinOrganization = _Paths.joinOrganization;
  static const joinEvent = _Paths.joinEvent;
  static const contactDetails = _Paths.contactDetails;
  static const inviteMembers = _Paths.inviteMembers;
  static const termsPrivacy = _Paths.termsPrivacy;
  static const termsConditions = _Paths.termsConditions;
  static const privacyPolicy = _Paths.privacyPolicy;
  static const support = _Paths.support;
  static const editProfile = _Paths.editProfile;
  static const scanResult = _Paths.scanResult;
  static const qrScanner = _Paths.qrScanner;
  static const manualEntry = _Paths.manualEntry;
  static const editContact = _Paths.editContact;
  static const qrContact = _Paths.qrContact;
}

abstract class _Paths {
  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';
  static const completeProfile = '/completeProfile';
  static const home = '/home';
  static const bottomNavigation = '/bottomNavigation';
  static const createOrganization = '/createOrganization';
  static const editOrganization = '/editOrganization';
  static const manageOrganization = '/manageOrganization';
  static const organizationDetail = '/organizationDetail';
  static const manageEvent = '/manageEvent';
  static const editEvent = '/editEvent';
  static const notifications = '/notifications';
  static const joinOrganization = '/joinOrganization';
  static const joinEvent = '/joinEvent';
  static const contactDetails = '/contactDetails';
  static const inviteMembers = '/inviteMembers';
  static const termsPrivacy = '/termsPrivacy';
  static const termsConditions = '/termsConditions';
  static const privacyPolicy = '/privacyPolicy';
  static const support = '/support';
  static const editProfile = '/editProfile';
  static const scanResult = '/scanResult';
  static const qrScanner = '/qrScanner';
  static const manualEntry = '/manualEntry';
  static const editContact = '/editContact';
  static const qrContact = '/qrContact';
}

/// Public store listings for “Get the app” links (e.g. contact share sheet).
abstract class AppListingUrls {
  AppListingUrls._();

  /// Matches `applicationId` in `android/app/build.gradle.kts`.
  static const String googlePlay =
      'https://play.google.com/store/apps/details?id=com.forudyog.justcards';

  /// Replace with your App Store Connect **Apple ID** (numeric) after the iOS app is live.
  /// Example: `https://apps.apple.com/app/just-cards/id1234567890`
  static const String appStore =
      'https://apps.apple.com/app/just-cards/id0000000000';
}

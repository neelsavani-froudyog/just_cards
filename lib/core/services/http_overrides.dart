import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      // Development only: allow self-signed certificates.
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}


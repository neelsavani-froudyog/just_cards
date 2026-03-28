import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'core/services/api.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_session_service.dart';
import 'core/services/business_card_upload_service.dart';
import 'core/services/create_contact_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/parse_card_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'widgets/no_internet_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  ApiUrl.configure(baseUrl: ApiUrl.baseUrl);
  final session = Get.put<AuthSessionService>(
    AuthSessionService(),
    permanent: true,
  );
  await session.loadPersistedSession();
  Get.put<ApiService>(ApiService(), permanent: true);
  Get.put<ParseCardService>(ParseCardService(), permanent: true);
  Get.put<BusinessCardUploadService>(BusinessCardUploadService(), permanent: true);
  Get.put<CreateContactService>(CreateContactService(), permanent: true);
  Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
  runApp(const JustCardsApp());
}

class JustCardsApp extends StatelessWidget {
  const JustCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'JustCards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        textTheme: AppTextStyles.textTheme(),
        useMaterial3: true,
      ),
      initialRoute: Routes.splash,
      getPages: AppPages.pages,
      builder: (context, child) {
        return NoInternetOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

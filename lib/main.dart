import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/services/api.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_session_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiUrl.configure(baseUrl: ApiUrl.baseUrl);
  final session = Get.put<AuthSessionService>(
    AuthSessionService(),
    permanent: true,
  );
  await session.loadPersistedSession();
  Get.put<ApiService>(ApiService(), permanent: true);
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
    );
  }
}

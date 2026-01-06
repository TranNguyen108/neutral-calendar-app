import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/translations/app_translations.dart';
import 'core/utils/logger.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();
    final langCode = storage.getLanguage();
    final locale =
        langCode == 'vi' ? const Locale('vi', 'VN') : const Locale('en', 'US');

    Get.find<Logger>().info('Loading app with locale: $locale', tag: 'APP');

    return GetMaterialApp(
      title: 'Neural Calendar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      translations: AppTranslations(),
      locale: locale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}

import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import 'bindings/splash_binding.dart';
import 'views/splash_view.dart';

class SplashModule {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
  ];
}

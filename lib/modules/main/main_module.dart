import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import 'bindings/main_binding.dart';
import 'views/main_view.dart';

class MainModule {
  static final routes = [
    GetPage(
      name: AppRoutes.main,
      page: () => const MainView(),
      binding: MainBinding(),
    ),
  ];
}

import 'package:get/get.dart';
import 'bindings/home_binding.dart';
import 'views/home_view.dart';

class HomeModule {
  static final routes = [
    GetPage(
      name: '/home',
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
  ];
}

import 'package:get/get.dart';
import '../modules/splash/splash_module.dart';
import '../modules/main/main_module.dart';
import '../modules/task_detail/views/task_detail_view.dart';
import '../modules/report/bindings/report_binding.dart';
import '../modules/report/views/report_view.dart';
import '../modules/search/views/search_view.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    ...SplashModule.routes,
    ...MainModule.routes,
    GetPage(
      name: AppRoutes.taskDetail,
      page: () => const TaskDetailView(),
    ),
    GetPage(
      name: AppRoutes.report,
      page: () => const ReportView(),
      binding: ReportBinding(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchView(),
    ),
  ];
}

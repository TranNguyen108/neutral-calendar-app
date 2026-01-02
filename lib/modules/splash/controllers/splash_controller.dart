import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    print('✅ SplashController initialized');
    print('📍 Current route: ${Get.currentRoute}');
    print('📋 All routes: ${Get.routeTree}');
    _navigateToHome();
  }

  void _navigateToHome() {
    print('⏱️ Starting navigation timer (2 seconds)');
    Future.delayed(const Duration(seconds: 2), () {
      print('⏰ Timer completed!');
      if (!isClosed) {
        print('🚀 Attempting navigation to: ${AppRoutes.MAIN}');
        try {
          Get.offNamed(AppRoutes.MAIN);
          print('✅ Navigation called successfully');
        } catch (e) {
          print('❌ Navigation error: $e');
        }
      } else {
        print('⚠️ Controller is closed, skipping navigation');
      }
    });
  }

  void navigateNow() {
    print('🔥 Manual navigation triggered');
    Get.offNamed(AppRoutes.MAIN);
  }
}

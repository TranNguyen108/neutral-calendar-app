import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/logger.dart';

class SplashController extends GetxController {
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    Logger.d('SplashController: onInit called');
    _navigateToHome();
  }

  @override
  void onClose() {
    Logger.d('SplashController: onClose called - cancelling navigation');
    _isDisposed = true;
    super.onClose();
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 2), () {
      // Check both isClosed (GetX) and custom flag to prevent navigation after disposal
      if (!isClosed && !_isDisposed) {
        try {
          Get.offNamed(AppRoutes.main);
        } catch (e) {
          Logger.e('SplashController: Navigation error: $e');
        }
      } else {
        Logger.d(
            'SplashController: Navigation cancelled - controller disposed');
      }
    });
  }

  void navigateNow() {
    if (!_isDisposed) {
      Get.offNamed(AppRoutes.main);
    }
  }
}

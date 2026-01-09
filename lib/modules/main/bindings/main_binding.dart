import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../../manage/controllers/manage_controller.dart';
import '../../ai_chat/controllers/ai_chat_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<ManageController>(() => ManageController());
    Get.lazyPut<AIChatController>(() => AIChatController());
  }
}

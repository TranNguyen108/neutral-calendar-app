import 'package:get/get.dart';
import '../controllers/ai_chat_controller.dart';

class AIChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AIChatController>(() => AIChatController());
  }
}

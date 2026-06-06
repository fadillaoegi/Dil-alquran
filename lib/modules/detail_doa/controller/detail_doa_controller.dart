import 'package:dilalquran/modules/doa/model/doa_model.dart';
import 'package:get/get.dart';

class DetailDoaController extends GetxController {
  final Rx<DoaModel?> doa = Rx<DoaModel?>(null);

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is DoaModel) {
      doa.value = Get.arguments as DoaModel;
    }
  }
}

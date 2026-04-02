import 'package:get/get.dart';

import 'qr_contact_controller.dart';

class QrContactBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QrContactController>(
      () => QrContactController(),
      fenix: true,
    );
  }
}


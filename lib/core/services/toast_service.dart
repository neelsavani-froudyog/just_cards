import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';

class ToastService {
  static Future<void> success(String message) {
    return _show(
      message: message,
      type: ToastificationType.success,
    );
  }

  static Future<void> info(String message) {
    return _show(
      message: message,
      type: ToastificationType.info,
    );
  }

  static Future<void> error(String message) {
    return _show(
      message: message,
      type: ToastificationType.error,
    );
  }

  static Future<void> _show({
    required String message,
    required ToastificationType type,
  }) async {
    final context = Get.context;
    if (context == null) return;

    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.minimal,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 3),
      showProgressBar: false,
      title: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}

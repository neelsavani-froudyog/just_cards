import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastService {
  static Future<void> success(String message) {
    return _show(
      message: message,
      backgroundColor: Colors.green.shade700,
    );
  }

  static Future<void> info(String message) {
    return _show(
      message: message,
      backgroundColor: Colors.blueGrey.shade700,
    );
  }

  static Future<void> error(String message) {
    return _show(
      message: message,
      backgroundColor: Colors.red.shade700,
    );
  }

  static Future<void> _show({
    required String message,
    required Color backgroundColor,
  }) async {
    await Fluttertoast.cancel();
    await Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 14,
    );
  }
}


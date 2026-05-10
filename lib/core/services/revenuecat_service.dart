import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class RevenueCatService extends GetxService {
  final _customerInfoStream = StreamController<CustomerInfo>.broadcast();
  Stream<CustomerInfo> get customerInfoUpdates => _customerInfoStream.stream;

  bool _isConfigured = false;

  Future<void> initialize({
    required String apiKey,
    String? appUserId,
  }) async {
    if (_isConfigured) {
      if ((appUserId ?? '').trim().isNotEmpty) {
        await logIn(appUserId!.trim());
      }
      return;
    }

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    final configuration = PurchasesConfiguration(apiKey);
    final normalizedUserId = appUserId?.trim() ?? '';
    if (normalizedUserId.isNotEmpty) {
      configuration.appUserID = normalizedUserId;
    }

    await Purchases.configure(configuration);
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _isConfigured = true;
  }

  Future<void> logIn(String appUserId) async {
    final normalized = appUserId.trim();
    if (normalized.isEmpty) return;
    await Purchases.logIn(normalized);
  }

  Future<CustomerInfo> getCustomerInfo() async {
    return Purchases.getCustomerInfo();
  }

  Future<Offerings> getOfferings() async {
    return Purchases.getOfferings();
  }

  Future<CustomerInfo> restorePurchases() async {
    return Purchases.restorePurchases();
  }

  Future<PurchaseResult> purchasePackage(Package package) async {
    return Purchases.purchase(PurchaseParams.package(package));
  }

  Future<PaywallResult> presentPaywallIfNeeded({
    required String entitlementId,
    Offering? offering,
  }) async {
    return RevenueCatUI.presentPaywallIfNeeded(
      entitlementId,
      offering: offering,
      displayCloseButton: true,
    );
  }

  Future<void> presentCustomerCenter() async {
    await RevenueCatUI.presentCustomerCenter();
  }

  bool isPurchaseCancelled(PlatformException error) {
    return PurchasesErrorHelper.getErrorCode(error) ==
        PurchasesErrorCode.purchaseCancelledError;
  }

  String readableError(Object error) {
    if (error is PlatformException) {
      final details = error.message?.trim() ?? '';
      if (details.isNotEmpty) return details;
      return 'RevenueCat error code: ${error.code}';
    }
    return error.toString();
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _customerInfoStream.add(info);
  }

  @override
  void onClose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _customerInfoStream.close();
    super.onClose();
  }
}

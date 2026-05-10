import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../core/constants/revenuecat_constants.dart';
import '../../core/services/auth_session_service.dart';
import '../../core/services/revenuecat_service.dart';
import '../../core/services/toast_service.dart';

class SubscriptionController extends GetxController {
  late final RevenueCatService _revenueCatService;
  late final AuthSessionService _session;

  final isInitializing = true.obs;
  final isLoadingOfferings = false.obs;
  final isPurchasing = false.obs;
  final isRestoring = false.obs;
  final isOpeningCustomerCenter = false.obs;

  final customerInfo = Rxn<CustomerInfo>();
  final currentOffering = Rxn<Offering>();
  final availablePackages = <Package>[].obs;

  final hasProAccess = false.obs;
  final activePlanName = ''.obs;
  final lastError = RxnString();

  StreamSubscription<CustomerInfo>? _customerInfoSub;
  Worker? _emailWorker;

  @override
  void onInit() {
    super.onInit();
    _revenueCatService = Get.find<RevenueCatService>();
    _session = Get.find<AuthSessionService>();

    _customerInfoSub = _revenueCatService.customerInfoUpdates.listen(
      _updateCustomerInfo,
    );

    _emailWorker = ever<String>(_session.email, (email) async {
      final normalized = email.trim();
      if (normalized.isEmpty || normalized == 'you@example.com') return;
      await _safeRun(() => _revenueCatService.logIn(normalized));
      await refreshCustomerInfo();
    });

    initialize();
  }

  Future<void> initialize() async {
    if (!isInitializing.value) return;

    try {
      await _revenueCatService.initialize(
        apiKey: RevenueCatConstants.apiKey,
        appUserId: _effectiveAppUserId,
      );
      await Future.wait([refreshCustomerInfo(), loadOfferings()]);
      lastError.value = null;
    } catch (error) {
      lastError.value = _revenueCatService.readableError(error);
      await ToastService.error('Unable to initialize subscriptions.');
    } finally {
      isInitializing.value = false;
      update();
    }
  }

  String? get _effectiveAppUserId {
    final email = _session.email.value.trim();
    if (email.isEmpty || email == 'you@example.com') return null;
    return email;
  }

  Future<void> loadOfferings() async {
    if (isLoadingOfferings.value) return;
    isLoadingOfferings.value = true;
    update();

    try {
      final offerings = await _revenueCatService.getOfferings();
      final offering = offerings.current;
      currentOffering.value = offering;

      final packages = (offering?.availablePackages ?? <Package>[])
          .where(
            (pkg) => RevenueCatConstants.expectedProductIds.contains(
              pkg.storeProduct.identifier,
            ),
          )
          .toList();

      availablePackages.assignAll(packages);
      lastError.value = null;
    } catch (error) {
      lastError.value = _revenueCatService.readableError(error);
      await ToastService.error('Failed to load subscription products.');
    } finally {
      isLoadingOfferings.value = false;
      update();
    }
  }

  Future<void> refreshCustomerInfo() async {
    try {
      final info = await _revenueCatService.getCustomerInfo();
      _updateCustomerInfo(info);
      lastError.value = null;
    } catch (error) {
      lastError.value = _revenueCatService.readableError(error);
      update();
    }
  }

  Future<void> purchase(Package package) async {
    if (isPurchasing.value) return;
    isPurchasing.value = true;
    update();

    try {
      final result = await _revenueCatService.purchasePackage(package);
      _updateCustomerInfo(result.customerInfo);
      await ToastService.success('Purchase successful. Pro unlocked.');
    } on PlatformException catch (error) {
      if (_revenueCatService.isPurchaseCancelled(error)) {
        await ToastService.info('Purchase cancelled.');
      } else {
        await ToastService.error(_revenueCatService.readableError(error));
      }
    } catch (error) {
      await ToastService.error(_revenueCatService.readableError(error));
    } finally {
      isPurchasing.value = false;
      update();
    }
  }

  Future<void> showPaywall() async {
    try {
      final result = await _revenueCatService.presentPaywallIfNeeded(
        entitlementId: RevenueCatConstants.proEntitlementId,
        offering: currentOffering.value,
      );
      if (result == PaywallResult.purchased || result == PaywallResult.restored) {
        await refreshCustomerInfo();
        await ToastService.success('Subscription updated successfully.');
      }
    } catch (error) {
      await ToastService.error(_revenueCatService.readableError(error));
    }
  }

  Future<void> restorePurchases() async {
    if (isRestoring.value) return;
    isRestoring.value = true;
    update();

    try {
      final info = await _revenueCatService.restorePurchases();
      _updateCustomerInfo(info);
      if (hasProAccess.value) {
        await ToastService.success('Purchases restored.');
      } else {
        await ToastService.info('No active subscription found to restore.');
      }
    } catch (error) {
      await ToastService.error(_revenueCatService.readableError(error));
    } finally {
      isRestoring.value = false;
      update();
    }
  }

  Future<void> openCustomerCenter() async {
    if (isOpeningCustomerCenter.value) return;
    isOpeningCustomerCenter.value = true;
    update();

    try {
      await _revenueCatService.presentCustomerCenter();
      await refreshCustomerInfo();
    } catch (error) {
      await ToastService.error(_revenueCatService.readableError(error));
    } finally {
      isOpeningCustomerCenter.value = false;
      update();
    }
  }

  void _updateCustomerInfo(CustomerInfo info) {
    customerInfo.value = info;
    hasProAccess.value =
        info.entitlements.active[RevenueCatConstants.proEntitlementId]?.isActive ==
        true;
    activePlanName.value = _resolveActivePlanName(info);
    update();
  }

  String _resolveActivePlanName(CustomerInfo info) {
    final allIds = <String>{
      ...info.activeSubscriptions,
      ...info.allPurchasedProductIdentifiers,
    };
    if (allIds.contains(RevenueCatConstants.yearlyProductId)) return 'Yearly';
    if (allIds.contains(RevenueCatConstants.threeMonthProductId)) return 'Three Month';
    if (allIds.contains(RevenueCatConstants.monthlyProductId)) return 'Monthly';
    if (allIds.contains(RevenueCatConstants.lifetimeProductId)) return 'Lifetime';
    return '';
  }

  Future<void> _safeRun(Future<void> Function() callback) async {
    try {
      await callback();
    } catch (_) {
      // Ignore temporary identify errors; user can still purchase anonymously.
    }
  }

  @override
  void onClose() {
    _customerInfoSub?.cancel();
    _emailWorker?.dispose();
    super.onClose();
  }
}

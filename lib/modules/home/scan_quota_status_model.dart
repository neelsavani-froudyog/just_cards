class ScanQuotaStatusResponse {
  const ScanQuotaStatusResponse({
    required this.ok,
    required this.message,
    required this.data,
  });

  final bool ok;
  final String message;
  final List<ScanQuotaStatusItem> data;

  ScanQuotaStatusItem? get primary => data.isNotEmpty ? data.first : null;

  factory ScanQuotaStatusResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final items = <ScanQuotaStatusItem>[];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          items.add(ScanQuotaStatusItem.fromJson(item));
        }
      }
    }
    return ScanQuotaStatusResponse(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
      data: items,
    );
  }
}

class ScanQuotaStatusItem {
  const ScanQuotaStatusItem({
    required this.outUserId,
    required this.monthStartUtc,
    required this.monthlyScanLimit,
    required this.isScanEnabled,
    required this.reservedCount,
    required this.completedCount,
    required this.releasedCount,
    required this.failedCount,
    required this.inProgressCount,
    required this.usedCount,
    required this.remainingCount,
    required this.allowed,
    required this.planCode,
  });

  final String outUserId;
  final String monthStartUtc;
  final int monthlyScanLimit;
  final bool isScanEnabled;
  final int reservedCount;
  final int completedCount;
  final int releasedCount;
  final int failedCount;
  final int inProgressCount;
  final int usedCount;
  final int remainingCount;
  final bool allowed;
  final String planCode;

  bool get canScan => allowed && isScanEnabled && remainingCount > 0;

  factory ScanQuotaStatusItem.fromJson(Map<String, dynamic> json) {
    return ScanQuotaStatusItem(
      outUserId: (json['out_user_id'] ?? '').toString(),
      monthStartUtc: (json['month_start_utc'] ?? '').toString(),
      monthlyScanLimit: _toInt(json['monthly_scan_limit']),
      isScanEnabled: json['is_scan_enabled'] == true,
      reservedCount: _toInt(json['reserved_count']),
      completedCount: _toInt(json['completed_count']),
      releasedCount: _toInt(json['released_count']),
      failedCount: _toInt(json['failed_count']),
      inProgressCount: _toInt(json['in_progress_count']),
      usedCount: _toInt(json['used_count']),
      remainingCount: _toInt(json['remaining_count']),
      allowed: json['allowed'] == true,
      planCode: (json['plan_code'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

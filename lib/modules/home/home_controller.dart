import 'package:get/get.dart';

import '../../core/services/api.dart';
import '../../core/services/api_service.dart';
import '../notifications/notifications_model.dart';
import 'home_contacts_model.dart';
import 'home_events_model.dart';
import 'scan_quota_status_model.dart';
import '../organization/manage/my_organizations_model.dart';

class HomeController extends GetxController {
  late final ApiService _apiService;

  final selectedFilter = 0.obs;
  final searchQuery = ''.obs;

  final filters = const [
    'All',
    'Today',
    'Yesterday',
    'Last 7 days',
    'Last 30 days',
  ];

  final overview =
      <HomeOverviewStat>[
        const HomeOverviewStat('Contacts', '--'),
        const HomeOverviewStat('Scans', '--'),
        const HomeOverviewStat('Events', '--'),
        const HomeOverviewStat('Scans Left', '--'),
      ].obs;

  final events = <HomeMiniEvent>[].obs;
  final isEventsLoading = false.obs;
  final eventsErrorText = RxnString();
  final scansCount = 0.obs;
  final scansLeftCount = 0.obs;
  final isScanQuotaLoading = false.obs;
  final scanQuota = Rxn<ScanQuotaStatusItem>();
  final unreadNotificationsCount = 0.obs;
  final isNotificationsCountLoading = false.obs;

  final contacts = <HomeContact>[].obs;
  final isContactsLoading = false.obs;
  final contactsErrorText = RxnString();
  final myContactsTotalCount = RxnInt();
  final isMyContactsTotalCountLoading = false.obs;
  final contactsTotal = 0.obs;
  final contactsLimit = 20.obs;
  final contactsOffset = 0.obs;
  final isQuickAddSheetFlowInProgress = false.obs;
  int _contactsRequestVersion = 0;
  Worker? _contactsSearchWorker;

  final organizations = <OrganizationSummary>[].obs;
  final isOrganizationsLoading = false.obs;
  final organizationsErrorText = RxnString();

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _contactsSearchWorker = debounce<String>(
      searchQuery,
      (_) => fetchContacts(reset: true),
      time: const Duration(milliseconds: 350),
    );
    _initLoad();
  }

  @override
  void onClose() {
    _contactsSearchWorker?.dispose();
    super.onClose();
  }

  Future<void> _initLoad() async {
    await refreshAllData(force: true);
  }

  Future<void> refreshAllData({bool force = false}) async {
    await Future.wait(<Future<void>>[
      fetchEvents(force: force),
      fetchContacts(reset: true, force: force),
      fetchOrganizations(force: force),
      fetchScanQuotaStatus(force: force),
      fetchMyContactsTotalCount(),
      fetchUnreadNotificationsCount(),
    ]);
  }

  Future<void> refreshContactsData() async {
    await Future.wait(<Future<void>>[
      fetchContacts(reset: true, force: true),
      fetchMyContactsTotalCount(),
      fetchScanQuotaStatus(force: true),
    ]);
  }

  Future<void> fetchOrganizations({bool force = false}) async {
    if (isOrganizationsLoading.value) return;
    if (!force && organizations.isNotEmpty) return;

    isOrganizationsLoading.value = true;
    organizationsErrorText.value = null;
    try {
      await _apiService.getRequest(
        url: ApiUrl.profileOrganizations,
        queryParameters: const <String, dynamic>{'limit': 10, 'offset': 0},
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) {
            organizationsErrorText.value = 'Invalid organizations response';
            organizations.clear();
            return;
          }

          final parsed = MyOrganizationsResponse.fromJson(raw);
          if (!parsed.ok) {
            organizationsErrorText.value =
                parsed.message.isNotEmpty
                    ? parsed.message
                    : 'Failed to load organizations';
            organizations.clear();
            return;
          }

          organizations.assignAll(parsed.data);
        },
        onError: (message) {
          organizationsErrorText.value =
              (message?.isNotEmpty ?? false)
                  ? message
                  : 'Failed to load organizations';
          organizations.clear();
        },
      );
    } finally {
      isOrganizationsLoading.value = false;
    }
  }

  /// Badge count = notifications with `is_seen == false` (not invite "pending" totals).
  Future<void> fetchUnreadNotificationsCount() async {
    if (isNotificationsCountLoading.value) return;
    isNotificationsCountLoading.value = true;
    try {
      var unseenTotal = 0;
      var offset = 0;
      const limit = 80;
      const maxPages = 25;

      for (var pageIdx = 0; pageIdx < maxPages; pageIdx++) {
        var pageItems = <AppNotificationItem>[];
        var failed = false;

        await _apiService.postRequest(
          url: ApiUrl.notifications,
          data: <String, dynamic>{
            'status': 'pending',
            'search': '',
            'limit': limit,
            'offset': offset,
          },
          showSuccessToast: false,
          showErrorToast: false,
          onSuccess: (payload) {
            try {
              final raw = payload['response'];
              if (raw is Map<String, dynamic>) {
                pageItems =
                    NotificationsResponse.fromJson(raw).data.notifications;
              }
            } catch (_) {
              failed = true;
            }
          },
          onError: (_) => failed = true,
        );

        if (failed) {
          if (pageIdx == 0) return;
          break;
        }

        if (pageItems.isEmpty) break;

        unseenTotal += pageItems.where((n) => !n.isSeen).length;

        if (pageItems.length < limit) break;
        offset += limit;
      }

      unreadNotificationsCount.value = unseenTotal;
    } finally {
      isNotificationsCountLoading.value = false;
    }
  }

  Future<void> fetchMyContactsTotalCount() async {
    if (isMyContactsTotalCountLoading.value) return;
    isMyContactsTotalCountLoading.value = true;
    try {
      await _apiService.getRequest(
        url: ApiUrl.myContactsTotalCount,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) {
            myContactsTotalCount.value = null;
            return;
          }
          final ok = raw['ok'] == true;
          if (!ok) {
            myContactsTotalCount.value = null;
            return;
          }
          final total = raw['total'];
          if (total is num) {
            myContactsTotalCount.value = total.toInt();
          } else {
            myContactsTotalCount.value = int.tryParse(total?.toString() ?? '');
          }
        },
        onError: (_) {
          myContactsTotalCount.value = null;
        },
      );
    } finally {
      isMyContactsTotalCountLoading.value = false;
      _syncOverview();
    }
  }

  String _apiFilterFromIndex(int index) {
    switch (index) {
      case 0:
        return 'all';
      case 1:
        return 'today';
      case 2:
        return 'yesterday';
      case 3:
        return 'last_7_days';
      case 4:
        return 'last_30_days';
      default:
        return 'all';
    }
  }

  Future<void> fetchContacts({required bool reset, bool force = false}) async {
    final requestVersion = ++_contactsRequestVersion;
    contactsErrorText.value = null;

    if (force) {
      isContactsLoading.value = true;
      contacts.clear();
    }

    final selectedFilterIndex = selectedFilter.value;
    final requestOffset = contactsOffset.value;
    final requestLimit = contactsLimit.value;

    isContactsLoading.value = true;

    try {
      await _apiService.postRequest(
        url: ApiUrl.myContacts,
        data: <String, dynamic>{
          'p_filter': _apiFilterFromIndex(selectedFilterIndex),
          'p_limit': requestLimit,
          'p_offset': requestOffset,
          'p_search':
              searchQuery.value.trim().isEmpty
                  ? null
                  : searchQuery.value.trim(),
        },
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          if (requestVersion != _contactsRequestVersion) {
            return;
          }

          final rawDynamic = payload['response'];
          if (rawDynamic is! Map) {
            contactsErrorText.value = 'Invalid contacts response';
            return;
          }
          final raw = Map<String, dynamic>.from(rawDynamic);

          final parsed = HomeContactsResponse.fromJson(raw);
          if (!parsed.ok) {
            contactsErrorText.value =
                parsed.message.isNotEmpty
                    ? parsed.message
                    : 'Failed to load contacts';
            return;
          }

          contacts.assignAll(
            parsed.data
                .map(
                  (c) => HomeContact(
                    id: c.id,
                    name:
                        c.fullName.trim().isNotEmpty
                            ? c.fullName.trim()
                            : '${c.firstName} ${c.lastName}'.trim(),
                    email:
                        c.email1.trim().isNotEmpty ? c.email1.trim() : c.phone1,
                    company:
                        c.companyName.trim().isNotEmpty
                            ? c.companyName.trim()
                            : c.designation.trim(),
                  ),
                )
                .toList(),
          );

          contactsTotal.value = parsed.total;
          contactsLimit.value = parsed.limit == 0 ? requestLimit : parsed.limit;
          contactsOffset.value = parsed.offset;
        },
        onError: (message) {
          if (requestVersion != _contactsRequestVersion) {
            return;
          }
          contactsErrorText.value =
              message.isNotEmpty ? message : 'Failed to load contacts';
        },
      );
    } finally {
      if (requestVersion == _contactsRequestVersion) {
        isContactsLoading.value = false;
        _syncOverview();
      }
    }
  }

  Future<void> fetchEvents({bool force = false}) async {
    if (isEventsLoading.value) return;

    if (force) {
      isEventsLoading.value = true;
    }
    eventsErrorText.value = null;
    try {
      await _apiService.getRequest(
        url: ApiUrl.events,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final rawDynamic = payload['response'];
          if (rawDynamic is! Map) {
            eventsErrorText.value = 'Invalid events response';
            return;
          }
          final raw = Map<String, dynamic>.from(rawDynamic);
          final parsed = HomeEventsResponse.fromJson(raw);
          if (!parsed.ok) {
            eventsErrorText.value =
                parsed.message.isNotEmpty
                    ? parsed.message
                    : 'Failed to load events';
            return;
          }
          events.assignAll(
            parsed.data
                .map(
                  (e) => HomeMiniEvent(
                    e.title.isNotEmpty ? e.title : 'Untitled Event',
                    e.membersCount,
                    id: e.id,
                    location: e.location,
                    eventDate: e.eventDate,
                    scope: e.scope,
                    organizationId: e.organizationId,
                    role: e.role,
                    type: e.type,
                    createdBy: e.createdBy,
                  ),
                )
                .toList(),
          );
        },
        onError: (message) {
          eventsErrorText.value =
              (message?.isNotEmpty ?? false)
                  ? message
                  : 'Failed to load events';
        },
      );
    } finally {
      isEventsLoading.value = false;
      _syncOverview();
    }
  }

  Future<void> fetchScanQuotaStatus({bool force = false}) async {
    if (isScanQuotaLoading.value) return;

    isScanQuotaLoading.value = true;
    try {
      await _apiService.getRequest(
        url: ApiUrl.scanQuotaStatus,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final rootDynamic = payload['response'];
          if (rootDynamic is! Map) {
            _syncOverview();
            return;
          }
          final root = Map<String, dynamic>.from(rootDynamic);
          final parsed = ScanQuotaStatusResponse.fromJson(root);
          final item = parsed.primary;
          scanQuota.value = item;
          scansCount.value = item?.usedCount ?? 0;
          scansLeftCount.value = item?.remainingCount ?? 0;
          _syncOverview();
        },
        onError: (_) {
          _syncOverview();
        },
      );
    } finally {
      isScanQuotaLoading.value = false;
    }
  }

  void _syncOverview() {
    final contactsCountText =
        (myContactsTotalCount.value != null)
            ? myContactsTotalCount.value.toString()
            : '--';
    overview.assignAll(<HomeOverviewStat>[
      HomeOverviewStat('Contacts', contactsCountText),
      HomeOverviewStat('Scans', scansCount.value.toString()),
      HomeOverviewStat('Events', events.length.toString()),
      HomeOverviewStat('Scans Left', scansLeftCount.value.toString()),
    ]);
  }

  bool get canProceedManualEntry => (scanQuota.value?.remainingCount ?? 0) > 0;

  bool get hasActiveSearch => searchQuery.value.trim().isNotEmpty;

  void setFilter(int index) {
    selectedFilter.value = index;
    fetchContacts(reset: true, force: true);
  }

  void setSearch(String v) {
    final normalized = v.trimLeft();
    if (searchQuery.value == normalized) {
      return;
    }
    searchQuery.value = normalized;
  }

  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class HomeMiniEvent {
  const HomeMiniEvent(
    this.title,
    this.count, {
    required this.id,
    this.location = '',
    this.eventDate = '',
    this.scope = '',
    this.organizationId,
    this.role = '',
    this.type = '',
    this.createdBy = '',
  });

  final String id;
  final String title;
  final int count;
  final String location;
  final String eventDate;
  final String scope;
  final String? organizationId;
  final String role;
  final String type;
  final String createdBy;
}

class HomeOverviewStat {
  const HomeOverviewStat(this.label, this.value);

  final String label;
  final String value;
}

class HomeContact {
  const HomeContact({
    required this.id,
    required this.name,
    required this.email,
    required this.company,
  });

  final String id;
  final String name;
  final String email;
  final String company;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final a = parts.isNotEmpty ? parts.first : '';
    final b = parts.length > 1 ? parts[1] : '';
    final i1 = a.isEmpty ? '' : a[0];
    final i2 = b.isEmpty ? '' : b[0];
    return (i1 + i2).toUpperCase();
  }
}

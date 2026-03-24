import 'package:get/get.dart';

import '../../core/services/api.dart';
import '../../core/services/api_service.dart';
import 'home_events_model.dart';

class HomeController extends GetxController {
  late final ApiService _apiService;

  final selectedFilter = 0.obs;
  final searchQuery = ''.obs;

  final filters = const ['All', 'Today', 'Yesterday', 'Last 7 days', 'Last 30 days'];

  final overview = const <HomeOverviewStat>[
    HomeOverviewStat('Contacts', '125'),
    HomeOverviewStat('Scans', '43'),
    HomeOverviewStat('Events', '04'),
    HomeOverviewStat('Scans Left', '530'),
  ];

  final events = <HomeMiniEvent>[].obs;
  final isEventsLoading = false.obs;
  final eventsErrorText = RxnString();

  final contacts = const <HomeContact>[
    HomeContact(name: 'Randy Rudolph', email: 'name@domain.com', company: 'Company Name'),
    HomeContact(name: 'Alex Carter', email: 'alex@company.com', company: 'Acme Inc'),
    HomeContact(name: 'Priya Shah', email: 'priya@startup.io', company: 'Startup Studio'),
    HomeContact(name: 'Daniel Kim', email: 'daniel@domain.com', company: 'Kim & Co'),
  ];

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    if (isEventsLoading.value) return;
    isEventsLoading.value = true;
    eventsErrorText.value = null;
    try {
      await _apiService.getRequest(
        url: ApiUrl.events,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) {
            eventsErrorText.value = 'Invalid events response';
            return;
          }
          final parsed = HomeEventsResponse.fromJson(raw);
          if (!parsed.ok) {
            eventsErrorText.value =
                parsed.message.isNotEmpty ? parsed.message : 'Failed to load events';
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
                  ),
                )
                .toList(),
          );
        },
        onError: (message) {
          eventsErrorText.value =
              (message?.isNotEmpty ?? false) ? message : 'Failed to load events';
        },
      );
    } finally {
      isEventsLoading.value = false;
    }
  }

  void setFilter(int index) => selectedFilter.value = index;

  void setSearch(String v) => searchQuery.value = v;

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
  });

  final String id;
  final String title;
  final int count;
  final String location;
  final String eventDate;
  final String scope;
  final String? organizationId;
}

class HomeOverviewStat {
  const HomeOverviewStat(this.label, this.value);

  final String label;
  final String value;
}

class HomeContact {
  const HomeContact({required this.name, required this.email, required this.company});

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

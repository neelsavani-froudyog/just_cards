import 'package:get/get.dart';

class HomeController extends GetxController {
  final selectedFilter = 0.obs;
  final searchQuery = ''.obs;

  final filters = const ['All', 'Today', 'Yesterday', 'Last 7 days', 'Last 30 days'];

  final overview = const <HomeOverviewStat>[
    HomeOverviewStat('Contacts', '125'),
    HomeOverviewStat('Scans', '43'),
    HomeOverviewStat('Events', '04'),
    HomeOverviewStat('Scans Left', '530'),
  ];

  final events = const <HomeMiniEvent>[
    HomeMiniEvent('Electronica 2026', 36),
    HomeMiniEvent('PlastIndia 2026', 68),
    HomeMiniEvent('Aahar 2026', 12),
  ];

  final contacts = const <HomeContact>[
    HomeContact(name: 'Randy Rudolph', email: 'name@domain.com', company: 'Company Name'),
    HomeContact(name: 'Alex Carter', email: 'alex@company.com', company: 'Acme Inc'),
    HomeContact(name: 'Priya Shah', email: 'priya@startup.io', company: 'Startup Studio'),
    HomeContact(name: 'Daniel Kim', email: 'daniel@domain.com', company: 'Kim & Co'),
  ];

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
  const HomeMiniEvent(this.title, this.count);

  final String title;
  final int count;
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrader/upgrader.dart';

import '../../core/services/auth_session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../bottomNavigation/bottom_navigation_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../events/create/create_event_sheet.dart';
import 'home_controller.dart';
import 'home_events_shimmer_view.dart';
import 'home_contacts_shimmer_sliver.dart';
import 'widgets/add_contact_sheet.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeController controller;
  late final TextEditingController _homeSearchController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomeController>();
    _homeSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _homeSearchController.dispose();
    super.dispose();
  }

  Future<void> _openQuickAddSheet() async {
    if (controller.isQuickAddSheetFlowInProgress.value ||
        (Get.isBottomSheetOpen ?? false)) {
      return;
    }

    controller.isQuickAddSheetFlowInProgress.value = true;
    try {
      await controller.fetchScanQuotaStatus();

      if (Get.isBottomSheetOpen ?? false) return;

      final result = await Get.bottomSheet(
        const AddContactSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
      if (result == true) {
        await controller.refreshAllData();
      }
    } finally {
      controller.isQuickAddSheetFlowInProgress.value = false;
    }
  }

  Future<void> _openCreateEventSheet() async {
    if (Get.isBottomSheetOpen ?? false) return;
    final created = await CreateEventSheet.open();
    if (created == true) {
      await controller.refreshAllData();
    }
  }

  Future<void> _openContactsTab() async {
    if (!Get.isRegistered<BottomNavigationController>()) {
      return;
    }
    await Get.find<BottomNavigationController>().onSelect(1);
  }

  Widget build(BuildContext context) {
    final greeting = controller.greeting();
    final session = Get.find<AuthSessionService>();

    return UpgradeAlert(
      upgrader: Upgrader(messages: JustCardsUpgraderMessages()),
      showIgnore: false,
      showLater: false,
      barrierDismissible: false,
      showReleaseNotes: true,
      showPrompt: false,
      shouldPopScope: () => false,
      dialogStyle:
          Platform.isIOS
              ? UpgradeDialogStyle.cupertino
              : UpgradeDialogStyle.material,
      navigatorKey: Get.key,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        floatingActionButton: FloatingActionButton(
          heroTag: 'home_quick_add_fab',
          onPressed: _openQuickAddSheet,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 10,
          child: const Icon(Icons.badge_rounded),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => controller.refreshAllData(force: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(
                                () => Text(
                                  'Hi, ${session.displayName.value}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color: AppColors.ink.withValues(
                                      alpha: 0.55,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                greeting,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Obx(
                          () => _NotificationBellButton(
                            count: controller.unreadNotificationsCount.value,
                            onTap: () async {
                              await Get.toNamed(Routes.notifications);
                              await controller.fetchUnreadNotificationsCount();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                  sliver: SliverToBoxAdapter(
                    child: _SearchBar(
                      hintText: 'Search…',
                      controller: _homeSearchController,
                      onSubmitted: (q) async {
                        final query = q.trim();
                        await Get.toNamed(
                          Routes.contactSearch,
                          arguments: query,
                        );
                        _homeSearchController.clear();
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.dashboard_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Overview',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 5, 18, 10),
                  sliver: SliverToBoxAdapter(
                    child: Obx(
                      () => _OverviewStats(stats: controller.overview.toList()),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.event_rounded,
                            size: 16,
                            color: AppColors.accentTeal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Events',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.ink),
                        ),
                        Obx(() {
                          final count = controller.events.length;
                          if (count == 0) return const SizedBox.shrink();
                          return Row(
                            children: [
                              const SizedBox(width: 4),
                              Text(
                                '($count)',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: AppColors.ink.withValues(alpha: 0.62),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        }),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Get.toNamed(Routes.allEvents),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: const Row(
                            children: [
                              Text('View All'),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 18, 10),
                  sliver: SliverToBoxAdapter(
                    child: Obx(() {
                      if (controller.isEventsLoading.value) {
                        return const HomeEventsShimmerView();
                      }
                      if (controller.events.isEmpty) {
                        return SizedBox(
                          height: 168,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                10,
                                12,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.ink.withValues(alpha: 0.12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.ink.withValues(
                                      alpha: 0.02,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.event_busy_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'No events found',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.copyWith(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          controller.eventsErrorText.value ??
                                              'Create your first event to get started.',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: AppColors.ink.withValues(
                                              alpha: 0.60,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: FilledButton.icon(
                                            onPressed: _openCreateEventSheet,
                                            icon: const Icon(
                                              Icons.event_available_rounded,
                                              size: 18,
                                            ),
                                            label: const Text('Create event'),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              foregroundColor: AppColors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 118,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          scrollDirection: Axis.horizontal,
                          itemBuilder:
                              (context, index) =>
                                  _EventCard(event: controller.events[index]),
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 14),
                          itemCount: controller.events.length,
                        ),
                      );
                    }),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return Obx(() {
                            final selected =
                                controller.selectedFilter.value == index;
                            return ChoiceChip(
                              label: Text(controller.filters[index]),
                              selected: selected,
                              onSelected: (_) => controller.setFilter(index),
                              selectedColor: AppColors.accentTeal.withValues(
                                alpha: 0.18,
                              ),
                              backgroundColor: AppColors.white,
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color:
                                    selected
                                        ? AppColors.ink
                                        : AppColors.ink.withValues(alpha: 0.62),
                              ),
                              side: BorderSide(
                                color:
                                    selected
                                        ? AppColors.accentTeal.withValues(
                                          alpha: 0.70,
                                        )
                                        : AppColors.ink.withValues(alpha: 0.08),
                                width: selected ? 1.6 : 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            );
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                  sliver: Obx(() {
                    if (controller.isContactsLoading.value &&
                        controller.contacts.isEmpty) {
                      return const HomeContactsShimmerSliver();
                    }
                    if (controller.contacts.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.ink.withValues(alpha: 0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.ink.withValues(alpha: 0.03),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentTeal.withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.accentTeal.withValues(
                                        alpha: 0.30,
                                      ),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.person_search_rounded,
                                    color: AppColors.ink.withValues(
                                      alpha: 0.72,
                                    ),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No contacts found',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  controller.contactsErrorText.value ??
                                      'Scan a card or add a contact manually to see it here.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.ink.withValues(
                                      alpha: 0.60,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  onPressed: _openQuickAddSheet,
                                  icon: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Add Contact'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList.separated(
                      itemCount: controller.contacts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final contact = controller.contacts[index];
                        return _ContactTile(contact: contact);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JustCardsUpgraderMessages extends UpgraderMessages {
  @override
  String get title => 'Update JustCards';

  @override
  String get body =>
      'A new version of {{appName}} is available (v{{currentAppStoreVersion}}).\n'
      'You’re on v{{currentInstalledVersion}}.\n\n'
      'Please update to continue.';

  @override
  String get buttonTitleUpdate => 'UPDATE NOW';
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.hintText,
    required this.controller,
    required this.onSubmitted,
  });

  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hint: hintText,
      prefixIcon: Icon(
        Icons.search_rounded,
        color: AppColors.ink.withValues(alpha: 0.55),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      borderRadius: 8,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      filled: true,
      fillColor: AppColors.surface,
      borderColor: AppColors.ink.withValues(alpha: 0.2),
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeText = count > 99 ? '99+' : count.toString();
    final isSingleDigit = badgeText.length == 1;
    return Tooltip(
      message: 'Notifications',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.ink.withValues(alpha: 0.90),
                      size: 24,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        height: 18,
                        constraints: BoxConstraints(
                          minWidth: isSingleDigit ? 18 : 22,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSingleDigit ? 0 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: AppColors.white,
                            width: 1.2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badgeText,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewStats extends StatelessWidget {
  const _OverviewStats({required this.stats});

  final List<HomeOverviewStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cardWidth = (c.maxWidth / 4).clamp(140.0, 180.0);

        return SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final s = stats[index];
              return SizedBox(
                width: cardWidth,
                child: _StatCard(label: s.label, value: s.value),
              );
            },
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.02),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.56),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          value,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final HomeMiniEvent event;

  @override
  Widget build(BuildContext context) {
    const cardsCount = 143;
    final location =
        event.location.isNotEmpty ? event.location : 'Location not specified';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            () => Get.toNamed(
              Routes.manageEvent,
              arguments: <String, dynamic>{
                'eventId': event.id,
                'title': event.title,
                'location': location,
                'eventDate': event.eventDate,
                'type': event.type.isNotEmpty ? event.type : 'member',
                'member_role': event.role,
                'organizationId': event.organizationId,
                'createdBy': event.createdBy,
                'membersCount': event.count,
                'cardsCount': cardsCount,
                'role': event.role,
              },
            ),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: Ink(
          width: 192,
          height: 112,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _MetricPill(
                        icon: Icons.group_rounded,
                        color: AppColors.primary,
                        label: '${event.count} Members',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.70),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});

  final HomeContact contact;

  @override
  Widget build(BuildContext context) {
    final initials = contact.initials;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final id = contact.id.trim();
          if (id.isEmpty) return;
          final result = await Get.toNamed(
            Routes.contactDetails,
            arguments: id,
          );
          if (result == Routes.contactDeletedPopResult) {
            final c = Get.find<HomeController>();
            await c.fetchContacts(reset: true);
            await c.fetchMyContactsTotalCount();
          }
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.040),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentTeal.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppColors.accentTeal.withValues(alpha: 0.60),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.70),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      contact.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.ink.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// HomeMiniEvent and HomeContact live in `home_controller.dart`.

// AddContactSheet moved to `modules/home/widgets/add_contact_sheet.dart`.

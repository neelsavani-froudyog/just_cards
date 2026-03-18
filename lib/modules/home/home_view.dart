import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import 'home_controller.dart';
import 'widgets/add_contact_sheet.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final greeting = controller.greeting();

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Get.bottomSheet(
              const AddContactSheet(),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 10,
        child: const Icon(Icons.badge_rounded),
      ),
      body: SafeArea(
        child: CustomScrollView(
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
                          Text(
                            'Hi, Coffee Lover',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: AppColors.ink.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w700,
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
                    IconButton(
                      onPressed: () => Get.toNamed(Routes.notifications),
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: AppColors.ink,
                      tooltip: 'Notifications',
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
                  onChanged: controller.setSearch,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              sliver: SliverToBoxAdapter(
                child: _OverviewStats(stats: controller.overview),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Events',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.ink),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 95,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  itemBuilder:
                      (context, index) =>
                          _EventCard(event: controller.events[index]),
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemCount: controller.events.length,
                ),
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
                          backgroundColor: Colors.white,
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
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 90),
              sliver: SliverList.separated(
                itemCount: controller.contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final contact = controller.contacts[index];
                  return _ContactTile(contact: contact);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hintText, required this.onChanged});

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      hint: hintText,
      prefixIcon: Icon(
        Icons.search_rounded,
        color: AppColors.ink.withValues(alpha: 0.55),
      ),
      onChanged: onChanged,
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      filled: true,
      fillColor: AppColors.surface,
      borderColor: AppColors.ink.withValues(alpha: 0.2),
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
        final compact = c.maxWidth < 360;
        final cardWidth = compact ? 138.0 : (c.maxWidth) / 4;

        return SizedBox(
          height: 85,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.60),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final HomeMiniEvent event;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            () => Get.toNamed(
              Routes.manageEvent,
              arguments: <String, dynamic>{
                'title': event.title,
                'location': 'Greater Noida, India',
                'membersCount': 12,
                'cardsCount': 143,
              },
            ),
        child: Ink(
          width: 174,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.020),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${event.count}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
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
        onTap: () => Get.toNamed(Routes.contactDetails),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
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

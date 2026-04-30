import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_cards/design_system/justcards_design_system.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/custom_text_field.dart';
import '../../home/home_controller.dart';
import '../../home/widgets/add_contact_sheet.dart';

class ContactListView extends GetView<HomeController> {
  const ContactListView({super.key});

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
        await controller.refreshContactsData();
      }
    } finally {
      controller.isQuickAddSheetFlowInProgress.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton(
        heroTag: 'contact_list_quick_add_fab',
        onPressed: _openQuickAddSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 10,
        child: const Icon(Icons.badge_rounded),
      ),
      appBar: AppBar(
        title: const Text('Contact'),
        centerTitle: false,
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh contacts',
            onPressed: () => controller.refreshContactsData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refreshContactsData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                sliver: SliverToBoxAdapter(
                  child: _ContactSearchBar(
                    hintText: 'Search contacts...',
                    onChanged: controller.setSearch,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  10,
                  0,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 12, 0, 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            itemCount: controller.filters.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              return Obx(() {
                                final selected =
                                    controller.selectedFilter.value == index;
                                return ChoiceChip(
                                  showCheckmark: false,
                                  label: Text(controller.filters[index]),
                                  selected: selected,
                                  onSelected: (_) => controller.setFilter(index),
                                  selectedColor: AppColors.primary,
                                  backgroundColor: AppColors.white,
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: selected
                                            ? AppColors.white
                                            : AppColors.ink.withValues(
                                                alpha: 0.62,
                                              ),
                                      ),
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.primary
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
                        const SizedBox(height: 12),
                        Obx(() {
                          if (controller.isContactsLoading.value &&
                              controller.contacts.isEmpty) {
                            return const _ContactsShimmerList();
                          }
                          if (controller.contacts.isEmpty) {
                            final emptyMessage = controller.hasActiveSearch
                                ? 'No contacts match your search.'
                                : controller.contactsErrorText.value ??
                                    'Scan a card or add a contact manually to see it here.';

                            return Padding(
                              padding: EdgeInsets.only(top: 6,right: 18,bottom: MediaQuery.of(context).size.height * 0.275),
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
                                        color: AppColors.ink.withValues(alpha: 0.72),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No contacts found',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      emptyMessage,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
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
                            );
                          }

                          return ListView.separated(
                            itemCount: controller.contacts.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(0, 0, 18, 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final contact = controller.contacts[index];
                              return _ContactTile(contact: contact,index: index,);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactsShimmerList extends StatefulWidget {
  // ignore: unused_element_parameter
  const _ContactsShimmerList({this.itemCount = 6});

  final int itemCount;

  @override
  State<_ContactsShimmerList> createState() => _ContactsShimmerListState();
}

class _ContactsShimmerListState extends State<_ContactsShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Column(
          children: [
            for (var i = 0; i < widget.itemCount; i++) ...[
              _ShimmerContactCard(progress: t),
              if (i < widget.itemCount - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _ShimmerContactCard extends StatelessWidget {
  const _ShimmerContactCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 18, 0),
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
          _ShimmerBlock(width: 48, height: 48, radius: 24, progress: progress),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBlock(width: 170, height: 14, radius: 8, progress: progress),
                const SizedBox(height: 8),
                _ShimmerBlock(width: 220, height: 12, radius: 8, progress: progress),
                const SizedBox(height: 6),
                _ShimmerBlock(width: 140, height: 12, radius: 8, progress: progress),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _ShimmerBlock(width: 18, height: 18, radius: 9, progress: progress),
        ],
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.width,
    required this.height,
    required this.radius,
    required this.progress,
  });

  final double width;
  final double height;
  final double radius;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final begin = -1.2 + (progress * 2.4);
    final end = begin + 1.0;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(begin, -0.3),
          end: Alignment(end, 0.3),
          colors: [
            AppColors.ink.withValues(alpha: 0.06),
            AppColors.ink.withValues(alpha: 0.12),
            AppColors.ink.withValues(alpha: 0.06),
          ],
        ),
      ),
    );
  }
}

class _ContactSearchBar extends StatelessWidget {
  const _ContactSearchBar({required this.hintText, required this.onChanged});

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
      borderRadius: 8,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      filled: true,
      fillColor: AppColors.surface,
      borderColor: AppColors.ink.withValues(alpha: 0.2),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, required this.index});

   final int index;

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
            await c.refreshContactsData();
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
                  color: JCColors.avatarColors[index % JCColors.avatarColors.length],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
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
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/custom_text_field.dart';
import '../../home/home_contacts_shimmer_sliver.dart';
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
      backgroundColor: AppColors.surface,
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
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
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
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
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
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                sliver: Obx(() {
                  if (controller.isContactsLoading.value) {
                    return const HomeContactsShimmerSliver();
                  }
                  if (controller.contacts.isEmpty) {
                    final emptyMessage =
                        controller.hasActiveSearch
                            ? 'No contacts match your search.'
                            : controller.contactsErrorText.value ??
                                'Scan a card or add a contact manually to see it here.';

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
                                  color: AppColors.ink.withValues(alpha: 0.72),
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
                                emptyMessage,
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.ink.withValues(alpha: 0.60),
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

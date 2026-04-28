import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/custom_text_field.dart';
import '../../home/home_contacts_shimmer_sliver.dart';
import '../../home/home_controller.dart';

class ContactSearchView extends StatefulWidget {
  const ContactSearchView({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<ContactSearchView> createState() => _ContactSearchViewState();
}

class _ContactSearchViewState extends State<ContactSearchView> {
  late final HomeController _controller;
  late final TextEditingController _textController;
  late final String _previousQuery;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<HomeController>();
    _previousQuery = _controller.searchQuery.value;
    final arg = Get.arguments;
    final initial = (widget.initialQuery ?? (arg is String ? arg : null)) ?? '';
    _textController = TextEditingController(text: initial);

    _controller.setSearch(_textController.text);
  }

  @override
  void dispose() {
    _controller.setSearch(_previousQuery);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Search Contacts'),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              sliver: SliverToBoxAdapter(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, _) {
                    final hasText = value.text.trim().isNotEmpty;
                    return Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _textController,
                            hint: 'Search contacts...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.ink.withValues(alpha: 0.55),
                            ),
                            textInputAction: TextInputAction.search,
                            onChanged: _controller.setSearch,
                            borderRadius: 8,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            borderColor: AppColors.ink.withValues(alpha: 0.2),
                          ),
                        ),
                        if (hasText) ...[
                          const SizedBox(width: 10),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                _textController.clear();
                                _controller.setSearch('');
                              },
                              child: Ink(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(
                                    alpha: 0.95,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.ink.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: AppColors.ink.withValues(alpha: 0.60),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
              sliver: Obx(() {
                if (_controller.isContactsLoading.value) {
                  return const HomeContactsShimmerSliver();
                }

                if (_controller.contacts.isEmpty) {
                  final emptyMessage =
                      _controller.hasActiveSearch
                          ? 'No contacts match your search.'
                          : 'Start typing to search your contacts.';

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
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList.separated(
                  itemCount: _controller.contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = _controller.contacts[index];
                    return _ContactTile(contact: contact);
                  },
                );
              }),
            ),
          ],
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
        onTap: () async {
          final id = contact.id.trim();
          if (id.isEmpty) return;
          await Get.toNamed(Routes.contactDetails, arguments: id);
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
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        contact.company,
                        contact.email,
                      ].where((e) => e.trim().isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.ink.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/custom_text_field.dart';
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
    // Ensure the shared HomeController list returns to the previous query state
    // when leaving the search screen.
    _controller.fetchContacts(reset: true, force: true);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Search Contacts'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                                color: AppColors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.ink.withValues(alpha: 0.08),
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
            Obx(() {
              if (_controller.isContactsLoading.value) {
                return const Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: _ContactsShimmerList(),
                  ),
                );
              }

              if (_controller.contacts.isEmpty) {
                final emptyMessage =
                    _controller.hasActiveSearch
                        ? 'No contacts match your search.'
                        : 'Start typing to search your contacts.';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
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

              return Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                  ),
                  child: ListView.separated(
                    itemCount: _controller.contacts.length,
                    shrinkWrap: true,
                    primary: false,
                    padding: EdgeInsets.zero,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final contact = _controller.contacts[index];
                      return _ContactTile(contact: contact);
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ContactsShimmerList extends StatefulWidget {
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
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Column(
            children: [
              for (var i = 0; i < widget.itemCount; i++) ...[
                _ShimmerContactCard(progress: t),
                if (i < widget.itemCount - 1) const SizedBox(height: 12),
              ],
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
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

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});

  final HomeContact contact;

  Color _avatarColorFor(String seed) {
    const palette = <Color>[
      Color(0xFF0A66C2),
      Color(0xFF7B2FC7),
      Color(0xFF0D8A4E),
      Color(0xFFC47A00),
      Color(0xFF0D6C8A),
      Color(0xFFB00020),
    ];
    if (seed.trim().isEmpty) return palette.first;
    var hash = 0;
    for (final c in seed.codeUnits) {
      hash = 0x1fffffff & (hash + c);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return palette[hash.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final initials = contact.initials;
    final avatarColor = _avatarColorFor(
      '${contact.name}|${contact.email}|$initials',
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final id = contact.id.trim();
          if (id.isEmpty) return;
          await Get.toNamed(Routes.contactDetails, arguments: id);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
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
                  color: avatarColor,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (contact.company.trim().isNotEmpty)
                      Text(
                        contact.company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.ink.withValues(alpha: 0.30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

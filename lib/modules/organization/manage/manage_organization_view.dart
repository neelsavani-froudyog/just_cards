import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import 'manage_organization_controller.dart';
import 'manage_organization_shimmer_view.dart';
import 'my_organizations_model.dart';

class ManageOrganizationView extends GetView<ManageOrganizationController> {
  const ManageOrganizationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('My Organizations'),
        actions: [
          IconButton(
            onPressed: controller.fetchOrganizations,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'manage_organization_create_fab',
        onPressed: () async {
          await Get.toNamed(Routes.createOrganization);
          controller.fetchOrganizations();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add_business_rounded),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ManageOrganizationShimmerView();
        }

        final error = controller.errorText.value;
        if (error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: controller.fetchOrganizations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.organizations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.apartment_rounded,
                    size: 52,
                    color: AppColors.ink.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No organizations yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap the button below to create your first organization.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final ownedOrganizations = controller.organizations
            .where((org) => _normalizedRole(org) == _OrgRole.owner)
            .toList(growable: false);
        final memberOrganizations = controller.organizations
            .where((org) => _normalizedRole(org) != _OrgRole.owner)
            .toList(growable: false);

        return RefreshIndicator(
          onRefresh: controller.fetchOrganizations,
          child: ListView(
            controller: controller.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              if (ownedOrganizations.isNotEmpty) ...[
                for (final org in ownedOrganizations) ...[
                  _OrganizationCard(org: org),
                  const SizedBox(height: 12),
                ],
              ],
              if (memberOrganizations.isNotEmpty) ...[
                for (final org in memberOrganizations) ...[
                  _OrganizationCard(org: org),
                  const SizedBox(height: 12),
                ],
              ],
              if (controller.isFetchingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({required this.org});

  final OrganizationSummary org;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () => Get.toNamed(
            Routes.organizationDetail,
            arguments: <String, dynamic>{
              'organizationId': org.id,
              'organization_id': org.id,
              'name': org.name,
              'industry': org.industry,
              'type': org.type,
              'role': org.role,
              'member_role': org.role,
              'isActive': org.isActive,
            },
          ),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.apartment_rounded, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    org.industry?.isNotEmpty == true
                        ? org.industry!
                        : 'General',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RoleBadge(role: _normalizedRole(org)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:
                    org.isActive
                        ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                        : const Color(0xFF64748B).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                org.isActive ? 'Active' : 'Inactive',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color:
                      org.isActive
                          ? const Color(0xFF15803D)
                          : const Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OrgRole { owner, editor, viewer, member }

_OrgRole _normalizedRole(OrganizationSummary org) {
  final normalizedType = org.type.trim().toLowerCase();
  final normalizedRole = org.role.trim().toLowerCase();
  final candidate = normalizedType.isNotEmpty && normalizedType != 'member'
      ? normalizedType
      : normalizedRole;

  switch (candidate) {
    case 'owner':
      return _OrgRole.owner;
    case 'editor':
      return _OrgRole.editor;
    case 'viewer':
      return _OrgRole.viewer;
    default:
      return _OrgRole.member;
  }
}

class _OrganizationSectionHeader extends StatelessWidget {
  const _OrganizationSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.ink.withValues(alpha: 0.7),
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final _OrgRole role;

  @override
  Widget build(BuildContext context) {
    final style = _badgeStyle(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.foregroundColor),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: style.foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
}

_BadgeStyle _badgeStyle(_OrgRole role) {
  switch (role) {
    case _OrgRole.owner:
      return _BadgeStyle(
        label: 'Owner',
        icon: Icons.workspace_premium_rounded,
        backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.16),
        foregroundColor: const Color(0xFFB45309),
      );
    case _OrgRole.editor:
      return _BadgeStyle(
        label: 'Editor',
        icon: Icons.person_rounded,
        backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
        foregroundColor: const Color(0xFF1D4ED8),
      );
    case _OrgRole.viewer:
      return _BadgeStyle(
        label: 'Viewer',
        icon: Icons.person_rounded,
        backgroundColor: AppColors.ink.withValues(alpha: 0.08),
        foregroundColor: AppColors.ink.withValues(alpha: 0.75),
      );
    case _OrgRole.member:
      return _BadgeStyle(
        label: 'Member',
        icon: Icons.person_rounded,
        backgroundColor: AppColors.primary.withValues(alpha: 0.10),
        foregroundColor: AppColors.primary,
      );
  }
}

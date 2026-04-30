import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_cards/core/theme/app_colors.dart';
import 'package:just_cards/modules/bottomNavigation/bottom_navigation_controller.dart';
import 'package:just_cards/modules/contacts/list/contact_list_view.dart';
import 'package:just_cards/modules/home/home_view.dart';

import '../profile/profile_view.dart';
import 'widgets/bottom_navigation/just_bottom_navigation_bar.dart';

class BottomNavigationView extends GetView<BottomNavigationController> {
  const BottomNavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = const <Widget>[HomeView(), ContactListView(), ProfileView()];

    return Obx(() {
      final index = controller.selectedIndex.value;
      return Scaffold(
        backgroundColor: AppColors.white,
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: JustBottomNavigationBar(
          index: index,
          onSelect: controller.onSelect,
        ),
      );
    });
  }
}

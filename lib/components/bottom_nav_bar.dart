import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../pages/firstPage.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Define navigation items with Eva icons
    final List<({IconData icon, IconData activeIcon, String label})>
        navigationItems = const [
      (
        icon: EvaIcons.homeOutline,
        activeIcon: EvaIcons.home,
        label: 'Home',
      ),
      (
        icon: EvaIcons.shoppingBagOutline,
        activeIcon: EvaIcons.shoppingBag,
        label: 'Deliveries',
      ),
      (
        icon: EvaIcons.headphonesOutline,
        activeIcon: EvaIcons.headphones,
        label: 'Support',
      ),
      (
        icon: EvaIcons.personOutline,
        activeIcon: EvaIcons.person,
        label: 'Profile',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: BottomNavigationBar(
            selectedItemColor: const Color.fromRGBO(0, 31, 62, 1),
            currentIndex: context.watch<IndexProvider>().selectedIndex,
            backgroundColor: Colors.white,
            onTap: context.read<IndexProvider>().setSelectedIndex,
            unselectedItemColor: Colors.grey.shade400,
            iconSize: 24,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            elevation: 0,
            items: navigationItems
                .map((item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      label: item.label,
                      activeIcon: Icon(item.activeIcon),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

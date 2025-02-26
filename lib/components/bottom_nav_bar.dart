import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/firstPage.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 12),
          child: BottomNavigationBar(
            selectedItemColor: Color.fromRGBO(0, 70, 67, 1),
            currentIndex: context.watch<IndexProvider>().selectedIndex,
            backgroundColor: Colors.white,
            onTap: context.read<IndexProvider>().setSelectedIndex,
            unselectedItemColor: Colors.grey.shade400,
            iconSize: 28,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home_outlined),
                ),
                label: 'Home',
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home),
                ),
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.search_outlined),
                ),
                label: 'Search',
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.search),
                ),
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.shopping_cart_outlined),
                ),
                label: 'Orders',
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.shopping_cart),
                ),
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.chat_bubble_outline_outlined),
                ),
                label: 'Support',
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.chat_bubble),
                ),
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_2_outlined),
                ),
                label: 'Profile',
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

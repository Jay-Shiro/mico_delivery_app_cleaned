import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/pages/MapPage.dart';
import 'package:micollins_delivery_app/pages/homePage.dart';
import 'package:micollins_delivery_app/pages/ordersPage.dart';
import 'package:micollins_delivery_app/pages/profilePage.dart';
import 'package:micollins_delivery_app/pages/supportPage.dart';
import 'package:provider/provider.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class IndexProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}

final List<Widget> _pages = [
  Homepage(),
  MapPage(),
  OrdersPage(
    startPoint: '', distance: '', endPoint: '', price: '',
    // You can pass data here if needed
  ),
  SupportPage(),
  ProfilePage(),
];

class _FirstPageState extends State<FirstPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => IndexProvider()),
          ],
          child: Consumer<IndexProvider>(
            builder: (context, indexProvider, child) {
              return Scaffold(
                body: IndexedStack(
                  index: indexProvider.selectedIndex,
                  children: _pages,
                ),
                bottomNavigationBar: BottomNavigationBar(
                  selectedItemColor: Color.fromRGBO(0, 70, 67, 1),
                  currentIndex: indexProvider.selectedIndex, // Corrected
                  backgroundColor: Color.fromRGBO(241, 241, 241, 1),
                  onTap: indexProvider.setSelectedIndex, // Corrected
                  unselectedItemColor: Colors.black87,
                  iconSize: 32,
                  showUnselectedLabels: true,
                  selectedIconTheme: IconThemeData(size: 34),
                  items: [
                    //home
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      label: 'HOME',
                      activeIcon: Icon(Icons.home),
                    ),
                    //search
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search_outlined),
                      label: 'SEARCH',
                    ),
                    //orders
                    BottomNavigationBarItem(
                      icon: Icon(Icons.shopping_cart_outlined),
                      label: 'ORDERS',
                      activeIcon: Icon(Icons.shopping_cart),
                    ),
                    //support
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat_bubble_outline_outlined),
                      label: 'SUPPORT',
                      activeIcon: Icon(Icons.chat_bubble),
                    ),
                    //profile
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_2_outlined),
                      label: 'PROFILE',
                      activeIcon: Icon(Icons.person_2),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/components/bottom_nav_bar.dart';
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
  OrdersPage(),
  SupportPage(),
  ProfilePage(),
];

class _FirstPageState extends State<FirstPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => IndexProvider()),
          ],
          child: Consumer<IndexProvider>(
            builder: (context, indexProvider, child) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: IndexedStack(
                  index: indexProvider.selectedIndex,
                  children: _pages,
                ),
                bottomNavigationBar: CustomBottomNavBar(),
              );
            },
          ),
        ),
      ),
    );
  }
}

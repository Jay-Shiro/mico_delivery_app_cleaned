import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/pages/user_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:micollins_delivery_app/components/bottom_nav_bar.dart';
import 'package:micollins_delivery_app/pages/ordersPage.dart';
import 'package:micollins_delivery_app/pages/supportPage.dart'; // Make sure this is imported
import 'package:micollins_delivery_app/pages/profilePage.dart';
import 'package:micollins_delivery_app/pages/MapPage.dart';

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

// ignore: unused_element
final List<Widget> _pages = [
  MapPage(), // Home (Maps)
  OrdersPage(), // Deliveries
  UserChatScreen(), // Chat
  SupportPage(), // Support
  ProfilePage(), // Profile
];

class _FirstPageState extends State<FirstPage> {
  // Inside your FirstPage class
  @override
  Widget build(BuildContext context) {
    // Get the current selected index from the provider
    final selectedIndex = context.watch<IndexProvider>().selectedIndex;

    // Return the correct page based on the selected index
    Widget getPage() {
      switch (selectedIndex) {
        case 0:
          return const MapPage(); // Home tab
        case 1:
          return const OrdersPage(); // Deliveries tab
        case 2:
          return const SupportPage(); // Support tab - make sure this is SupportPage, not ChatScreen
        case 3:
          return const ProfilePage(); // Profile tab
        default:
          return const MapPage();
      }
    }

    return Scaffold(
      body: getPage(),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

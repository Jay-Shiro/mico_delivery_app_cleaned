import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:micollins_delivery_app/components/bottom_nav_bar.dart';
import 'package:micollins_delivery_app/pages/ordersPage.dart';
import 'package:micollins_delivery_app/pages/supportPage.dart';
import 'package:micollins_delivery_app/pages/profilePage.dart';
import 'package:micollins_delivery_app/pages/MapPage.dart';
import 'package:micollins_delivery_app/pages/user_chat_screen.dart';
import 'package:micollins_delivery_app/services/notification_service.dart';
import 'package:upgrader/upgrader.dart';

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

class _FirstPageState extends State<FirstPage> {
  late final StreamSubscription<String> _notificationSubscription;

  @override
  void initState() {
    super.initState();

    // Listen for notification taps
    _notificationSubscription =
        NotificationService().onNotificationTapped.listen((payload) {
      if (!mounted) return;

      final Map<String, dynamic> payloadData = json.decode(payload);

      if (payloadData['type'] == 'new_message') {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => UserChatScreen(
            deliveryId: payloadData['deliveryId'],
            senderId: payloadData['senderId'],
            receiverId: payloadData['receiverId'],
            userName: payloadData['userName'],
            userImage: payloadData['userImage'],
          ),
        ));
      } else if (payloadData['type'] == 'delivery_completed') {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const OrdersPage(),
        ));
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the Scaffold with ChangeNotifierProvider
    return UpgradeAlert(
      child: ChangeNotifierProvider(
        create: (context) => IndexProvider(),
        child: _FirstPageContent(),
      ),
    );
  }
}

// Create a separate widget for the content to use the provider
class _FirstPageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectedIndex = context.watch<IndexProvider>().selectedIndex;

    Widget getPage() {
      switch (selectedIndex) {
        case 0:
          return const MapPage();
        case 1:
          return const OrdersPage();
        case 2:
          return const SupportPage();
        case 3:
          return const ProfilePage();
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

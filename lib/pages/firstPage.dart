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
import 'package:shared_preferences/shared_preferences.dart';

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

    _checkAndShowSurgePrompt();

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
            recipientName: '',
          ),
        ));
      } else if (payloadData['type'] == 'delivery_completed') {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const OrdersPage(),
        ));
      }
    });
  }

  Future<void> _checkAndShowSurgePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSurgePromptDate = prefs.getString('lastSurgePromptDate');
    final today = DateTime.now().toIso8601String().split('T').first;

    if (lastSurgePromptDate != today && _isPeakHour()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => _buildSurgeDialog(prefs, today),
        );
      });
    }
  }

  Widget _buildSurgeDialog(SharedPreferences prefs, String today) {
    bool doNotShowAgain = false;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color.fromRGBO(0, 31, 62, 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.access_time,
                color: Color.fromRGBO(0, 31, 62, 1),
                size: 40,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Surge Period',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(0, 31, 62, 1),
              ),
            ),
            SizedBox(height: 15),
            Text(
              'It\'s currently a surge period. Making an order at a later time might help you get better prices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Checkbox(
                  value: doNotShowAgain,
                  onChanged: (value) {
                    doNotShowAgain = value ?? false;
                  },
                ),
                Expanded(
                  child: Text(
                    'Don\'t show this again today',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 25),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (doNotShowAgain) {
                    prefs.setString('lastSurgePromptDate', today);
                  }
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(0, 31, 62, 1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Example helper to check if it's peak time
  bool _isPeakHour() {
    final now = DateTime.now();
    final hour = now.hour;
    return (hour >= 7 && hour <= 10) || (hour >= 17 && hour <= 20);
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

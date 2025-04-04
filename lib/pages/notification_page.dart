import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:micollins_delivery_app/components/m_orange_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool isNotificationsEnabled = false;
  bool isUpdatesEnabled = false;
  bool isLoading = false;
  String? userId;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Get user ID from shared preferences
    final userString = prefs.getString('user');
    if (userString != null) {
      final userData = json.decode(userString);
      userId = userData['_id'];
      // Add more detailed debug information
      print('Debug - User data from SharedPreferences: $userData');
      print('Debug - User ID in Notification Settings: $userId');
    } else {
      print('Debug - No user data found in SharedPreferences');
    }

    setState(() {
      isNotificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      isUpdatesEnabled = prefs.getBool('updatesEnabled') ?? false;
    });
  }

  Future<void> _updateSettings() async {
    if (userId == null || userId!.isEmpty) {
      // Try to reload user data one more time
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString != null) {
        try {
          final userData = json.decode(userString);
          userId = userData['_id'];
          print('Debug - Retrieved user ID on second attempt: $userId');
        } catch (e) {
          print('Debug - Error parsing user data: $e');
        }
      }

      // If still null, show error
      if (userId == null || userId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "User ID not found. Cannot update settings. Please log in again."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', isNotificationsEnabled);
      await prefs.setBool('updatesEnabled', isUpdatesEnabled);

      // Manage notification permissions
      if (isNotificationsEnabled) {
        _enableNotifications();
      } else {
        _disableNotifications();
      }

      // Use form-urlencoded format instead of JSON
      final url =
          Uri.parse('https://deliveryapi-ten.vercel.app/users/$userId/update');

      // Create form data with only the notification settings
      final Map<String, String> formData = {
        'email_notification': isUpdatesEnabled ? "true" : "false",
        'push_notification': isNotificationsEnabled ? "true" : "false",
      };

      print('Debug - Form data: $formData');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'accept': 'application/json'
        },
        body: formData,
      );

      print('Update Notification Settings Response: ${response.body}');
      print('Update Notification Settings Status Code: ${response.statusCode}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.statusCode == 200
                ? "Notification settings updated successfully!"
                : "Failed to update notification settings.",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: response.statusCode == 200
              ? const Color.fromRGBO(0, 31, 62, 1)
              : Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _enableNotifications() async {
    final AndroidFlutterLocalNotificationsPlugin? androidSettings =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidSettings != null) {
      await androidSettings.requestNotificationsPermission();
    }
  }

  Future<void> _disableNotifications() async {
    await _notificationsPlugin
        .cancelAll(); // Cancels all scheduled notifications
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(
            color: Color.fromRGBO(0, 31, 62, 1),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromRGBO(0, 31, 62, 1),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),

                // Notification illustration
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 31, 62, 0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    size: 80,
                    color: Color.fromRGBO(0, 31, 62, 0.8),
                  ),
                ),

                const SizedBox(height: 24),

                // Description text
                const Text(
                  "Manage Your Notifications",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(0, 31, 62, 1),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Control how you receive notifications and updates about your deliveries",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // Settings cards
                _buildSettingsCard(
                  title: "Push Notifications",
                  description:
                      "Receive alerts on your device about delivery updates",
                  icon: Icons.notifications_none,
                  isEnabled: isNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      isNotificationsEnabled = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                _buildSettingsCard(
                  title: "Email & SMS Updates",
                  description:
                      "Get delivery status updates via email and text messages",
                  icon: Icons.email_outlined,
                  isEnabled: isUpdatesEnabled,
                  onChanged: (value) {
                    setState(() {
                      isUpdatesEnabled = value;
                    });
                  },
                ),

                const SizedBox(height: 40),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _updateSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(0, 31, 62, 1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor:
                          const Color.fromRGBO(0, 31, 62, 0.6),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 31, 62, 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color.fromRGBO(0, 31, 62, 1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(0, 31, 62, 1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color.fromRGBO(0, 31, 62, 1),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}

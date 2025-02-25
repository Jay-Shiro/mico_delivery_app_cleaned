import 'dart:convert';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isNotificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      isUpdatesEnabled = prefs.getBool('updatesEnabled') ?? false;
    });
  }

  Future<void> _updateSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', isNotificationsEnabled);
    await prefs.setBool('updatesEnabled', isUpdatesEnabled);

    final url = Uri.parse("YOUR_API_ENDPOINT"); // Replace with your API URL
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer YOUR_ACCESS_TOKEN",
      },
      body: jsonEncode({
        "notifications_enabled": isNotificationsEnabled,
        "updates_enabled": isUpdatesEnabled,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings updated successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update settings.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 90),
                const Text(
                  "Notification Settings",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    backgroundColor: const Color.fromRGBO(227, 223, 214, 1),
                    radius: 60,
                    child: const Icon(
                      Icons.notifications,
                      size: 50,
                      color: Color.fromRGBO(0, 31, 62, 1),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                settingsSection(),
                const SizedBox(height: 30),
                MOrangeButtons(
                  onTap: _updateSettings,
                  btnText: 'Save Settings',
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget settingsSection() {
    return Column(
      children: [
        SwitchListTile(
          activeTrackColor: Color.fromRGBO(126, 168, 82, 1),
          title: const Text("Enable Notifications"),
          subtitle: const Text("Turn on/off notifications on this device"),
          value: isNotificationsEnabled,
          onChanged: (bool value) {
            setState(() {
              isNotificationsEnabled = value;
            });
          },
        ),
        SwitchListTile(
          activeTrackColor: Color.fromRGBO(126, 168, 82, 1),
          title: const Text("Receive Updates via Email & Phone"),
          subtitle:
              const Text("Receive delivery updates through email and phone"),
          value: isUpdatesEnabled,
          onChanged: (bool value) {
            setState(() {
              isUpdatesEnabled = value;
            });
          },
        ),
      ],
    );
  }
}

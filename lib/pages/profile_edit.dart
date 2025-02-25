import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:micollins_delivery_app/components/m_orange_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  final TextEditingController nameEditController = TextEditingController();
  final TextEditingController phoneEditController = TextEditingController();
  final TextEditingController emailEditController = TextEditingController();

  String? firstName;
  String? lastName;
  String? userEmail;
  String? phone;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');

    if (userString != null) {
      final userData = json.decode(userString);
      setState(() {
        userEmail = userData['email'];
        firstName = userData['firstname'];
        lastName = userData['lastname'];
        phone = userData['phone'];
        nameEditController.text = '$firstName $lastName';
        emailEditController.text = userEmail ?? '';
        phoneEditController.text = phone ?? '';
      });
    }
  }

  Future<void> updateProfile() async {
    try {
      final url = Uri.parse("https://deliveryapi-plum.vercel.app/usersignup");
      final response = await http.post(
        url,
        body: jsonEncode({
          "firstname": nameEditController.text.split(' ')[0].trim(),
          "lastname": nameEditController.text.split(' ').length > 1
              ? nameEditController.text.split(' ')[1].trim()
              : "",
          "email": emailEditController.text.trim(),
          "phone": phoneEditController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.lightGreen,
              content: Text("Profile updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text("Failed to update profile")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.blueGrey,
            content: Text("An error occurred: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          // Fix: Wrap content in scroll view
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 90),
                const Text(
                  "Edit Profile",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    backgroundColor: const Color.fromRGBO(227, 223, 214, 1),
                    radius: 60,
                    child: Image.asset(
                      'assets/images/profilepic.png',
                      scale: 4.3,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    '${firstName ?? ''} ${lastName ?? ''}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Center(
                  child: Text(
                    userEmail ?? '',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w300),
                  ),
                ),
                const SizedBox(height: 20),
                settingsSection(),
                const SizedBox(height: 20),
                Center(
                  child: MOrangeButtons(
                      onTap: updateProfile, btnText: 'Update Profile'),
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
        customTextField(nameEditController, "Full Name"),
        const SizedBox(height: 10),
        customTextField(emailEditController, "Email"),
        const SizedBox(height: 10),
        customTextField(phoneEditController, "Phone"),
      ],
    );
  }

  Widget customTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color.fromRGBO(242, 241, 241, 1),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

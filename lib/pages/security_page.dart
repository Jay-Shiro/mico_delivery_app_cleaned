import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:micollins_delivery_app/components/m_orange_buttons.dart';
// ignore: unused_import
import 'package:shared_preferences/shared_preferences.dart';

class SecuritySettings extends StatefulWidget {
  const SecuritySettings({super.key});

  @override
  State<SecuritySettings> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<SecuritySettings> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isOldPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  Future<void> changePassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("New passwords do not match!"),
        ),
      );
      return;
    }

    try {
      final url =
          Uri.parse("https://deliveryapi-plum.vercel.app/change-password");
      final response = await http.post(
        url,
        body: jsonEncode({
          "old_password": oldPasswordController.text.trim(),
          "new_password": newPasswordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Password updated successfully!"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Failed to update password."),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blueGrey,
          content: Text("An error occurred: $e"),
        ),
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
                  "Security Settings",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                passwordSection(),
                const SizedBox(height: 20),
                Center(
                  child: MOrangeButtons(
                    onTap: changePassword,
                    btnText: 'Change Password',
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

  Widget passwordSection() {
    return Column(
      children: [
        passwordField(
            oldPasswordController, "Old Password", isOldPasswordVisible, () {
          setState(() {
            isOldPasswordVisible = !isOldPasswordVisible;
          });
        }),
        const SizedBox(height: 10),
        passwordField(
            newPasswordController, "New Password", isNewPasswordVisible, () {
          setState(() {
            isNewPasswordVisible = !isNewPasswordVisible;
          });
        }),
        const SizedBox(height: 10),
        passwordField(confirmPasswordController, "Confirm Password",
            isConfirmPasswordVisible, () {
          setState(() {
            isConfirmPasswordVisible = !isConfirmPasswordVisible;
          });
        }),
      ],
    );
  }

  Widget passwordField(TextEditingController controller, String hint,
      bool isVisible, VoidCallback toggleVisibility) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
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
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}

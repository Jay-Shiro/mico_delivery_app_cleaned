import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:micollins_delivery_app/components/m_orange_buttons.dart';
import 'package:micollins_delivery_app/pages/RecoverPassword.dart';
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
  bool isLoading = false;

  Future<void> changePassword() async {
    // Validation checks remain the same
    if (oldPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Please fill in all fields"),
        ),
      );
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("New passwords do not match!"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("User not found. Please log in again."),
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final userData = json.decode(userString);
      final userId = userData['_id'];

      // Use the correct endpoint with user ID
      final url = Uri.parse(
          "https://deliveryapi-ten.vercel.app/auth/change-password/user/$userId");

      // Create a multipart request
      var request = http.MultipartRequest('PUT', url);

      // Add form fields
      request.fields['old_password'] = oldPasswordController.text.trim();
      request.fields['new_password'] = newPasswordController.text.trim();

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Change Password Response: ${response.body}');
      print('Change Password Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromRGBO(0, 31, 62, 1),
            content: Text(
              "Password updated successfully!",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        // Clear fields after successful update
        oldPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
      } else {
        // Parse error message if available
        String errorMessage = "Failed to update password.";
        try {
          final responseData = json.decode(response.body);
          if (responseData['detail'] != null) {
            errorMessage = responseData['detail'];
          }
        } catch (e) {
          // Use default error message if parsing fails
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(errorMessage),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("An error occurred: $e"),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
          'SECURITY',
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

                // Security illustration
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 31, 62, 0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Color.fromRGBO(0, 31, 62, 0.8),
                  ),
                ),

                const SizedBox(height: 24),

                // Description text
                const Text(
                  "Change Your Password",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(0, 31, 62, 1),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Create a strong password that you don't use for other accounts",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // Password fields
                _buildPasswordField(
                  controller: oldPasswordController,
                  label: "Current Password",
                  isVisible: isOldPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      isOldPasswordVisible = !isOldPasswordVisible;
                    });
                  },
                ),

                const SizedBox(height: 16),

                _buildPasswordField(
                  controller: newPasswordController,
                  label: "New Password",
                  isVisible: isNewPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      isNewPasswordVisible = !isNewPasswordVisible;
                    });
                  },
                ),

                const SizedBox(height: 16),

                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: "Confirm New Password",
                  isVisible: isConfirmPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      isConfirmPasswordVisible = !isConfirmPasswordVisible;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecoverPassword(),
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color.fromRGBO(0, 31, 62, 1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Password requirements
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 31, 62, 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color.fromRGBO(0, 31, 62, 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Password Requirements:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(0, 31, 62, 1),
                        ),
                      ),
                      SizedBox(height: 8),
                      _PasswordRequirement(
                        text: "At least 8 characters",
                        icon: Icons.check_circle,
                      ),
                      SizedBox(height: 4),
                      _PasswordRequirement(
                        text: "Contains uppercase letters",
                        icon: Icons.check_circle,
                      ),
                      SizedBox(height: 4),
                      _PasswordRequirement(
                        text: "Contains numbers or symbols",
                        icon: Icons.check_circle,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Update button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : changePassword,
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
                            'Update Password',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback toggleVisibility,
  }) {
    return Container(
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
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Color.fromRGBO(0, 31, 62, 0.7),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: const Color.fromRGBO(0, 31, 62, 0.7),
            ),
            onPressed: toggleVisibility,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color.fromRGBO(0, 31, 62, 1),
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  final String text;
  final IconData icon;

  const _PasswordRequirement({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color.fromRGBO(0, 31, 62, 0.7),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

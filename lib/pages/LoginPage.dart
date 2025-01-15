import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:micollins_delivery_app/components/m_buttons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool _isObscured = true;
  bool _isLoading = false;

  InputDecoration customInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding:
          const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _signIn() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    const String apiUrl = "https://deliveryapi-plum.vercel.app/usersignin";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
        },
      );

      final data = json.decode(response.body);
      debugPrint('API Response: $data'); // Log the full response

      if (response.statusCode == 200 && data['status'] == 'success') {
        // Save all relevant data to SharedPreferences with null checks
        final prefs = await SharedPreferences.getInstance();
        final userData = data['user'] as Map<String, dynamic>;

        await prefs.setString('user', json.encode(userData));
        await prefs.setString('email', userData['email']?.toString() ?? '');
        await prefs.setString('name', userData['name']?.toString() ?? '');
        await prefs.setString('phone', userData['phone']?.toString() ?? '');

        // Log the saved data
        debugPrint('Saved User Data:');
        debugPrint('Email: ${userData['email']}');
        debugPrint('Name: ${userData['name']}');
        debugPrint('Phone: ${userData['phone']}');
        debugPrint('Full User Object: ${json.encode(userData)}');

        Fluttertoast.showToast(
          msg: data['message'] ?? 'Sign-in successful!',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Save user data to shared preferences
        await prefs.setString('user', json.encode(data['user']));

        // Navigate to the next screen
        Navigator.of(context).pushReplacementNamed('/firstpage');
      } else {
        Fluttertoast.showToast(
          msg: data['detail'] ?? 'Incorrect email or password',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      Fluttertoast.showToast(
        msg: 'An error occurred. Please try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  // Logo and App Name
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/micollins_icon.png',
                          height: 40,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'MICO',
                          style: TextStyle(
                            color: const Color.fromRGBO(40, 115, 115, 1),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Page Title
                  Center(
                    child: Text(
                      'Sign into Your Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromRGBO(40, 115, 115, 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email Address
                  const Text('Email Address'),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: emailController,
                    decoration:
                        customInputDecoration('Enter your email address'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),

                  // Password
                  const Text('Password'),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _isObscured,
                    decoration:
                        customInputDecoration('Enter your password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscured ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed('/resetpasspage');
                      },
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: const Color.fromRGBO(40, 115, 115, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Sign In Button
                  Center(
                    child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              const Color.fromRGBO(40, 115, 115, 1),
                            ),
                          )
                        : MButtons(
                            btnText: 'Sign In',
                            onTap: _signIn,
                          ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

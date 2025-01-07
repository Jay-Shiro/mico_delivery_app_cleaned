import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:micollins_delivery_app/components/m_buttons.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool? isChecked = false;
  bool _isObscured = true;
  bool _isLoading = false; // Loading state

  final formKey = GlobalKey<FormState>();

  InputDecoration customInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding:
          const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _signup() async {
    if (!formKey.currentState!.validate() || isChecked == false) {
      Fluttertoast.showToast(
        msg: 'Please complete all fields and agree to the terms.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true; // Start showing the loading spinner
    });

    const String apiUrl =
        "https://deliveryapi-plum.vercel.app/usersignup"; // Replace with your actual API URL.

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'firstname': firstNameController.text.trim(),
          'lastname': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        Fluttertoast.showToast(
          msg: data['message'] ?? 'Signup successful!',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        // Navigate to the login page or another screen
        Navigator.of(context).pushReplacementNamed('/loginpage');
      } else {
        Fluttertoast.showToast(
          msg: data['detail'] ?? 'Signup failed.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An error occurred: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide the loading spinner
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  // Logo and App Name
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/micollins_icon.png',
                          height: 50,
                        ),
                        Text(
                          'MICO',
                          style: TextStyle(
                            color: const Color.fromRGBO(40, 115, 115, 1),
                            fontSize: 20,
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
                      'Create an Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromRGBO(40, 115, 115, 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // First Name
                  const Text('First Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: firstNameController,
                    decoration: customInputDecoration('Enter your first name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),

                  // Last Name
                  const Text('Last Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: lastNameController,
                    decoration: customInputDecoration('Enter your last name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),

                  // Email Address
                  const Text('Email Address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    decoration:
                        customInputDecoration('Enter your email address'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),

                  // Phone Number
                  const Text('Phone Number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneController,
                    decoration:
                        customInputDecoration('Enter your phone number'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),

                  // Password
                  const Text('Password'),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 20),

                  // Privacy Policy
                  Row(
                    children: [
                      Checkbox(
                        activeColor: const Color.fromRGBO(40, 115, 115, 1),
                        value: isChecked,
                        onChanged: (newBool) {
                          setState(() {
                            isChecked = newBool;
                          });
                        },
                      ),
                      Flexible(
                        child: Text(
                          'I have read and agreed to the User Agreement and Privacy Policy',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[800]),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Create Account Button
                  Center(
                    child: _isLoading
                        ? CircularProgressIndicator() // Show progress indicator
                        : MButtons(
                            btnText: 'Create Account',
                            onTap: _signup,
                          ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

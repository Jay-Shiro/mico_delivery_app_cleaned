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
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: Colors.grey[200]!, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: Color.fromRGBO(0, 31, 62, 1), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: Colors.red, width: 1.5),
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
        "https://deliveryapi-ten.vercel.app/usersignup"; // Replace with your actual API URL.

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'firstname': firstNameController.text.trim(),
          'lastname': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'phone': phoneController.text.trim(),
          'email_notification': 'true', // Set to true by default
          'push_notification': 'true', // Set to true by default
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
                  const SizedBox(height: 80),

                  // Logo and App Name
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Image.asset(
                                'assets/images/logo_mico_resized.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Page Title
                  Center(
                    child: Text(
                      'Create an Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromRGBO(0, 31, 62, 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Center(
                    child: Text(
                      'Please fill in the details to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const SizedBox(height: 20),

                  // Page Title
                  Center(
                    child: Text(
                      'Create an Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromRGBO(0, 31, 62, 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // First Name
                  const Text(
                    'First Name',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color.fromRGBO(0, 31, 62, 1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: firstNameController,
                    decoration: customInputDecoration('Enter your first name'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'First name is required'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Last Name
                  const Text('Last Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color.fromRGBO(0, 31, 62, 1),
                      )),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: lastNameController,
                    decoration: customInputDecoration('Enter your last name'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Last name is required'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Email Address
                  const Text('Email Address',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color.fromRGBO(0, 31, 62, 1),
                      )),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        customInputDecoration('Enter your email address')
                            .copyWith(
                      prefixIcon: Icon(Icons.email_outlined,
                          color: Colors.grey[500], size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Phone Number
                  const Text('Phone Number',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color.fromRGBO(0, 31, 62, 1),
                      )),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: customInputDecoration('Enter your phone number')
                        .copyWith(
                      prefixIcon: Icon(Icons.phone_outlined,
                          color: Colors.grey[500], size: 20),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Phone number is required'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Password
                  const Text('Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color.fromRGBO(0, 31, 62, 1),
                      )),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _isObscured,
                    decoration:
                        customInputDecoration('Enter your password').copyWith(
                      prefixIcon: Icon(Icons.lock_outline,
                          color: Colors.grey[500], size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscured ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),

                  // Privacy Policy
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Transform.scale(
                          scale: 1.1,
                          child: Checkbox(
                            activeColor: const Color.fromRGBO(0, 31, 62, 1),
                            value: isChecked,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (newBool) {
                              setState(() {
                                isChecked = newBool;
                              });
                            },
                          ),
                        ),
                        Flexible(
                          child: Text(
                            'I have read and agreed to the User Agreement and Privacy Policy',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Create Account Button
                  Center(
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: const Color.fromRGBO(0, 31, 62, 1),
                          )
                        : Container(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(0, 31, 62, 1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 25),

                  // Already have an account
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .pushReplacementNamed('/loginpage');
                          },
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: const Color.fromRGBO(0, 31, 62, 1),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

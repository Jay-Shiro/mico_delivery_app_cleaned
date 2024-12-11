// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/components/alt_sign_in_tile.dart';
import 'package:micollins_delivery_app/components/m_buttons.dart';
import 'package:micollins_delivery_app/components/emailTextField.dart';
import 'package:micollins_delivery_app/services/auth_service.dart';

class Loginpage extends StatefulWidget {
  Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  bool? isChecked = false;

  bool _isObscured = true;

  final email_formKey = GlobalKey<FormState>();

  final pass_formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 255, 254),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 110),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/micollins_icon.png',
                          height: 100,
                          scale: 2.5,
                        ),
                        Text('MICO',
                            style: TextStyle(
                              color: const Color.fromRGBO(40, 115, 115, 1),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ))
                      ],
                    ),
                  ),
                  //sign in prompt
                  Text(
                    'Sign into your account',
                    style: TextStyle(
                      color: const Color.fromRGBO(40, 115, 115, 1),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  //email textfield
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Text(
                          'Email Address',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  EmailTextField(
                    form_Key: email_formKey,
                    controller: emailController,
                    hintText: 'Enter your email address',
                    obscureText: false,
                  ),

                  const SizedBox(height: 20),

                  //password textfield
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      children: [
                        Text(
                          'Password',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Form(
                      key: pass_formKey,
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          return null;
                        },
                        controller: passwordController,
                        obscureText: _isObscured,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _isObscured = !_isObscured;
                                });
                              },
                              icon: _isObscured
                                  ? const Icon(Icons.visibility_off)
                                  : const Icon(Icons.visibility)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                            ),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  //forgot password?
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed('/resetpasspage');
                          },
                          child: Text(
                            'Forgot password??',
                            style: TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  //create account
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Don't have an account?"),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed('/signuppage');
                          },
                          child: Text(
                            'Create an Account',
                            style: TextStyle(
                              color: const Color.fromRGBO(40, 115, 115, 1),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  //sign in button
                  MButtons(
                    btnText: 'Sign In',
                    onTap: () async {
                      if (email_formKey.currentState!.validate() &&
                          pass_formKey.currentState!.validate()) {
                        await AuthService().signIn(
                          email: emailController.text,
                          password: passwordController.text,
                          context: context,
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('Or continue with'),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  //google + apple sign in options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AltSignInTile(imagePath: 'assets/images/google_icon.png'),
                      const SizedBox(width: 10),
                      AltSignInTile(imagePath: 'assets/images/apple_icon.png'),
                    ],
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

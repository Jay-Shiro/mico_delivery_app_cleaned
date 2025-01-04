import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/components/m_buttons.dart';
import 'package:micollins_delivery_app/components/emailTextField.dart';

class RecoverPassword extends StatelessWidget {
  RecoverPassword({super.key});

  final resetEmailController = TextEditingController();

  final formKey = GlobalKey<FormState>();

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
                    'Reset your Password',
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
                    form_Key: formKey,
                    controller: resetEmailController,
                    hintText: 'Enter email to get a password reset email',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),

                  //forgot password?
                  const SizedBox(height: 20),

                  const SizedBox(height: 40),

                  //sign in button
                  MButtons(
                    btnText: 'Send Link',
                    onTap: () async {},
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

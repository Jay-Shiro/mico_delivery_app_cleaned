import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:micollins_delivery_app/components/nameFields.dart';
import 'package:micollins_delivery_app/components/alt_sign_in_tile.dart';
import 'package:micollins_delivery_app/components/emailTextField.dart';
import 'package:micollins_delivery_app/components/m_buttons.dart';
import 'package:micollins_delivery_app/services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  final nameController = TextEditingController();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  bool? isChecked = false;

  bool _isObscured = true;

  final name_formKey = GlobalKey<FormState>();

  final email_formKey = GlobalKey<FormState>();

  final pass_formKey = GlobalKey<FormState>();

  var eMessage;

  @override
  Widget build(BuildContext context) {
    final userName = db.collection("users");
    final name = <String, dynamic>{'name': nameController.text};

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
                    'Create an Account',
                    style: TextStyle(
                      color: const Color.fromRGBO(40, 115, 115, 1),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  //name textfield
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Text(
                          'First name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  nameFields(
                    form_Key: name_formKey,
                    controller: nameController,
                    hintText: 'Enter your Name',
                    obscureText: false,
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
                            return 'Please create a password';
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
                            hintStyle: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  //privacy policy
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: const Color.fromRGBO(40, 115, 115, 1),
                          value: isChecked,
                          onChanged: (newBool) {
                            setState(() {
                              isChecked = newBool;
                            });
                          },
                          checkColor: Colors.white,
                        ),
                        Flexible(
                          child: Text(
                              'I have read and agreed to the User Agreement  and Privacy Policy'),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  //create account button
                  MButtons(
                    btnText: 'Create Account',
                    onTap: () async {
                      if (name_formKey.currentState!.validate() &&
                          email_formKey.currentState!.validate() &&
                          pass_formKey.currentState!.validate() &&
                          isChecked == true) {
                        await AuthService().signUp(
                          email: emailController.text,
                          password: passwordController.text,
                          context: context,
                        );
                        userName.doc('UN').set(name);
                      } else {
                        eMessage =
                            'Please tick box to agree to user agreement and privacy policy';
                      }
                      Fluttertoast.showToast(
                        msg: eMessage,
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.SNACKBAR,
                        backgroundColor: Colors.black54,
                        textColor: Colors.white,
                        fontSize: 14,
                      );
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

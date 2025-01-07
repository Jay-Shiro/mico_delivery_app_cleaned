import 'package:flutter/material.dart';

class EmailTextField extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;
  final form_Key;
  EmailTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.form_Key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Form(
        key: form_Key,
        child: TextFormField(
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an email address';
            }
            return null;
          },
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
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
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}

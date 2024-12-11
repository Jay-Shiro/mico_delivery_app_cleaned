import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthService {
  var message;

  Future<void> signUp({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Display a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: const Color.fromRGBO(40, 115, 115, 1),
          ),
        ),
      );

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Navigate to the homepage after a slight delay
      await Future.delayed(const Duration(seconds: 1));
      Navigator.of(context).pushReplacementNamed('/loginpage');
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Dismiss the loading indicator
      print('FirebaseAuthException: ${e.code} - ${e.message}'); // Log the error

      switch (e.code) {
        case 'email-already-in-use':
          message = 'The email address is already in use by another account.';
          break;
        case 'weak-password':
          message = 'Password should be Alphanumeric and at least 6 characters';
          break;
        default:
          message =
              'An error occurred during authentication. Please try again later.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14,
      );
      // ignore: unused_catch_clause
    } on SocketException catch (e) {
      Navigator.pop(context); // Dismiss the loading indicator
      Fluttertoast.showToast(
        msg: 'Network error. Please check your internet connection.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14,
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Display a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: const Color.fromRGBO(40, 115, 115, 1),
          ),
        ),
      );

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Navigate to the homepage after a slight delay
      await Future.delayed(const Duration(seconds: 1));
      Navigator.of(context).pushReplacementNamed('/firstpage');
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Dismiss the loading indicator
      print('FirebaseAuthException: ${e.code} - ${e.message}'); // Log the error

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'invalid-credential':
          message = 'Wrong email or password provided for that user.';
          break;
        default:
          message =
              'An error occurred during authentication. Please try again later.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14,
      );
      // ignore: unused_catch_clause
    } on SocketException catch (e) {
      Navigator.pop(context); // Dismiss the loading indicator
      Fluttertoast.showToast(
        msg: 'Network error. Please check your internet connection.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14,
      );
    }
  }

  Future<void> sendPasswordResetLink(
      {required email, required BuildContext context}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await Future.delayed(const Duration(seconds: 1));
      Navigator.of(context).pushReplacementNamed('/loginpage');
    } catch (e) {
      print(e.toString());
    }
  }
}

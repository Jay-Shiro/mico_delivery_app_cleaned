import 'package:flutter/material.dart';

class MButtonsLoading extends StatelessWidget {
  final String btnText;

  final Function()? onTap;

  final bool isLoading;

  const MButtonsLoading({
    super.key,
    required this.onTap,
    required this.btnText,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 50),
        decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 31, 62, 1),
            borderRadius: BorderRadius.circular(30)),
        child: Center(
          child: Text(
            btnText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

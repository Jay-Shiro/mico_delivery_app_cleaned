import 'package:flutter/material.dart';

class AltSignInTile extends StatelessWidget {
  final String imagePath;

  const AltSignInTile({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(18)),
      child: Image.asset(
        imagePath,
        height: 30,
      ),
    );
  }
}

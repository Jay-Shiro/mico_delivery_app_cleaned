import 'package:flutter/material.dart';

class ChatBubbleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double width = size.width;
    double height = size.height;
    double radius = 8.0; // Rounded corners

    // Main bubble with rounded corners
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            0, 0, width, height - 10), // Adjust height for pointer space
        Radius.circular(radius),
      ),
    );

    // Triangle pointer (bottom-right)
    double triangleBase = 12; // Width of triangle
    // ignore: unused_local_variable
    double triangleHeight = 10; // Height of triangle
    double triangleX = width - 20; // Adjust pointer position
    double triangleY = height - 10; // Adjust to align with bottom

    path.moveTo(triangleX, triangleY); // Start of triangle
    path.lineTo(triangleX + triangleBase / 2, height); // Bottom tip
    path.lineTo(triangleX + triangleBase, triangleY); // End of triangle
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

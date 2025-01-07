import 'package:flutter/material.dart';

class ToggleBar extends StatefulWidget {
  final Function(int) onStatusChanged;

  const ToggleBar({Key? key, required this.onStatusChanged}) : super(key: key);

  @override
  State<ToggleBar> createState() => _ToggleBarState();
}

class _ToggleBarState extends State<ToggleBar> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    List<Color> mColors = [
      Colors.white,
      Color.fromRGBO(0, 70, 67, 1),
    ];

    List<String> statusLabels = ['All', 'Pending', 'On Route', 'Complete'];

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceEvenly, // Distribute buttons evenly
      children: List.generate(
        statusLabels.length,
        (index) => GestureDetector(
          onTap: () => _onToggleTap(index),
          child: Container(
            width: index == 0 ? 44 : 87,
            height: 36,
            decoration: BoxDecoration(
              color: mColors[index == selectedIndex ? 1 : 0],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color.fromRGBO(0, 70, 67, 1)),
            ),
            child: Center(
              child: Text(
                statusLabels[index],
                style: TextStyle(
                  color: mColors[index == selectedIndex ? 0 : 1],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onToggleTap(int index) {
    setState(() {
      selectedIndex = index;
    });
    widget.onStatusChanged(index);
  }
}

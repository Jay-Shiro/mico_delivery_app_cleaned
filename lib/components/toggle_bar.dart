import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class ToggleBar extends StatefulWidget {
  final Function(int) onStatusChanged;

  const ToggleBar({super.key, required this.onStatusChanged});

  @override
  State<ToggleBar> createState() => _ToggleBarState();
}

class _ToggleBarState extends State<ToggleBar> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    List<Color> mColors = [
      Colors.white,
      Color.fromRGBO(0, 31, 62, 1),
    ];

    List<String> statusLabels = ['All', 'In Transit', 'Complete'];
    List<IconData> statusIcons = [
      EvaIcons.gridOutline,
      EvaIcons.carOutline,
      EvaIcons.checkmarkCircle2Outline,
    ];

    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          statusLabels.length,
          (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _onToggleTap(index),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: mColors[index == selectedIndex ? 1 : 0],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color.fromRGBO(0, 31, 62, 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        statusIcons[index],
                        size: 16,
                        color: mColors[index == selectedIndex ? 0 : 1],
                      ),
                      SizedBox(width: 4),
                      Text(
                        statusLabels[index],
                        style: TextStyle(
                          color: mColors[index == selectedIndex ? 0 : 1],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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

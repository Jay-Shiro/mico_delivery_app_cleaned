import 'package:flutter/material.dart';

class MicoListTiles extends StatelessWidget {
  final Image leading;
  final Text title;
  final Icon trailing;
  const MicoListTiles({
    super.key,
    required this.leading,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(242, 241, 241, 1),
        borderRadius: BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      height: 52,
      width: 351,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: ListTile(
            leading: leading,
            title: title,
            trailing: trailing,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// ignore: must_be_immutable
class ActivityTile extends StatelessWidget {
  final String ActivityLoc;
  Function(BuildContext)? deleteFunction;

  ActivityTile({
    super.key,
    required this.ActivityLoc,
    required this.deleteFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, right: 25, top: 25, bottom: 0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: StretchMotion(),
          children: [
            SlidableAction(
              onPressed: deleteFunction,
              icon: Icons.delete,
              backgroundColor: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Container(
          // ignore: sort_child_properties_last
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.all(24),
          // ignore: sort_child_properties_last
          child: Row(
            children: [
              //checkbox
              Icon(
                Icons.location_on,
              ),

              //task name
              Text(
                ActivityLoc,
                style: TextStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

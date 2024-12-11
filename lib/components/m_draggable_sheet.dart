import 'package:flutter/material.dart';

class MDraggableSheet extends StatefulWidget {
  const MDraggableSheet({super.key});

  @override
  State<MDraggableSheet> createState() => _MDraggableSheetState();
}

class _MDraggableSheetState extends State<MDraggableSheet> {
  final _sheet = GlobalKey();
  final _controller = DraggableScrollableController();
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      key: _sheet,
      initialChildSize: 0.3,
      maxChildSize: 0.5,
      minChildSize: 0.2,
      expand: true,
      snap: true,
      snapSizes: const [0.5],
      controller: _controller,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              const SliverToBoxAdapter(
                child: Text('Title'),
              ),
              SliverList.list(
                children: const [
                  Text('Content'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

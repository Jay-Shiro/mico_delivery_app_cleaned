import 'package:flutter/material.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({
    super.key,
    required this.startPoint,
    required this.endPoint,
    required this.distance,
    required this.price,
  });
  final String? startPoint;
  final String? endPoint;
  final String? distance;
  final String? price;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).maybePop();
          },
          child: Image.asset(
            'assets/images/back.png',
            scale: 24,
          ),
        ),
        backgroundColor: Colors.white,
        title: Text(
          'ORDER',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: SafeArea(child: Container()),
      ),
    );
  }
}

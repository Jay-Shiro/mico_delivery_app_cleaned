import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/components/toggle_bar.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';
import 'package:provider/provider.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IndexProvider>(context);

    return SingleChildScrollView(
      child: SafeArea(
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.9,
          width: MediaQuery.sizeOf(context).width,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: orderUi(),
            ),
          ),
        ),
      ),
    );
  }
}

Widget orderUi() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 74),
      orderSearchbar(),
      const SizedBox(height: 32),
      ToggleBar()
    ],
  );
}

Widget orderSearchbar() {
  return Container(
    child: Column(
      children: [
        Text(
          'MY ORDER',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter receipt number or location',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: Colors.black,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.search,
              ),
              iconSize: 22,
            ),
            suffixIconColor: Colors.grey,
          ),
        ),
      ],
    ),
  );
}

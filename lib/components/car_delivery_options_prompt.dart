import 'package:flutter/material.dart';

class CarDeliveryOptionsPrompt extends StatelessWidget {
  final String? amountFormatted;

  const CarDeliveryOptionsPrompt({
    Key? key,
    required this.amountFormatted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const Divider(thickness: 0.8, color: Colors.grey),
          const SizedBox(height: 10),
          _buildDeliveryOption(
            title: "Car Delivery",
            price: amountFormatted,
          ),
          const Divider(thickness: 0.8, color: Colors.grey),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String title,
    required String? price,
  }) {
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color.fromRGBO(0, 70, 67, 0.24),
        ),
        height: 80,
        width: 60,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset('assets/images/car.png', scale: 2),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(price ?? ' ', style: const TextStyle(fontSize: 16)),
    );
  }
}

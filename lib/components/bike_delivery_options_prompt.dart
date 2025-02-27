import 'package:flutter/material.dart';

class bikeDeliveryOptionsPrompt extends StatelessWidget {
  final bool isStandardSelected;
  final bool isExpressSelected;
  final bool is25Selected;
  final bool is50Selected;
  final bool is75Selected;
  final bool is100Selected;
  final Function(bool?) onStandardSelected;
  final Function(bool?) onExpressSelected;
  final Function(bool?) on25Selected;
  final Function(bool?) on50Selected;
  final Function(bool?) on75Selected;
  final Function(bool?) on100Selected;
  final String? standardFormatted;
  final String? expressFormatted;
  final String? size25Formatted;
  final String? size50Formatted;
  final String? size75Formatted;
  final String? size100Formatted;

  const bikeDeliveryOptionsPrompt({
    Key? key,
    required this.isStandardSelected,
    required this.isExpressSelected,
    required this.is25Selected,
    required this.is50Selected,
    required this.is75Selected,
    required this.is100Selected,
    required this.onStandardSelected,
    required this.onExpressSelected,
    required this.on25Selected,
    required this.on50Selected,
    required this.on75Selected,
    required this.on100Selected,
    required this.standardFormatted,
    required this.expressFormatted,
    required this.size25Formatted,
    required this.size50Formatted,
    required this.size75Formatted,
    required this.size100Formatted,
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
            title: "Same-Day Delivery",
            price: standardFormatted,
            value: isStandardSelected,
            onChanged: onStandardSelected,
          ),
          const SizedBox(height: 20),
          _buildDeliveryOption(
            title: "Express Delivery",
            price: expressFormatted,
            value: isExpressSelected,
            onChanged: onExpressSelected,
          ),
          const Divider(thickness: 0.8, color: Colors.grey),
          const SizedBox(height: 10),
          const SizedBox(
            width: 340,
            child: Text(
              'Our delivery boxes are 3.05 cubic feet, and thus we charge on the space your item takes. Select an option from below',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _buildSizeOption(
            title: 'Quarter the Box & Below',
            price: size25Formatted,
            value: is25Selected,
            onChanged: on25Selected,
          ),
          _buildSizeOption(
            title: 'Half the Box & Below',
            price: size50Formatted,
            value: is50Selected,
            onChanged: on50Selected,
          ),
          _buildSizeOption(
            title: '3 quarter the Box & Below',
            price: size75Formatted,
            value: is75Selected,
            onChanged: on75Selected,
          ),
          _buildSizeOption(
            title: 'Full Box & Below',
            price: size100Formatted,
            value: is100Selected,
            onChanged: on100Selected,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String title,
    required String? price,
    required bool value,
    required Function(bool?) onChanged,
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
          child: Image.asset('assets/images/bike.png', scale: 2),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(price ?? '', style: const TextStyle(fontSize: 16)),
      trailing: Checkbox(
        activeColor: const Color.fromRGBO(0, 31, 62, 1),
        value: value,
        onChanged: onChanged,
        checkColor: Colors.white,
      ),
    );
  }

  Widget _buildSizeOption({
    required String title,
    required String? price,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(price ?? 'Free'),
      trailing: Checkbox(
        activeColor: const Color.fromRGBO(0, 31, 62, 1),
        value: value,
        onChanged: onChanged,
        checkColor: Colors.white,
      ),
    );
  }
}

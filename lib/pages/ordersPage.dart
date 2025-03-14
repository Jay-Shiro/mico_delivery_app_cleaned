import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:micollins_delivery_app/components/toggle_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String currentStatus = 'all'; // Track current filter status

  // Sample order data
  final List<Map<String, String>> orders = [
    {'number': '#MC123456789', 'status': 'pending'},
    {'number': '#MC987654321', 'status': 'in_transit'},
    {'number': '#MC456789123', 'status': 'completed'},
  ];

  // Get filtered orders based on status
  List<Map<String, String>> getFilteredOrders() {
    if (currentStatus == 'all') return orders;
    return orders.where((order) => order['status'] == currentStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAFAFA),
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                18, 0, 18, MediaQuery.of(context).padding.bottom),
            child: Column(
              children: [
                const SizedBox(height: 74),

                orderSearchbar(),
                const SizedBox(height: 40),

                // Add ToggleBar
                ToggleBar(onStatusChanged: (status) {
                  setState(() {
                    switch (status) {
                      case 0:
                        currentStatus = 'all';
                        break;
                      case 1:
                        currentStatus = 'pending';
                        break;
                      case 2:
                        currentStatus = 'in_transit';
                        break;
                      case 3:
                        currentStatus = 'completed';
                        break;
                    }
                  });
                }),
                const SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: 20),
                    itemCount: getFilteredOrders().length,
                    itemBuilder: (context, index) {
                      final order = getFilteredOrders()[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: orderCard(order['number']!, order['status']!),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget orderCard(String trackingNumber, String status) {
    return FutureBuilder(
      future: _getPaymentStatus(),
      builder: (context, AsyncSnapshot<Map<String, bool>> snapshot) {
        bool isCashorTransfer = snapshot.data?['isCashorTransfer'] ?? false;
        bool isOnlinePayment = snapshot.data?['isOnlinePayment'] ?? false;

        String actionButtonText = 'Unknown';
        VoidCallback? actionButtonOnPressed;

        if (status == 'completed') {
          actionButtonText = 'View E-receipt';
          actionButtonOnPressed =
              () => _showReceiptPrompt(context, trackingNumber);
        } else if (isOnlinePayment) {
          actionButtonText = 'Pay Online';
          actionButtonOnPressed = () {};
        } else if (isCashorTransfer) {
          actionButtonText = 'Waiting for Rider';
        } else {
          actionButtonText = 'Pay Online';
          actionButtonOnPressed = () {};
        }

        bool canTrack = status == 'in_transit';

        return Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Tracking Number',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          trackingNumber,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(color: Colors.grey[300]),
                SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: actionButtonOnPressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color.fromRGBO(0, 31, 62, 1),
                          side: BorderSide(color: Color.fromRGBO(0, 31, 62, 1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(actionButtonText),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            canTrack ? () => _showTrackingSheet(context) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(0, 31, 62, 1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Track'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to display receipt prompt
  void _showReceiptPrompt(BuildContext context, String trackingNumber) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'E-Receipt',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12.0),
              Text('Receipt details for $trackingNumber'),
              const SizedBox(height: 10),
              const Text('Amount Paid: \₦50'),
              const Text('Payment Method: Online'),
              const Text('Delivery Date: 12th March 2025'),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        );
      },
    );
  }

  // Function to show tracking bottom sheet
  void _showTrackingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            height: 380,
            child: Column(
              children: [
                Text(
                  "Rider on the way",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        AssetImage('assets/images/profilepic.png')),
                SizedBox(height: 10),
                Text("John Doe",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text("+234 812 345 6789",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                SizedBox(height: 20),
                LinearProgressIndicator(
                  value: 0.6,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromRGBO(0, 31, 62, 1),
                  ),
                ), // Progress simulation
                SizedBox(height: 10),
                Text("Estimated time: 10 minutes"),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Call rider
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          Color.fromRGBO(0, 31, 62, 1),
                        ),
                      ),
                      icon: Icon(Icons.call, color: Colors.white),
                      label: Text(
                        "Call",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Chat with rider
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Color.fromRGBO(0, 31, 62, 1)),
                      ),
                      icon: Icon(Icons.chat, color: Colors.white),
                      label: Text(
                        "Chat",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Color.fromRGBO(0, 31, 62, 1)),
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget orderSearchbar() {
    return Container(
      child: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          Text(
            'MY ORDER',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),
          TextField(
            autofocus: false,
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
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.black),
              ),
              suffixIcon: IconButton(
                onPressed: () {},
                icon: Icon(Icons.search),
                iconSize: 22,
              ),
              suffixIconColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, bool>> _getPaymentStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'isCashorTransfer': prefs.getBool('isCashorTransfer') ?? false,
      'isOnlinePayment': prefs.getBool('isOnlinePayment') ?? false,
    };
  }
}

// Utility function to get status color
Color _getStatusColor(String status) {
  return {
        'pending': Color.fromRGBO(184, 194, 43, 1),
        'in_transit': Color.fromRGBO(0, 31, 62, 1),
        'completed': Color.fromRGBO(76, 175, 80, 1),
      }[status] ??
      Colors.grey;
}

// Utility function to get status text
String _getStatusText(String status) {
  return {
        'pending': 'Pending',
        'in_transit': 'In Transit',
        'completed': 'Completed',
      }[status] ??
      'Unknown';
}

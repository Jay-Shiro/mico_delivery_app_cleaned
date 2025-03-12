import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/components/toggle_bar.dart';
import 'package:flutter/services.dart';
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
    {
      'number': '#MC123456789',
      'status': 'pending',
    },
    {
      'number': '#MC987654321',
      'status': 'in_transit',
    },
    {
      'number': '#MC456789123',
      'status': 'completed',
    },
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
                const SizedBox(height: 32),
                ToggleBar(
                  onStatusChanged: (status) {
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
                  },
                ),
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

  Widget orderUi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 74),
        orderSearchbar(),
        const SizedBox(height: 32),
        ToggleBar(
          onStatusChanged: (status) {
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
          },
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
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
    );
  }

  Widget orderCard(String trackingNumber, String status) {
    return FutureBuilder(
      future: _getPaymentStatus(),
      builder: (context, AsyncSnapshot<Map<String, bool>> snapshot) {
        bool isCashorTransfer = snapshot.data?['isCashorTransfer'] ?? false;
        bool isOnlinePayment = snapshot.data?['isOnlinePayment'] ?? false;

        // Determine the correct button text based on status and payment method
        String actionButtonText = 'Unknown';
        if (status == 'completed') {
          actionButtonText = 'View E-receipt';
        } else if (isOnlinePayment) {
          actionButtonText = 'Pay Online';
        } else if (isCashorTransfer) {
          actionButtonText = 'Waiting for Rider';
        } else {
          actionButtonText = 'Pay Online'; // Default case
        }

        Color statusColor = {
              'pending': Color.fromRGBO(184, 194, 43, 1),
              'in_transit': Color.fromRGBO(0, 31, 62, 1),
              'completed': Color.fromRGBO(76, 175, 80, 1),
            }[status] ??
            Colors.grey;

        String statusText = {
              'pending': 'Pending',
              'in_transit': 'In Transit',
              'completed': 'Completed',
            }[status] ??
            'Unknown';

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
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          trackingNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
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
                        onPressed: () {
                          // Add functionality for Pay Online, Waiting for Rider, or E-receipt
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color.fromRGBO(0, 31, 62, 1),
                          side: BorderSide(
                            color: Color.fromRGBO(0, 31, 62, 1),
                          ),
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
                        onPressed: () {
                          // Add functionality for tracking the order
                        },
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

// Function to retrieve payment status from SharedPreferences
  Future<Map<String, bool>> _getPaymentStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isCashorTransfer = prefs.getBool('isCashorTransfer') ?? false;
    bool isOnlinePayment = prefs.getBool('isOnlinePayment') ?? false;

    return {
      'isCashorTransfer': isCashorTransfer,
      'isOnlinePayment': isOnlinePayment,
    };
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
}

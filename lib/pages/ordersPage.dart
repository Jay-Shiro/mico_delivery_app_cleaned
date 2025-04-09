import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:micollins_delivery_app/components/toggle_bar.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';
import 'package:micollins_delivery_app/pages/user_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String currentStatus = 'all';
  List<dynamic> deliveries = [];
  bool isLoading = true;
  String? userEmail;
  String? userId;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) {
      fetchDeliveries();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get userId directly
      String? loadedUserId = prefs.getString('user_id');
      debugPrint('Direct user_id from SharedPreferences: $loadedUserId');

      // If not found, try to extract from user object
      if (loadedUserId == null || loadedUserId.isEmpty) {
        final userString = prefs.getString('user');
        debugPrint(
            'User string from SharedPreferences: ${userString != null ? "Found" : "Not found"}');

        if (userString != null) {
          try {
            final userData = json.decode(userString);
            loadedUserId = userData['_id'];
            debugPrint('Extracted user_id from user object: $loadedUserId');
          } catch (e) {
            debugPrint('Error parsing user JSON: $e');
          }
        }
      }

      // Also get email for completeness
      final loadedEmail = prefs.getString('email');

      setState(() {
        userId = loadedUserId;
        userEmail = loadedEmail;
      });

      debugPrint('Final loaded User ID: $userId');
      debugPrint('Final loaded User Email: $userEmail');

      if (userId == null || userId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not found. Please log in again.')),
        );
      }
    } catch (e) {
      debugPrint('Error in _loadUserData: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  Future<void> cancelDelivery(String deliveryId) async {
    try {
      debugPrint('Canceling delivery for $deliveryId');

      // Make the DELETE request
      final response = await http.delete(Uri.parse(
          'https://deliveryapi-ten.vercel.app/deliveries/$deliveryId/delete'));

      // Check for redirect (308 status code)
      if (response.statusCode == 308) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          debugPrint('Redirecting to: $redirectUrl');
          final redirectResponse = await http.delete(Uri.parse(redirectUrl));

          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            if (data['status'] == 'success') {
              debugPrint('Delivery canceled successfully');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delivery canceled successfully')),
              );
              fetchDeliveries(); // Refresh the deliveries list
            } else {
              debugPrint('Failed to cancel delivery: ${data['message']}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(data['message'] ?? 'Failed to cancel delivery')),
              );
            }
          } else {
            debugPrint(
                'Error canceling delivery after redirect: ${redirectResponse.statusCode}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error canceling delivery after redirect')),
            );
          }
        } else {
          debugPrint('Redirect URL not found in response headers');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Redirect URL not found')),
          );
        }
      } else if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          debugPrint('Delivery canceled successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delivery canceled successfully')),
          );
          fetchDeliveries(); // Refresh the deliveries list
        } else {
          debugPrint('Failed to cancel delivery: ${data['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(data['message'] ?? 'Failed to cancel delivery')),
          );
        }
      } else {
        debugPrint('Error canceling delivery: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error canceling delivery: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('Exception while canceling delivery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred while canceling the delivery')),
      );
    }
  }

  Future<void> fetchDeliveries() async {
    if (userId == null) {
      debugPrint('fetchDeliveries: userId is null, cannot fetch deliveries');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found. Please log in again.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      debugPrint('Fetching deliveries for userId: $userId');
      final response = await http.get(
        Uri.parse('https://deliveryapi-ten.vercel.app/deliveries'),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final allDeliveries = data['deliveries'];
          debugPrint('Total deliveries received: ${allDeliveries.length}');

          // Filter deliveries by user_id
          final userDeliveries = allDeliveries
              .where((delivery) => delivery['user_id'] == userId)
              .toList();

          // Sort deliveries by creation date (assuming there's a createdAt field)
          // If there's no createdAt field, you might need to adjust this logic
          userDeliveries.sort((a, b) {
            // Check if createdAt exists, otherwise try to use _id which often contains a timestamp
            final DateTime dateA = a['createdAt'] != null
                ? DateTime.parse(a['createdAt'])
                : DateTime.fromMillisecondsSinceEpoch(
                    int.tryParse(a['_id'].substring(0, 8), radix: 16) ??
                        0 * 1000);

            final DateTime dateB = b['createdAt'] != null
                ? DateTime.parse(b['createdAt'])
                : DateTime.fromMillisecondsSinceEpoch(
                    int.tryParse(b['_id'].substring(0, 8), radix: 16) ??
                        0 * 1000);

            // Sort in descending order (newest first)
            return dateB.compareTo(dateA);
          });

          debugPrint(
              'Filtered deliveries for current user: ${userDeliveries.length}');

          setState(() {
            deliveries = userDeliveries;
            isLoading = false;
          });
        } else {
          debugPrint(
              'API returned success: false - ${data['message'] ?? "No message"}');
          setState(() {
            deliveries = []; // Set empty list instead of showing error
            isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        // Handle 404 specifically - this means no deliveries exist yet
        debugPrint('No deliveries found (404)');
        setState(() {
          deliveries = []; // Set empty list
          isLoading = false;
        });
      } else {
        debugPrint('HTTP Error: ${response.statusCode} - ${response.body}');
        setState(() {
          deliveries = []; // Set empty list instead of showing error
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Exception in fetchDeliveries: $e');
      setState(() {
        deliveries = []; // Set empty list instead of showing error
        isLoading = false;
      });
    }
  }

  // Get filtered deliveries based on status and search query
  List<dynamic> getFilteredDeliveries() {
    List<dynamic> filtered = deliveries;

    // Filter by status
    if (currentStatus != 'all') {
      if (currentStatus == 'in_transit') {
        // Include both in_transit and inprogress statuses for the "on route" tab
        filtered = filtered
            .where((delivery) =>
                delivery['status']['current'] == 'in_transit' ||
                delivery['status']['current'] == 'inprogress')
            .toList();
      } else {
        filtered = filtered
            .where((delivery) => delivery['status']['current'] == currentStatus)
            .toList();
      }
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((delivery) =>
              delivery['_id']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              delivery['startpoint']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              delivery['endpoint']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Future<Map<String, dynamic>> _fetchRiderDetails(String riderId) async {
    try {
      final response = await http.get(
        Uri.parse('https://deliveryapi-ten.vercel.app/riders/$riderId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['rider'];
        }
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching rider details: $e');
      return {};
    }
  }

  Future<double> _fetchRiderRating(String riderId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://deliveryapi-ten.vercel.app/riders/$riderId/overall-rating'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Safely handle null rating
          return (data['rating'] ?? 0.0).toDouble();
        }
      }
      return 0.0; // Default value if the API response is not successful
    } catch (e) {
      debugPrint('Error fetching rider rating: $e');
      return 0.0; // Default value in case of an exception
    }
  }

  Future<Map<String, dynamic>> _fetchRiderLocation(String deliveryId) async {
    try {
      final Uri url = Uri.parse(
          'https://deliveryapi-ten.vercel.app/deliveries/$deliveryId/rider-location');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json', // Use 'Accept' as per your API example
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success' && data.containsKey('location_data')) {
          final locationData = data['location_data'];

          return {
            'latitude': locationData['latitude'] ?? 0.0,
            'longitude': locationData['longitude'] ?? 0.0,
            'last_updated': locationData['last_updated'] ?? '',
            'eta_minutes': locationData['eta_minutes'] ?? 0,
            'eta_time': locationData['eta_time'] ?? '',
          };
        } else {
          debugPrint('API Error: ${data['message']}');
          return _emptyLocation();
        }
      } else {
        debugPrint('HTTP Error ${response.statusCode}: ${response.body}');
        return _emptyLocation();
      }
    } catch (e) {
      debugPrint('Error fetching rider location: $e');
      return _emptyLocation();
    }
  }

// Helper function to return a consistent empty location response
  Map<String, dynamic> _emptyLocation() {
    return {
      'latitude': 0.0,
      'longitude': 0.0,
      'last_updated': '',
      'eta_minutes': 0,
      'eta_time': '',
    };
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
        body: RefreshIndicator(
          onRefresh: fetchDeliveries,
          color: Color.fromRGBO(0, 31, 62, 1),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  18, 0, 18, MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Header and Search
                  orderSearchbar(),
                  const SizedBox(height: 24),

                  // Toggle Bar for filtering
                  ToggleBar(onStatusChanged: (status) {
                    setState(() {
                      switch (status) {
                        case 0:
                          currentStatus = 'all';
                          break;
                        case 1:
                          currentStatus = 'in_transit';
                          break;
                        case 2:
                          currentStatus = 'completed';
                          break;
                      }
                    });
                  }),
                  const SizedBox(height: 20),

                  // Delivery cards
                  Expanded(
                    child: isLoading
                        ? _buildLoadingShimmer()
                        : deliveries.isEmpty
                            ? _buildEmptyState()
                            : getFilteredDeliveries().isEmpty
                                ? _buildNoResultsFound()
                                : ListView.builder(
                                    padding: EdgeInsets.only(bottom: 20),
                                    itemCount: getFilteredDeliveries().length,
                                    itemBuilder: (context, index) {
                                      final delivery =
                                          getFilteredDeliveries()[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: _buildDeliveryCard(delivery),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            EvaIcons.carOutline, // Changed to Eva Icons
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No deliveries yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your delivery history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            EvaIcons.searchOutline, // Changed to Eva Icons
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(dynamic delivery) {
    // Add null checks for status fields
    final String actualStatus =
        delivery['status'] != null && delivery['status']['current'] != null
            ? delivery['status']['current']
            : 'pending';

    // Display status - show 'pending' for UI if status is 'ongoing'
    // Also show 'in_transit' for 'inprogress' status
    final String displayStatus;
    if (actualStatus == 'ongoing') {
      displayStatus = 'pending';
    } else if (actualStatus == 'inprogress') {
      displayStatus = 'in_transit';
    } else {
      displayStatus = actualStatus;
    }

    final String shortId = delivery['_id'].toString().substring(0, 8);
    final double price = delivery['price'] is double
        ? delivery['price']
        : double.parse(delivery['price'].toString());
    final String formattedPrice = NumberFormat.currency(
      symbol: '₦',
      decimalDigits: 2,
    ).format(price);

    // Check if tracking is available - enable tracking for 'ongoing' status
    final bool canTrack = actualStatus == 'accepted' ||
        actualStatus == 'in_progress' ||
        actualStatus == 'ongoing' ||
        actualStatus == 'in_transit' ||
        actualStatus == 'inprogress';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with ID and status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 31, 62, 0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #MC$shortId',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(0, 31, 62, 1),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(displayStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(displayStatus),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        _getStatusText(displayStatus),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(displayStatus),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Delivery details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // From location
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 31, 62, 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        EvaIcons.pinOutline, // Changed to Eva Icons
                        color: Color.fromRGBO(0, 31, 62, 1),
                        size: 14,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            delivery['startpoint'],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Vertical line
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),

                // To location
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        EvaIcons.pinOutline, // Changed to Eva Icons
                        color: Colors.red,
                        size: 14,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            delivery['endpoint'],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Price and action buttons
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedPrice,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(0, 31, 62, 1),
                        ),
                      ),
                      Row(
                        children: [
                          // Show different buttons based on status
                          if (displayStatus == 'pending' ||
                              displayStatus == 'in_transit')
                            OutlinedButton(
                              onPressed: canTrack
                                  ? () {
                                      _showTrackingSheet(context, delivery);
                                    }
                                  : null, // Disable button if order not accepted
                              style: OutlinedButton.styleFrom(
                                foregroundColor: canTrack
                                    ? Color.fromRGBO(0, 31, 62, 1)
                                    : Colors.grey,
                                side: BorderSide(
                                    color: canTrack
                                        ? Color.fromRGBO(0, 31, 62, 1)
                                        : Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              child: Text('Track'),
                            ),

                          if (displayStatus == 'completed')
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    // Navigate to chat screen with delivery info
                                    final String riderId =
                                        delivery['rider_id'] ?? '';
                                    if (riderId.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UserChatScreen(
                                            userName: "Rider",
                                            userImage: null,
                                            orderId: "MC$shortId",
                                            deliveryId: delivery['_id'],
                                            senderId: userId,
                                            receiverId: riderId,
                                            isDeliveryCompleted:
                                                true, // Set to true for completed deliveries
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Rider information not available')),
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Color.fromRGBO(0, 31, 62, 1),
                                    side: BorderSide(
                                        color: Color.fromRGBO(0, 31, 62, 1)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  child: Icon(EvaIcons.messageCircleOutline,
                                      size: 18),
                                ),
                                SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    _showReceiptPrompt(
                                        context, shortId, delivery);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Color.fromRGBO(0, 31, 62, 1),
                                    side: BorderSide(
                                        color: Color.fromRGBO(0, 31, 62, 1)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  child: Text('Receipt'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ]),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget orderSearchbar() {
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        Text(
          'MY ORDERS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(0, 31, 62, 1),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: searchController,
          autofocus: false,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Search by ID or location',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Color.fromRGBO(0, 31, 62, 1)),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                if (searchQuery.isNotEmpty) {
                  searchController.clear();
                  setState(() {
                    searchQuery = '';
                  });
                }
              },
              icon: Icon(
                searchQuery.isEmpty
                    ? EvaIcons.searchOutline
                    : EvaIcons.closeCircleOutline, // Changed to Eva Icons
                color: Colors.grey,
              ),
              iconSize: 22,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _showTrackingSheet(BuildContext context, dynamic delivery) async {
    final String shortId = delivery['_id'].toString().substring(0, 8);
    final String riderId = delivery['rider_id'] ?? '';

    // Show loading state first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.only(bottom: 20),
              ),
              Text(
                "Loading Rider Details...",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(0, 31, 62, 1)),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                color: Color.fromRGBO(0, 31, 62, 1),
              ),
              SizedBox(height: 30),
            ],
          ),
        );
      },
    );

    // Fetch rider details
    if (riderId.isEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rider information not available yet')),
      );
      return;
    }

    final riderDetails = await _fetchRiderDetails(riderId);
    final riderRating = await _fetchRiderRating(riderId);

    // Close the loading sheet
    Navigator.pop(context);

    if (riderDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load rider details')),
      );
      return;
    }

    // Show the actual tracking sheet with rider details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.only(bottom: 20),
              ),
              Text(
                "Tracking Your Delivery",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(0, 31, 62, 1)),
              ),
              SizedBox(height: 20),

              // Rider profile image
              riderDetails['facial_picture_url'] != null
                  ? CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                        (riderDetails['facial_picture_url'] ?? '').replaceFirst(
                            'deliveryapi-plum', 'deliveryapi-ten'),
                      ),
                      backgroundColor: Color.fromRGBO(0, 31, 62, 0.1),
                    )
                  : CircleAvatar(
                      radius: 40,
                      backgroundColor: Color.fromRGBO(0, 31, 62, 0.1),
                      child: Icon(
                        EvaIcons.personOutline,
                        size: 40,
                        color: Color.fromRGBO(0, 31, 62, 1),
                      ),
                    ),
              SizedBox(height: 16),

              // Rider name and rating
              Text(
                "${riderDetails['firstname'] ?? ''} ${riderDetails['lastname'] ?? ''}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "${riderRating.toStringAsFixed(1)} Rating",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                riderDetails['phone'] ?? "No phone number",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Text(
                "Vehicle: ${riderDetails['vehicle_type']?.toString().toUpperCase() ?? 'Bike'}",
                style: TextStyle(
                  fontSize: 12,
                  color: Color.fromRGBO(0, 31, 62, 1),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),

              // Delivery progress
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0, 31, 62, 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Rider's current location
                    FutureBuilder<Map<String, dynamic>>(
                      future: _fetchRiderLocation(delivery['_id']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Row(
                            children: [
                              Icon(EvaIcons.pinOutline,
                                  color: Color.fromRGBO(0, 31, 62, 1),
                                  size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Fetching rider's location...",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        } else if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Row(
                            children: [
                              Icon(EvaIcons.pinOutline,
                                  color: Color.fromRGBO(0, 31, 62, 1),
                                  size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Rider's location unavailable",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.red),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        } else {
                          final riderLocation = snapshot.data!;
                          final double latitude = riderLocation['latitude'];
                          final double longitude = riderLocation['longitude'];

                          return FutureBuilder<List<Placemark>>(
                            future:
                                placemarkFromCoordinates(latitude, longitude),
                            builder: (context, addressSnapshot) {
                              if (addressSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Row(
                                  children: [
                                    Icon(EvaIcons.pinOutline,
                                        color: Color.fromRGBO(0, 31, 62, 1),
                                        size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Converting coordinates to address...",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              } else if (addressSnapshot.hasError ||
                                  !addressSnapshot.hasData ||
                                  addressSnapshot.data!.isEmpty) {
                                return Row(
                                  children: [
                                    Icon(EvaIcons.pinOutline,
                                        color: Color.fromRGBO(0, 31, 62, 1),
                                        size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Address unavailable",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.red),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                final placemark = addressSnapshot.data!.first;
                                final riderAddress = [
                                  placemark.street,
                                  placemark.subLocality,
                                  placemark.locality,
                                  placemark.administrativeArea,
                                  placemark.country,
                                ]
                                    .where((element) =>
                                        element != null && element.isNotEmpty)
                                    .join(', ');

                                return Row(
                                  children: [
                                    Icon(EvaIcons.pinOutline,
                                        color: Color.fromRGBO(0, 31, 62, 1),
                                        size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        riderAddress,
                                        style: TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          );
                        }
                      },
                    ),
                    SizedBox(height: 8),

                    // Progress bar
                    Container(
                      height: 40,
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            alignment: Alignment.center,
                            child: Container(
                              width: 1,
                              height: 40,
                              color: Color.fromRGBO(0, 31, 62, 1),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: FutureBuilder<Map<String, dynamic>>(
                              future: _fetchRiderLocation(delivery[
                                  '_id']), // Fetch rider location and ETA
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return LinearProgressIndicator(
                                    value:
                                        null, // Indeterminate progress while loading
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromRGBO(0, 31, 62, 1),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  );
                                } else if (snapshot.hasError ||
                                    !snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return LinearProgressIndicator(
                                    value:
                                        0.0, // No progress if there's an error or no data
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.red, // Red to indicate an error
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  );
                                } else {
                                  final riderLocation = snapshot.data!;
                                  final int etaMinutes =
                                      riderLocation['eta_minutes'] ?? 0;
                                  final String etaTime =
                                      riderLocation['eta_time'] ?? '';

                                  // Validate and parse etaTime
                                  DateTime? etaDateTime;
                                  try {
                                    etaDateTime = DateTime.parse(etaTime);
                                  } catch (e) {
                                    debugPrint(
                                        'Invalid eta_time format: $etaTime');
                                    etaDateTime =
                                        null; // Fallback to null if parsing fails
                                  }

                                  if (etaDateTime == null) {
                                    return LinearProgressIndicator(
                                      value:
                                          0.0, // No progress if eta_time is invalid
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.red, // Red to indicate an error
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    );
                                  }

                                  // Calculate progress based on elapsed time
                                  final DateTime now = DateTime.now();
                                  final int totalSeconds = etaMinutes * 60;
                                  final int elapsedSeconds = totalSeconds -
                                      etaDateTime.difference(now).inSeconds;

                                  // Ensure progress is between 0.0 and 1.0
                                  final double progress =
                                      (elapsedSeconds / totalSeconds)
                                          .clamp(0.0, 1.0);

                                  return LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromRGBO(0, 31, 62, 1),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),

                    // Pickup or Delivery endpoint
                    Row(
                      children: [
                        Icon(
                          EvaIcons.pinOutline,
                          color: Color.fromRGBO(0, 31, 62, 1),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: _fetchRiderLocation(delivery['_id']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text(
                                  "Fetching location...",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              } else if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return Text(
                                  "Location unavailable",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.red),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              } else {
                                final riderLocation = snapshot.data!;
                                final double riderLat =
                                    riderLocation['latitude'];
                                final double riderLng =
                                    riderLocation['longitude'];
                                final double pickupLat =
                                    delivery['pickup_lat'] ?? 0.0;
                                final double pickupLng =
                                    delivery['pickup_lng'] ?? 0.0;

                                // Check if rider is at the pickup location
                                if (riderLat == pickupLat &&
                                    riderLng == pickupLng) {
                                  return Text(
                                    delivery['startpoint'],
                                    style: TextStyle(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                } else {
                                  return Text(
                                    delivery['endpoint'],
                                    style: TextStyle(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>>(
                future: _fetchRiderLocation(
                    delivery['_id']), // Fetch rider location and ETA
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      "Calculating estimated arrival...",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return Text(
                      "Unable to calculate arrival time",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  } else {
                    final riderLocation = snapshot.data!;
                    final int etaMinutes = riderLocation['eta_minutes'] ?? 0;

                    // Display the dynamic estimated arrival time
                    return Text(
                      "Estimated arrival: $etaMinutes minutes",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: EvaIcons.phoneOutline,
                    label: "Call",
                    onPressed: () {
                      // Implement call functionality with rider's phone
                      final phone = riderDetails['phone'] ?? '';
                      Navigator.pop(context);
                      if (phone.isNotEmpty) {
                        // Launch phone call
                        launchUrl(Uri.parse('tel:$phone'));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Phone number not available')),
                        );
                      }
                    },
                  ),
                  _buildActionButton(
                    icon: EvaIcons.messageCircleOutline,
                    label: "Chat",
                    onPressed: () {
                      // Navigate to chat screen with rider info
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserChatScreen(
                            userName:
                                "${riderDetails['firstname'] ?? ''} ${riderDetails['lastname'] ?? ''}",
                            userImage: riderDetails['facial_picture_url'],
                            orderId: "MC$shortId",
                            deliveryId: delivery['_id'],
                            senderId: userId,
                            receiverId: riderId,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: EvaIcons.closeCircleOutline,
                    label: "Cancel",
                    onPressed: () {
                      // Implement cancel functionality
                      Navigator.pop(context);
                      _showCancelConfirmation(context, delivery);
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 31, 62, 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Color.fromRGBO(0, 31, 62, 1),
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, dynamic delivery) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text("Cancel Delivery?"),
          content: Text(
              "Are you sure you want to cancel this delivery? A cancellation fee may apply."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "No",
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement cancel delivery logic
                cancelDelivery(delivery['_id']);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delivery cancelled')),
                );
                // Optionally, navigate to another page or refresh the order list
                Provider.of<IndexProvider>(context, listen: false)
                    .setSelectedIndex(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Yes, Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _showReceiptPrompt(
      BuildContext context, String shortId, dynamic delivery) {
    final double price = delivery['price'] is double
        ? delivery['price']
        : double.parse(delivery['price'].toString());
    final String formattedPrice = NumberFormat.currency(
      symbol: '₦',
      decimalDigits: 2,
    ).format(price);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.only(bottom: 20),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'E-Receipt',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(0, 31, 62, 1),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Receipt content
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ID:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '#MC$shortId',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24),
                    _buildReceiptRow('From:', delivery['startpoint']),
                    SizedBox(height: 8),
                    _buildReceiptRow('To:', delivery['endpoint']),
                    SizedBox(height: 8),
                    _buildReceiptRow('Distance:', delivery['distance']),
                    SizedBox(height: 8),
                    _buildReceiptRow('Vehicle Type:', delivery['vehicletype']),
                    SizedBox(height: 8),
                    _buildReceiptRow(
                        'Payment Method:', delivery['transactiontype']),
                    Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formattedPrice,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 31, 62, 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Implement download receipt functionality
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Receipt downloaded')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(0, 31, 62, 1),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.download),
                label: Text('Download Receipt'),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _processOnlinePayment(dynamic delivery) {
    // Implement online payment logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Processing payment...')),
    );
  }
}

// Utility function to get status color
Color _getStatusColor(String status) {
  switch (status) {
    case 'pending':
      return Color.fromRGBO(255, 152, 0, 1); // Orange
    case 'in_transit':
      return Color.fromRGBO(33, 150, 243, 1); // Blue
    case 'completed':
      return Color.fromRGBO(76, 175, 80, 1); // Green
    case 'cancelled':
      return Color.fromRGBO(244, 67, 54, 1); // Red
    default:
      return Color.fromRGBO(158, 158, 158, 1); // Grey
  }
}

// Utility function to get status text
String _getStatusText(String status) {
  switch (status) {
    case 'pending':
      return 'Pending';
    case 'in_transit':
      return 'In Transit';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return 'Unknown';
  }
}

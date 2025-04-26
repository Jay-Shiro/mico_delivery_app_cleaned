import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:micollins_delivery_app/components/toggle_bar.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';
import 'package:micollins_delivery_app/pages/user_chat_screen.dart';
import 'package:micollins_delivery_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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
  Timer? _locationTimer;

  late GoogleMapController _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _moveToLocation(LatLng location) {
    _mapController.animateCamera(CameraUpdate.newLatLng(location));
  }

  void _zoomIn() {
    _mapController.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) {
      fetchDeliveries();
    });

    // Set up periodic check for completed deliveries
    Timer.periodic(Duration(minutes: 1), (timer) {
      checkForCompletedDeliveries();
    });

    // Check immediately on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForCompletedDeliveries();
    });
  }

  final Set<String> notifiedMessageIds = {};

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

      final response = await http.delete(Uri.parse(
          'https://deliveryapi-ten.vercel.app/deliveries/$deliveryId/delete'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          debugPrint('Delivery canceled successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delivery canceled successfully')),
          );

          // Fetch updated deliveries
          fetchDeliveries();

          // Show the rating modal
          final canceledDelivery = deliveries.firstWhere(
            (delivery) => delivery['_id'] == deliveryId,
            orElse: () => null,
          );
          if (canceledDelivery != null) {
            _showRatingModal(canceledDelivery);
          }
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

  void startFetchingLocation(
    String deliveryId,
    Function(Map<String, dynamic>) onLocationUpdated,
  ) {
    _locationTimer?.cancel(); // Cancel existing timer if any

    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final location = await _fetchRiderLocation(deliveryId);
      onLocationUpdated(location); // Pass the new location to your callback
    });
  }

  void stopFetchingLocation() {
    _locationTimer?.cancel();
    _locationTimer = null;
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
          'Accept': 'application/json',
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

  // Add this new method to show the rating modal
  Future<void> _showRatingModal(dynamic delivery) async {
    final riderId = delivery['rider_id'];
    if (riderId == null) {
      debugPrint('No rider ID found for this delivery');
      return;
    }

    double rating = 5.0;
    final commentController = TextEditingController();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate Customer',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF001F3E),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'How was your experience with this customer?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: index < rating ? Colors.amber : Colors.grey,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
              // Comment field
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF001F3E), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // Submit rating
                    await _submitRating(riderId!, delivery['_id'], rating,
                        commentController.text);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001F3E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Submit Rating',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Skip button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this method to submit the rating
  Future<void> _submitRating(
      String riderId, String deliveryId, double rating, String comment) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://deliveryapi-ten.vercel.app/riders/$userId/rate-rider/$riderId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
            {'rating': rating, 'comment': comment, 'delivery_id': deliveryId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Rating submitted successfully!'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        debugPrint(
            'Error submitting rating: ${response.statusCode}, ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to submit rating'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
    final String actualStatus =
        delivery['status'] != null && delivery['status']['current'] != null
            ? delivery['status']['current']
            : 'pending';

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
                        EvaIcons.pinOutline,
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
                        EvaIcons.pinOutline,
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

                // Action buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (displayStatus != 'completed')
                        Text(
                          formattedPrice,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 31, 62, 1),
                          ),
                        ),
                      if (displayStatus == 'pending' ||
                          displayStatus == 'in_transit')
                        Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: OutlinedButton(
                            onPressed: canTrack
                                ? () {
                                    _showTrackingSheet(context, delivery);
                                  }
                                : null,
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
                                  horizontal: 16, vertical: 8),
                            ),
                            child: Text('Track'),
                          ),
                        ),
                      if (displayStatus == 'completed') ...[
                        SizedBox(width: 4),
                        OutlinedButton(
                          onPressed: () {
                            final String riderId = delivery['rider_id'] ?? '';
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
                                    isDeliveryCompleted: true,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Rider information not available')),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color.fromRGBO(0, 31, 62, 1),
                            side:
                                BorderSide(color: Color.fromRGBO(0, 31, 62, 1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: Icon(EvaIcons.messageCircleOutline, size: 18),
                        ),
                        SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            _showReceiptPrompt(context, shortId, delivery);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color.fromRGBO(0, 31, 62, 1),
                            side:
                                BorderSide(color: Color.fromRGBO(0, 31, 62, 1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(EvaIcons.fileTextOutline, size: 16),
                              SizedBox(width: 4),
                              Text('Receipt'),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            const url =
                                'https://tawk.to/chat/67d9b700ceba8418ffbf99f7/1iml75og6';
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Could not launch support chat')),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color.fromRGBO(0, 31, 62, 1),
                            side:
                                BorderSide(color: Color.fromRGBO(0, 31, 62, 1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(EvaIcons.micOutline, size: 16),
                              SizedBox(width: 4),
                              Text('Support'),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showRatingDialog(delivery);
                          },
                          icon: Icon(
                            EvaIcons.starOutline,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Rate',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(0, 31, 62, 1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showRatingDialog(dynamic delivery) {
    final String riderId = delivery['rider_id'] ?? '';
    if (riderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rider information not available')),
      );
      return;
    }

    double ratingValue = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with icon
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 31, 62, 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        EvaIcons.starOutline,
                        color: Color.fromRGBO(0, 31, 62, 1),
                        size: 30,
                      ),
                    ),
                    SizedBox(height: 15),

                    // Title
                    Text(
                      'Rate Your Rider',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(0, 31, 62, 1),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Subtitle
                    Text(
                      'How was your delivery experience?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Star rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              ratingValue = index + 1.0;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(
                              index < ratingValue
                                  ? Icons.star
                                  : Icons.star_border,
                              color: index < ratingValue
                                  ? Colors.amber
                                  : Colors.grey[400],
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 20),

                    // Comment field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add your comments here...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(15),
                        ),
                      ),
                    ),
                    SizedBox(height: 25),

                    // Submit button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _submitRiderRating(
                            riderId,
                            delivery['_id'],
                            ratingValue,
                            commentController.text,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(0, 31, 62, 1),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Cancel button
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Method to submit the rider rating
  Future<void> _submitRiderRating(
    String riderId,
    String deliveryId,
    double rating,
    String comment,
  ) async {
    try {
      // Using the correct endpoint format as shown in the curl example
      final response = await http.post(
        Uri.parse(
            'https://deliveryapi-ten.vercel.app/users/$userId/rate-rider/$riderId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rating': rating,
          'comment': comment,
          'delivery_id': deliveryId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thank you for rating your rider!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        debugPrint(
            'Error submitting rating: ${response.statusCode}, ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Exception while submitting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update this method to check for completed deliveries
  Future<void> checkForCompletedDeliveries() async {
    if (deliveries.isEmpty) return;

    for (var delivery in deliveries) {
      final String deliveryId = delivery['_id'];
      final String status = delivery['status']['current'] ?? '';

      // Check if this is a newly completed delivery that we haven't notified about yet
      if (status == 'completed' && !notifiedMessageIds.contains(deliveryId)) {
        // Add to our set of notified IDs
        notifiedMessageIds.add(deliveryId);

        // Send the notification using our fixed method
        _sendCompletionNotification(delivery);
      }
    }
  }

  // Fix the method to send notifications for completed deliveries
  void _sendCompletionNotification(dynamic delivery) {
    final String shortId = delivery['_id'].toString().substring(0, 8);
    final String title = 'Delivery Completed';
    final String body =
        'Your delivery (MC$shortId) has been completed successfully!';

    debugPrint('Sending notification for delivery MC$shortId');

    NotificationService().showMessageNotification(
      title: title,
      body: body,
      payload: {
        'type': 'delivery_completed',
        'deliveryId': delivery['_id'],
        'orderId': shortId,
        'userName': delivery['user_name'] ?? '',
        'userImage': delivery['user_image'] ?? '',
      },
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

  Future<void> _convertAddressToLatLng(
      String address, Function(LatLng) onLatLngConverted) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        LatLng latLng =
            LatLng(locations.first.latitude, locations.first.longitude);
        onLatLngConverted(latLng);
      }
    } catch (e) {
      debugPrint('Error converting address to LatLng: $e');
    }
  }

  Future<void> _updatePolylineAndMarkers({
    required LatLng riderLatLng,
    required LatLng pickupLatLng,
    required LatLng destinationLatLng,
    required Function(Set<Marker>) onMarkersUpdated,
    required Function(Set<Polyline>) onPolylinesUpdated,
  }) async {
    try {
      // Load custom pin icon for pickup and destination
      BitmapDescriptor pinIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(48, 48)),
        'assets/icons/pin.png',
      );

      // Create markers
      Set<Marker> markers = {
        Marker(
          markerId: MarkerId('rider'),
          position: riderLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: "Rider's Location"),
        ),
        Marker(
          markerId: MarkerId('pickup'),
          position: pickupLatLng,
          icon: pinIcon, // Use custom pin icon for pickup
          infoWindow: InfoWindow(title: "Pickup Location"),
        ),
        Marker(
          markerId: MarkerId('destination'),
          position: destinationLatLng,
          icon: pinIcon, // Use custom pin icon for destination
          infoWindow: InfoWindow(title: "Destination"),
        ),
      };

      // Create polyline
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: 'AIzaSyC_Op-lSfNmmGPzKvsdImneVuL1jzYfNoM',
        request: PolylineRequest(
          origin: PointLatLng(pickupLatLng.latitude, pickupLatLng.longitude),
          destination: PointLatLng(
              destinationLatLng.latitude, destinationLatLng.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        Set<Polyline> polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            points: polylineCoordinates,
            color: Color.fromRGBO(0, 31, 62, 1),
            width: 4,
          ),
        };

        onMarkersUpdated(markers);
        onPolylinesUpdated(polylines);
      }
    } catch (e) {
      debugPrint('Error updating polyline and markers: $e');
    }
  }

  void _showTrackingSheet(BuildContext context, dynamic delivery) async {
    final String shortId = delivery['_id'].toString().substring(0, 8);
    final String riderId = delivery['rider_id'] ?? '';

    // Show initial loading modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildLoadingSheet(),
    );

    if (riderId.isEmpty) {
      Navigator.pop(context);
      _showSnackBar(context, 'Rider information not available yet');
      return;
    }

    final riderDetails = await _fetchRiderDetails(riderId);
    final riderRating = await _fetchRiderRating(riderId);
    final riderLocation = await _fetchRiderLocation(delivery['_id']);

    if (riderDetails.isEmpty || riderLocation.isEmpty) {
      Navigator.pop(context);
      _showSnackBar(context, 'Failed to load rider details or location');
      return;
    }

    LatLng riderLatLng =
        LatLng(riderLocation['latitude'], riderLocation['longitude']);
    LatLng? pickupLatLng;
    LatLng? destinationLatLng;

    await _convertAddressToLatLng(
        delivery['startpoint'], (latLng) => pickupLatLng = latLng);
    await _convertAddressToLatLng(
        delivery['endpoint'], (latLng) => destinationLatLng = latLng);

    if (pickupLatLng == null || destinationLatLng == null) {
      Navigator.pop(context);
      _showSnackBar(context, 'Failed to convert addresses to coordinates');
      return;
    }

    BitmapDescriptor riderIcon =
        await _getRiderIcon(riderDetails['vehicle_type']);

    Navigator.pop(context); // Close loading modal

    // Show Tracking Sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        Set<Marker> markers = {};
        Set<Polyline> polylines = {};
        String etaText = "Calculating ETA...";
        LatLng currentRiderLatLng = riderLatLng;

        return StatefulBuilder(
          builder: (context, setState) {
            _updatePolylineAndMarkers(
              riderLatLng: riderLatLng,
              pickupLatLng: pickupLatLng!,
              destinationLatLng: destinationLatLng!,
              onMarkersUpdated: (updatedMarkers) =>
                  setState(() => markers = updatedMarkers),
              onPolylinesUpdated: (updatedPolylines) =>
                  setState(() => polylines = updatedPolylines),
            );

            startFetchingLocation(delivery['_id'], (newLocation) async {
              if (newLocation == null) return;

              LatLng newRiderLatLng =
                  LatLng(newLocation['latitude'], newLocation['longitude']);
              _animateMarkerMovement(currentRiderLatLng, newRiderLatLng,
                  (animatedPosition) {
                setState(() {
                  markers.removeWhere((m) => m.markerId.value == 'rider');
                  markers.add(
                    Marker(
                      markerId: MarkerId('rider'),
                      position: animatedPosition,
                      icon: riderIcon,
                      infoWindow: InfoWindow(title: "Rider's Location"),
                    ),
                  );
                });
              });

              currentRiderLatLng = newRiderLatLng;

              double distanceToPickup = Geolocator.distanceBetween(
                newRiderLatLng.latitude,
                newRiderLatLng.longitude,
                pickupLatLng!.latitude,
                pickupLatLng!.longitude,
              );

              setState(() {
                etaText = distanceToPickup < 50
                    ? "ETA to destination: ${newLocation['eta_time'] ?? 'Unknown'}"
                    : "ETA to pickup: ${newLocation['eta_time'] ?? 'Unknown'}";
              });

              _mapController
                  .animateCamera(CameraUpdate.newLatLng(newRiderLatLng));
            });

            return _buildTrackingContent(
              context,
              riderLatLng,
              markers,
              polylines,
              etaText,
              riderDetails,
              riderRating,
              delivery,
              shortId,
              riderId,
            );
          },
        );
      },
    );
  }

  void _animateMarkerMovement(
    LatLng fromLatLng,
    LatLng toLatLng,
    Function(LatLng) onUpdate,
  ) async {
    const int animationDurationMs = 1000; // 1 second
    final int frameRate = 60;
    final int totalFrames = (animationDurationMs / (1000 / frameRate)).round();

    for (int frame = 0; frame <= totalFrames; frame++) {
      double t = frame / totalFrames;
      double lat = _lerp(fromLatLng.latitude, toLatLng.latitude, t);
      double lng = _lerp(fromLatLng.longitude, toLatLng.longitude, t);
      onUpdate(LatLng(lat, lng));
      await Future.delayed(Duration(milliseconds: (1000 / frameRate).round()));
    }
  }

  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  Widget _buildLoadingSheet() {
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
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text(
            "Loading Rider Details...",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF001F3E)),
          ),
          SizedBox(height: 20),
          CircularProgressIndicator(color: Color(0xFF001F3E)),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<BitmapDescriptor> _getRiderIcon(String? vehicleType) async {
    String asset = 'assets/icons/bike.png'; // default
    if (vehicleType?.toUpperCase() == 'car') {
      asset = 'assets/icons/car.png';
    } else if (vehicleType?.toUpperCase() == 'truck') {
      asset = 'assets/icons/truck.png';
    }
    return await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(48, 48)), asset);
  }

  Widget _buildTrackingContent(
    BuildContext context,
    LatLng riderLatLng,
    Set<Marker> markers,
    Set<Polyline> polylines,
    String etaText,
    Map riderDetails,
    double riderRating,
    dynamic delivery,
    String shortId,
    String riderId,
  ) {
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
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text(
            "Tracking Your Delivery",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF001F3E)),
          ),
          SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundImage: riderDetails['facial_picture_url'] != null
                ? NetworkImage((riderDetails['facial_picture_url'] ?? '')
                    .replaceFirst('deliveryapi-plum', 'deliveryapi-ten'))
                : null,
            backgroundColor: Color.fromRGBO(0, 31, 62, 0.1),
            child: riderDetails['facial_picture_url'] == null
                ? Icon(EvaIcons.personOutline,
                    size: 40, color: Color(0xFF001F3E))
                : null,
          ),
          SizedBox(height: 16),
          Text(
            "${riderDetails['firstname'] ?? ''} ${riderDetails['lastname'] ?? ''}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 18),
              SizedBox(width: 4),
              Text("${riderRating.toStringAsFixed(1)} Rating",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ],
          ),
          SizedBox(height: 4),
          Text(riderDetails['phone'] ?? "No phone number",
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text(
            "Vehicle: ${riderDetails['vehicle_type']?.toUpperCase() ?? 'Bike'}",
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF001F3E),
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 250,
              child: Stack(
                children: [
                  GoogleMap(
                    zoomControlsEnabled: false,
                    onMapCreated: _onMapCreated,
                    initialCameraPosition:
                        CameraPosition(target: riderLatLng, zoom: 14),
                    markers: markers,
                    polylines: polylines,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      children: [
                        _buildSmallButton(Icons.my_location_rounded,
                            () => _moveToLocation(riderLatLng)),
                        SizedBox(height: 8),
                        _buildSmallButton(Icons.add, _zoomIn),
                        SizedBox(height: 8),
                        _buildSmallButton(Icons.remove, _zoomOut),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFF001F3E), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(etaText,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF001F3E))),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(EvaIcons.phoneOutline, "Call",
                  () => _callRider(riderDetails['phone'])),
              _buildActionButton(
                  EvaIcons.messageCircleOutline,
                  "Chat",
                  () => _startChat(context, riderDetails, shortId,
                      delivery['_id'], riderId)),
              _buildActionButton(EvaIcons.closeCircleOutline, "Cancel",
                  () => _showCancelConfirmation(context, delivery)),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

// --- Utility Widgets/Functions ---

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildSmallButton(IconData icon, VoidCallback onPressed) {
    return FloatingActionButton.small(
      backgroundColor: Colors.white,
      onPressed: onPressed,
      child: Icon(icon, color: Color(0xFF001F3E)),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        FloatingActionButton(
          mini: true,
          backgroundColor: Color(0xFF001F3E),
          child: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  void _callRider(String? phone) {
    if (phone != null && phone.isNotEmpty) {
      launchUrl(Uri.parse('tel:$phone'));
    }
  }

  void _startChat(BuildContext context, Map riderDetails, String shortId,
      String deliveryId, String riderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserChatScreen(
          userName:
              "${riderDetails['firstname'] ?? ''} ${riderDetails['lastname'] ?? ''}",
          userImage: riderDetails['facial_picture_url'],
          orderId: "MC$shortId",
          deliveryId: deliveryId,
          senderId: userId,
          receiverId: riderId,
        ),
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

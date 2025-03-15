import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:micollins_delivery_app/components/Deliveries.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';
import 'package:provider/provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Delivery> _deliveries = [];
  bool _isLoadingLoc = false;
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 0;
  late String? _userLocation = 'Click button to get your Location';

  final List<String> carouselImages = [
    'assets/images/advert_1.png',
    'assets/images/advert_1.png',
    'assets/images/advert_1.png',
    'assets/images/advert_1.png',
  ];

  final List<Color> carouselColors = [
    Color.fromRGBO(70, 14, 0, 1),
    Color.fromRGBO(0, 31, 62, 1),
    Color.fromRGBO(70, 0, 61, 1),
    Color.fromRGBO(0, 49, 58, 1),
  ];

  @override
  void initState() {
    super.initState();
    fetchRecentDeliveries();
  }

  // Function to navigate to a specific index on the navbar
  void navigateToIndex(int index) {
    context.read<IndexProvider>().setSelectedIndex(index);
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoadingLoc = true);

    try {
      Position location = await _determinePosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      setState(() {
        _userLocation = [
          placemarks.first.street ?? '',
          placemarks.first.subLocality ?? '',
          placemarks.first.locality ?? '',
        ].where((element) => element.isNotEmpty).join(', ');

        _userLocation =
            _userLocation!.isNotEmpty ? _userLocation : 'Unknown location';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error getting location: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoadingLoc = false);
    }
  }

  Future<void> fetchRecentDeliveries() async {
    const String apiUrl = "https://deliveryapi-plum.vercel.app/deliveries";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _deliveries = data.map((json) => Delivery.fromJson(json)).toList();
          _isLoading = false;
          _hasError = false;
        });
      } else {
        throw Exception('API Error: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Widget _buildCarouselIndicator(int itemCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => Container(
          width: _currentPage == index ? 28 : 11,
          height: 6,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4),
            color: _currentPage == index
                ? Color.fromRGBO(0, 31, 62, 1)
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> carouselItems = List.generate(
      4,
      (index) => GestureDetector(
        onTap: () => navigateToIndex(1),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: carouselColors[index],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Image.asset(carouselImages[index], fit: BoxFit.cover),
        ),
      ),
    );

    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Location Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Icon(Icons.place,
                              color: Color.fromRGBO(0, 31, 62, 1)),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: _isLoadingLoc
                                ? SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color.fromRGBO(0, 31, 62, 1),
                                    ))
                                : Text(_userLocation ?? 'Unknown location',
                                    style: TextStyle(fontSize: 12)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: GestureDetector(
                              onTap: _isLoadingLoc ? null : _initializeLocation,
                              child: Icon(Icons.add),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),

                    // Carousel Slider
                    Column(
                      children: [
                        CarouselSlider(
                          items: carouselItems,
                          options: CarouselOptions(
                            height: 192,
                            enlargeCenterPage: true,
                            autoPlay: true,
                            viewportFraction: 0.9,
                            onPageChanged: (value, _) =>
                                setState(() => _currentPage = value),
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildCarouselIndicator(carouselItems.length),
                      ],
                    ),
                    SizedBox(height: 20),

                    //Parcel Delivery
                    GestureDetector(
                      onTap: () {
                        context.read<IndexProvider>().setSelectedIndex(1);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          width: 390,
                          height: 192,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(217, 217, 217, 1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  Image.asset(
                                    'assets/images/lumber_man_2.png',
                                    scale: 2.2,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                width: 1,
                              ),
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 140),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Parcel Delivery',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.0),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 10),
                                          child: CircleAvatar(
                                            backgroundColor:
                                                Color.fromRGBO(0, 31, 62, 1),
                                            radius: 14,
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: Color.fromRGBO(
                                                  217, 217, 217, 1),
                                              weight: 8,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    //Recent Activity
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 200),
                            child: Text(
                              'Recent Activity',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: Color.fromRGBO(0, 70, 67, 1),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.sizeOf(context).width,
                            width: MediaQuery.sizeOf(context).width,
                            child: Center(
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 80,
                                  ),
                                  Image.asset(
                                    'assets/images/no_user_history.png',
                                    scale: 5,
                                  ),
                                  Text(
                                    'No user History',
                                    style: TextStyle(
                                      color: Color.fromRGBO(165, 175, 175, 1),
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}

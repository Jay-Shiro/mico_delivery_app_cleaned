import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:micollins_delivery_app/components/Deliveries.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    _initializeLocation();
    fetchRecentDeliveries(); // Call API when the screen loads
  }

  List<Delivery> _deliveries = [];
  bool _isLoading = true;
  bool _hasError = false;

  int _currentPage = 0;

  late String? _userLocation = 'Click button to get your Location';

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _initializeLocation() async {
    try {
      // ignore: unused_local_variable
      Position location = await _determinePosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      setState(() {
        String address = [
          placemarks.first.street,
          placemarks.first.subLocality,
          placemarks.first.locality,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        _userLocation = address;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: const Color.fromRGBO(255, 91, 82, 1),
          ),
        );
      }
    }
  }

  Future<void> fetchRecentDeliveries() async {
    const String apiUrl =
        "https://deliveryapi-plum.vercel.app/deliveries"; // FIXED URL

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
        throw Exception('Failed to load deliveries');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //adverts
    List<Widget> carouselItems = [
      GestureDetector(
        onTap: () {
          context.read<IndexProvider>().setSelectedIndex(1);
        },
        child: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          decoration: BoxDecoration(
            color: Color.fromRGBO(70, 14, 0, 1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Image.asset('assets/images/advert_two.png'),
        ),
      ),
      GestureDetector(
        onTap: () {
          context.read<IndexProvider>().setSelectedIndex(1);
        },
        child: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          decoration: BoxDecoration(
            color: Color.fromRGBO(0, 70, 67, 1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Image.asset('assets/images/advert_two.png'),
        ),
      ),
      GestureDetector(
        onTap: () {
          context.read<IndexProvider>().setSelectedIndex(1);
        },
        child: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          decoration: BoxDecoration(
            color: Color.fromRGBO(70, 0, 61, 1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Image.asset('assets/images/advert_two.png'),
        ),
      ),
      GestureDetector(
        onTap: () {
          context.read<IndexProvider>().setSelectedIndex(1);
        },
        child: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          decoration: BoxDecoration(
            color: Color.fromRGBO(28, 70, 0, 1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Image.asset('assets/images/advert_two.png'),
        ),
      ),
    ];

    buildCarouselIndicator() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < carouselItems.length; i++)
            Container(
              margin: EdgeInsets.all(2),
              height: 6,
              width: i == _currentPage ? 28 : 11,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? Color.fromRGBO(0, 31, 62, 1)
                    : Color.fromRGBO(217, 217, 217, 1),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(
                  Radius.circular(4),
                ),
              ),
            )
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 255, 254),
      body: SingleChildScrollView(
        child: SafeArea(
            child: Center(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 40.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      //Select location
                      Icon(
                        Icons.place,
                        color: Color.fromRGBO(0, 31, 62, 1),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(_userLocation!)),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: GestureDetector(
                            onTap: () {
                              _initializeLocation();
                            },
                            child: Icon(Icons.add)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                //first advert slider
                Column(
                  children: [
                    CarouselSlider(
                      items: carouselItems,
                      options: CarouselOptions(
                          height: 192,
                          enlargeFactor: 0.8,
                          enlargeCenterPage: true,
                          autoPlay: true,
                          enableInfiniteScroll: true,
                          viewportFraction: 0.9,
                          autoPlayAnimationDuration: Duration(
                            microseconds: 800,
                          ),
                          onPageChanged: (value, _) {
                            setState(() {
                              _currentPage = value;
                            });
                          }),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    buildCarouselIndicator()
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

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
                        children: [
                          Column(
                            children: [
                              Image.asset(
                                'assets/images/lumber_man_2.png',
                                scale: 11,
                              ),
                            ],
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
                                          fontSize: 20.0),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: CircleAvatar(
                                        backgroundColor:
                                            Color.fromRGBO(0, 31, 62, 1),
                                        radius: 14,
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color:
                                              Color.fromRGBO(217, 217, 217, 1),
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

                const SizedBox(
                  height: 30,
                ),

                //Recent Activity
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: Color.fromRGBO(0, 31, 62, 1),
                        ),
                      ),
                      const SizedBox(height: 80),
                      _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                              color: Color.fromRGBO(0, 31, 62, 1),
                            )) // Show loading indicator
                          : _hasError
                              ? Center(
                                  child: Text(
                                      'Failed to load deliveries')) // Show error message
                              : _deliveries.isEmpty
                                  ? Center(
                                      child: Text(
                                          'No recent deliveries found')) // Show empty state
                                  : SizedBox(
                                      height:
                                          200, // Set a fixed height or use Expanded
                                      child: ListView.builder(
                                        itemCount: _deliveries.length,
                                        shrinkWrap:
                                            true, // Prevent infinite height issues
                                        physics:
                                            AlwaysScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          final delivery = _deliveries[index];
                                          return Card(
                                            elevation: 2,
                                            margin: EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: ListTile(
                                              leading: Icon(
                                                  Icons.local_shipping,
                                                  color: Colors.blue),
                                              title: Text(
                                                  'Delivery ID: ${delivery.id}'),
                                              subtitle: Text(
                                                  'Status: ${delivery.status} • Cost: \$${delivery.cost}'),
                                              trailing: Text(delivery.date),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ),
    );
  }
}

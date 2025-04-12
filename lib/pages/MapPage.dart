import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:micollins_delivery_app/components/m_buttons.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:paystack_for_flutter/paystack_for_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:micollins_delivery_app/components/ad_banner_carousel.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  LatLng? _userCurrentLocation;
  final Set<Marker> _userMarkers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<TextEditingController> _stopControllers = [];
  List<FocusNode> _stopFocusNodes = [];
  int _stopCount = 1;

  static final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.435872, 3.456507),
    zoom: 15,
  );

  String? userEmail;
  String? userId;

  final TextEditingController _promoCodeController = TextEditingController();
  bool _isPromoCodeApplied = false;
  double _promoDiscountAmount = 0.0;

  int _promoCodeUsageLimit = 3; // Maximum number of uses allowed
  int _promoCodeUsageCount =
      0; // Tracks the number of times the promo code has been used

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadUserEmail();
    _loadPromoCodeUsageCount();
  }

  bool _isInLagos(double latitude, double longitude) {
    // Define the approximate latitude and longitude boundaries of Lagos
    const double lagosMinLat = 6.4000;
    const double lagosMaxLat = 6.7000;
    const double lagosMinLng = 3.2000;
    const double lagosMaxLng = 3.6000;

    return latitude >= lagosMinLat &&
        latitude <= lagosMaxLat &&
        longitude >= lagosMinLng &&
        longitude <= lagosMaxLng;
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await _determinePosition();

      // Check if the user's location is within Lagos
      if (!_isInLagos(position.latitude, position.longitude)) {
        // Show a modern and visually appealing alert dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
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
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 31, 62, 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_off,
                        color: Color.fromRGBO(0, 31, 62, 1),
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Service Unavailable',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(0, 31, 62, 1),
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Our services are currently only available in Lagos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'We\'re working on expanding to more locations soon!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 25),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(0, 31, 62, 1),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Got it',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        return;
      }

      if (mounted) {
        setState(() {
          _userCurrentLocation = LatLng(position.latitude, position.longitude);
          _userMarkers.add(
            Marker(
              markerId: const MarkerId('user_location'),
              position: _userCurrentLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
            ),
          );
          _mapController.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: _userCurrentLocation!, zoom: 15)));
        });

        // Get address for the location
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          setState(() {
            String address = [
              placemarks.first.street,
              placemarks.first.subLocality,
              placemarks.first.locality,
            ]
                .where((element) => element != null && element.isNotEmpty)
                .join(', ');

            _startPointController.text = address;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error getting location: please enter your Pickup Address'),
            backgroundColor: const Color.fromRGBO(255, 91, 82, 1),
          ),
        );
      }
    }
  }

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

  static final String key = "AIzaSyC_Op-lSfNmmGPzKvsdImneVuL1jzYfNoM";
  final _startPointController = TextEditingController();
  final _destinationController = TextEditingController();
  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();

  final FocusNode _startPointFN = FocusNode();
  final FocusNode _endPointFN = FocusNode();

  @override
  void dispose() {
    _mapController.dispose();
    _startPointController.dispose();
    _destinationController.dispose();
    _controller1.dispose();
    _controller2.dispose();
    _startPointFN.dispose();
    _endPointFN.dispose();
    _isMounted = false;
    super.dispose();
  }

  List<LatLng> _userDestinations = []; // List to store multiple destinations

  late double _userDestinationLatDEC;

  late double _userDestinationLngDEC;

  // ignore: unused_field
  late double? _userLocationLatDEC;

  // ignore: unused_field
  late double? _userLocationLngDEC;

  final _controller1 = TextEditingController();
  // ignore: unused_field
  final _controller2 = TextEditingController();

  void _userDesToMarker(Prediction pCoordinates) {
    try {
      double destinationLat = double.parse(pCoordinates.lat!);
      double destinationLng = double.parse(pCoordinates.lng!);
      LatLng destinationLatLng = LatLng(destinationLat, destinationLng);

      if (mounted) {
        setState(() {
          _destinationController.text = pCoordinates.description ?? '';
          _userDestinations
              .add(destinationLatLng); // Add to the list of destinations
          _userMarkers.add(
            Marker(
              markerId: MarkerId('destination_${_userDestinations.length}'),
              position: destinationLatLng,
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
        });

        Future.delayed(Duration(milliseconds: 100), () {
          if (_userCurrentLocation != null) {
            _mapController.animateCamera(
              CameraUpdate.newLatLngZoom(destinationLatLng, 15),
            );
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error adding destination marker: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _userLocToMarker(Prediction pCoordinates) {
    try {
      _userLocationLatDEC = double.parse(pCoordinates.lat!);
      _userLocationLngDEC = double.parse(pCoordinates.lng!);
      if (mounted) {
        setState(() {
          _userCurrentLocation =
              LatLng(_userLocationLatDEC!, _userLocationLngDEC!);
          _userMarkers.removeWhere(
              (marker) => marker.markerId.value == 'user_location');
          _userMarkers.add(
            Marker(
              markerId: const MarkerId('user_location'),
              position: _userCurrentLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
            ),
          );
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(
              _userCurrentLocation!,
              15,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error adding pickup marker: $e');
    }
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    try {
      if (_userCurrentLocation == null || _userDestinations.isEmpty) {
        debugPrint('Current location or destinations are null');
        return polylineCoordinates;
      }

      PolylinePoints polylinePoints = PolylinePoints();
      LatLng previousPoint = _userCurrentLocation!;

      for (LatLng destination in _userDestinations) {
        PolylineResult lineResult =
            await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: key,
          request: PolylineRequest(
            origin:
                PointLatLng(previousPoint.latitude, previousPoint.longitude),
            destination:
                PointLatLng(destination.latitude, destination.longitude),
            mode: TravelMode.driving,
          ),
        );

        if (lineResult.points.isNotEmpty) {
          polylineCoordinates.addAll(lineResult.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList());
        } else {
          debugPrint('Error fetching polyline: ${lineResult.errorMessage}');
        }

        previousPoint =
            destination; // Update the previous point for the next leg
      }

      if (polylineCoordinates.isNotEmpty) {
        await _calculateDeliveryDetails(polylineCoordinates);
        generatePolylineFromPoints(polylineCoordinates);
      }
    } catch (e) {
      debugPrint('Error generating polyline: $e');
    }
    return polylineCoordinates;
  }

  void generatePolylineFromPoints(List<LatLng> polylineCordinates) {
    if (polylineCordinates.isEmpty) return;

    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Color.fromRGBO(0, 70, 67, 1),
      points: polylineCordinates,
      width: 4,
    );
    setState(() {
      polylines[id] = polyline;
    });
  }

  void _addStopToMap(Prediction prediction, int index) {
    try {
      double stopLat = double.parse(prediction.lat!);
      double stopLng = double.parse(prediction.lng!);
      LatLng stopLatLng = LatLng(stopLat, stopLng);

      setState(() {
        // Add the stop's location to the map
        _userDestinations.add(stopLatLng);
        _userMarkers.add(
          Marker(
            markerId: MarkerId('stop_${index + 1}'),
            position: stopLatLng,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
    } catch (e) {
      debugPrint('Error adding stop to map: $e');
    }
  }

  void _addStopToMapWithCoordinates(LatLng coordinates, int index) {
    try {
      setState(() {
        // Add the stop's location to the map
        _userDestinations.add(coordinates);
        _userMarkers.add(
          Marker(
            markerId: MarkerId('stop_${index + 1}'),
            position: coordinates,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
    } catch (e) {
      debugPrint('Error adding stop to map with coordinates: $e');
    }
  }

  Future<void> _calculateDeliveryDetails(
      List<LatLng> polylineCoordinates) async {
    try {
      if (_userCurrentLocation != null && _userDestinations.isNotEmpty) {
        double totalDistance = 0.0;
        LatLng previousPoint = _userCurrentLocation!;

        for (LatLng destination in _userDestinations) {
          totalDistance += Geolocator.distanceBetween(
            previousPoint.latitude,
            previousPoint.longitude,
            destination.latitude,
            destination.longitude,
          );
          previousPoint = destination;
        }

        setState(() {
          finalDistance = totalDistance / 1000; // Convert to km
          roundDistanceKM = double.parse(finalDistance.toStringAsFixed(1));

          bool isIslandToMainland = _isIslandToMainland(
            _userCurrentLocation!.latitude,
            _userCurrentLocation!.longitude,
            _userDestinations.last.latitude,
            _userDestinations.last.longitude,
          );

          const double markdown = 0.96;
          final double surge = _isPeakHour() ? 1.3 : 1.0;

          // Base fares (₦)
          final baseFares = {
            'bike': 300.0,
            'car': 500.0,
            'bus': 700.0,
            'truck': 1000.0,
          };

          // Per km rates (₦)
          final perKmRates = isIslandToMainland
              ? {
                  'bike': 130.0,
                  'car': 160.0,
                  'bus': 110.0,
                  'truck': 250.0,
                }
              : {
                  'bike': 120.0,
                  'car': 150.0,
                  'bus': 180.0,
                  'truck': 220.0,
                };

          // Fare calculator with dynamic minimum brackets
          double calculateFare(
              double km, double baseFare, double rate, String vehicleType) {
            const double markdown = 0.96;
            final double surge = _isPeakHour() ? 1.3 : 1.0;

            // Use higher rates for distances below 7.5 km
            if (km < 7.5) {
              if (vehicleType == 'bike') {
                rate *= 2.2; // Use 2.2 multiplier for bikes
              } else if (vehicleType == 'car') {
                rate *= 3.2; // Use 3.2 multiplier for cars
              } else if (vehicleType == 'bus') {
                rate *= 5.2; // Use 3.2 multiplier for cars
              } else if (vehicleType == 'truck') {
                rate *= 8.2; // Use 3.2 multiplier for cars
              }
            } else if (km > 10.5) {
              if (vehicleType == 'bike') {
                rate *= 1.8; // Use 2.2 multiplier for bikes
              } else if (vehicleType == 'car') {
                rate *= 2.4; // Use 3.2 multiplier for cars
              } else if (vehicleType == 'bus') {
                rate *= 3.2; // Use 3.2 multiplier for cars
              } else if (vehicleType == 'truck') {
                rate *= 4.6; // Use 3.2 multiplier for cars
              }
            }

            double price = (baseFare + (km * rate)) * markdown * surge;

            // Regular minimum fare for longer trips
            return price < 1000 ? 1000 : price;
          }

          // Fare breakdown
          // Fare breakdown
          expressCost = calculateFare(
              roundDistanceKM, baseFares['bike']!, perKmRates['bike']!, 'bike');
          standardCost = calculateFare(roundDistanceKM, baseFares['bike']!,
              perKmRates['bike']! / 1.8, 'bike');
          carExpressCost = calculateFare(
              roundDistanceKM, baseFares['car']!, perKmRates['car']!, 'car');
          carStandardCost = calculateFare(roundDistanceKM, baseFares['car']!,
              perKmRates['car']! / 1.8, 'car');
          busCost = calculateFare(
              roundDistanceKM, baseFares['bus']!, perKmRates['bus']!, 'bus');
          truckCost = calculateFare(roundDistanceKM, baseFares['truck']!,
              perKmRates['truck']!, 'truck');

          // Format results for display
          standardFormatted = formatMoney(standardCost);
          expressFormatted = formatMoney(expressCost);
          carExpressFormatted = formatMoney(carExpressCost);
          carStandardFormatted = formatMoney(carStandardCost);
          busFormatted = formatMoney(busCost);
          truckFormatted = formatMoney(truckCost);
          size50Formatted = formatMoney(packageSize50Price);
          size75Formatted = formatMoney(packageSize75Price);
          size100Formatted = formatMoney(packageSize100Price);
        });
      }
    } catch (e) {
      debugPrint('Error calculating delivery details: $e');
    }
  }

// Example helper to check if it's peak time
  bool _isPeakHour() {
    final now = DateTime.now();
    final hour = now.hour;
    return (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 20);
  }

  bool _isIslandToMainland(
      double startLat, double startLng, double endLat, double endLng) {
    bool isStartOnIsland = startLat >= 6.41 &&
        startLat <= 6.46 &&
        startLng >= 3.39 &&
        startLng <= 3.44;

    bool isEndOnMainland =
        endLat >= 6.50 && endLat <= 6.60 && endLng >= 3.30 && endLng <= 3.40;

    return isStartOnIsland && isEndOnMainland;
  }

  MoneyFormatterOutput formatMoney(double amount) {
    return MoneyFormatter(
      amount: amount,
      settings: MoneyFormatterSettings(
        symbol: '₦',
        thousandSeparator: ',',
        decimalSeparator: '.',
        symbolAndNumberSeparator: ' ',
        fractionDigits: 0,
        compactFormatType: CompactFormatType.short,
      ),
    ).output;
  }

  double _getDeliveryCost() {
    if (selectedVehicleType == "car") {
      return isExpressSelected! ? carExpressCost : carStandardCost;
    } else if (selectedVehicleType == "bus") {
      return isExpressSelected! ? truckCost : busCost;
    } else {
      return isExpressSelected! ? expressCost : standardCost;
    }
  }

  double _getPackagePrice() {
    double packagePrice = 0;

    if (is25Selected) {
      packagePrice = packageSize25Price;
    } else if (is50Selected) {
      packagePrice = packageSize50Price;
    } else if (is75Selected) {
      packagePrice = packageSize75Price;
    } else if (is100Selected) {
      packagePrice = packageSize100Price;
    }
    print(packagePrice);
    return packagePrice;
  }

  void confirmOrder(BuildContext ctx) {
    _modeOfPayment();
  }

  void _modeOfPayment() {
    showDialog(
      context: context,
      builder: (context) {
        bool dialogIsCashorTransfer = isCashorTransfer;
        bool dialogIsOnlinePayment = isOnlinePayment;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(0, 31, 62, 1),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cash payment option
                    _buildPaymentOptionCard(
                      title: 'Cash Payment',
                      subtitle: 'Pay with cash on delivery',
                      icon: Icons.money,
                      isSelected: dialogIsCashorTransfer,
                      onTap: () {
                        setDialogState(() {
                          dialogIsCashorTransfer = true;
                          dialogIsOnlinePayment = false;
                        });
                      },
                    ),

                    const SizedBox(height: 12.0),

                    // Online payment option
                    _buildPaymentOptionCard(
                      title: 'Online Payment',
                      subtitle: 'Pay with card or bank transfer',
                      icon: Icons.credit_card,
                      isSelected: dialogIsOnlinePayment,
                      onTap: () {
                        setDialogState(() {
                          dialogIsOnlinePayment = true;
                          dialogIsCashorTransfer = false;
                        });
                      },
                    ),

                    const SizedBox(height: 20.0),

                    // Process order button
                    Container(
                      width: double.infinity,
                      child: MButtons(
                        onTap: () {
                          setState(() {
                            isCashorTransfer = dialogIsCashorTransfer;
                            isOnlinePayment = dialogIsOnlinePayment;
                          });
                          _processPayment();
                        },
                        btnText: 'Process Order',
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

  Widget _buildPackageSizeOption({
    required String size,
    required String description,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color.fromRGBO(0, 31, 62, 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Color.fromRGBO(0, 31, 62, 1)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color.fromRGBO(0, 31, 62, 1)
                    : Color.fromRGBO(0, 31, 62, 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                size,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected ? Colors.white : Color.fromRGBO(0, 31, 62, 1),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(0, 31, 62, 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color.fromRGBO(0, 31, 62, 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Color.fromRGBO(0, 31, 62, 1)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color.fromRGBO(0, 31, 62, 1)
                    : Color.fromRGBO(0, 31, 62, 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Color.fromRGBO(0, 31, 62, 1),
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(0, 31, 62, 1),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Color.fromRGBO(0, 31, 62, 1) : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? Color.fromRGBO(0, 31, 62, 1)
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleOption(
      {required IconData icon,
      required String label,
      required bool isSelected}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Color.fromRGBO(0, 31, 62, 1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSelected ? Color.fromRGBO(0, 31, 62, 1) : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Color.fromRGBO(0, 31, 62, 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey.shade700,
            size: 28,
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    String? cost,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Color.fromRGBO(0, 31, 62, 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSelected ? Color.fromRGBO(0, 31, 62, 1) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Color.fromRGBO(0, 31, 62, 1)
                  : Color.fromRGBO(0, 31, 62, 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Color.fromRGBO(0, 31, 62, 1),
              size: 20,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color.fromRGBO(0, 31, 62, 1),
            ),
          ),
          SizedBox(height: 4),
          Text(
            cost ?? "₦0",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment() async {
    if (!_isMounted) return;

    if (isCashorTransfer == true && isOnlinePayment == false) {
      FocusManager.instance.primaryFocus?.unfocus();

      // Close the payment dialog first
      Navigator.of(context).pop();

      // Call submit delivery function for cash/transfer payments
      // This will show the success modal
      await _submitDelivery();

      // Navigation to orders page will happen in the success modal's OK button
    } else if (isOnlinePayment == true && isCashorTransfer == false) {
      if (userEmail == null || userEmail!.isEmpty) {
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User email not found'),
              backgroundColor: Color.fromRGBO(255, 91, 82, 1),
            ),
          );
        }
        return;
      }

      try {
        if (!_isMounted) return;

        PaystackFlutter().pay(
          context: context,
          secretKey: 'sk_test_c69312cc47b0d93bd17d0407d4292f11ee38e2fb',
          amount: paymentParameter * 100,
          email: userEmail!,
          callbackUrl: 'https://callback.com',
          showProgressBar: true,
          paymentOptions: [
            PaymentOption.card,
            PaymentOption.bankTransfer,
            PaymentOption.mobileMoney,
          ],
          currency: Currency.NGN,
          metaData: {
            "start_point": _startPointController.text,
            "end_point": _destinationController.text,
            "delivery_price": paymentAmt,
          },
          onSuccess: (paystackCallback) {
            if (!_isMounted) return;

            // Log the successful transaction details
            debugPrint('💳 PAYMENT SUCCESSFUL');
            debugPrint(
                '📝 Transaction Reference: ${paystackCallback.reference}');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Transaction Successful: ${paystackCallback.reference}'),
                backgroundColor: Color.fromRGBO(0, 31, 62, 1),
              ),
            );
            FocusManager.instance.primaryFocus?.unfocus();

            // Close the payment dialog first
            Navigator.of(context).pop();

            // Call submit delivery function after successful payment
            // This will show the success modal
            _submitDelivery(
              paymentReference: paystackCallback.reference,
              paymentStatus: 'paid',
              paymentDate: DateTime.now().toIso8601String(),
              amountPaid: paymentAmt,
            );
          },
          onCancelled: (paystackCallback) {
            if (!_isMounted) return;

            // Log the failed transaction details
            debugPrint('❌ PAYMENT FAILED');
            debugPrint(
                '📝 Transaction Reference: ${paystackCallback.reference}');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Transaction Failed: ${paystackCallback.reference}'),
                backgroundColor: Color.fromRGBO(255, 91, 82, 1),
              ),
            );
          },
        );
      } catch (e) {
        debugPrint('❌ Payment error: $e');
      }
    } else {
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a mode of Payment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String selectedVehicleType = "bike"; // Default selection

  bool _isMounted = true;

  Future<void> _submitDelivery({
    String? paymentReference,
    String? paymentStatus,
    String? paymentDate,
    double? amountPaid,
  }) async {
    if (!_isMounted) return;

    try {
      // Ensure the user is logged in
      if (userId == null || userId!.isEmpty) {
        if (_isMounted) {
          _showErrorSnackbar('Error: User ID not found. Please log in again.');
        }
        return;
      }

      // Determine the correct API endpoint based on vehicle type
      final Map<String, String> endpoints = {
        "bike": "https://deliveryapi-ten.vercel.app/delivery/bike",
        "car": "https://deliveryapi-ten.vercel.app/delivery/car",
        "bus-truck": "https://deliveryapi-ten.vercel.app/delivery/bus-truck"
      };

      final String? endpoint = endpoints[selectedVehicleType];
      if (endpoint == null) {
        throw Exception("Invalid vehicle type selected");
      }

      // Round payment amount to avoid decimal issues
      final double roundedPrice = double.parse(paymentAmt.toStringAsFixed(2));

      // Extract stops from controllers
      List<String> stops = _stopControllers
          .map((controller) => controller.text.trim())
          .where((stop) => stop.isNotEmpty)
          .toList();

      // Ensure `endpoint` is taken from the destination controller, NOT stops
      final String finalDestination = _destinationController.text.trim();

      // Remove the final destination from the stops list if it exists
      stops.remove(finalDestination);

      // Debugging: Log values to check what's being sent
      debugPrint('🛑 Stops List: $stops');
      debugPrint('📍 Final Destination (Endpoint): $finalDestination');

      // Prepare request payload
      final Map<String, dynamic> requestBody = {
        'user_id': userId,
        'price': roundedPrice,
        'distance': '$roundDistanceKM km',
        'startpoint': _startPointController.text.trim(),
        'endpoint': finalDestination,
        'stops': stops,
        'vehicletype': selectedVehicleType,
        'transactiontype': isCashorTransfer ? 'cash' : 'online',
        'deliveryspeed': isExpressSelected! ? 'express' : 'standard',
        'status': {'deliverystatus': 'pending', 'orderstatus': 'pending'}
      };

      // Add package size only for bike deliveries
      if (selectedVehicleType == "bike") {
        requestBody['packagesize'] = _getPackageSize();
      }

      debugPrint('🚀 Sending delivery request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody),
      );

      debugPrint(
          '📩 Server Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 && _isMounted) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Extract delivery ID using a cleaner approach
        final String deliveryId = responseData['_id'] ??
            responseData['delivery_id'] ??
            responseData['delivery']?['_id'] ??
            '';

        if (deliveryId.isNotEmpty) {
          debugPrint('✅ Delivery created successfully with ID: $deliveryId');

          // Ensure payment details are correctly set
          final actualPaymentStatus =
              paymentStatus ?? (isCashorTransfer ? 'pending' : 'paid');
          final actualPaymentReference = paymentReference ?? '';
          final actualPaymentDate =
              paymentDate ?? DateTime.now().toIso8601String();
          final actualAmountPaid =
              amountPaid ?? (isCashorTransfer ? 0.0 : roundedPrice);

          debugPrint('💰 Updating payment details:');
          debugPrint('   - Payment status: $actualPaymentStatus');
          debugPrint('   - Payment reference: $actualPaymentReference');
          debugPrint('   - Payment date: $actualPaymentDate');
          debugPrint('   - Amount paid: $actualAmountPaid');

          // Update transaction information
          await _updateTransactionInfo(
            deliveryId: deliveryId,
            transactionType: isCashorTransfer ? 'cash' : 'online',
            paymentStatus: actualPaymentStatus,
            paymentReference: actualPaymentReference,
            paymentDate: actualPaymentDate,
            amountPaid: actualAmountPaid,
          );

          // Show success confirmation
          _showSuccessModal(context);
        } else {
          debugPrint('❌ ERROR: Empty delivery ID received from server.');
          debugPrint('📄 Full response: ${response.body}');
        }
      } else {
        _showErrorSnackbar('Failed to create delivery: ${response.body}');
      }
    } catch (e) {
      debugPrint('🚨 Error creating delivery: $e');
      _showErrorSnackbar('Error creating delivery: $e');
    }
  }

  /// Helper function to show error messages
  void _showErrorSnackbar(String message) {
    if (_isMounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateTransactionInfo({
    required String deliveryId,
    required String transactionType,
    required String paymentStatus,
    required String paymentReference,
    required String paymentDate,
    required double amountPaid,
  }) async {
    // Check if widget is still mounted before proceeding
    if (!_isMounted) {
      debugPrint('Skipping transaction update - widget no longer mounted');
      return;
    }

    try {
      final String endpoint =
          'https://deliveryapi-ten.vercel.app/delivery/$deliveryId/transaction';

      debugPrint('🔄 Updating transaction for delivery ID: $deliveryId');
      debugPrint('🔗 Transaction endpoint: $endpoint');

      // Log payment details for debugging
      debugPrint('💰 Payment details being sent:');
      debugPrint('   - Transaction type: $transactionType');
      debugPrint('   - Payment status: $paymentStatus');
      debugPrint(
          '   - Payment reference: ${paymentReference.isNotEmpty ? paymentReference : "None"}');
      debugPrint(
          '   - Payment date: ${paymentDate.isNotEmpty ? paymentDate : "None"}');
      debugPrint(
          '   - Amount paid: ${amountPaid > 0 ? amountPaid.toString() : "None"}');

      // Create the request body with the exact structure expected by the API
      final Map<String, dynamic> requestBody = {
        'transaction_type': transactionType,
        'payment_status': paymentStatus,
      };

      // Only add these fields if they have values (for online payments)
      if (paymentReference.isNotEmpty) {
        requestBody['payment_reference'] = paymentReference;
      }

      if (paymentDate.isNotEmpty) {
        requestBody['payment_date'] = paymentDate;
      }

      if (amountPaid > 0) {
        requestBody['amount_paid'] = amountPaid;
      }

      debugPrint('📦 Transaction request body: ${jsonEncode(requestBody)}');

      // Add a timeout to the HTTP request to prevent hanging
      final response = await http
          .put(
        Uri.parse(endpoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(Duration(seconds: 30), onTimeout: () {
        debugPrint('⏱️ Transaction update request timed out');
        return http.Response('{"error": "Request timed out"}', 408);
      });

      debugPrint('📊 Transaction Update Response Code: ${response.statusCode}');
      debugPrint('📄 Transaction Update Response Body: ${response.body}');

      // Check if widget is still mounted before processing response
      if (!_isMounted) {
        debugPrint('Widget no longer mounted after transaction update');
        return;
      }

      if (response.statusCode == 200) {
        debugPrint('✅ TRANSACTION UPDATED SUCCESSFULLY');
        // Parse the response to verify the update
        final responseData = jsonDecode(response.body);

        // Show a more detailed log of the updated transaction
        if (responseData.containsKey('updated_data')) {
          debugPrint('📝 Updated transaction details:');
          final updatedData = responseData['updated_data'];
          if (updatedData is Map) {
            updatedData.forEach((key, value) {
              debugPrint('   - $key: $value');
            });
          } else {
            debugPrint('   $updatedData');
          }
        } else {
          debugPrint('📝 Response data: $responseData');
        }

        // Show a user-visible notification for successful transaction update
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment information updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('❌ FAILED TO UPDATE TRANSACTION: ${response.body}');

        // Show a user-visible notification for failed transaction update
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update payment information'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ ERROR UPDATING TRANSACTION: $e');

      // Show a user-visible notification for transaction update error
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating payment information: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Modern success modal
  void _showSuccessModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 31, 62, 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Color.fromRGBO(0, 31, 62, 1),
                    size: 50,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Success!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(0, 31, 62, 1),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Your delivery request has been submitted successfully.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "A rider will reach out to you shortly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog

                      // Clear form fields
                      setState(() {
                        _startPointController.clear();
                        _destinationController.clear();
                        _userMarkers.clear();
                        polylines.clear();
                        roundDistanceKM = 0;
                      });

                      // Navigate to the OrdersPage
                      Provider.of<IndexProvider>(context, listen: false)
                          .setSelectedIndex(1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(0, 31, 62, 1),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPackageSize() {
    if (is25Selected) {
      return 'Quarter and below';
    } else if (is50Selected) {
      return 'Half to quarter';
    } else if (is75Selected) {
      return '3 quarter to half';
    } else if (is100Selected) {
      return 'Full to 3 quarter';
    }
    return 'Quarter and below'; // Default
  }

  var finalDistance;
  var roundDistanceKM;
  bool? isExpressSelected = false;
  bool? isStandardSelected = false;

  bool isCashorTransfer = false;
  bool isOnlinePayment = false;

  bool is25Selected = false;
  bool is50Selected = false;
  bool is75Selected = false;
  bool is100Selected = false;

  double packageSize25Price = 0;
  double packageSize50Price = 250;
  double packageSize75Price = 500;
  double packageSize100Price = 750;

  double expressCost = 0;
  double standardCost = 0;
  double carExpressCost = 0;
  double carStandardCost = 0;
  double busCost = 0;
  double truckCost = 0;

  MoneyFormatterOutput? standardFormatted;
  MoneyFormatterOutput? expressFormatted;
  MoneyFormatterOutput? carStandardFormatted;
  MoneyFormatterOutput? carExpressFormatted;
  MoneyFormatterOutput? busFormatted;
  MoneyFormatterOutput? truckFormatted;
  MoneyFormatterOutput? size25Formatted;
  MoneyFormatterOutput? size50Formatted;
  MoneyFormatterOutput? size75Formatted;
  MoneyFormatterOutput? size100Formatted;

  double get paymentAmt {
    double total = _getDeliveryCost() + _getPackagePrice();
    if (_isPromoCodeApplied) {
      total -= _promoDiscountAmount; // Subtract the promo discount
    }
    return total;
  }

  void _applyPromoCode() {
    const List<String> validPromoCodes = [
      "SAVE10",
      "MICOSTARTDATE"
    ]; // List of valid promo codes

    if (_promoCodeUsageCount >= _promoCodeUsageLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Promo code usage limit reached."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if the entered promo code exists in the validPromoCodes list
    if (validPromoCodes
        .contains(_promoCodeController.text.trim().toUpperCase())) {
      setState(() {
        _isPromoCodeApplied = true;
        _promoDiscountAmount = paymentAmt * 0.1; // Apply 10% discount
        _promoCodeUsageCount++; // Increment the usage count
      });
      _savePromoCodeUsageCount(); // Save the updated usage count
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Promo code applied successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _isPromoCodeApplied = false;
        _promoDiscountAmount = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid promo code."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePromoCodeUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('promoCodeUsageCount', _promoCodeUsageCount);
  }

  Future<void> _loadPromoCodeUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _promoCodeUsageCount = prefs.getInt('promoCodeUsageCount') ?? 0;
    });
  }

  String get formattedPaymentAmt => formatMoney(paymentAmt).symbolOnLeft;
  int get paymentParameter => (paymentAmt).toInt();

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required Function(Prediction) onItemClick,
    required Function(Prediction) onGetDetailWithLatLng,
    bool isPickupField = false,
  }) {
    return StatefulBuilder(builder: (context, setState) {
      // Remove the listener setup from here

      return Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: GooglePlaceAutoCompleteTextField(
          focusNode: focusNode,
          textEditingController: controller,
          debounceTime: 600,
          googleAPIKey: key,
          isLatLngRequired: true,
          countries: isPickupField ? ['ng'] : null,
          getPlaceDetailWithLatLng: onGetDetailWithLatLng,
          itemClick: onItemClick,
          inputDecoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.transparent),
            ),
            prefixIcon: Icon(
              Icons.location_on_rounded,
              color: Color.fromRGBO(0, 31, 62, 1),
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                    },
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      );
    });
  }

  Future<void> _loadUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get user ID directly from the dedicated key
      userId = prefs.getString('user_id');
      userEmail = prefs.getString('email');

      // Fallback to extracting from the full user object if direct keys are not available
      if (userId == null || userEmail == null) {
        final userString = prefs.getString('user');
        if (userString != null) {
          final userData = json.decode(userString);
          if (_isMounted) {
            setState(() {
              userEmail = userData['email'] ?? '';
              userId = userData['_id'];
            });
          }
        }
      } else if (_isMounted) {
        setState(() {
          // Variables already set from direct keys
        });
      }

      debugPrint('Loaded User ID: $userId');
      debugPrint('Loaded User Email: $userEmail');
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                12, 12, 12, MediaQuery.of(context).padding.bottom),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: GoogleMap(
                initialCameraPosition: _initialPosition,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  if (_userCurrentLocation != null) {
                    _mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(_userCurrentLocation!, 15),
                    );
                  }
                },
                markers: _userMarkers,
                polylines: Set<Polyline>.of(polylines.values),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'location_button',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (_userCurrentLocation != null) {
                      _mapController.animateCamera(
                        CameraUpdate.newLatLngZoom(_userCurrentLocation!, 15),
                      );
                    }
                  },
                  child: Icon(
                    Icons.my_location_rounded,
                    color: Color.fromRGBO(0, 31, 62, 1),
                  ),
                ),
                SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in_button',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    _mapController.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: Icon(
                    Icons.add,
                    color: Color.fromRGBO(0, 31, 62, 1),
                  ),
                ),
                SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out_button',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    _mapController.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: Icon(
                    Icons.remove,
                    color: Color.fromRGBO(0, 31, 62, 1),
                  ),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            controller: _bottomSheetController,
            maxChildSize: 0.9,
            initialChildSize: 0.4,
            minChildSize: 0.25,
            builder: (BuildContext context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 12),
                        height: 5,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      // Ad Carousel Banner with improved styling
                      AdBannerCarousel(),

                      // Vehicle Type Selection
                      Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Vehicle Type",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color.fromRGBO(0, 31, 62, 1),
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isStandardSelected = true;
                                        isExpressSelected = false;
                                        selectedVehicleType = "bike";
                                        is25Selected = true;
                                        is50Selected = is75Selected =
                                            is100Selected = false;
                                      });
                                    },
                                    child: _buildVehicleOption(
                                      icon: Icons.motorcycle,
                                      label: "Bike",
                                      isSelected: selectedVehicleType == "bike",
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isExpressSelected = true;
                                        isStandardSelected = false;
                                        selectedVehicleType = "car";
                                        is25Selected = true;
                                        is50Selected = is75Selected =
                                            is100Selected = false;
                                      });
                                    },
                                    child: _buildVehicleOption(
                                      icon: Icons.directions_car,
                                      label: "Car",
                                      isSelected: selectedVehicleType == "car",
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedVehicleType = "bus";
                                        isStandardSelected = true;
                                        isExpressSelected = false;
                                        is25Selected = true;
                                        is50Selected = is75Selected =
                                            is100Selected = false;
                                      });
                                    },
                                    child: _buildVehicleOption(
                                      icon: Icons.local_shipping,
                                      label: "Bus/Truck",
                                      isSelected: selectedVehicleType == "bus",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Input fields for pickup and destination
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Pickup Location Input Field
                            _buildInputField(
                              controller: _startPointController,
                              focusNode: _startPointFN,
                              hintText: 'Pickup Location',
                              isPickupField: true,
                              onItemClick: (prediction) async {
                                setState(() {
                                  _startPointController.text =
                                      prediction.description!;
                                  _startPointController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                        offset: prediction.description!.length),
                                  );

                                  // Reset roundDistanceKM if the pickup location is empty
                                  if (_startPointController.text.isEmpty ||
                                      _destinationController.text.isEmpty) {
                                    roundDistanceKM = 0;
                                    _userMarkers.clear();
                                    polylines.clear();
                                  }
                                });
                              },
                              onGetDetailWithLatLng: (cordinatesCus) {
                                _userLocToMarker(cordinatesCus);
                                getPolylinePoints().then(
                                  (cordinates) =>
                                      generatePolylineFromPoints(cordinates),
                                );
                              },
                            ),

                            // Destination Location Input Field
                            _buildInputField(
                              controller: _destinationController,
                              focusNode: _endPointFN,
                              hintText: 'Destination Location',
                              onItemClick: (prediction) async {
                                setState(() {
                                  _destinationController.text =
                                      prediction.description!;
                                  _destinationController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                        offset: prediction.description!.length),
                                  );

                                  // Reset roundDistanceKM if either pickup or delivery is empty
                                  if (_startPointController.text.isEmpty ||
                                      _destinationController.text.isEmpty) {
                                    roundDistanceKM = 0;
                                    _userMarkers.clear();
                                    polylines.clear();
                                  }
                                });
                                _userDesToMarker(prediction);
                              },
                              onGetDetailWithLatLng: (coordinates) {
                                _userDesToMarker(coordinates);

                                // Reset roundDistanceKM if either pickup or delivery is empty
                                if (_startPointController.text.isEmpty ||
                                    _destinationController.text.isEmpty) {
                                  setState(() {
                                    roundDistanceKM = 0;
                                    _userMarkers.clear();
                                    polylines.clear();
                                  });
                                } else {
                                  getPolylinePoints().then(
                                    (cordinates) =>
                                        generatePolylineFromPoints(cordinates),
                                  );
                                }
                              },
                            ),
                            // Dynamically added stops
                            ...List.generate(_stopControllers.length, (index) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      // Stop input field
                                      Expanded(
                                        child: _buildInputField(
                                          controller: _stopControllers[index],
                                          focusNode: _stopFocusNodes[index],
                                          hintText:
                                              'Stop ${index + 2}', // Hint text starts at Stop 2
                                          onItemClick: (prediction) {
                                            setState(() {
                                              // Update only the selected stop's controller
                                              _stopControllers[index].text =
                                                  prediction.description!;
                                              _stopControllers[index]
                                                      .selection =
                                                  TextSelection.fromPosition(
                                                TextPosition(
                                                    offset: prediction
                                                        .description!.length),
                                              );
                                            });
                                            // Add the stop's location to the map
                                            _addStopToMap(prediction, index);
                                          },
                                          onGetDetailWithLatLng: (coordinates) {
                                            // Add the stop's location to the map
                                            LatLng stopCoordinates = LatLng(
                                              double.parse(coordinates.lat!),
                                              double.parse(coordinates.lng!),
                                            );
                                            _addStopToMapWithCoordinates(
                                                stopCoordinates, index);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Delete button
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            // Remove the stop controller and focus node
                                            _stopControllers.removeAt(index);
                                            _stopFocusNodes.removeAt(index);

                                            // Optionally, remove the corresponding marker and recalculate the route
                                            if (index <
                                                _userDestinations.length) {
                                              _userDestinations.removeAt(index);
                                              getPolylinePoints().then(
                                                (coordinates) =>
                                                    generatePolylineFromPoints(
                                                        coordinates),
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // Increment the stop count and add a new controller and focus node
                            _stopCount++;
                            _stopControllers.add(TextEditingController());
                            _stopFocusNodes.add(FocusNode());
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(16),
                        ),
                        child: Icon(
                          Icons.add_location_alt_rounded,
                          color: Color.fromRGBO(0, 31, 62, 1),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        "Add more stops",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color.fromRGBO(0, 31, 62, 1),
                        ),
                      ),

                      // Delivery details and options
                      FutureBuilder(
                        future: getPolylinePoints(),
                        builder: (deliveryDetails, snapshot) {
                          if (snapshot.hasData) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Column(
                                children: [
                                  // Distance and location info with improved design
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          // Distance display
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Color.fromRGBO(
                                                      0, 31, 62, 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.route,
                                                  color: Color.fromRGBO(
                                                      0, 31, 62, 1),
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Distance',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    '${roundDistanceKM ?? 0} Km',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color.fromRGBO(
                                                          0, 31, 62, 1),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Spacer(),
                                              if (roundDistanceKM != null &&
                                                  roundDistanceKM != 0)
                                                IconButton(
                                                  icon: Icon(Icons.refresh,
                                                      color: Colors.grey),
                                                  onPressed: () {
                                                    setState(() {
                                                      roundDistanceKM = 0;
                                                      _userMarkers.clear();
                                                      polylines.clear();
                                                      _startPointController
                                                          .clear();
                                                      _destinationController
                                                          .clear();
                                                    });
                                                  },
                                                ),
                                            ],
                                          ),

                                          Divider(
                                              height: 24,
                                              color: Colors.grey.shade200),

                                          // Pickup location
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Color.fromRGBO(
                                                      0, 31, 62, 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.my_location,
                                                  color: Color.fromRGBO(
                                                      0, 31, 62, 1),
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Pickup',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      _startPointController
                                                              .text.isEmpty
                                                          ? 'Select pickup location'
                                                          : _startPointController
                                                              .text,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Color.fromRGBO(
                                                            0, 31, 62, 1),
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 16),

                                          // Destination location
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Color.fromRGBO(
                                                      0, 31, 62, 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.location_on,
                                                  color: Color.fromRGBO(
                                                      0, 31, 62, 1),
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Destination',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      _destinationController
                                                              .text.isEmpty
                                                          ? 'Select destination location'
                                                          : _destinationController
                                                              .text,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Color.fromRGBO(
                                                            0, 31, 62, 1),
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Delivery Type Selection
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Delivery Type",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color.fromRGBO(0, 31, 62, 1),
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    isExpressSelected = true;
                                                    isStandardSelected = false;
                                                  });
                                                },
                                                child: _buildDeliveryOption(
                                                  icon: selectedVehicleType ==
                                                          "bus"
                                                      ? Icons
                                                          .local_shipping // Truck icon for Express
                                                      : Icons
                                                          .flash_on, // Default express icon
                                                  label: selectedVehicleType ==
                                                          "bus"
                                                      ? "Truck" // Change label if Bus is selected
                                                      : "Express",
                                                  isSelected:
                                                      isExpressSelected ??
                                                          false,
                                                  cost: selectedVehicleType ==
                                                          "car"
                                                      ? carExpressFormatted
                                                          ?.symbolOnLeft
                                                      : selectedVehicleType ==
                                                              "bus"
                                                          ? truckFormatted
                                                              ?.symbolOnLeft // Use truck cost
                                                          : expressFormatted
                                                              ?.symbolOnLeft,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    isStandardSelected = true;
                                                    isExpressSelected = false;
                                                  });
                                                },
                                                child: _buildDeliveryOption(
                                                  icon: selectedVehicleType ==
                                                          "bus"
                                                      ? Icons
                                                          .directions_bus // Bus icon for Standard
                                                      : Icons
                                                          .pedal_bike, // Default standard icon
                                                  label: selectedVehicleType ==
                                                          "bus"
                                                      ? "Bus" // Change label if Bus is selected
                                                      : "Standard",
                                                  isSelected:
                                                      isStandardSelected ??
                                                          false,
                                                  cost: selectedVehicleType ==
                                                          "car"
                                                      ? carStandardFormatted
                                                          ?.symbolOnLeft
                                                      : selectedVehicleType ==
                                                              "bus"
                                                          ? busFormatted
                                                              ?.symbolOnLeft // Use bus cost
                                                          : standardFormatted
                                                              ?.symbolOnLeft,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Package Size Selection
                                  // Package Size Selection
                                  if (selectedVehicleType == "bike")
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Select Package Size",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  Color.fromRGBO(0, 31, 62, 1),
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Expanded(
                                                child: _buildPackageSizeOption(
                                                  size: "¼",
                                                  description:
                                                      "Quarter and below of delivery box",
                                                  price: size25Formatted
                                                          ?.symbolOnLeft ??
                                                      "₦0",
                                                  isSelected: is25Selected,
                                                  onTap: () {
                                                    setState(() {
                                                      is25Selected = true;
                                                      is50Selected = false;
                                                      is75Selected = false;
                                                      is100Selected = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: _buildPackageSizeOption(
                                                  size: "½",
                                                  description:
                                                      "Half to quarter of delivery box",
                                                  price: size50Formatted
                                                          ?.symbolOnLeft ??
                                                      "₦250",
                                                  isSelected: is50Selected,
                                                  onTap: () {
                                                    setState(() {
                                                      is25Selected = false;
                                                      is50Selected = true;
                                                      is75Selected = false;
                                                      is100Selected = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: _buildPackageSizeOption(
                                                  size: "¾",
                                                  description:
                                                      "3 quarter to half of delivery box",
                                                  price: size75Formatted
                                                          ?.symbolOnLeft ??
                                                      "₦500",
                                                  isSelected: is75Selected,
                                                  onTap: () {
                                                    setState(() {
                                                      is25Selected = false;
                                                      is50Selected = false;
                                                      is75Selected = true;
                                                      is100Selected = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: _buildPackageSizeOption(
                                                  size: "F",
                                                  description:
                                                      "Full to 3 quarter of delivery box",
                                                  price: size100Formatted
                                                          ?.symbolOnLeft ??
                                                      "₦750",
                                                  isSelected: is100Selected,
                                                  onTap: () {
                                                    setState(() {
                                                      is25Selected = false;
                                                      is50Selected = false;
                                                      is75Selected = false;
                                                      is100Selected = true;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 30),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Enter Promo Code",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color.fromRGBO(0, 31, 62, 1),
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          "Promo code uses remaining: ${_promoCodeUsageLimit - _promoCodeUsageCount}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller:
                                                    _promoCodeController,
                                                decoration: InputDecoration(
                                                  hintText: "Enter promo code",
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color.fromRGBO(
                                                          0, 31, 62, 1),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                _applyPromoCode();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color.fromRGBO(
                                                    0, 31, 62, 1),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text("Apply"),
                                            ),
                                          ],
                                        ),
                                        if (_isPromoCodeApplied)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              "Promo code applied! You saved ₦${_promoDiscountAmount.toStringAsFixed(2)}",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 20),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        confirmOrder(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Color.fromRGBO(0, 31, 62, 1),
                                        foregroundColor: Colors.white,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8), // Reduced border radius
                                        ),
                                      ),
                                      child: Text(
                                        'Confirm Order(${formatMoney(paymentAmt).symbolOnLeft})',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          } else {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 60.0),
                                child: CircularProgressIndicator(
                                  color: Color.fromRGBO(0, 31, 62, 1),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

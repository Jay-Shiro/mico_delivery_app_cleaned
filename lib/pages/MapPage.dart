// ignore: file_names
// ignore_for_file: unused_local_variable

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:micollins_delivery_app/components/bike_delivery_options_prompt.dart';
import 'package:micollins_delivery_app/components/car_delivery_options_prompt.dart';
import 'package:micollins_delivery_app/components/m_buttons.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.435872, 3.456507),
    zoom: 15,
  );

  String? userEmail;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadUserEmail();
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await _determinePosition();

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
            content: Text('Error getting location: $e'),
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
    super.dispose();
  }

  LatLng? _userDestinationLatLng;

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
      // First check if we have valid coordinates
      //if (pCoordinates.lat == null || pCoordinates.lng == null) {
      //debugPrint('Invalid coordinates in prediction');
      //return;
      //}

      // Parse coordinates
      _userDestinationLatDEC = double.parse(pCoordinates.lat!);
      _userDestinationLngDEC = double.parse(pCoordinates.lng!);

      if (mounted) {
        setState(() {
          // Update destination text first
          _destinationController.text = pCoordinates.description ?? '';

          // Create the LatLng object
          _userDestinationLatLng =
              LatLng(_userDestinationLatDEC, _userDestinationLngDEC);

          // Update markers
          _userMarkers
              .removeWhere((marker) => marker.markerId.value == 'destination');
          _userMarkers.add(
            Marker(
              markerId: const MarkerId('destination'),
              position: _userDestinationLatLng!,
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
        });

        // Wait a bit to ensure state is updated
        Future.delayed(Duration(milliseconds: 100), () {
          if (_userCurrentLocation != null && _userDestinationLatLng != null) {
            // Update map and calculate route
            _mapController.animateCamera(
              CameraUpdate.newLatLngZoom(_userDestinationLatLng!, 15),
            );
          } else {
            debugPrint('Current location: $_userCurrentLocation');
            debugPrint('Destination location: $_userDestinationLatLng');
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
          // Clear previous pickup marker
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
      // Check if both locations are available
      if (_userCurrentLocation == null || _userDestinationLatLng == null) {
        debugPrint('One or both locations are null');
        return polylineCoordinates;
      }

      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult lineResult =
          await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: key,
        request: PolylineRequest(
          origin: PointLatLng(
            _userCurrentLocation!.latitude,
            _userCurrentLocation!.longitude,
          ),
          destination: PointLatLng(
            _userDestinationLatLng!.latitude,
            _userDestinationLatLng!.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      if (lineResult.points.isNotEmpty) {
        polylineCoordinates = lineResult.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        if (polylineCoordinates.isNotEmpty) {
          // Calculate and update the distance
          await _calculateDeliveryDetails(polylineCoordinates);

          // Update the polyline on the map
          generatePolylineFromPoints(polylineCoordinates);
        }
      } else {
        debugPrint('Error fetching polyline: ${lineResult.errorMessage}');
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

  Future<void> _calculateDeliveryDetails(
      List<LatLng> polylineCoordinates) async {
    try {
      if (_userCurrentLocation != null && _userDestinationLatLng != null) {
        double totalDistance = Geolocator.distanceBetween(
          _userCurrentLocation!.latitude,
          _userCurrentLocation!.longitude,
          _userDestinationLatLng!.latitude,
          _userDestinationLatLng!.longitude,
        );

        setState(() {
          finalDistance = totalDistance / 1000; // Convert to kilometers
          roundDistanceKM = double.parse(finalDistance.toStringAsFixed(1));

          // Determine if the route is from the Island to the Mainland
          bool isIslandToMainland = _isIslandToMainland(
            _userCurrentLocation!.latitude,
            _userCurrentLocation!.longitude,
            _userDestinationLatLng!.latitude,
            _userDestinationLatLng!.longitude,
          );

          // Use different pricing if the delivery is from the Island to the Mainland
          if (isIslandToMainland) {
            if (roundDistanceKM <= 5) {
              expressCost = (roundDistanceKM / 0.8) * 345.60;
              standardCost = (roundDistanceKM / 1.6) * 345.60;
              carCost = (roundDistanceKM / 4.2) * 345.60;
            } else if (roundDistanceKM <= 10) {
              expressCost = (roundDistanceKM / 0.8) * 317.12;
              standardCost = (roundDistanceKM / 1.6) * 317.12;
              carCost = (roundDistanceKM / 4.2) * 317.12;
            } else if (roundDistanceKM <= 15) {
              expressCost = (roundDistanceKM / 0.8) * 259.60;
              standardCost = (roundDistanceKM / 1.6) * 259.60;
              carCost = (roundDistanceKM / 4.2) * 259.60;
            } else if (roundDistanceKM <= 20) {
              expressCost = (roundDistanceKM / 0.8) * 283.74;
              standardCost = (roundDistanceKM / 1.6) * 283.74;
              carCost = (roundDistanceKM / 4.2) * 283.74;
            } else if (roundDistanceKM <= 25) {
              expressCost = (roundDistanceKM / 0.8) * 256.31;
              standardCost = (roundDistanceKM / 1.6) * 256.31;
              carCost = (roundDistanceKM / 4.2) * 256.31;
            } else if (roundDistanceKM <= 30) {
              expressCost = (roundDistanceKM / 0.8) * 242.88;
              standardCost = (roundDistanceKM / 1.6) * 242.88;
              carCost = (roundDistanceKM / 4.2) * 242.88;
            } else if (roundDistanceKM <= 35) {
              expressCost = (roundDistanceKM / 0.8) * 236.03;
              standardCost = (roundDistanceKM / 1.6) * 236.03;
              carCost = (roundDistanceKM / 4.2) * 236.03;
            } else if (roundDistanceKM <= 40) {
              expressCost = (roundDistanceKM / 0.8) * 250.06;
              standardCost = (roundDistanceKM / 1.6) * 250.06;
              carCost = (roundDistanceKM / 4.2) * 250.06;
            } else if (roundDistanceKM <= 45) {
              expressCost = (roundDistanceKM / 0.8) * 268.75;
              standardCost = (roundDistanceKM / 1.6) * 268.75;
              carCost = (roundDistanceKM / 4.2) * 268.75;
            } else if (roundDistanceKM <= 50) {
              expressCost = (roundDistanceKM / 0.8) * 255.49;
              standardCost = (roundDistanceKM / 1.6) * 255.49;
              carCost = (roundDistanceKM / 4.2) * 255.49;
            } else {
              expressCost = (roundDistanceKM / 0.8) * 200;
              standardCost = (roundDistanceKM / 1.6) * 200;
              carCost = (roundDistanceKM / 4.2) * 200;
            }
          } else {
            // Default pricing tiers
            if (roundDistanceKM <= 5) {
              expressCost = (roundDistanceKM / 0.8) * 302.46;
              standardCost = (roundDistanceKM / 1.6) * 302.46;
              carCost = (roundDistanceKM / 4.2) * 302.46;
            } else if (roundDistanceKM <= 10) {
              expressCost = (roundDistanceKM / 0.8) * 232.34;
              standardCost = (roundDistanceKM / 1.6) * 232.34;
              carCost = (roundDistanceKM / 4.2) * 232.34;
            } else if (roundDistanceKM <= 15) {
              expressCost = (roundDistanceKM / 0.8) * 222.52;
              standardCost = (roundDistanceKM / 1.6) * 222.52;
              carCost = (roundDistanceKM / 4.2) * 222.52;
            } else if (roundDistanceKM <= 20) {
              expressCost = (roundDistanceKM / 0.8) * 205.06;
              standardCost = (roundDistanceKM / 1.6) * 205.06;
              carCost = (roundDistanceKM / 4.2) * 205.06;
            } else if (roundDistanceKM <= 25) {
              expressCost = (roundDistanceKM / 0.8) * 240.78;
              standardCost = (roundDistanceKM / 1.6) * 240.78;
              carCost = (roundDistanceKM / 4.2) * 240.78;
            } else if (roundDistanceKM <= 30) {
              expressCost = (roundDistanceKM / 0.8) * 189.83;
              standardCost = (roundDistanceKM / 1.6) * 189.83;
              carCost = (roundDistanceKM / 4.2) * 189.93;
            } else if (roundDistanceKM <= 35) {
              expressCost = (roundDistanceKM / 0.8) * 182.98;
              standardCost = (roundDistanceKM / 1.6) * 182.98;
              carCost = (roundDistanceKM / 4.2) * 182.98;
            } else if (roundDistanceKM <= 40) {
              expressCost = (roundDistanceKM / 0.8) * 172.43;
              standardCost = (roundDistanceKM / 1.6) * 172.43;
              carCost = (roundDistanceKM / 4.2) * 172.43;
            } else if (roundDistanceKM <= 45) {
              expressCost = (roundDistanceKM / 0.8) * 169.03;
              standardCost = (roundDistanceKM / 1.6) * 169.03;
              carCost = (roundDistanceKM / 4.2) * 169.03;
            } else if (roundDistanceKM <= 50) {
              expressCost = (roundDistanceKM / 0.8) * 192.86;
              standardCost = (roundDistanceKM / 1.6) * 192.86;
              carCost = (roundDistanceKM / 4.2) * 192.86;
            } else {
              expressCost = (roundDistanceKM / 0.8) * 160;
              standardCost = (roundDistanceKM / 1.6) * 160;
              carCost = (roundDistanceKM / 4.2) * 160;
            }
          }

          // Update formatted values
          standardFormatted = formatMoney(standardCost);
          expressFormatted = formatMoney(expressCost);
          carAmtFormatted = formatMoney(carCost);

          // Update size-related formatted values
          size50Formatted = formatMoney(packageSize50Price);
          size75Formatted = formatMoney(packageSize75Price);
          size100Formatted = formatMoney(packageSize100Price);
        });
      }
    } catch (e) {
      debugPrint('Error calculating delivery details: $e');
    }
  }

  /// Function to check if a delivery is from the Island to the Mainland
  bool _isIslandToMainland(
      double startLat, double startLng, double endLat, double endLng) {
    // Rough coordinates defining Lagos Island region
    bool isStartOnIsland = startLat >= 6.41 &&
        startLat <= 6.46 &&
        startLng >= 3.39 &&
        startLng <= 3.44;

    // Rough coordinates defining Mainland region
    bool isEndOnMainland =
        endLat >= 6.50 && endLat <= 6.60 && endLng >= 3.30 && endLng <= 3.40;

    return isStartOnIsland && isEndOnMainland;
  }

  // Utility function to format the money values
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
    return isExpressSelected! ? expressCost : standardCost;
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
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (context) {
        bool isriderLoading = false; // Track loading state

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Select Delivery Type
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: const Text(
                      "Delivery Options",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color.fromRGBO(0, 31, 62, 1),
                      ),
                    ),
                  ),

                  // Select Box Size
                  bikeDeliveryOptionsPrompt(
                    isStandardSelected: isStandardSelected ?? false,
                    isExpressSelected: isExpressSelected ?? false,
                    is25Selected: is25Selected,
                    is50Selected: is50Selected,
                    is75Selected: is75Selected,
                    is100Selected: is100Selected,
                    onStandardSelected: (newValue) {
                      setModalState(() {
                        isStandardSelected = newValue ?? false;
                        isExpressSelected = false;
                      });
                    },
                    onExpressSelected: (newValue) {
                      setModalState(() {
                        isExpressSelected = newValue ?? false;
                        isStandardSelected = false;
                      });
                    },
                    on25Selected: (newValue) {
                      setModalState(() {
                        is25Selected = newValue ?? false;
                        is50Selected = false;
                        is75Selected = false;
                        is100Selected = false;
                      });
                    },
                    on50Selected: (newValue) {
                      setModalState(() {
                        is25Selected = false;
                        is50Selected = newValue ?? false;
                        is75Selected = false;
                        is100Selected = false;
                      });
                    },
                    on75Selected: (newValue) {
                      setModalState(() {
                        is25Selected = false;
                        is50Selected = false;
                        is75Selected = newValue ?? false;
                        is100Selected = false;
                      });
                    },
                    on100Selected: (newValue) {
                      setModalState(() {
                        is25Selected = false;
                        is50Selected = false;
                        is75Selected = false;
                        is100Selected = newValue ?? false;
                      });
                    },
                    standardFormatted: standardFormatted?.symbolOnLeft,
                    expressFormatted: expressFormatted?.symbolOnLeft,
                    size25Formatted: size25Formatted?.symbolOnLeft,
                    size50Formatted: size50Formatted?.symbolOnLeft,
                    size75Formatted: size75Formatted?.symbolOnLeft,
                    size100Formatted: size100Formatted?.symbolOnLeft,
                  ),

                  const SizedBox(height: 20),

                  // Confirm Button with Loading Animation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: MButtons(
                      onTap: () {
                        Navigator.pop(ctx); // Close the modal first
                        Future.delayed(Duration(milliseconds: 200), () {
                          _modeOfPayment(); // Call the function after the modal closes
                        });
                      },
                      btnText: 'Confirm Delivery',
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void confirmCarOrder(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Select Delivery Type
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: const Text(
                      "Car Delivery Options",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color.fromRGBO(0, 31, 62, 1),
                      ),
                    ),
                  ),

                  // Delivery Options Prompt
                  CarDeliveryOptionsPrompt(
                    amountFormatted: carAmtFormatted?.symbolOnLeft,
                  ),

                  const SizedBox(height: 20),

                  // Confirm Button with Loading Animation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: MButtons(
                      onTap: () {
                        Navigator.pop(ctx); // Close modal first
                        Future.delayed(Duration(milliseconds: 200), () {
                          _modeOfPayment(); // Proceed to payment
                        });
                      },
                      btnText: 'Confirm Car Delivery',
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _modeOfPayment() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        bool dialogIsCashorTransfer = isCashorTransfer;
        bool dialogIsOnlinePayment = isOnlinePayment;

        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  const SizedBox(height: 4.0),
                  _buildPaymentOption(
                    title: 'Cash',
                    value: dialogIsCashorTransfer,
                    onChanged: (newBool) {
                      setDialogState(() {
                        dialogIsCashorTransfer = newBool!;
                        dialogIsOnlinePayment = false;
                      });
                    },
                  ),
                  const SizedBox(height: 2.0),
                  _buildPaymentOption(
                    title: 'Pay Online',
                    value: dialogIsOnlinePayment,
                    onChanged: (newBool) {
                      setDialogState(() {
                        dialogIsOnlinePayment = newBool!;
                        dialogIsCashorTransfer = false;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  MButtons(
                    onTap: () {
                      setState(() {
                        isCashorTransfer = dialogIsCashorTransfer;
                        isOnlinePayment = dialogIsOnlinePayment;
                      });
                      _processPayment();
                      Navigator.of(context).pop();
                    },
                    btnText: 'Process Order',
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Checkbox(
        activeColor: const Color.fromRGBO(0, 31, 62, 1),
        value: value,
        onChanged: onChanged,
        checkColor: Colors.white,
      ),
    );
  }

  void _processPayment() async {
    // Save payment method to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCashorTransfer', isCashorTransfer);
    await prefs.setBool('isOnlinePayment', isOnlinePayment);
    FocusManager.instance.primaryFocus?.unfocus();
    Provider.of<IndexProvider>(context, listen: false).setSelectedIndex(2);
    Navigator.of(context).pop();

    // Show pop-up for cash payment
    _showRiderNotification();

    /* if (isCashorTransfer == true || isOnlinePayment == false) {
      FocusManager.instance.primaryFocus?.unfocus();
      Provider.of<IndexProvider>(context, listen: false).setSelectedIndex(2);
      Navigator.of(context).pop();

      // Show pop-up for cash payment
      _showRiderNotification();
    }
    /* else if (isOnlinePayment == true && isCashorTransfer == false) {
    if (userEmail == null || userEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User email not found'),
          backgroundColor: Color.fromRGBO(255, 91, 82, 1),
        ),
      );
      return;
    }

    try {
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
        onSuccess: (paystackCallback) async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction Successful: ${paystackCallback.reference}'),
              backgroundColor: Color.fromRGBO(0, 31, 62, 1),
            ),
          );

          // Save payment method on successful payment
          await prefs.setBool('isCashorTransfer', false);
          await prefs.setBool('isOnlinePayment', true);

          FocusManager.instance.primaryFocus?.unfocus();
          Provider.of<IndexProvider>(context, listen: false).setSelectedIndex(2);
          Navigator.of(context).pop();

          // Show pop-up for successful online payment
          _showRiderNotification();
        },
        onCancelled: (paystackCallback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction Failed: ${paystackCallback.reference}'),
              backgroundColor: Color.fromRGBO(255, 91, 82, 1),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Payment error: $e');
    }
  } */
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mode of Payment'),
          backgroundColor: Colors.red,
        ),
      );
    } */
  }

  void _showRiderNotification() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: AlertDialog(
            elevation: 2,
            title: Text("Order Confirmed"),
            content: Text(
                "You will receive a notification as soon as a rider accepts your order."),
            actions: [
              MButtons(
                onTap: () {
                  Navigator.of(context).pop();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                btnText: "OK",
              ),
            ],
          ),
        );
      },
    );
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
  double carCost = 0;

  MoneyFormatterOutput? standardFormatted;
  MoneyFormatterOutput? expressFormatted;
  MoneyFormatterOutput? carAmtFormatted;
  MoneyFormatterOutput? size25Formatted;
  MoneyFormatterOutput? size50Formatted;
  MoneyFormatterOutput? size75Formatted;
  MoneyFormatterOutput? size100Formatted;

  String selectedDeliveryType = "Bike";

  double get paymentAmt => _getDeliveryCost() + _getPackagePrice();
  String get formattedPaymentAmt => formatMoney(paymentAmt).symbolOnLeft;
  int get paymentParameter => (paymentAmt).toInt();

  // First, let's create a reusable method for the input field container
  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required Function(Prediction) onItemClick,
    required Function(Prediction) onGetDetailWithLatLng,
    bool isPickupField = false,
  }) {
    return StatefulBuilder(builder: (context, setState) {
      controller.addListener(() {
        setState(() {});
      });

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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map with rounded corners
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

          // Floating action buttons with unique hero tags
          Positioned(
            top: 60,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'location_button', // Add unique hero tag
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
                  heroTag: 'zoom_in_button', // Add unique hero tag
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
                  heroTag: 'zoom_out_button', // Add unique hero tag
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

          // Bottom sheet with glass effect
          DraggableScrollableSheet(
            controller: _bottomSheetController,
            maxChildSize: 0.9,
            initialChildSize: 0.4,
            minChildSize: 0.25,
            builder: (BuildContext context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Modern drag handle
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 12),
                      height: 5,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Scrollable content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        physics: BouncingScrollPhysics(),
                        children: [
                          // Search fields styling
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _buildInputField(
                                  controller: _startPointController,
                                  focusNode: _startPointFN,
                                  hintText: 'Pickup Location',
                                  isPickupField: true,
                                  onItemClick: (prediction) {
                                    _startPointController.text =
                                        prediction.description!;
                                    _startPointController.selection =
                                        TextSelection.fromPosition(
                                      TextPosition(
                                          offset:
                                              prediction.description!.length),
                                    );
                                  },
                                  onGetDetailWithLatLng: (cordinatesCus) {
                                    _userLocToMarker(cordinatesCus);
                                    getPolylinePoints().then(
                                      (cordinates) =>
                                          generatePolylineFromPoints(
                                              cordinates),
                                    );
                                  },
                                ),
                                SizedBox(height: 16),
                                _buildInputField(
                                  controller: _destinationController,
                                  focusNode: _endPointFN,
                                  hintText: 'Destination Location',
                                  onItemClick: (prediction) {
                                    setState(() {
                                      _destinationController.text =
                                          prediction.description!;
                                      _destinationController.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(
                                            offset:
                                                prediction.description!.length),
                                      );
                                    });
                                    _userDesToMarker(prediction);
                                  },
                                  onGetDetailWithLatLng: (cordinates) {
                                    _userDesToMarker(cordinates);
                                    getPolylinePoints().then(
                                      (cordinates) =>
                                          generatePolylineFromPoints(
                                              cordinates),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          FutureBuilder(
                            future: getPolylinePoints(),
                            builder: (deliveryDetails, snapshot) {
                              if (snapshot.hasData) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: SingleChildScrollView(
                                    physics: NeverScrollableScrollPhysics(),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 20),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Distance',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    '${roundDistanceKM ?? 0}Km',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color.fromRGBO(
                                                          0, 31, 62, 1),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (roundDistanceKM != null &&
                                                  roundDistanceKM != 0)
                                                IconButton(
                                                  icon: Icon(Icons.close,
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
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                  child: Divider(
                                                thickness: 0.8,
                                                color: Colors.grey,
                                              ))
                                            ],
                                          ),
                                        ),
                                        ListTile(
                                          leading: Container(
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(8)),
                                                color: Color.fromRGBO(
                                                    0, 70, 67, 0.24)),
                                            height: 80,
                                            width: 60,
                                            child: Icon(
                                              Icons.location_on,
                                              size: 40,
                                              color: const Color.fromRGBO(
                                                  0, 31, 62, 1),
                                            ),
                                          ),
                                          title: Text(
                                            'Pickup Location',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle:
                                              Text(_startPointController.text),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        ListTile(
                                          leading: Container(
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(8)),
                                                color: Color.fromRGBO(
                                                    0, 70, 67, 0.24)),
                                            height: 80,
                                            width: 60,
                                            child: Icon(
                                              Icons.location_on,
                                              size: 40,
                                              color: const Color.fromRGBO(
                                                  0, 31, 67, 1),
                                            ),
                                          ),
                                          title: Text(
                                            'Delivery Location',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle:
                                              Text(_destinationController.text),
                                        ),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                  child: Divider(
                                                thickness: 0.8,
                                                color: Colors.grey,
                                              ))
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 15,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0),
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: selectedDeliveryType,
                                            decoration: InputDecoration(
                                              labelText: "Select Delivery Type",
                                              labelStyle: TextStyle(
                                                color: Color.fromRGBO(
                                                    0, 31, 62, 1),
                                                fontSize: 22,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              border: InputBorder
                                                  .none, // Removes the border completely
                                              enabledBorder: InputBorder
                                                  .none, // No border when not focused
                                              focusedBorder: InputBorder
                                                  .none, // No border when focused
                                            ),
                                            isExpanded: true,
                                            items: ["Bike", "Car", "Bus"]
                                                .map((String type) {
                                              return DropdownMenuItem<String>(
                                                value: type,
                                                child: Text(type),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  selectedDeliveryType =
                                                      newValue;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        MButtons(
                                          onTap: () {
                                            if (selectedDeliveryType ==
                                                "Bike") {
                                              confirmOrder(context);
                                            } else if (selectedDeliveryType ==
                                                "Car") {
                                              confirmCarOrder(context);
                                            } else if (selectedDeliveryType ==
                                                "Bus") {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Image.asset(
                                                          "assets/images/coiming_soon.png",
                                                          width: 250,
                                                          height: 250,
                                                          fit: BoxFit.contain,
                                                        ),
                                                        const SizedBox(
                                                            height: 20),
                                                        const Text(
                                                          "We are working on something amazing.\nStay tuned!",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: const Text(
                                                          "OK",
                                                          style: TextStyle(
                                                              color: Color
                                                                  .fromRGBO(
                                                                      0,
                                                                      31,
                                                                      62,
                                                                      1)),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                            ;
                                          },
                                          btnText: 'Process Order',
                                        ),
                                      ],
                                    ),
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
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ignore: file_names
import 'dart:async';
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
      List<LatLng> polylineCordinates) async {
    try {
      if (_userCurrentLocation != null && _userDestinationLatLng != null) {
        // Calculate direct distance between points
        double totalDistance = Geolocator.distanceBetween(
          _userCurrentLocation!.latitude,
          _userCurrentLocation!.longitude,
          _userDestinationLatLng!.latitude,
          _userDestinationLatLng!.longitude,
        );

        setState(() {
          finalDistance = totalDistance / 1000; // Convert to kilometers
          roundDistanceKM = double.parse(finalDistance.toStringAsFixed(1));

          // Calculate costs based on distance
          expressCost = (roundDistanceKM / 1.2) * 1200;
          standardCost = (roundDistanceKM / 1.6) * 1200;

          // Update formatted values
          standardFormatted = formatMoney(standardCost);
          expressFormatted = formatMoney(expressCost);

          // Update size-related formatted values
          size25Formatted = formatMoney(packageSize25Price);
          size50Formatted = formatMoney(packageSize50Price);
          size75Formatted = formatMoney(packageSize75Price);
          size100Formatted = formatMoney(packageSize100Price);
        });
      }
    } catch (e) {
      debugPrint('Error calculating delivery details: $e');
    }
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
    return isExpressSelected == true ? expressCost : standardCost;
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
              content: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 20.0),
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
                      title: 'Cash or Transfer',
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
                    const SizedBox(height: 8.0),
                    MButtons(
                      onTap: () {
                        setState(() {
                          isCashorTransfer = dialogIsCashorTransfer;
                          isOnlinePayment = dialogIsOnlinePayment;
                        });
                        _processPayment();
                      },
                      btnText: 'Process Order',
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
        activeColor: const Color.fromRGBO(40, 115, 115, 1),
        value: value,
        onChanged: onChanged,
        checkColor: Colors.white,
      ),
    );
  }

  void _processPayment() async {
    if (isCashorTransfer == true && isOnlinePayment == false) {
      Provider.of<IndexProvider>(context, listen: false).setSelectedIndex(2);
      Navigator.of(context).pop();
    } else if (isOnlinePayment == true && isCashorTransfer == false) {
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
          onSuccess: (paystackCallback) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Transaction Successful: ${paystackCallback.reference}'),
                backgroundColor: Color.fromRGBO(0, 70, 67, 1),
              ),
            );
            Provider.of<IndexProvider>(context, listen: false)
                .setSelectedIndex(2);
            Navigator.of(context).pop();
          },
          onCancelled: (paystackCallback) {
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
        debugPrint('Payment error: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mode of Payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  double packageSize25Price = 1250;
  double packageSize50Price = 2500;
  double packageSize75Price = 3750;
  double packageSize100Price = 5000;

  double expressCost = 0;
  double standardCost = 0;

  MoneyFormatterOutput? standardFormatted;
  MoneyFormatterOutput? expressFormatted;
  MoneyFormatterOutput? size25Formatted;
  MoneyFormatterOutput? size50Formatted;
  MoneyFormatterOutput? size75Formatted;
  MoneyFormatterOutput? size100Formatted;

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
              color: Color.fromRGBO(0, 70, 67, 1),
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
                    color: Color.fromRGBO(0, 70, 67, 1),
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
                    color: Color.fromRGBO(0, 70, 67, 1),
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
                    color: Color.fromRGBO(0, 70, 67, 1),
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
                          const SizedBox(
                            height: 20,
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
                                                          0, 70, 67, 1),
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
                                                  0, 70, 67, 1),
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
                                                  0, 70, 67, 1),
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
                                          height: 10,
                                        ),
                                        ListTile(
                                          leading: Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(8)),
                                                  color: Color.fromRGBO(
                                                      0, 70, 67, 0.24)),
                                              height: 80,
                                              width: 60,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(6.0),
                                                child: Image.asset(
                                                  'assets/images/bike.png',
                                                  scale: 12,
                                                ),
                                              )),
                                          title: Text(
                                            'Same-Day Delivery',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            standardFormatted?.symbolOnLeft ??
                                                ''.toString(),
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          trailing: Checkbox(
                                            activeColor: const Color.fromRGBO(
                                                40, 115, 115, 1),
                                            value: isStandardSelected,
                                            onChanged: (newBool) {
                                              setState(() {
                                                isStandardSelected =
                                                    newBool ?? false;
                                                isExpressSelected = false;
                                              });
                                            },
                                            checkColor: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        ListTile(
                                          leading: Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(8)),
                                                  color: Color.fromRGBO(
                                                      0, 70, 67, 0.24)),
                                              height: 80,
                                              width: 60,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(6.0),
                                                child: Image.asset(
                                                  'assets/images/bike.png',
                                                  scale: 12,
                                                ),
                                              )),
                                          title: Text(
                                            'Express Delivery',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            expressFormatted?.symbolOnLeft ??
                                                ''.toString(),
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          trailing: Checkbox(
                                            activeColor: const Color.fromRGBO(
                                                40, 115, 115, 1),
                                            value: isExpressSelected,
                                            onChanged: (newBool) {
                                              setState(() {
                                                isExpressSelected =
                                                    newBool ?? false;
                                                isStandardSelected = false;
                                              });
                                            },
                                            checkColor: Colors.white,
                                          ),
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
                                          height: 10,
                                        ),
                                        SizedBox(
                                          width: 340,
                                          child: Text(
                                            'Our delivery boxes are 3.05 cubic feet, and thus we charge on the space your item takes. Select an option from below',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Quarter the Box',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            size25Formatted?.symbolOnLeft ?? '',
                                          ),
                                          trailing: Checkbox(
                                            activeColor: const Color.fromRGBO(
                                                40, 115, 115, 1),
                                            value: is25Selected,
                                            onChanged: (newBool) {
                                              setState(() {
                                                is25Selected = newBool ?? false;
                                                is50Selected = false;
                                                is75Selected = false;
                                                is100Selected = false;
                                              });
                                            },
                                            checkColor: Colors.white,
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Half the Box',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            size25Formatted?.symbolOnLeft ?? '',
                                          ),
                                          trailing: Checkbox(
                                            activeColor: const Color.fromRGBO(
                                                40, 115, 115, 1),
                                            value: is50Selected,
                                            onChanged: (newBool) {
                                              setState(() {
                                                is25Selected = false;
                                                is50Selected = newBool ?? false;
                                                is75Selected = false;
                                                is100Selected = false;
                                              });
                                            },
                                            checkColor: Colors.white,
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'One quarter the Box',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            size75Formatted?.symbolOnLeft ?? '',
                                          ),
                                          trailing: Checkbox(
                                            activeColor: const Color.fromRGBO(
                                                40, 115, 115, 1),
                                            value: is75Selected,
                                            onChanged: (newBool) {
                                              setState(() {
                                                is25Selected = false;
                                                is50Selected = false;
                                                is75Selected = newBool ?? false;
                                                is100Selected = false;
                                              });
                                            },
                                            checkColor: Colors.white,
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Full Box',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            size100Formatted?.symbolOnLeft ??
                                                '',
                                          ),
                                          trailing: Checkbox(
                                            activeColor: const Color.fromRGBO(
                                                40, 115, 115, 1),
                                            value: is100Selected,
                                            onChanged: (newBool) {
                                              setState(() {
                                                is25Selected = false;
                                                is50Selected = false;
                                                is75Selected = false;
                                                is100Selected =
                                                    newBool ?? false;
                                              });
                                            },
                                            checkColor: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        MButtons(
                                            onTap: () {
                                              confirmOrder(context);
                                            },
                                            btnText: 'Confirm Order')
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 60.0),
                                    child: CircularProgressIndicator(
                                      color: Color.fromRGBO(0, 70, 67, 1),
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

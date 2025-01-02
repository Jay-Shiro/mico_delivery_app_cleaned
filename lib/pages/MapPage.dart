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

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  late LatLng _userCurrentLocation;
  final Set<Marker> _userMarkers = {};
  Map<PolylineId, Polyline> polylines = {};

  Future<void> _getUserLocation() async {
    try {
      Position position = await _determinePosition();
      if (mounted) {
        setState(() {
          _userCurrentLocation = LatLng(position.latitude, position.longitude);
          _userMarkers.add(
            Marker(
              markerId: const MarkerId('user_location'),
              position: _userCurrentLocation,
            ),
          );
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(_userCurrentLocation, 15),
          );
        });
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      _startPointController.text = placemarks.first.street ?? '';
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

  @override
  void initState() {
    super.initState();
    _getUserLocation();
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

  static const String key = "AIzaSyAGpi5xRhCSbDFkoj25FlDkzGXDhILXRow";
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

  static final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.435872, 3.456507),
    zoom: 13,
  );

  late LatLng _userDestinationLatLng;

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
      _userDestinationLatDEC = double.parse(pCoordinates.lat!);
      _userDestinationLngDEC = double.parse(pCoordinates.lng!);
      if (mounted) {
        setState(() {
          _userDestinationLatLng =
              LatLng(_userDestinationLatDEC, _userDestinationLngDEC);
          _userMarkers.add(
            Marker(
              markerId: const MarkerId('destination'),
              position: _userDestinationLatLng,
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(
              _userDestinationLatLng,
              15,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error adding destination marker: $e');
    }
  }

  void _userLocToMarker(Prediction pCoordinates) {
    try {
      _userLocationLatDEC = double.parse(pCoordinates.lat!);
      _userLocationLngDEC = double.parse(pCoordinates.lng!);
      if (mounted) {
        setState(() {
          _userCurrentLocation =
              LatLng(_userDestinationLatDEC, _userDestinationLngDEC);
          _userMarkers.add(
            Marker(
              markerId: const MarkerId('user_des_location'),
              position: _userDestinationLatLng,
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(
              _userDestinationLatLng,
              15,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error adding destination marker: $e');
    }
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    try {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult lineResult =
          await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: key,
        request: PolylineRequest(
          origin: PointLatLng(
            _userCurrentLocation.latitude,
            _userCurrentLocation.longitude,
          ),
          destination: PointLatLng(
            _userDestinationLatLng.latitude,
            _userDestinationLatLng.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      if (lineResult.points.isNotEmpty) {
        polylineCoordinates = lineResult.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        await _calculateDeliveryDetails(polylineCoordinates);
      } else {
        debugPrint('Error fetching polyline: ${lineResult.errorMessage}');
      }
    } catch (e) {
      debugPrint('Error generating polyline: $e');
    }
    return polylineCoordinates;
  }

  void generatePolylineFromPoints(List<LatLng> polylineCordinates) async {
    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCordinates,
      width: 8,
    );
    setState(() {
      polylines[id] = polyline;
    });
  }

  Future<void> _calculateDeliveryDetails(
      List<LatLng> polylineCordinates) async {
    double totalDistance = 0.0;
    for (int i = 0; i < polylineCordinates.length - 1; i++) {
      LatLng start = polylineCordinates[i];
      LatLng end = polylineCordinates[i + 1];
      totalDistance += await Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );
    }

    setState(() {
      finalDistance = totalDistance / 1000;
      roundDistanceKM = double.parse(finalDistance.toStringAsFixed(1));
      expressCost = (roundDistanceKM / 1.2) * 1200;
      standardCost = (roundDistanceKM / 1.6) * 1200;

      // Update formatted values only after cost changes
      standardFormatted = formatMoney(standardCost);
      expressFormatted = formatMoney(expressCost);

      // Update size-related formatted values
      size25Formatted = formatMoney(packageSize25Price);
      size50Formatted = formatMoney(packageSize50Price);
      size75Formatted = formatMoney(packageSize75Price);
      size100Formatted = formatMoney(packageSize100Price);
    });
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

  void _showPaymentPrompt() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Use MainAxisSize.min for dynamic height
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 16.0),
                _buildEmailField(),
                const SizedBox(height: 16.0),
                _buildPriceRow('Delivery Price', _getDeliveryCost()),
                _buildPriceRow('Package Price', _getPackagePrice()),
                const SizedBox(height: 20.0),
                MButtons(
                  onTap: () async {
                    await makePayment().then((_) {
                      Provider.of<IndexProvider>(context, listen: false)
                          .setSelectedIndex(2);
                    });
                  },
                  btnText: 'Pay $formattedPaymentAmt',
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address (needed for receipt)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        TextField(
          controller: _controller1,
          decoration: InputDecoration(
            enabledBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
            fillColor: Colors.white,
            filled: true,
            hintText: 'Enter email address',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double price) {
    final formattedPrice =
        formatMoney(price).symbolOnLeft; // Access formatted string with symbol
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(formattedPrice), // Correctly formatted output
      ],
    );
  }

  Future<void> makePayment() async {
    if (_controller1.text.isEmpty || !_controller1.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Invalid email address'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await PaystackFlutter().pay(
        context: context,
        secretKey: 'sk_test_c69312cc47b0d93bd17d0407d4292f11ee38e2fb',
        amount: paymentParameter * 100,
        email: _controller1.text,
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
              content:
                  Text('Transaction Successful: ${paystackCallback.reference}'),
              backgroundColor: Color.fromRGBO(0, 70, 67, 1),
            ),
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Payment failed: $e'), backgroundColor: Colors.red),
      );
    }
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

  void _processPayment() {
    if (isCashorTransfer == true && isOnlinePayment == false) {
      Provider.of<IndexProvider>(context, listen: false).setSelectedIndex(2);
      Navigator.of(context).pop();
    } else if (isOnlinePayment == true && isCashorTransfer == false) {
      _showPaymentPrompt();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        // google map integration
        GoogleMap(
          initialCameraPosition: _initialPosition,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _mapController.animateCamera(
              CameraUpdate.newLatLngZoom(_userCurrentLocation, 15),
            );
          },
          markers: _userMarkers,
          polylines: Set<Polyline>.of(polylines.values),
        ),
        // reset location button
        Padding(
          padding: const EdgeInsets.only(top: 60.0, right: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                backgroundColor: Color.fromRGBO(0, 70, 67, 1),
                onPressed: () {
                  _mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(_userCurrentLocation, 15));
                },
                child: Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        //draggable bottom sheet
        DraggableScrollableSheet(
          controller: _bottomSheetController,
          maxChildSize: 0.8,
          initialChildSize: 0.4,
          minChildSize: 0.3,
          builder: (BuildContext context, scrollController) {
            return Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(217, 217, 217, 1),
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        height: 9,
                        width: 60,
                        margin:
                            const EdgeInsetsDirectional.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                  SliverList.list(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: GooglePlaceAutoCompleteTextField(
                          focusNode: _startPointFN,
                          textEditingController: _startPointController,
                          debounceTime: 600,
                          googleAPIKey: key,
                          isLatLngRequired: true,
                          countries: ['ng'],
                          getPlaceDetailWithLatLng:
                              (Prediction cordinates_cus) {
                            _userLocToMarker(cordinates_cus);
                            getPolylinePoints().then(
                              (cordinates) => {
                                generatePolylineFromPoints(cordinates),
                              },
                            );
                          },
                          itemClick: (Prediction prediction) {
                            _startPointController.text =
                                prediction.description!;
                            _startPointController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: prediction.description!.length),
                            );
                          },
                          inputDecoration: InputDecoration(
                            hintText: 'Pickup',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: Color.fromRGBO(231, 231, 231, 1),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromRGBO(0, 70, 67, 1),
                              ),
                            ),
                          ),
                          itemBuilder: (context, index, Prediction prediction) {
                            return Container(
                              padding: EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 30,
                                    color: const Color.fromRGBO(0, 70, 67, 1),
                                  ),
                                  SizedBox(
                                    width: 7,
                                  ),
                                  Expanded(
                                      child: Text(
                                          "${prediction.description ?? ""}"))
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: GooglePlaceAutoCompleteTextField(
                          focusNode: _endPointFN,
                          textEditingController: _destinationController,
                          debounceTime: 600,
                          googleAPIKey: key,
                          getPlaceDetailWithLatLng: (Prediction cordinates) {
                            _userDesToMarker(cordinates);
                            getPolylinePoints().then(
                              (cordinates) => {
                                generatePolylineFromPoints(cordinates),
                              },
                            );
                          },
                          itemClick: (Prediction prediction) {
                            _destinationController.text =
                                prediction.description!;
                            _destinationController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                offset: prediction.description!.length,
                              ),
                            );
                          },
                          inputDecoration: InputDecoration(
                            hintText: 'Destination',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: Color.fromRGBO(231, 231, 231, 1),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromRGBO(0, 70, 67, 1),
                              ),
                            ),
                          ),
                          itemBuilder: (context, index, Prediction prediction) {
                            return Container(
                              padding: EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 30,
                                    color: const Color.fromRGBO(0, 70, 67, 1),
                                  ),
                                  SizedBox(
                                    width: 7,
                                  ),
                                  Expanded(
                                      child: Text(
                                          "${prediction.description ?? ""}"))
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      FutureBuilder(
                        future: getPolylinePoints(),
                        builder: (deliveryDetails, snapshot) {
                          if (snapshot.hasData) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: Container(
                                  height: 860,
                                  width: MediaQuery.sizeOf(context).width,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'Distance',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                                  Text(
                                                    '${roundDistanceKM}Km ',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
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
                                                borderRadius: BorderRadius.all(
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
                                          standardFormatted!.symbolOnLeft
                                              .toString(),
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        trailing: Checkbox(
                                          activeColor: const Color.fromRGBO(
                                              40, 115, 115, 1),
                                          value: isStandardSelected,
                                          onChanged: (newBool) {
                                            setState(() {
                                              isStandardSelected = newBool;
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
                                                borderRadius: BorderRadius.all(
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
                                          expressFormatted!.symbolOnLeft
                                              .toString(),
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        trailing: Checkbox(
                                          activeColor: const Color.fromRGBO(
                                              40, 115, 115, 1),
                                          value: isExpressSelected,
                                          onChanged: (newBool) {
                                            setState(() {
                                              isExpressSelected = newBool;
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
                                      Container(
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
                                          size25Formatted?.symbolOnLeft ??
                                              'N/A', // Null-safe access
                                        ),
                                        trailing: Checkbox(
                                          activeColor: const Color.fromRGBO(
                                              40, 115, 115, 1),
                                          value: is25Selected,
                                          onChanged: (newBool) {
                                            setState(() {
                                              is25Selected = newBool ??
                                                  false; // Avoid null assignment
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
                                          'Half of Box',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Text(
                                          size50Formatted?.symbolOnLeft ??
                                              'N/A', // Null-safe access
                                        ),
                                        trailing: Checkbox(
                                          activeColor: const Color.fromRGBO(
                                              40, 115, 115, 1),
                                          value: is50Selected,
                                          onChanged: (newBool) {
                                            setState(() {
                                              is50Selected = newBool ??
                                                  false; // Avoid null assignment
                                              is25Selected = false;
                                              is75Selected = false;
                                              is100Selected = false;
                                            });
                                          },
                                          checkColor: Colors.white,
                                        ),
                                      ),
                                      ListTile(
                                        title: Text(
                                          'One Quarter of Box',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Text(
                                          size75Formatted?.symbolOnLeft ??
                                              'N/A', // Null-safe access
                                        ),
                                        trailing: Checkbox(
                                          activeColor: const Color.fromRGBO(
                                              40, 115, 115, 1),
                                          value: is75Selected,
                                          onChanged: (newBool) {
                                            setState(() {
                                              is75Selected = newBool ??
                                                  false; // Avoid null assignment
                                              is50Selected = false;
                                              is25Selected = false;
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
                                              'N/A', // Null-safe access
                                        ),
                                        trailing: Checkbox(
                                          activeColor: const Color.fromRGBO(
                                              40, 115, 115, 1),
                                          value: is100Selected,
                                          onChanged: (newBool) {
                                            setState(() {
                                              is100Selected = newBool ??
                                                  false; // Avoid null assignment
                                              is50Selected = false;
                                              is75Selected = false;
                                              is25Selected = false;
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
                              ),
                            );
                          } else {
                            return Center(
                              child: Container(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 60.0),
                                  child: CircularProgressIndicator(
                                    color: Color.fromRGBO(0, 70, 67, 1),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ],
    ));
  }
}

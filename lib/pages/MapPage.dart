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
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:money_formatter/money_formatter.dart';

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

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      Position position = await _determinePosition();
      setState(
        () {
          _userCurrentLocation = LatLng(position.latitude, position.longitude);

          // Update the existing marker or add a new one
          if (_userMarkers.isEmpty) {
            _userMarkers.add(
              Marker(
                markerId: const MarkerId('user_location'),
                position: _userCurrentLocation,
                icon: BitmapDescriptor.defaultMarker,
              ),
            );
          } else {
            _userMarkers.clear();
            _userMarkers.add(
              Marker(
                markerId: const MarkerId('user_location'),
                position: _userCurrentLocation,
                icon: BitmapDescriptor.defaultMarker,
              ),
            );
          }
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(_userCurrentLocation, 15),
          );
        },
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      _startPointController.text = placemarks.first.name ?? '';
    } catch (error) {
      print("Error getting address: $error");
      // Handle error, e.g., display a snackbar
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

  static const String key = "AIzaSyAGpi5xRhCSbDFkoj25FlDkzGXDhILXRow";
  final _startPointController = TextEditingController();
  final _destinationController = TextEditingController();
  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();

  final FocusNode _startPointFN = FocusNode();
  final FocusNode _endPointFN = FocusNode();

  @override
  void dispose() {
    super.dispose();
    _startPointFN.dispose();
    _endPointFN.dispose();
  }

  static final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.435872, 3.456507),
    zoom: 13,
  );

  late LatLng _userDestinationLatLng;

  late double _userDestinationLatDEC;

  late double _userDestinationLngDEC;

  // ignore: unused_field
  late double _userLocationLatDEC;

  // ignore: unused_field
  late double _userLocationLngDEC;

  final _controller1 = TextEditingController();
  // ignore: unused_field
  final _controller2 = TextEditingController();

  void _userDesToMarker(Prediction pCordinates) {
    _userDestinationLatDEC = double.parse(pCordinates.lat!);
    _userDestinationLngDEC = double.parse(pCordinates.lng!);
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

  void _userLocToMarker(Prediction pCordinatesLoc) {
    _userLocationLatDEC = double.parse(pCordinatesLoc.lat!);
    _userLocationLngDEC = double.parse(pCordinatesLoc.lng!);
    setState(() {
      _userCurrentLocation = LatLng(_userLocationLatDEC, _userLocationLngDEC);
      _userMarkers.clear();
      _userMarkers.add(
        Marker(
          markerId: const MarkerId('user_des_location'),
          position: _userCurrentLocation,
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          _userCurrentLocation,
          15,
        ),
      );
    });
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult lineResult = await polylinePoints.getRouteBetweenCoordinates(
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
      lineResult.points.forEach(
        (PointLatLng point) async {
          polylineCordinates.add(
            LatLng(point.latitude, point.longitude),
          );
        },
      );
      calculateDistance(polylineCordinates);
      calculateExpress(polylineCordinates);
      calculateStandard(polylineCordinates);
    } else {
      print(lineResult.errorMessage);
    }
    return polylineCordinates;
  }

  void generatePolylineFromPoints(List<LatLng> polylineCordinates) async {
    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCordinates,
      width: 8,
    );
    setState(() async {
      polylines[id] = polyline;
    });
  }

  Future<double> calculateDistance(pCordinates) async {
    double totalDistance = 0.0;
    for (int i = 0; i < pCordinates.length - 1; i++) {
      LatLng start = pCordinates[i];
      LatLng end = pCordinates[i + 1];
      totalDistance += await Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );
    }
    setState(() {
      finalDistance = totalDistance / 1000;
      roundDistanceKM = double.parse((finalDistance).toStringAsFixed(1));
    });

    return roundDistanceKM;
  }

  Future<double> calculateExpress(pCordinates) async {
    for (int i = 0; i < pCordinates.length - 1; i++) {
      setState(() {
        expressCost = (roundDistanceKM / 1.2) * 1200;
      });
    }

    return expressCost;
  }

  Future<double> calculateStandard(pCordinates) async {
    for (int i = 0; i < pCordinates.length - 1; i++) {
      setState(() {
        standardCost = (roundDistanceKM / 1.6) * 1200;
      });
    }

    return standardCost;
  }

  void makePayment() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Container(
            height: 250,
            width: 300,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 4.0, right: 4, top: 16, bottom: 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Icon(Icons.close),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Email Address(required)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _controller1,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                        ),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      hintText: 'Enter email address',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      (isExpressSelected == false
                              ? standardFormated.symbolOnLeft
                              : expressFormated.symbolOnLeft)
                          .toString(),
                    ),
                  ),
                  MButtons(
                      onTap: () {
                        final uniqueTransRef =
                            PayWithPayStack().generateUuidV4();

                        PayWithPayStack().now(
                            context: context,
                            secretKey:
                                "sk_test_c69312cc47b0d93bd17d0407d4292f11ee38e2fb",
                            customerEmail: _controller1.text,
                            reference: uniqueTransRef,
                            currency: "NGN",
                            amount: isExpressSelected == false
                                ? standardAmt
                                : expressAmt,
                            transactionCompleted: () {
                              print("Transaction Successful");
                            },
                            transactionNotCompleted: () {
                              print("Transaction Not Successful!");
                            },
                            callbackUrl: '');
                      },
                      btnText: 'Pay now'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void confirmOrder(BuildContext ctx) {
    makePayment();
  }

  var finalDistance;
  var roundDistanceKM;
  bool? isExpressSelected = false;
  bool? isStandardSelected = false;

  late double expressCost;
  late double standardCost;
  late double standardAmt = double.parse(
    standardCost.toString(),
  );
  late double expressAmt = double.parse(
    expressCost.toString(),
  );

  late MoneyFormatter exFo = MoneyFormatter(
    amount: expressAmt,
    settings: MoneyFormatterSettings(
        symbol: '₦',
        thousandSeparator: ',',
        decimalSeparator: '.',
        symbolAndNumberSeparator: ' ',
        fractionDigits: 0,
        compactFormatType: CompactFormatType.short),
  );
  late MoneyFormatterOutput expressFormated = exFo.output;

  late MoneyFormatter staFo = MoneyFormatter(
    amount: standardAmt,
    settings: MoneyFormatterSettings(
        symbol: '₦',
        thousandSeparator: ',',
        decimalSeparator: '.',
        symbolAndNumberSeparator: ' ',
        fractionDigits: 0,
        compactFormatType: CompactFormatType.short),
  );
  late MoneyFormatterOutput standardFormated = staFo.output;

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
                          debounceTime: 800,
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
                          debounceTime: 800,
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
                                  height: 550,
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
                                          standardFormated.symbolOnLeft
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
                                          expressFormated.symbolOnLeft
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

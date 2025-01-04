import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';
import 'package:provider/provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentPage = 0;

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
                    ? Color.fromRGBO(255, 133, 85, 1)
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
                        color: Color.fromRGBO(255, 133, 82, 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          'Select location',
                          style: TextStyle(fontFamily: 'poppins', fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: GestureDetector(
                          onTap: () {},
                          child: Image.asset(
                            'assets/images/drop_down_icon.png',
                            scale: 28.0,
                          ),
                        ),
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
                                          fontSize: 16.0),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Image.asset(
                                        'assets/images/pointer_r.png',
                                        scale: 20,
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
                      Container(
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
        )),
      ),
    );
  }
}

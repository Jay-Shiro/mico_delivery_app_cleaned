import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class AdBannerCarousel extends StatefulWidget {
  @override
  _AdBannerCarouselState createState() => _AdBannerCarouselState();
}

class _AdBannerCarouselState extends State<AdBannerCarousel> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> adData = [
    {
      'image': 'assets/images/advert_2.png',
      'title': 'Express Delivery',
      'subtitle': 'Get 10% off your first order',
      'gradient': LinearGradient(
        colors: [Color(0xFF001F3E), Color(0xFF004643)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'image': 'assets/images/advert_3.png',
      'title': '',
      'subtitle': '',
      'gradient': LinearGradient(
        colors: [Color(0xffdbe64b), Color(0xffdbe64b)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
    },
    {
      'image': 'assets/images/advert_2.png',
      'title': 'New Service',
      'subtitle': 'Try our premium delivery option',
      'gradient': LinearGradient(
        colors: [Color(0xFFF77F00), Color(0xFFD62828)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
  ];

  Widget _buildAdBanner(
      String imagePath, String title, String subtitle, Gradient gradient) {
    // Check if the current ad is "Advert 3"
    bool isFullWidthAd = imagePath == 'assets/images/advert_3.png';

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(
          horizontal: isFullWidthAd ? 0 : 4), // No margin for full-width ad
      child: isFullWidthAd
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity, // Full width
                height: 180, // Match carousel height
              ),
            )
          : Row(
              children: [
                Image.asset(
                  imagePath,
                  cacheHeight: 210,
                  cacheWidth: 218,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 8),
            autoPlayAnimationDuration: Duration(milliseconds: 800),
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: adData.map((ad) {
            return _buildAdBanner(
              ad['image']!,
              ad['title']!,
              ad['subtitle']!,
              ad['gradient']!,
            );
          }).toList(),
        ),

        SizedBox(height: 10),

        /// Curved Rectangle Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: adData.asMap().entries.map((entry) {
            int index = entry.key;
            bool isActive = _currentIndex == index;

            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: isActive ? 18 : 6,
              height: 6,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? Color.fromRGBO(0, 31, 62, 1) : Colors.grey,
                borderRadius: BorderRadius.circular(8), // Curved effect
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

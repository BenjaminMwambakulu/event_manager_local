import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class FeaturedCourasel extends StatelessWidget {
  const FeaturedCourasel({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> imgList = [
      'https://picsum.photos/id/1011/800/400',
      'https://picsum.photos/id/1012/800/400',
      'https://picsum.photos/id/1013/800/400',
    ];
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(),
        child: CarouselSlider(
          items: imgList
              .map(
                (item) => Container(
                  child: Center(
                    child: Image.network(item, fit: BoxFit.cover, width: 1000),
                  ),
                ),
              )
              .toList(),
          options: CarouselOptions(
            autoPlay: true,
            height: 200.0,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            autoPlayInterval: Duration(seconds: 3),
          ),
        ),
      ),
    );
  }
}

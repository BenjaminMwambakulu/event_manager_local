import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class EventMap extends StatelessWidget {
  const EventMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(51.509364, -0.128928),
          initialZoom: 9.2,
        ),
        children: [
          
          // Alternative: Use OpenStreetMap with proper attribution and less strict tile server
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example',
          ),
      
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'Mapbox',
                onTap: () => launchUrl(
                  Uri.parse('https://www.mapbox.com/'),
                ),
              ),
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () => launchUrl(
                  Uri.parse('https://openstreetmap.org/copyright'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
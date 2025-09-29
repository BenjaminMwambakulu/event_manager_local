import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class EventLocationMap extends StatefulWidget {
  const EventLocationMap({super.key});

  @override
  State<EventLocationMap> createState() => _EventMapState();
}

class _EventMapState extends State<EventLocationMap> {
  LatLng? selectedLocation; // Store the tapped location

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Event Location"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (selectedLocation != null) {
                Navigator.pop(context, selectedLocation);
                // This returns the LatLng to the previous screen
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select a location")),
                );
              }
            },
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(51.509364, -0.128928),
          initialZoom: 9.2,
          onTap: (tapPosition, point) {
            setState(() {
              selectedLocation = point; // Save tapped location
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example',
          ),

          // Show marker if a location is selected
          if (selectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: selectedLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),

          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'Mapbox',
                onTap: () => launchUrl(Uri.parse('https://www.mapbox.com/')),
              ),
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () =>
                    launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

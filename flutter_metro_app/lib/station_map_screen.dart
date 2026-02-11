import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_metro_app/metrostation_class.dart';
import 'package:latlong2/latlong.dart';

class StationMapScreen extends StatelessWidget {
  final MetroStation station;

  const StationMapScreen({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(station.name)),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(station.lat, station.lng),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.flutter_application_1',
          ),

          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                '© OpenStreetMap contributors © CARTO',
                onTap: () {},
              ),
            ],
          ),

          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(station.lat, station.lng),
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
        ],
      ),
    );
  }
}

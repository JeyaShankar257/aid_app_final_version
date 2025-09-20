import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapComponentScreen extends StatefulWidget {
  const MapComponentScreen({super.key});

  @override
  State<MapComponentScreen> createState() => _MapComponentScreenState();
}

class _MapComponentScreenState extends State<MapComponentScreen> {
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    // You can use connectivity_plus for real online check
    isOnline = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Component')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.map, color: Colors.blue),
                SizedBox(width: 8),
                Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: isOnline ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(20.5937, 78.9629),
                initialZoom: 5,
              ),
              children: [
                TileLayer(
                  urlTemplate: isOnline
                      ? 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
                      : '', // Offline tiles can be handled here
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.flutter_app',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

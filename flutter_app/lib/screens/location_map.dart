import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  LatLng? userLocation;
  String? locationError;
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    _getLocation();
    isOnline = true; // You can use connectivity_plus for real online check
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationError = 'Location services are disabled.';
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            locationError = 'Location permissions are denied.';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationError = 'Location permissions are permanently denied.';
        });
        return;
      }
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        userLocation = LatLng(pos.latitude, pos.longitude);
        locationError = null;
      });
    } catch (e) {
      setState(() {
        locationError = 'Unable to get your location.';
      });
    }
  }

  List<Marker> getMarkers() {
    final markers = <Marker>[];
    if (userLocation != null) {
      markers.add(
        Marker(
          point: userLocation!,
          child: const Icon(Icons.location_on, color: Colors.red, size: 32),
        ),
      );
      // Emergency services
      final emergencyServices = [
        {
          'name': 'General Hospital',
          'coords': LatLng(
            userLocation!.latitude + 0.01,
            userLocation!.longitude + 0.005,
          ),
          'icon': Icons.local_hospital,
          'color': Colors.green,
        },
        {
          'name': 'Police Station',
          'coords': LatLng(
            userLocation!.latitude - 0.008,
            userLocation!.longitude - 0.003,
          ),
          'icon': Icons.local_police,
          'color': Colors.blue,
        },
        {
          'name': 'Fire Department',
          'coords': LatLng(
            userLocation!.latitude + 0.005,
            userLocation!.longitude - 0.008,
          ),
          'icon': Icons.local_fire_department,
          'color': Colors.orange,
        },
      ];
      for (var service in emergencyServices) {
        markers.add(
          Marker(
            point: service['coords'] as LatLng,
            child: Icon(
              service['icon'] as IconData,
              color: service['color'] as Color,
              size: 28,
            ),
          ),
        );
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Location & Services')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.map, color: Colors.red),
                SizedBox(width: 8),
                Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: isOnline ? Colors.green : Colors.orange,
                  ),
                ),
                Spacer(),
                if (userLocation != null)
                  Text(
                    'Current Location: ${userLocation!.latitude.toStringAsFixed(6)}, ${userLocation!.longitude.toStringAsFixed(6)}',
                  ),
              ],
            ),
          ),
          if (locationError != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locationError!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: userLocation ?? LatLng(40.7128, -74.0060),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: isOnline
                      ? 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
                      : '', // Offline tiles can be handled here
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.flutter_app',
                ),
                MarkerLayer(markers: getMarkers()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 18),
                  SizedBox(width: 4),
                  Text('Your Location'),
                  SizedBox(width: 12),
                  Icon(Icons.local_hospital, color: Colors.green, size: 18),
                  SizedBox(width: 4),
                  Text('Hospital'),
                  SizedBox(width: 12),
                  Icon(Icons.local_police, color: Colors.blue, size: 18),
                  SizedBox(width: 4),
                  Text('Police Station'),
                  SizedBox(width: 12),
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text('Fire Department'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

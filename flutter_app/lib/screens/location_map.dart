import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final MapController _mapController = MapController();
  final double _currentZoom = 15.0;
  final store = FMTCStore('offline');
  bool isDownloading = false;

  // Example safe places near a default location (can be replaced with real data)
  List<Map<String, dynamic>> getSafePlaces(LatLng userLocation) => [
    {
      'name': 'Hospital',
      'coords': LatLng(
        userLocation.latitude + 0.01,
        userLocation.longitude + 0.005,
      ),
      'icon': Icons.local_hospital,
      'color': Colors.green,
    },
    {
      'name': 'Police Station',
      'coords': LatLng(
        userLocation.latitude - 0.008,
        userLocation.longitude - 0.003,
      ),
      'icon': Icons.local_police,
      'color': Colors.blue,
    },
    {
      'name': 'Fire Station',
      'coords': LatLng(
        userLocation.latitude + 0.005,
        userLocation.longitude - 0.008,
      ),
      'icon': Icons.local_fire_department,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final defaultCenter = LatLng(20.5937, 78.9629);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location & Safe Places'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Offline Map Info',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Offline Map Usage'),
                  content: const Text(
                    'You can use the download button to save map tiles for offline use.\n\n'
                    'This app uses open-source map data from OpenStreetMap.\n\n'
                    'To use offline maps, browse the area you want to save, then tap the download button.\n'
                    'Learn more at https://www.openstreetmap.org/about',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: defaultCenter,
          initialZoom: _currentZoom,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.flutter_app',
            tileProvider: store.getTileProvider(),
          ),
          CurrentLocationLayer(),
          MarkerLayer(
            markers: getSafePlaces(defaultCenter)
                .map(
                  (s) => Marker(
                    point: s['coords'] as LatLng,
                    child: Icon(
                      s['icon'] as IconData,
                      color: s['color'] as Color,
                      size: 28,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isDownloading ? null : _downloadVisibleArea,
        label: isDownloading
            ? const Text('Downloading...')
            : const Text('Download Area'),
        icon: const Icon(Icons.download),
      ),
    );
  }

  Future<void> _downloadVisibleArea() async {
    setState(() => isDownloading = true);
    try {
      // Get the visible bounds from the map controller
      final bounds = _mapController.camera.visibleBounds;
      final minZoom = _currentZoom.floor();
      final maxZoom = (_currentZoom + 2).ceil();

      // Create a RectangleRegion for the visible bounds
      final region = RectangleRegion(bounds);

      // Recreate the TileLayer options to match the map
      final tileLayerOptions = TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.flutter_app',
      );

      // Convert to DownloadableRegion
      final downloadableRegion = region.toDownloadable(
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: tileLayerOptions,
      );

      // Start the download
      store.download.startForeground(region: downloadableRegion);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Map region downloaded successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('⚠ Error: $e')));
      }
    } finally {
      setState(() => isDownloading = false);
    }
  }
}

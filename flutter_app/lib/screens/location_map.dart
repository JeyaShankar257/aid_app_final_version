import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  int _downloadInstanceId = 0;
  Future<void> _showCachedRegions() async {
    try {
      // Get the app support directory and construct the FMTC cache path for 'offline' store
      final baseDir = await getApplicationSupportDirectory();
      final cacheDir = Directory(
        '${baseDir.path}/flutter_map_tile_caching/offline',
      );
      final dir = cacheDir;
      final exists = await dir.exists();
      if (!exists) {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text('Cached Map Tiles'),
            content: Text('No cache directory found.'),
          ),
        );
        return;
      }
      final files = await dir.list(recursive: true).toList();
      final tileFiles = files.whereType<File>().toList();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cached Map Tiles'),
          content: tileFiles.isEmpty
              ? const Text('No cached map tiles found.')
              : SizedBox(
                  width: 300,
                  height: 400,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tileFiles.length,
                    itemBuilder: (context, index) {
                      final file = tileFiles[index];
                      return ListTile(
                        title: Text(
                          file.path.split(Platform.pathSeparator).last,
                        ),
                        subtitle: Text(file.path),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to list cached tiles: $e'),
        ),
      );
    }
  }

  final MapController _mapController = MapController();
  final double _currentZoom = 15.0;
  final store = FMTCStore('offline');
  bool isDownloading = false;
  LatLng? _currentLocation;
  Future<void> _centerOnCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied.'),
          ),
        );
        return;
      }
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_currentLocation!, _currentZoom);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

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
          IconButton(
            icon: const Icon(Icons.storage),
            tooltip: 'View Cached Map Areas',
            onPressed: _showCachedRegions,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: defaultCenter,
          initialZoom: _currentZoom,
          onPositionChanged: (position, hasGesture) {
            // Optionally, you can update something here if needed
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.flutter_app',
            tileProvider: store.getTileProvider(),
          ),
          CurrentLocationLayer(),
          MarkerLayer(
            markers: getSafePlaces(_currentLocation ?? defaultCenter)
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'currentLocation',
            onPressed: _centerOnCurrentLocation,
            tooltip: 'Go to Current Location',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'downloadArea',
            onPressed: isDownloading ? null : _downloadVisibleArea,
            label: isDownloading
                ? const Text('Downloading...')
                : const Text('Cache Map Area'),
            icon: const Icon(Icons.download),
          ),
        ],
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

      // Use a unique instanceId for each download
      _downloadInstanceId++;
      store.download.startForeground(
        region: downloadableRegion,
        instanceId: _downloadInstanceId,
      );

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

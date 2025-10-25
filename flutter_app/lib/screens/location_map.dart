import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  @override
  void initState() {
    super.initState();
    _centerOnCurrentLocationOnStart();
    // Initialize the FMTC tile provider so FlutterMap will use cached tiles
    // when available and fall back to the network otherwise.
    _tileProvider = FMTCTileProvider(
      stores: const {'offline': BrowseStoreStrategy.readUpdateCreate},
    );
  }

  Future<void> _centerOnCurrentLocationOnStart() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_currentLocation!, _currentZoom);
    } catch (_) {
      // Ignore errors on startup
    }
  }

  void _zoomIn() {
    final newZoom = _mapController.camera.zoom + 1;
    _mapController.move(_mapController.camera.center, newZoom);
  }

  void _zoomOut() {
    final newZoom = _mapController.camera.zoom - 1;
    _mapController.move(_mapController.camera.center, newZoom);
  }

  int _downloadInstanceId = 0;

  final MapController _mapController = MapController();
  final double _currentZoom = 15.0;
  final store = FMTCStore('offline');
  late final FMTCTileProvider _tileProvider;
  bool isDownloading = false;
  LatLng? _currentLocation;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  // Nearby places fetched from Overpass (OSM)
  List<Map<String, dynamic>> _nearbyPlaces = [];
  bool _loadingPlaces = false;
  final int _placesRadiusMeters = 2000; // default search radius
  Future<void> _centerOnCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permissions are denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permissions are permanently denied.');
        return;
      }
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_currentLocation!, _currentZoom);
      // Fetch real nearby safe places after obtaining location
      await _fetchNearbySafePlaces();
    } catch (e) {
      _showSnack('Error getting location: $e');
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

  /// Fetch nearby safe places (hospital, police, fire_station) from Overpass API
  Future<void> _fetchNearbySafePlaces({int? radiusMeters}) async {
    if (_currentLocation == null) return;
    final radius = radiusMeters ?? _placesRadiusMeters;
    setState(() {
      _loadingPlaces = true;
    });
    try {
      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final query =
          '''
      [out:json][timeout:25];
      (
        node["amenity"~"hospital|police|fire_station"](around:$radius,${_currentLocation!.latitude},${_currentLocation!.longitude});
        way["amenity"~"hospital|police|fire_station"](around:$radius,${_currentLocation!.latitude},${_currentLocation!.longitude});
        relation["amenity"~"hospital|police|fire_station"](around:$radius,${_currentLocation!.latitude},${_currentLocation!.longitude});
      );
      out center;
      ''';

      final resp = await http.post(url, body: {'data': query});
      if (resp.statusCode != 200) {
        throw Exception('Overpass API returned ${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final elements = decoded['elements'] as List<dynamic>? ?? [];
      final results = <Map<String, dynamic>>[];
      for (final e in elements) {
        final Map<String, dynamic> elem = Map<String, dynamic>.from(e as Map);
        double? lat, lon;
        if (elem['type'] == 'node' &&
            elem.containsKey('lat') &&
            elem.containsKey('lon')) {
          lat = (elem['lat'] as num).toDouble();
          lon = (elem['lon'] as num).toDouble();
        } else if (elem.containsKey('center')) {
          final center = elem['center'] as Map<String, dynamic>;
          lat = (center['lat'] as num).toDouble();
          lon = (center['lon'] as num).toDouble();
        } else {
          continue; // can't determine coords
        }
        final tags = elem['tags'] as Map<String, dynamic>?;
        final amenity = tags != null && tags['amenity'] != null
            ? tags['amenity'] as String
            : 'place';
        final name = tags != null && tags['name'] != null
            ? tags['name'] as String
            : amenity;
        IconData icon = Icons.place;
        Color color = Colors.purple;
        if (amenity == 'hospital') {
          icon = Icons.local_hospital;
          color = Colors.green;
        } else if (amenity == 'police') {
          icon = Icons.local_police;
          color = Colors.blue;
        } else if (amenity == 'fire_station') {
          icon = Icons.local_fire_department;
          color = Colors.orange;
        }
        results.add({
          'name': name,
          'coords': LatLng(lat, lon),
          'amenity': amenity,
          'icon': icon,
          'color': color,
        });
      }

      // Optionally sort by distance from current location
      results.sort((a, b) {
        final dist = Distance();
        final da = dist(_currentLocation!, (a['coords'] as LatLng));
        final db = dist(_currentLocation!, (b['coords'] as LatLng));
        return da.compareTo(db);
      });

      setState(() {
        _nearbyPlaces = results;
      });
    } catch (e) {
      _showSnack('Failed to fetch nearby places: $e');
    } finally {
      setState(() {
        _loadingPlaces = false;
      });
    }
  }

  double? _downloadProgress; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    final defaultCenter = LatLng(20.5937, 78.9629);
    final mapCenter = _currentLocation ?? defaultCenter;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location & Safe Places'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Offline Map Info',
            onPressed: () {
              if (!mounted) return;
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
            icon: const Icon(Icons.wifi_off),
            tooltip: 'Test Offline (instructions)',
            onPressed: () {
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Test Offline Maps'),
                  content: const Text(
                    'To test offline tiles: first use "Cache Map Area" to download tiles for the area you want.\n\n'
                    'Then disable network on your device (Airplane mode) or the emulator, and revisit the cached area in the map.\n\n'
                    'On an Android emulator you can run:\nadb shell svc wifi disable\nadb shell svc data disable\n\n'
                    'Note: adb commands require a connected device and a debug build.',
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
            icon: const Icon(Icons.dataset),
            tooltip: 'Manage Offline Store',
            onPressed: _showStoreStats,
          ),
          // Fetch nearby safe places from Overpass
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: _loadingPlaces
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.place),
                    tooltip: 'Find Nearby Safe Places',
                    onPressed: _fetchNearbySafePlaces,
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: _currentZoom,
              onPositionChanged: (position, hasGesture) {
                // Optionally, you can update something here if needed
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_app',
                tileProvider: _tileProvider,
              ),
              CurrentLocationLayer(),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.my_location,
                        color: Colors.red,
                        size: 36,
                      ),
                    ),
                  // Show fetched nearby places if available, otherwise show example places
                  ...((_nearbyPlaces.isNotEmpty
                          ? _nearbyPlaces
                          : getSafePlaces(_currentLocation ?? defaultCenter))
                      .map(
                        (s) => Marker(
                          point: s['coords'] as LatLng,
                          width: 36,
                          height: 36,
                          child: Icon(
                            s['icon'] as IconData,
                            color: s['color'] as Color,
                            size: 28,
                          ),
                        ),
                      )
                      .toList()),
                ],
              ),
            ],
          ),
          // Zoom buttons in top right
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Zoom In',
                    onPressed: _zoomIn,
                  ),
                  const Divider(height: 1),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    tooltip: 'Zoom Out',
                    onPressed: _zoomOut,
                  ),
                ],
              ),
            ),
          ),
          // Floating action buttons (bottom right)
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
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
                if (_downloadProgress != null) ...{
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: _downloadProgress,
                      minHeight: 8,
                    ),
                  ),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadVisibleArea() async {
    setState(() {
      isDownloading = true;
      _downloadProgress = 0.0;
    });
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
      final streams = store.download.startForeground(
        region: downloadableRegion,
        instanceId: _downloadInstanceId,
      );

      await for (final event in streams.downloadProgress) {
        if (!mounted) break;
        setState(() {
          // percentageProgress is 0-100, convert to 0-1 for LinearProgressIndicator
          _downloadProgress = event.percentageProgress / 100.0;
        });
      }
      // When the stream completes, the download is done
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
      if (mounted) {
        setState(() {
          isDownloading = false;
          _downloadProgress = null;
        });
      }
    }
  }

  Future<void> _showStoreStats() async {
    try {
      final ready = await store.manage.ready;
      if (!ready) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Store Not Ready'),
            content: Text(
              'The offline store "${store.storeName}" does not exist.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final stats = store.stats;
      final length = await stats.length;
      final sizeKiB = await stats.size; // KiB
      final hits = await stats.hits;
      final misses = await stats.misses;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Store: ${store.storeName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tiles: $length'),
              Text('Approx. Size: ${sizeKiB.toStringAsFixed(1)} KiB'),
              Text('Hits: $hits'),
              Text('Misses: $misses'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Reset'),
                    content: const Text('Remove all tiles from this store?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await store.manage.reset();
                  if (!mounted) return;
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    const SnackBar(
                      content: Text('Store reset (tiles removed).'),
                    ),
                  );
                }
              },
              child: const Text('Reset Store'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text(
                      'Delete this store entirely (cannot be undone)?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  // Prevent deleting the store while our widget is performing a download
                  if (isDownloading) {
                    if (!mounted) return;
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Cannot delete store while a download is in progress.',
                        ),
                      ),
                    );
                    return;
                  }
                  try {
                    await store.manage.delete();
                    if (!mounted) return;
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('Store deleted.')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(content: Text('Failed to delete store: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete Store'),
            ),
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
          content: Text('Failed to retrieve store stats: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

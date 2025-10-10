import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

class EmergencyLogEntry {
  final String id;
  final String title;
  final String category;
  final String description;
  final DateTime timestamp;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String severity;

  EmergencyLogEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.timestamp,
    this.location,
    this.latitude,
    this.longitude,
    required this.severity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity,
    };
  }

  factory EmergencyLogEntry.fromJson(Map<String, dynamic> json) {
    return EmergencyLogEntry(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      severity: json['severity'],
    );
  }
}

class EmergencyLogScreen extends StatefulWidget {
  const EmergencyLogScreen({super.key});

  @override
  State<EmergencyLogScreen> createState() => _EmergencyLogScreenState();
}

class _EmergencyLogScreenState extends State<EmergencyLogScreen> {
  List<EmergencyLogEntry> _logEntries = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _emergencyCategories = [
    {
      'name': 'Medical Emergency',
      'icon': Icons.local_hospital,
      'color': Colors.red,
      'severity': 'Critical',
    },
    {
      'name': 'Fire Emergency',
      'icon': Icons.local_fire_department,
      'color': Colors.orange,
      'severity': 'Critical',
    },
    {
      'name': 'Police/Security',
      'icon': Icons.local_police,
      'color': Colors.blue,
      'severity': 'High',
    },
    {
      'name': 'Natural Disaster',
      'icon': Icons.warning,
      'color': Colors.purple,
      'severity': 'Critical',
    },
    {
      'name': 'Accident',
      'icon': Icons.car_crash,
      'color': Colors.deepOrange,
      'severity': 'High',
    },
    {
      'name': 'Safety Incident',
      'icon': Icons.shield,
      'color': Colors.green,
      'severity': 'Medium',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLogEntries();
  }

  Future<void> _loadLogEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? logsJson = prefs.getString('emergency_logs');
      if (logsJson != null) {
        final List<dynamic> logsList = jsonDecode(logsJson);
        setState(() {
          _logEntries = logsList
              .map((json) => EmergencyLogEntry.fromJson(json))
              .toList();
          _logEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        });
      }
    } catch (e) {
      print('Error loading logs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLogEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String logsJson = jsonEncode(
        _logEntries.map((entry) => entry.toJson()).toList(),
      );
      await prefs.setString('emergency_logs', logsJson);
    } catch (e) {
      // TODO: Replace with logging framework in production
      // print('Error saving logs: $e');
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Future<void> _addQuickEmergencyLog(
    String category,
    String title,
    String severity,
  ) async {
    final position = await _getCurrentLocation();

    final entry = EmergencyLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      description:
          'Quick emergency log entry created at ${DateTime.now().toString()}',
      timestamp: DateTime.now(),
      location: position != null
          ? 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}'
          : 'Location unavailable',
      latitude: position?.latitude,
      longitude: position?.longitude,
      severity: severity,
    );

    setState(() {
      _logEntries.insert(0, entry);
    });

    await _saveLogEntries();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Emergency logged: $title'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddLogDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = _emergencyCategories[0]['name'];
    String selectedSeverity = 'Medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Emergency Log Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Brief description of the emergency',
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(labelText: 'Category'),
                  items: _emergencyCategories.map<DropdownMenuItem<String>>((
                    category,
                  ) {
                    return DropdownMenuItem<String>(
                      value: category['name'] as String,
                      child: Row(
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            color: category['color'] as Color,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(category['name'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedSeverity,
                  decoration: InputDecoration(labelText: 'Severity'),
                  items: ['Critical', 'High', 'Medium', 'Low'].map((severity) {
                    return DropdownMenuItem(
                      value: severity,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getSeverityColor(severity),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(severity),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedSeverity = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Additional details about the incident...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                final position = await _getCurrentLocation();

                final entry = EmergencyLogEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  category: selectedCategory,
                  description: descriptionController.text.trim().isEmpty
                      ? 'No additional details provided'
                      : descriptionController.text.trim(),
                  timestamp: DateTime.now(),
                  location: position != null
                      ? 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}'
                      : 'Location unavailable',
                  latitude: position?.latitude,
                  longitude: position?.longitude,
                  severity: selectedSeverity,
                );

                setState(() {
                  _logEntries.insert(0, entry);
                });

                await _saveLogEntries();
                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Emergency log entry added'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Add Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow.shade700;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    final categoryData = _emergencyCategories.firstWhere(
      (cat) => cat['name'] == category,
      orElse: () => {'icon': Icons.emergency, 'color': Colors.grey},
    );
    return categoryData['icon'];
  }

  Color _getCategoryColor(String category) {
    final categoryData = _emergencyCategories.firstWhere(
      (cat) => cat['name'] == category,
      orElse: () => {'icon': Icons.emergency, 'color': Colors.grey},
    );
    return categoryData['color'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Log'),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _showAddLogDialog),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Quick Emergency Buttons
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Emergency Log',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _emergencyCategories.take(3).map((category) {
                          return ElevatedButton.icon(
                            onPressed: () => _addQuickEmergencyLog(
                              category['name'],
                              '${category['name']} - ${DateTime.now().toString().split('.')[0]}',
                              category['severity'],
                            ),
                            icon: Icon(category['icon'], size: 18),
                            label: Text(category['name']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: category['color'].withOpacity(
                                0.1,
                              ),
                              foregroundColor: category['color'],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Divider(),
                // Log Entries List
                Expanded(
                  child: _logEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_note,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No emergency logs yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Use quick buttons above or tap + to add entries',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _logEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _logEntries[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getCategoryColor(
                                    entry.category,
                                  ).withAlpha((0.1 * 255).toInt()),
                                  child: Icon(
                                    _getCategoryIcon(entry.category),
                                    color: _getCategoryColor(entry.category),
                                  ),
                                ),
                                title: Text(entry.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.category} • ${entry.severity}',
                                      style: TextStyle(
                                        color: _getSeverityColor(
                                          entry.severity,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      entry.timestamp.toString().split('.')[0],
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    if (entry.location != null)
                                      Text(
                                        entry.location!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      setState(() {
                                        _logEntries.removeAt(index);
                                      });
                                      _saveLogEntries();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Log entry deleted'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(entry.title),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildDetailRow(
                                              'Category',
                                              entry.category,
                                            ),
                                            _buildDetailRow(
                                              'Severity',
                                              entry.severity,
                                            ),
                                            _buildDetailRow(
                                              'Time',
                                              entry.timestamp.toString().split(
                                                '.',
                                              )[0],
                                            ),
                                            if (entry.location != null)
                                              _buildDetailRow(
                                                'Location',
                                                entry.location!,
                                              ),
                                            SizedBox(height: 12),
                                            Text(
                                              'Description:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(entry.description),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
                // Statistics
                if (_logEntries.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Total Logs',
                          _logEntries.length.toString(),
                          Icons.list,
                        ),
                        _buildStatCard(
                          'Critical',
                          _logEntries
                              .where((e) => e.severity == 'Critical')
                              .length
                              .toString(),
                          Icons.warning,
                        ),
                        _buildStatCard(
                          'This Month',
                          _logEntries
                              .where(
                                (e) =>
                                    e.timestamp.month == DateTime.now().month &&
                                    e.timestamp.year == DateTime.now().year,
                              )
                              .length
                              .toString(),
                          Icons.calendar_month,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

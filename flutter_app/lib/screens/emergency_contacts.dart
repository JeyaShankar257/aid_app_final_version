import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class LocationEntry {
  final String time;
  final double lat;
  final double lng;
  LocationEntry({required this.time, required this.lat, required this.lng});
}

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController senderEmailController = TextEditingController();
  TextEditingController appPasswordController = TextEditingController();
  List<TextEditingController> recipientControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  List<TextEditingController> extraRecipientControllers = [];
  bool sending = false;
  String? status;
  List<LocationEntry> locationTimeline = [];
  Timer? locationTimer;

  @override
  void initState() {
    super.initState();
    _loadFormData();
    _startLocationTracking();
  }

  @override
  void dispose() {
    senderEmailController.dispose();
    appPasswordController.dispose();
    for (var c in recipientControllers) {
      c.dispose();
    }
    for (var c in extraRecipientControllers) {
      c.dispose();
    }
    locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    final prefs = await SharedPreferences.getInstance();
    senderEmailController.text = prefs.getString('sosSenderEmail') ?? '';
    appPasswordController.text = prefs.getString('sosAppPassword') ?? '';
    final recipients = prefs.getStringList('sosRecipients') ?? ['', ''];
    for (
      int i = 0;
      i < recipients.length && i < recipientControllers.length;
      i++
    ) {
      recipientControllers[i].text = recipients[i];
    }
    final extraRecipients = prefs.getStringList('sosExtraRecipients') ?? [];
    extraRecipientControllers = extraRecipients
        .map((r) => TextEditingController(text: r))
        .toList();
    setState(() {});
  }

  Future<void> _saveFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sosSenderEmail', senderEmailController.text);
    await prefs.setString('sosAppPassword', appPasswordController.text);
    await prefs.setStringList(
      'sosRecipients',
      recipientControllers.map((c) => c.text).toList(),
    );
    await prefs.setStringList(
      'sosExtraRecipients',
      extraRecipientControllers.map((c) => c.text).toList(),
    );
  }

  void _startLocationTracking() async {
    await _addLocation();
    locationTimer = Timer.periodic(Duration(minutes: 3), (timer) {
      _addLocation();
    });
  }

  Future<void> _addLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    Position pos = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    final entry = LocationEntry(
      time: TimeOfDay.fromDateTime(DateTime.now()).format(context),
      lat: pos.latitude,
      lng: pos.longitude,
    );
    setState(() {
      locationTimeline.add(entry);
      // Only keep last 30 min (approx 10 entries)
      if (locationTimeline.length > 10) {
        locationTimeline = locationTimeline.sublist(
          locationTimeline.length - 10,
        );
      }
    });
  }

  void _addExtraRecipient() {
    setState(() {
      extraRecipientControllers.add(TextEditingController());
    });
    _saveFormData();
  }

  Future<void> _sendSOS() async {
    setState(() {
      status = null;
      sending = true;
    });
    await _saveFormData();
    final allRecipients = [
      ...recipientControllers.map((c) => c.text),
      ...extraRecipientControllers.map((c) => c.text),
    ].where((r) => r.trim().isNotEmpty).toList();
    if (recipientControllers[0].text.trim().isEmpty ||
        recipientControllers[1].text.trim().isEmpty) {
      setState(() {
        status = 'At least 2 recipient emails are required.';
        sending = false;
      });
      return;
    }
    if (senderEmailController.text.isEmpty ||
        appPasswordController.text.isEmpty) {
      setState(() {
        status = 'Sender email and app password are required.';
        sending = false;
      });
      return;
    }
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (e) {
      setState(() {
        status = 'Unable to get location.';
        sending = false;
      });
      return;
    }
    final lat = pos.latitude;
    final lng = pos.longitude;
    final now = DateTime.now();
    final locationUrl = 'https://maps.google.com/?q=$lat,$lng';
    final timeline = [
      ...locationTimeline,
      if (mounted)
        LocationEntry(
          time: TimeOfDay.fromDateTime(now).format(context),
          lat: lat,
          lng: lng,
        ),
    ];
    String timelineStr = '';
    for (int i = 0; i < timeline.length; i++) {
      timelineStr +=
          '${i + 1}. ${timeline[i].time} - https://maps.google.com/?q=${timeline[i].lat},${timeline[i].lng}\n';
    }
    final message =
        '🚨 SOS Alert - Emergency Location Update\n\nCurrent Time: ${now.toLocal()}\nCurrent Location: $locationUrl\n\nLast 30 min timeline:\n$timelineStr';
    try {
      final res = await http.post(
        Uri.parse(
          'https://aidappfinalversion-production-f72f.up.railway.app/api/send-sos-email',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderEmail': senderEmailController.text,
          'appPassword': appPasswordController.text,
          'recipients': allRecipients,
          'message': message,
        }),
      );
      print('SOS email response status: \\${res.statusCode}');
      print('SOS email response body: \\${res.body}');
      if (res.statusCode == 200) {
        setState(() {
          status = 'SOS email sent successfully!';
        });
      } else {
        setState(() {
          status = 'Failed to send SOS email.';
        });
      }
    } catch (e) {
      print('Error sending SOS email: \\${e.toString()}');
      setState(() {
        status = 'Error sending SOS email.';
      });
    }
    setState(() {
      sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🚨 SOS Email Form')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: senderEmailController,
                decoration: InputDecoration(labelText: 'Sender Gmail'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _saveFormData(),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: appPasswordController,
                decoration: InputDecoration(
                  labelText: 'Sender App Password',
                  helperText: 'Get app password from Gmail security settings.',
                ),
                obscureText: true,
                onChanged: (_) => _saveFormData(),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: recipientControllers[0],
                decoration: InputDecoration(labelText: 'Recipient Email 1'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _saveFormData(),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: recipientControllers[1],
                decoration: InputDecoration(labelText: 'Recipient Email 2'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _saveFormData(),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12),
              ...extraRecipientControllers.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Recipient Email ${entry.key + 3} (optional)',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => _saveFormData(),
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _addExtraRecipient,
                    child: Text('Add More Recipient'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: sending
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _sendSOS();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(sending ? 'Sending SOS...' : 'Send SOS Email'),
                  ),
                ],
              ),
              if (status != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: Text(status!, style: TextStyle(color: Colors.red)),
                  ),
                ),
              SizedBox(height: 24),
              Text(
                'Saved Recipient Emails',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...[
                    ...recipientControllers,
                    ...extraRecipientControllers,
                  ].where((c) => c.text.trim().isNotEmpty).isEmpty
                  ? [
                      Text(
                        'No recipient emails added yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ]
                  : [...recipientControllers, ...extraRecipientControllers]
                        .where((c) => c.text.trim().isNotEmpty)
                        .map((c) => Text(c.text)),
              SizedBox(height: 24),
              Text(
                'Location Timeline (last 30 min)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...locationTimeline.map(
                (entry) => ListTile(
                  title: Text('${entry.time}: ${entry.lat}, ${entry.lng}'),
                  subtitle: Text('Google Maps'),
                  onTap: () {
                    // You can use url_launcher to open this link:
                    // 'https://maps.google.com/?q=${entry.lat},${entry.lng}'
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

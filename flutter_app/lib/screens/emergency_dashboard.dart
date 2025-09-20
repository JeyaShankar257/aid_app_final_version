import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_map.dart';

class EmergencyDashboardScreen extends StatefulWidget {
  const EmergencyDashboardScreen({super.key});

  @override
  State<EmergencyDashboardScreen> createState() =>
      _EmergencyDashboardScreenState();
}

class _EmergencyDashboardScreenState extends State<EmergencyDashboardScreen> {
  int _selectedIndex = 0;
  List<Map<String, String>> emergencyContacts = [];
  bool showEmailForm = false;
  String email = '';
  String password = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = prefs.getStringList('sosContacts') ?? [];
    setState(() {
      emergencyContacts = contacts.map((e) {
        final parts = e.split('::');
        return {
          'email': parts[0],
          'password': parts.length > 1 ? parts[1] : '',
        };
      }).toList();
    });
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = emergencyContacts
        .map((e) => '${e['email']}::${e['password']}')
        .toList();
    await prefs.setStringList('sosContacts', contacts);
  }

  void _addContact() {
    if (email.isEmpty || password.isEmpty) return;
    setState(() {
      emergencyContacts.add({'email': email, 'password': password});
      email = '';
      password = '';
      showEmailForm = false;
    });
    _saveContacts();
  }

  void _removeContact(String emailToRemove) {
    setState(() {
      emergencyContacts.removeWhere((c) => c['email'] == emailToRemove);
    });
    _saveContacts();
  }

  void _sendSOS() {
    // TODO: Implement SOS email sending and location logic
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('SOS sent! (Demo only)')));
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade700),
            child: const Text(
              'Safety Guardian',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Offline Chatbot'),
            selected: _selectedIndex == 1,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Online Chatbot'),
            selected: _selectedIndex == 2,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('First Aid Training'),
            selected: _selectedIndex == 3,
            onTap: () => setState(() => _selectedIndex = 3),
          ),
          ListTile(
            leading: const Icon(Icons.contacts),
            title: const Text('Emergency Contacts'),
            selected: _selectedIndex == 4,
            onTap: () => setState(() => _selectedIndex = 4),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // SOS Button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FloatingActionButton.extended(
                backgroundColor: Colors.red,
                icon: const Icon(Icons.warning),
                label: const Text('SOS'),
                onPressed: _sendSOS,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Embedded Map
          SizedBox(
            height: 250,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const LocationMapScreen(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Navigation Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2,
            children: [
              _featureCard('Offline Chatbot', Icons.chat_bubble_outline, 1),
              _featureCard('Online Chatbot', Icons.cloud, 2),
              _featureCard('First Aid Training', Icons.school, 3),
              _featureCard('Emergency Contacts', Icons.contacts, 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureCard(String title, IconData icon, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.blue.shade700),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContacts() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Emergency Contacts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Contact'),
                onPressed: () => setState(() => showEmailForm = true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (showEmailForm)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      onChanged: (v) => setState(() => email = v),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Password'),
                      onChanged: (v) => setState(() => password = v),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _addContact,
                          child: const Text('Save'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () =>
                              setState(() => showEmailForm = false),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ...emergencyContacts.map(
            (c) => ListTile(
              leading: const Icon(Icons.email),
              title: Text(c['email'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeContact(c['email'] ?? ''),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Dashboard')),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          Center(
            child: Text(
              'Offline Chatbot (Coming Soon)',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Center(
            child: Text(
              'Online Chatbot (Coming Soon)',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Center(
            child: Text(
              'First Aid Training (Coming Soon)',
              style: TextStyle(fontSize: 18),
            ),
          ),
          _buildContacts(),
        ],
      ),
    );
  }
}

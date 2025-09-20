import 'package:flutter/material.dart';
import 'screens/emergency_chatbot.dart';
import 'screens/emergency_contacts.dart';
import 'screens/emergency_dashboard.dart';
import 'screens/emergency_log.dart';
import 'screens/first_aid_training.dart';
import 'screens/location_map.dart';
import 'screens/map_component.dart';
import 'screens/offline_chatbot.dart';
import 'screens/online_chatbot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<String> _screenTitles = [
    'Emergency Chatbot',
    'Emergency Contacts',
    'Emergency Dashboard',
    'Emergency Log',
    'First Aid Training',
    'Location Map',
    'Map Component',
    'Offline Chatbot',
    'Online Chatbot',
  ];

  static final List<Widget> _screens = [
    EmergencyChatbotScreen(),
    EmergencyContactsScreen(),
    EmergencyDashboardScreen(),
    EmergencyLogScreen(),
    FirstAidTrainingScreen(),
    LocationMapScreen(),
    MapComponentScreen(),
    OfflineChatbotScreen(),
    OnlineChatbotScreen(),
  ];

  void _onSelectScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_screenTitles[_selectedIndex]),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Features',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            for (int i = 0; i < _screenTitles.length; i++)
              ListTile(
                title: Text(_screenTitles[i]),
                selected: _selectedIndex == i,
                onTap: () => _onSelectScreen(i),
              ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}

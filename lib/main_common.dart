import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/screens/profile/profile_screen.dart';
import 'ui/screens/stations_map/stations_map_screen.dart';
import 'ui/screens/subscription/subscription_screen.dart';


void mainCommon(List<InheritedProvider> providers) {
  runApp(
    MultiProvider(
      providers: providers,
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 1;

  final List<Widget> _pages = const [
    SubscriptionScreen(),
    StationMapScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFFF4A261),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Pass',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
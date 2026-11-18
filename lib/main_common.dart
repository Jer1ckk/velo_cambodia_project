import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/screens/profile/profile_screen.dart';
import 'ui/screens/stations_map/stations_map_screen.dart';
import 'ui/screens/subscription/subscription_screen.dart';
import 'ui/theme/theme.dart';
import 'ui/states/user_state.dart';

void mainCommon(List<InheritedProvider> providers) {
  runApp(
    MultiProvider(
      providers: providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: veloTheme,
        home: const MyApp(),
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
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    final userState = context.read<UserState>();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed) {
          userState.resumeExpiryChecks();
        } else {
          userState.pauseExpiryChecks();
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Pass',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
